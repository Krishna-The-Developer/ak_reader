import "dart:convert";
import "dart:io";
import "package:archive/archive.dart";
import "package:flutter/foundation.dart";
import "package:pdfx/pdfx.dart";

enum PageStatus { loading, ready, failed }

class ReconstructedPage {
  final int pageIndex;
  final PageStatus status;
  final String? textContent;
  final bool isImage;
  final Uint8List? imageBytes;
  final String? errorMessage;

  const ReconstructedPage({
    required this.pageIndex,
    required this.status,
    this.textContent,
    this.isImage = false,
    this.imageBytes,
    this.errorMessage,
  });
}

class ProgressiveDocumentController extends ChangeNotifier {
  final String filePath;
  final String format;
  final int maxCacheSize;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  String _bookTitle = "";
  String get bookTitle => _bookTitle;

  String _bookAuthor = "";
  String get bookAuthor => _bookAuthor;

  final Map<int, ReconstructedPage> _pageCache = {};
  final List<String> _epubRawPages = [];

  PdfDocument? _pdfDocument;
  double _currentFontSize = 8.0;

  ProgressiveDocumentController({
    required this.filePath,
    required this.format,
    this.maxCacheSize = 20,
  });

  Future<void> initialize() async {
    try {
      final ext = format.toLowerCase().trim();
      if (ext == "epub") {
        await _loadEpubEngine();
      } else if (ext == "pdf") {
        await _loadPdfEngine();
      } else {
        await _loadTxtEngine();
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      _totalPages = 1;
      _pageCache[0] = ReconstructedPage(
        pageIndex: 0,
        status: PageStatus.failed,
        errorMessage: "Error loading book: $e",
      );
      notifyListeners();
    }
  }

  Future<void> _loadEpubEngine() async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("EPUB file does not exist at $filePath");
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final containerFile = _findFile(archive, "meta-inf/container.xml");
    if (containerFile == null) {
      throw Exception("Invalid EPUB: META-INF/container.xml missing");
    }

    final containerXml =
        utf8.decode(containerFile.content as List<int>, allowMalformed: true);
    final fullPathMatch =
        RegExp(r"full-path\s*=\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]")
            .firstMatch(containerXml);
    final opfRelativePath = fullPathMatch?.group(1) ?? "OEBPS/content.opf";

    var opfFile = _findFile(archive, opfRelativePath);
    opfFile ??= archive.files.cast<ArchiveFile?>().firstWhere(
          (f) => f != null && f.name.toLowerCase().endsWith(".opf"),
          orElse: () => null,
        );

    if (opfFile == null) {
      throw Exception("Invalid EPUB: OPF package file not found");
    }

    final opfDir = opfFile.name.contains("/")
        ? opfFile.name.substring(0, opfFile.name.lastIndexOf("/"))
        : "";
    final opfContent =
        utf8.decode(opfFile.content as List<int>, allowMalformed: true);

    final titleMatch =
        RegExp(r"<dc:title[^>]*>([^<]+)</dc:title>", caseSensitive: false)
            .firstMatch(opfContent);
    if (titleMatch != null) {
      _bookTitle = titleMatch.group(1)!.trim();
    }

    final authorMatch =
        RegExp(r"<dc:creator[^>]*>([^<]+)</dc:creator>", caseSensitive: false)
            .firstMatch(opfContent);
    if (authorMatch != null) {
      _bookAuthor = authorMatch.group(1)!.trim();
    }

    final manifestMap = <String, String>{};
    final itemRegex = RegExp(r"<item\b([^>]+)/?>", caseSensitive: false);
    for (final m in itemRegex.allMatches(opfContent)) {
      final attrs = m.group(1) ?? "";
      final idM = RegExp(r"id\s*=\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]")
          .firstMatch(attrs);
      final hrefM = RegExp(r"href\s*=\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]")
          .firstMatch(attrs);
      if (idM != null && hrefM != null) {
        final id = idM.group(1)!;
        final rawHref = Uri.decodeFull(hrefM.group(1)!.split("#").first);
        final fullPath =
            _normalizePath(opfDir.isNotEmpty ? "$opfDir/$rawHref" : rawHref);
        manifestMap[id] = fullPath;
      }
    }

    final spinePaths = <String>[];
    final itemrefRegex = RegExp(r"<itemref\b([^>]+)/?>", caseSensitive: false);
    for (final m in itemrefRegex.allMatches(opfContent)) {
      final attrs = m.group(1) ?? "";
      final idrefM = RegExp(r"idref\s*=\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]")
          .firstMatch(attrs);
      if (idrefM != null) {
        final idref = idrefM.group(1)!;
        final resolvedPath = manifestMap[idref];
        if (resolvedPath != null && !spinePaths.contains(resolvedPath)) {
          spinePaths.add(resolvedPath);
        }
      }
    }

    _epubRawPages.clear();
    for (final path in spinePaths) {
      final chapterFile = _findFile(archive, path);
      if (chapterFile == null) {
        continue;
      }

      final rawHtml =
          utf8.decode(chapterFile.content as List<int>, allowMalformed: true);
      final cleanText = _cleanHtmlToText(rawHtml);

      if (cleanText.length < 20) {
        continue;
      }

      final paginatedChunks = _paginateText(cleanText, _currentFontSize);
      _epubRawPages.addAll(paginatedChunks);
    }

    if (_epubRawPages.isEmpty) {
      _epubRawPages.add("This document is empty or its content is protected.");
    }

    _totalPages = _epubRawPages.length;
    _cacheEpubPages();
  }

  void _cacheEpubPages() {
    _pageCache.clear();
    for (int i = 0; i < _epubRawPages.length; i++) {
      _pageCache[i] = ReconstructedPage(
        pageIndex: i,
        status: PageStatus.ready,
        textContent: _epubRawPages[i],
        isImage: false,
      );
    }
  }

  String _cleanHtmlToText(String html) {
    var s = html
        .replaceAll(
            RegExp(r"<style[^>]*>[\s\S]*?</style>", caseSensitive: false), "")
        .replaceAll(
            RegExp(r"<script[^>]*>[\s\S]*?</script>", caseSensitive: false), "")
        .replaceAll(
            RegExp(r"<head[^>]*>[\s\S]*?</head>", caseSensitive: false), "")
        .replaceAll(
            RegExp(r"<svg[^>]*>[\s\S]*?</svg>", caseSensitive: false), "");

    s = s
        .replaceAll(
            RegExp(r"</?(?:p|div|h[1-6]|blockquote|pre|section|article)[^>]*>",
                caseSensitive: false),
            "\n\n")
        .replaceAll(RegExp(r"<br\s*/?>", caseSensitive: false), "\n")
        .replaceAll(RegExp(r"<li[^>]*>", caseSensitive: false), "\n- ")
        .replaceAll(RegExp(r"</li>", caseSensitive: false), "\n");

    s = s.replaceAll(RegExp(r"<[^>]+>"), "");

    s = s
        .replaceAll("&nbsp;", " ")
        .replaceAll("&#160;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", "\"")
        .replaceAll("&apos;", "'")
        .replaceAll("&rsquo;", "'")
        .replaceAll("&lsquo;", "'")
        .replaceAll("&rdquo;", "\"")
        .replaceAll("&ldquo;", "\"")
        .replaceAll("&mdash;", "--")
        .replaceAll("&ndash;", "-")
        .replaceAll("&hellip;", "...")
        .replaceAll("&bull;", "-")
        .replaceAll("&copy;", "(c)")
        .replaceAll("&reg;", "(r)")
        .replaceAll("&trade;", "(tm)")
        .replaceAllMapped(RegExp(r"&#(\d+);"), (m) {
      try {
        return String.fromCharCode(int.parse(m.group(1)!));
      } catch (_) {
        return "";
      }
    }).replaceAllMapped(RegExp(r"&#x([0-9a-fA-F]+);"), (m) {
      try {
        return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
      } catch (_) {
        return "";
      }
    });

    s = s.replaceAll(RegExp(r"[ \t]+"), " ");
    s = s.replaceAll(RegExp(r"\n\s*\n\s*\n+"), "\n\n");
    return s.trim();
  }

  List<String> _paginateText(String text, double fontSize) {
    if (text.isEmpty) {
      return [];
    }

    final targetChars = ((14.0 / fontSize) * 1050).round().clamp(550, 2600);
    final pages = <String>[];
    final paragraphs = text.split("\n\n");
    var currentChunk = StringBuffer();

    for (final para in paragraphs) {
      final p = para.trim();
      if (p.isEmpty) {
        continue;
      }

      if (p.length > targetChars) {
        if (currentChunk.isNotEmpty) {
          pages.add(currentChunk.toString().trim());
          currentChunk = StringBuffer();
        }

        final sentences = p.split(RegExp(r"(?<=[.?!])\s+"));
        for (final sentence in sentences) {
          if (currentChunk.length + sentence.length > targetChars &&
              currentChunk.isNotEmpty) {
            pages.add(currentChunk.toString().trim());
            currentChunk = StringBuffer();
          }
          if (currentChunk.isNotEmpty) {
            currentChunk.write(" ");
          }
          currentChunk.write(sentence);
        }
        continue;
      }

      if (currentChunk.length + p.length > targetChars &&
          currentChunk.isNotEmpty) {
        pages.add(currentChunk.toString().trim());
        currentChunk = StringBuffer();
      }

      if (currentChunk.isNotEmpty) {
        currentChunk.write("\n\n");
      }
      currentChunk.write(p);
    }

    if (currentChunk.isNotEmpty) {
      final last = currentChunk.toString().trim();
      if (last.isNotEmpty) {
        pages.add(last);
      }
    }

    return pages;
  }

  ArchiveFile? _findFile(Archive archive, String path) {
    final clean = _normalizePath(path).toLowerCase();
    for (final f in archive.files) {
      if (_normalizePath(f.name).toLowerCase() == clean) {
        return f;
      }
    }
    return null;
  }

  String _normalizePath(String rawPath) {
    var p = rawPath.replaceAll(r"\", "/").replaceAll("//", "/");
    if (p.startsWith("/")) {
      p = p.substring(1);
    }
    final parts = p.split("/");
    final resolved = <String>[];
    for (final part in parts) {
      if (part == "." || part.isEmpty) {
        continue;
      }
      if (part == "..") {
        if (resolved.isNotEmpty) {
          resolved.removeLast();
        }
      } else {
        resolved.add(part);
      }
    }
    return resolved.join("/");
  }

  Future<void> _loadPdfEngine() async {
    _pdfDocument = await PdfDocument.openFile(filePath);
    _totalPages = _pdfDocument!.pagesCount;
    if (_bookTitle.isEmpty) {
      final fileName = filePath.split(Platform.pathSeparator).last;
      _bookTitle = fileName.replaceAll(RegExp(r"\.[^.]+$"), "");
    }
  }

  Future<void> _loadTxtEngine() async {
    final file = File(filePath);
    final text = await file.readAsString();
    _epubRawPages.clear();
    _epubRawPages.addAll(_paginateText(text, _currentFontSize));
    _totalPages = _epubRawPages.length;
    _cacheEpubPages();
  }

  ReconstructedPage getPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _totalPages) {
      return ReconstructedPage(
        pageIndex: pageIndex,
        status: PageStatus.failed,
        errorMessage: "Page $pageIndex out of range",
      );
    }

    if (_pageCache.containsKey(pageIndex)) {
      return _pageCache[pageIndex]!;
    }

    if (format.toLowerCase() == "pdf") {
      _pageCache[pageIndex] = ReconstructedPage(
        pageIndex: pageIndex,
        status: PageStatus.loading,
      );
      _renderPdfPage(pageIndex);
      return _pageCache[pageIndex]!;
    }

    return ReconstructedPage(
      pageIndex: pageIndex,
      status: PageStatus.failed,
      errorMessage: "Content missing",
    );
  }

  Future<void> _renderPdfPage(int pageIndex) async {
    if (_pdfDocument == null) {
      return;
    }
    try {
      final page = await _pdfDocument!.getPage(pageIndex + 1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (pageImage != null) {
        _pageCache[pageIndex] = ReconstructedPage(
          pageIndex: pageIndex,
          status: PageStatus.ready,
          isImage: true,
          imageBytes: pageImage.bytes,
        );
        _pruneCache(pageIndex);
        notifyListeners();
      }
    } catch (e) {
      _pageCache[pageIndex] = ReconstructedPage(
        pageIndex: pageIndex,
        status: PageStatus.failed,
        errorMessage: "Failed to render PDF: $e",
      );
      notifyListeners();
    }
  }

  void _pruneCache(int currentPage) {
    if (_pageCache.length <= maxCacheSize) {
      return;
    }
    int furthest = -1;
    int maxDist = -1;
    for (final key in _pageCache.keys) {
      final dist = (key - currentPage).abs();
      if (dist > maxDist) {
        maxDist = dist;
        furthest = key;
      }
    }
    if (furthest != -1) {
      _pageCache.remove(furthest);
    }
  }

  void prefetch(int pageIndex) {
    if (format.toLowerCase() == "pdf") {
      if (pageIndex + 1 < _totalPages &&
          !_pageCache.containsKey(pageIndex + 1)) {
        _renderPdfPage(pageIndex + 1);
      }
      if (pageIndex - 1 >= 0 && !_pageCache.containsKey(pageIndex - 1)) {
        _renderPdfPage(pageIndex - 1);
      }
    }
  }

  void rePaginateOnFontSizeChange(
      {required double fontSize, required double lineHeight}) {
    if (format.toLowerCase() == "pdf") {
      return;
    }
    _currentFontSize = fontSize;
    initialize();
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }
}
