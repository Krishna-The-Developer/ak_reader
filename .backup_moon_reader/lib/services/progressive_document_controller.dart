import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

enum PageStatus { ready, loading, failed }

enum PageContentType { text, image, pdf }

class _PageSpec {
  final PageContentType type;
  final String? text;
  final Uint8List? imageBytes;
  final int? pdfIndex;

  _PageSpec.text(this.text)
      : type = PageContentType.text,
        imageBytes = null,
        pdfIndex = null;

  _PageSpec.image(this.imageBytes)
      : type = PageContentType.image,
        text = null,
        pdfIndex = null;

  _PageSpec.pdf(this.pdfIndex)
      : type = PageContentType.pdf,
        text = null,
        imageBytes = null;
}

class ReconstructedPage {
  final int index;
  final PageStatus status;
  final String? textContent;
  final Uint8List? imageBytes;
  final bool isImage;
  final String? errorMessage;

  ReconstructedPage({
    required this.index,
    required this.status,
    this.textContent,
    this.imageBytes,
    this.isImage = false,
    this.errorMessage,
  });
}

class ProgressiveDocumentController extends ChangeNotifier {
  final String filePath;
  final String format;
  final int maxCacheSize;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isImageBook = false;
  bool get isImageBook => _isImageBook;

  String? _initError;
  String? get initError => _initError;

  String _bookTitle = '';
  String get bookTitle => _bookTitle;

  String _bookAuthor = '';
  String get bookAuthor => _bookAuthor;

  final List<_PageSpec> _specs = [];
  final Map<int, ReconstructedPage> _cache = {};
  final List<int> _lruOrder = [];
  PdfDocument? _pdfDoc;

  ProgressiveDocumentController({
    required this.filePath,
    required this.format,
    this.maxCacheSize = 30,
  });

  Future<void> initialize() async {
    final file = File(filePath);
    if (!await file.exists()) {
      _initError = "File not found: $filePath";
      _isInitialized = true;
      notifyListeners();
      return;
    }

    String fmt = format.toLowerCase().replaceAll('.', '').trim();
    if (fmt.isEmpty) {
      fmt = filePath.split('.').last.toLowerCase().replaceAll('.', '').trim();
    }

    try {
      if (fmt == 'pdf') {
        _isImageBook = true;
        _pdfDoc = await PdfDocument.openFile(filePath);
        final count = _pdfDoc!.pagesCount > 0 ? _pdfDoc!.pagesCount : 1;
        for (int i = 0; i < count; i++) {
          _specs.add(_PageSpec.pdf(i));
        }
      } else if (fmt == 'cbz' || fmt == 'cbr' || fmt == 'zip') {
        _isImageBook = true;
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final imgFiles = archive.files.where((f) {
          final n = f.name.toLowerCase();
          return f.isFile &&
              (n.endsWith('.jpg') ||
                  n.endsWith('.jpeg') ||
                  n.endsWith('.png') ||
                  n.endsWith('.webp'));
        }).toList();
        imgFiles.sort((a, b) => a.name.compareTo(b.name));
        for (final f in imgFiles) {
          _specs
              .add(_PageSpec.image(Uint8List.fromList(f.content as List<int>)));
        }
      } else if (fmt == 'epub') {
        await _parseEpub(file);
      } else {
        await _parsePlainText(file);
      }
    } catch (e) {
      _initError = e.toString();
    }

    if (_specs.isEmpty) {
      _specs.add(_PageSpec.text("No readable content found."));
    }

    _totalPages = _specs.length;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _parseEpub(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    String opfPath = '';
    final containerFile = archive.findFile('META-INF/container.xml');
    if (containerFile != null) {
      final xml =
          utf8.decode(containerFile.content as List<int>, allowMalformed: true);
      final match = RegExp(r'full-path\s*=\s*["\x27]([^"\x27]+)["\x27]',
              caseSensitive: false)
          .firstMatch(xml);
      if (match != null) opfPath = match.group(1) ?? '';
    }

    ArchiveFile? opfFile;
    if (opfPath.isNotEmpty) opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      for (final f in archive.files) {
        if (f.name.toLowerCase().endsWith('.opf')) {
          opfFile = f;
          opfPath = f.name;
          break;
        }
      }
    }

    final manifestHrefs = <String, String>{};
    final spineIdrefs = <String>[];
    String coverId = '';
    String opfDir = '';
    if (opfPath.contains('/')) {
      opfDir = opfPath.substring(0, opfPath.lastIndexOf('/') + 1);
    }

    if (opfFile != null) {
      final opfXml =
          utf8.decode(opfFile.content as List<int>, allowMalformed: true);

      final titleMatch =
          RegExp(r'<dc:title[^>]*>([\s\S]*?)<\/dc:title>', caseSensitive: false)
              .firstMatch(opfXml);
      if (titleMatch != null) _bookTitle = _cleanXml(titleMatch.group(1));

      final authorMatch = RegExp(r'<dc:creator[^>]*>([\s\S]*?)<\/dc:creator>',
              caseSensitive: false)
          .firstMatch(opfXml);
      if (authorMatch != null) _bookAuthor = _cleanXml(authorMatch.group(1));

      final coverMeta = RegExp(
              r'<meta\s+[^>]*name=["\x27]cover["\x27][^>]*content=["\x27]([^"\x27]+)["\x27]',
              caseSensitive: false)
          .firstMatch(opfXml);
      if (coverMeta != null) coverId = coverMeta.group(1) ?? '';

      final itemMatches =
          RegExp(r'<item\s+([^>]+)>', caseSensitive: false).allMatches(opfXml);
      for (final m in itemMatches) {
        final tag = m.group(1) ?? '';
        final idMatch = RegExp(r'id=["\x27]([^"\x27]+)["\x27]').firstMatch(tag);
        final hrefMatch =
            RegExp(r'href=["\x27]([^"\x27]+)["\x27]').firstMatch(tag);
        final propMatch =
            RegExp(r'properties=["\x27]([^"\x27]+)["\x27]').firstMatch(tag);

        if (idMatch != null && hrefMatch != null) {
          final id = idMatch.group(1)!;
          final href = Uri.decodeFull(hrefMatch.group(1)!);
          manifestHrefs[id] = href;
          if (propMatch != null &&
              propMatch.group(1)!.contains('cover-image')) {
            coverId = id;
          }
        }
      }

      final spineMatches = RegExp(
              r'<itemref\s+[^>]*idref=["\x27]([^"\x27]+)["\x27]',
              caseSensitive: false)
          .allMatches(opfXml);
      for (final m in spineMatches) {
        final idref = m.group(1);
        if (idref != null) spineIdrefs.add(idref);
      }
    }

    // 1. Cover Page
    ArchiveFile? coverImgFile;
    if (coverId.isNotEmpty && manifestHrefs.containsKey(coverId)) {
      final href = manifestHrefs[coverId]!;
      final p =
          (opfDir.isNotEmpty ? '$opfDir$href' : href).replaceAll('\\', '/');
      coverImgFile = archive.findFile(p);
    }
    if (coverImgFile == null) {
      for (final f in archive.files) {
        final n = f.name.toLowerCase();
        if ((n.contains('cover') || n.contains('titlepage')) &&
            (n.endsWith('.jpg') ||
                n.endsWith('.jpeg') ||
                n.endsWith('.png') ||
                n.endsWith('.webp'))) {
          coverImgFile = f;
          break;
        }
      }
    }
    if (coverImgFile != null) {
      _specs.add(_PageSpec.image(
          Uint8List.fromList(coverImgFile.content as List<int>)));
    }

    // 2. Resolve Spine Chapters
    final List<ArchiveFile> chapterFiles = [];
    for (final idref in spineIdrefs) {
      final href = manifestHrefs[idref];
      if (href != null) {
        final fullPath =
            (opfDir.isNotEmpty ? '$opfDir$href' : href).replaceAll('\\', '/');
        final target = archive.findFile(fullPath) ??
            archive.files.firstWhere(
              (f) =>
                  f.name.toLowerCase() == fullPath.toLowerCase() ||
                  f.name.endsWith(href),
              orElse: () => ArchiveFile('', 0, []),
            );
        if (target.name.isNotEmpty) chapterFiles.add(target);
      }
    }

    if (chapterFiles.isEmpty) {
      for (final f in archive.files) {
        final n = f.name.toLowerCase();
        if (f.isFile &&
            (n.endsWith('.xhtml') ||
                n.endsWith('.html') ||
                n.endsWith('.htm')) &&
            !n.contains('toc')) {
          chapterFiles.add(f);
        }
      }
      chapterFiles.sort((a, b) => a.name.compareTo(b.name));
    }

    // 3. Natural Zero-Scroll Pagination (~1600-1800 chars per page: fits 70% book area perfectly)
    for (final f in chapterFiles) {
      String rawHtml = "";
      if (f.content is List<int>) {
        rawHtml = utf8.decode(f.content as List<int>, allowMalformed: true);
      } else if (f.rawContent != null) {
        rawHtml =
            utf8.decode(f.rawContent!.toUint8List(), allowMalformed: true);
      }

      final chapterText = _extractTextFromHtml(rawHtml);
      if (chapterText.trim().isEmpty) continue;

      _chunkChapterIntoPages(chapterText.trim(), targetChars: 1750);
    }
  }

  void _chunkChapterIntoPages(String text, {int targetChars = 1750}) {
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    StringBuffer current = StringBuffer();

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      if (current.length + trimmed.length > targetChars && current.isNotEmpty) {
        _specs.add(_PageSpec.text(current.toString().trim()));
        current = StringBuffer();
      }

      if (trimmed.length > targetChars) {
        final words = trimmed.split(' ');
        for (final w in words) {
          if (current.length + w.length > targetChars && current.isNotEmpty) {
            _specs.add(_PageSpec.text(current.toString().trim()));
            current = StringBuffer();
          }
          current.write('$w ');
        }
        current.write('\n\n');
      } else {
        current.write('$trimmed\n\n');
      }
    }

    if (current.isNotEmpty) {
      _specs.add(_PageSpec.text(current.toString().trim()));
    }
  }

  Future<void> _parsePlainText(File file) async {
    final bytes = await file.readAsBytes();
    String text = '';
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    _chunkChapterIntoPages(text, targetChars: 1750);
  }

  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'<(br|p|div|h[1-6]|li)[^>]*>', caseSensitive: false),
            '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _cleanXml(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  void _recordAccess(int index) {
    _lruOrder.remove(index);
    _lruOrder.add(index);
    if (_cache.length > maxCacheSize) {
      final oldest = _lruOrder.removeAt(0);
      _cache.remove(oldest);
    }
  }

  void setReadingPosition(int page) {}

  void retryPage(int index) {
    _cache.remove(index);
    notifyListeners();
  }

  ReconstructedPage getPage(int index) {
    if (index < 0 || index >= _specs.length) {
      return ReconstructedPage(
          index: index, status: PageStatus.failed, errorMessage: "End of Book");
    }

    if (_cache.containsKey(index)) {
      _recordAccess(index);
      return _cache[index]!;
    }

    final spec = _specs[index];
    if (spec.type == PageContentType.text) {
      final page = ReconstructedPage(
          index: index, status: PageStatus.ready, textContent: spec.text);
      _cache[index] = page;
      _recordAccess(index);
      return page;
    } else if (spec.type == PageContentType.image) {
      final page = ReconstructedPage(
          index: index,
          status: PageStatus.ready,
          isImage: true,
          imageBytes: spec.imageBytes);
      _cache[index] = page;
      _recordAccess(index);
      return page;
    } else {
      _schedulePdfLoad(index, spec.pdfIndex ?? index);
      return ReconstructedPage(
          index: index, status: PageStatus.loading, isImage: true);
    }
  }

  Future<void> _schedulePdfLoad(int pageIndex, int pdfIndex) async {
    if (_pdfDoc == null) return;
    try {
      final page = await _pdfDoc!.getPage(pdfIndex + 1);
      final img =
          await page.render(width: page.width * 2, height: page.height * 2);
      await page.close();
      final reconstructed = ReconstructedPage(
        index: pageIndex,
        status: PageStatus.ready,
        isImage: true,
        imageBytes: img?.bytes,
      );
      _cache[pageIndex] = reconstructed;
      _recordAccess(pageIndex);
      notifyListeners();
    } catch (e) {
      _cache[pageIndex] = ReconstructedPage(
          index: pageIndex,
          status: PageStatus.failed,
          errorMessage: e.toString());
      notifyListeners();
    }
  }
}
