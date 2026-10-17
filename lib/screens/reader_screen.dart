import "dart:io";
import "dart:math" as math;
import "package:flutter/material.dart";
import "../models/book_model.dart";
import "../models/page_annotation.dart";
import "../services/progressive_document_controller.dart";
import "../services/sound_service.dart";
import "../widgets/hardcover_view.dart";
import "../widgets/page_curl_view.dart";
import "../widgets/wooden_desk_frame.dart";
import "../widgets/ribbon_bookmark.dart";
import "../widgets/color_wheel_picker.dart";

enum ReadingMode { curl3d, horizontal, vertical }

class ReaderScreen extends StatefulWidget {
  final LocalBook book;
  final ReadingMode initialMode;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialMode = ReadingMode.curl3d,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  void _jumpToBookmark() {
    if (widget.book.bookmarkedPages.isEmpty) return;
    final target = widget.book.bookmarkedPages.first;
    SoundService.playWoodTap();
    if (!_isCoverOpen) {
      _openHardCover();
    }
    setState(() {
      _currentPage = target;
      _bookmarkDrapeController.value = 1.0;
    });
    SoundService.playWoodTap();
    if (!_isCoverOpen) {
      _openHardCover();
    }
    setState(() {
      _currentPage = target;
      _bookmarkDrapeController.value = 1.0;
    });
    if (_currentMode == ReadingMode.horizontal && _horizontalController.hasClients) {
      _horizontalController.jumpToPage(target);
    } else if (_currentMode == ReadingMode.vertical && _verticalController.hasClients) {
      _verticalController.jumpTo(target * _computedBookHeight);
    }
    _saveProgress(target);
  }

  late ProgressiveDocumentController _controller;
  late int _currentPage;
  late ReadingMode _currentMode;
  bool _loading = true;
  bool _isCoverOpen = false;

  late AnimationController _bookmarkDrapeController;
  late Animation<double> _bookmarkDrapeAnimation;

  ActiveTool _activeTool = ActiveTool.none;
  double _penWidth = 2.0;
  double _highlighterWidth = 12.0;
  Color _highlightColor = const Color(0xFFFFEB3B);
  Color _penColor = const Color(0xFF1A237E);
  Color _ribbonColor = const Color(0xFFC62828);

  final List<Offset> _activePoints = [];

  double _fontSize = 12.0;
  final double _lineHeight = 1.35;
  Color _pageBgColor = const Color(0xFFF5EACB);

  late PageController _horizontalController;
  late ScrollController _verticalController;

  double _computedBookHeight = 500.0;

  @override
  void initState() {
    super.initState();
    SoundService.init();
    _currentMode = widget.initialMode;
    _currentPage = widget.book.lastPage;

    _bookmarkDrapeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _bookmarkDrapeAnimation = CurvedAnimation(
      parent: _bookmarkDrapeController,
      curve: Curves.easeOutCubic,
    );

    if (widget.book.bookmarkedPages.contains(_currentPage)) {
      _bookmarkDrapeController.value = 1.0;
    }

    _horizontalController = PageController(initialPage: _currentPage);
    _verticalController = ScrollController();
    _verticalController.addListener(_onVerticalScroll);

    _controller = ProgressiveDocumentController(
      filePath: widget.book.filePath,
      format: widget.book.format,
    )..addListener(_onControllerUpdate);

    _initDocument();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onVerticalScroll() {
    if (_currentMode != ReadingMode.vertical ||
        !_verticalController.hasClients) {
      return;
    }
    final double pageSlot = _computedBookHeight + 16.0;
    if (pageSlot <= 0) return;
    final int scrolledPage = (_verticalController.offset / pageSlot)
        .round()
        .clamp(0, _controller.totalPages - 1);
    if (scrolledPage != _currentPage) {
      _saveProgress(scrolledPage);
    }
  }

  Future<void> _initDocument() async {
    await _controller.initialize();
    if (!mounted) return;

    if (widget.book.title.trim().isEmpty ||
        widget.book.title.toLowerCase() == "unknown") {
      String cleanTitle = _controller.bookTitle.trim();
      if (cleanTitle.isEmpty || cleanTitle.toLowerCase() == "unknown") {
        final fileName = widget.book.filePath
            .split(Platform.pathSeparator)
            .last
            .split("/")
            .last;
        cleanTitle = fileName
            .replaceAll(RegExp(r"\.[^.]+$"), "")
            .replaceAll(RegExp(r"[\-_]+"), " ")
            .trim();
      }
      if (cleanTitle.isNotEmpty) {
        widget.book.title = cleanTitle;
      }
    }

    if (widget.book.author.trim().isEmpty ||
        widget.book.author.toLowerCase() == "unknown author") {
      if (_controller.bookAuthor.isNotEmpty) {
        widget.book.author = _controller.bookAuthor;
      }
    }

    if (_currentPage >= _controller.totalPages) {
      _currentPage = 0;
    }

    setState(() {
      _loading = false;
      widget.book.totalPages = _controller.totalPages;
      widget.book.safeSave();
    });

    SoundService.playBookOpenThud();
  }

  @override
  void dispose() {
    _verticalController.removeListener(_onVerticalScroll);
    _bookmarkDrapeController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _openHardCover() {
    SoundService.playBookOpenThud();
    setState(() {
      _isCoverOpen = true;
    });
  }

  void _closeHardCover() {
    SoundService.playBookOpenThud();
    setState(() {
      _isCoverOpen = false;
      _currentPage = 0;
      widget.book.lastPage = 0;
      widget.book.safeSave();
    });
  }

  void _saveProgress(int page) {
    if (_currentPage == page) return;
    setState(() {
      _currentPage = page;
      if (widget.book.bookmarkedPages.contains(page)) {
        _bookmarkDrapeController.value = 1.0;
      } else {
        _bookmarkDrapeController.value = 0.0;
      }
    });

    if (_currentMode != ReadingMode.horizontal) {
      SoundService.playPageTurn();
    }
    widget.book.lastPage = page;
    widget.book.lastRead = DateTime.now();
    widget.book.safeSave();
    _controller.prefetch(page);
  }

  String? _getBookmarkNote(int pageIndex) {
    for (final raw in widget.book.highlights) {
      final a = PageAnnotation.fromHiveString(raw);
      if (a != null &&
          a.pageIndex == pageIndex &&
          (a.tool == "bookmark_note" || a.tool == "note")) {
        return a.text;
      }
    }
    return null;
  }

  void _toggleBookmark() {
    setState(() {
      if (widget.book.bookmarkedPages.contains(_currentPage)) {
        widget.book.bookmarkedPages.remove(_currentPage);
        _bookmarkDrapeController.reverse();
      } else {
        widget.book.bookmarkedPages.add(_currentPage);
        _bookmarkDrapeController.forward(from: 0.0);
      }
      widget.book.safeSave();
    });
  }

  Future<void> _showAddNoteDialog({int? targetPage}) async {
    final pageToNote = targetPage ?? _currentPage;
    final currentNote = _getBookmarkNote(pageToNote) ?? "";
    final textController = TextEditingController(text: currentNote);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF22130B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Page ${pageToNote + 1} Note",
                style: const TextStyle(
                  color: Color(0xFFFFD59E),
                  fontFamily: "serif",
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Write your thoughts, summary or chapter note:",
                style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLength: 120,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Enter notes for this page...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  counterStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0x44000000),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD7A878)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentNote.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, "__DELETE__"),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D4E24),
                    ),
                    onPressed: () =>
                        Navigator.pop(ctx, textController.text.trim()),
                    child: const Text("Save",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      widget.book.highlights.removeWhere((raw) {
        final a = PageAnnotation.fromHiveString(raw);
        return a != null &&
            a.pageIndex == pageToNote &&
            (a.tool == "bookmark_note" || a.tool == "note");
      });

      if (result != "__DELETE__" && result.isNotEmpty) {
        final annotation = PageAnnotation(
          pageIndex: pageToNote,
          tool: "bookmark_note",
          colorValue: _ribbonColor.toARGB32(),
          boundingBox: Rect.zero,
          text: result,
        );
        widget.book.highlights.add(annotation.toHiveString());
        if (!widget.book.bookmarkedPages.contains(pageToNote)) {
          widget.book.bookmarkedPages.add(pageToNote);
        }
      }
      widget.book.safeSave();
    });
  }

  void _onDrawingPanStart(DragStartDetails details) {
    SoundService.onWritingTouchDown(_activeTool.name);
    if (_activeTool == ActiveTool.none) return;
    if (_activeTool == ActiveTool.eraser) {
      _eraseAtPoint(details.localPosition);
      return;
    }
    setState(() {
      _activePoints.clear();
      _activePoints.add(details.localPosition);
    });
  }

  void _onDrawingPanUpdate(DragUpdateDetails details) {
    final double dist = details.delta.distance;
    final double normSpeed = (dist / 14.0).clamp(0.0, 1.0);
    SoundService.onWritingTouchMove(normSpeed);
    if (_activeTool == ActiveTool.none) return;
    if (_activeTool == ActiveTool.eraser) {
      _eraseAtPoint(details.localPosition);
      return;
    }
    setState(() {
      _activePoints.add(details.localPosition);
    });
  }

  void _onDrawingPanEnd(DragEndDetails details) {
    SoundService.onWritingTouchUp();
    if (_activeTool == ActiveTool.none || _activeTool == ActiveTool.eraser) {
      return;
      }
    if (_activePoints.length < 2) return;

    double minX = _activePoints.first.dx;
    double maxX = _activePoints.first.dx;
    double minY = _activePoints.first.dy;
    double maxY = _activePoints.first.dy;
    for (final p in _activePoints) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final toolName = _activeTool == ActiveTool.highlighter
        ? "highlighter"
        : _activeTool == ActiveTool.pen
            ? "pen"
            : "pencil";

    final colorVal = _activeTool == ActiveTool.highlighter
        ? _highlightColor.toARGB32()
        : _activeTool == ActiveTool.pen
            ? _penColor.toARGB32()
            : const Color(0xFF424242).toARGB32();

    final annotation = PageAnnotation(
      pageIndex: _currentPage,
      tool: toolName,
      colorValue: colorVal,
      boundingBox: Rect.fromLTWH(
          minX, minY, math.max(12.0, maxX - minX), math.max(12.0, maxY - minY)),
      text: "Mark",
      points: List.from(_activePoints),
    );

    setState(() {
      widget.book.highlights.add(annotation.toHiveString());
      _activePoints.clear();
      widget.book.safeSave();
    });
    SoundService.playToolGlide();
  }

  void _eraseAtPoint(Offset point) {
    final toRemove = <String>[];
    for (final raw in widget.book.highlights) {
      final ann = PageAnnotation.fromHiveString(raw);
      if (ann != null &&
          ann.pageIndex == _currentPage &&
          ann.tool != "bookmark_note" &&
          ann.tool != "note") {
        bool hit = ann.boundingBox.inflate(26.0).contains(point);
        if (!hit && ann.points.isNotEmpty) {
          hit = ann.points.any((p) => (p - point).distance < 28.0);
        }
        if (hit) toRemove.add(raw);
      }
    }

    if (toRemove.isNotEmpty) {
      SoundService.playEraserRub();
      setState(() {
        for (final r in toRemove) {
          widget.book.highlights.remove(r);
        }
        widget.book.safeSave();
      });
    }
  }

  ColorFilter _getPdfColorFilter(Color bgColor) {
    if (bgColor.computeLuminance() < 0.25) {
      return const ColorFilter.matrix([
        -0.85,
        0,
        0,
        0,
        235,
        0,
        -0.85,
        0,
        0,
        230,
        0,
        0,
        -0.85,
        0,
        220,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    return ColorFilter.mode(bgColor, BlendMode.multiply);
  }

  void _openSettingsDrawer() {
    final isPdfDoc = widget.book.format.toLowerCase() == "pdf";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22120A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDrawerState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reading Settings",
                    style: TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontFamily: "serif",
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.sticky_note_2_outlined,
                        color: Color(0xFFFFD59E), size: 16),
                    label: const Text("All Notes",
                        style:
                            TextStyle(color: Color(0xFFFFD59E), fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAllNotesDialog();
                    },
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3E2723)),
              const SizedBox(height: 6),
              if (!isPdfDoc) ...[
                Row(
                  children: [
                    const Text("Font Size:",
                        style:
                            TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 10,
                        max: 26,
                        divisions: 16,
                        activeColor: const Color(0xFFD4A373),
                        inactiveColor: const Color(0xFF3E2723),
                        onChanged: (val) {
                          setDrawerState(() => _fontSize = val);
                          setState(() => _fontSize = val);
                          _controller.rePaginateOnFontSizeChange(
                              fontSize: val, lineHeight: _lineHeight);
                        },
                      ),
                    ),
                    Text("${_fontSize.toInt()}px",
                        style: const TextStyle(
                            color: Color(0xFFFFE0B2), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  const Text("Paper Tone:  ",
                      style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
                  _buildThemeButton(const Color(0xFFF5EACB), "Parchment"),
                  const SizedBox(width: 8),
                  _buildThemeButton(const Color(0xFFFAF6EE), "Linen"),
                  const SizedBox(width: 8),
                  _buildThemeButton(const Color(0xFF231B15), "Dark Night"),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text("Mode:  ",
                      style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
                  ChoiceChip(
                    label: const Text("3D Curl"),
                    selected: _currentMode == ReadingMode.curl3d,
                    onSelected: (s) {
                      setState(() => _currentMode = ReadingMode.curl3d);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Horizontal"),
                    selected: _currentMode == ReadingMode.horizontal,
                    onSelected: (s) {
                      setState(() {
                        _currentMode = ReadingMode.horizontal;
                        _horizontalController =
                            PageController(initialPage: _currentPage);
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Vertical"),
                    selected: _currentMode == ReadingMode.vertical,
                    onSelected: (s) {
                      setState(() {
                        _currentMode = ReadingMode.vertical;
                        _verticalController = ScrollController(
                          initialScrollOffset:
                              _currentPage * (_computedBookHeight + 16.0),
                        )..addListener(_onVerticalScroll);
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllNotesDialog() {
    final noteList = <PageAnnotation>[];
    for (final raw in widget.book.highlights) {
      final a = PageAnnotation.fromHiveString(raw);
      if (a != null &&
          (a.tool == "bookmark_note" || a.tool == "note") &&
          a.text.isNotEmpty) {
        noteList.add(a);
      }
    }
    noteList.sort((a, b) => a.pageIndex.compareTo(b.pageIndex));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF22130B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bookmarks_outlined,
                      color: Color(0xFFFFD59E), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "All Book Notes",
                    style: TextStyle(
                        color: Color(0xFFFFD59E),
                        fontFamily: "serif",
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3E2723)),
              if (noteList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No notes created yet.\nTap 'Mark' to create a note.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: noteList.length,
                    itemBuilder: (c, i) {
                      final n = noteList[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF8D4E24),
                          child: Text("${n.pageIndex + 1}",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
                        ),
                        title: Text(n.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        subtitle: Text("Page ${n.pageIndex + 1}",
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Color(0xFFFFD59E), size: 12),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _saveProgress(n.pageIndex);
                            if (_currentMode == ReadingMode.horizontal) {
                              _horizontalController.jumpToPage(n.pageIndex);
                            } else if (_currentMode == ReadingMode.vertical &&
                                _verticalController.hasClients) {
                              _verticalController.jumpTo(
                                  n.pageIndex * (_computedBookHeight + 16.0));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close",
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(Color c, String tooltip) {
    return GestureDetector(
      onTap: () => setState(() => _pageBgColor = c),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
              color:
                  _pageBgColor == c ? const Color(0xFFFFD59E) : Colors.black45,
              width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_controller.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E0E05),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD4A373)),
              const SizedBox(height: 16),
              Text(
                "Opening \"${widget.book.title}\"...",
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, fontFamily: "serif"),
              ),
            ],
          ),
        ),
      );
    }

    final isBookmarked = widget.book.bookmarkedPages.contains(_currentPage);
    final total = _controller.totalPages;
    final currentNote = _getBookmarkNote(_currentPage);
    final Color solidPaperColor = _pageBgColor.withAlpha(255);

    return Scaffold(
      backgroundColor: const Color(0xFF1E0E05),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1609),
              Color(0xFF1E0E05),
              Color(0xFF120702),
            ],
          ),
        ),
        child: WoodenDeskFrame(
          activeTool: _activeTool,
          highlightColor: _highlightColor,
          penColor: _penColor,
          ribbonColor: _ribbonColor,
          isBookmarked: isBookmarked,
          hasBookmarks: widget.book.bookmarkedPages.isNotEmpty,
          currentPage: _currentPage,
          totalPages: total,
          onBookmarkTap: _toggleBookmark,
          onJumpToBookmark: _jumpToBookmark,
          onAddNoteTap: _showAddNoteDialog,
          penWidth: _penWidth,
          highlighterWidth: _highlighterWidth,
          onPenWidthChanged: (w) => setState(() => _penWidth = w),
          onHighlighterWidthChanged: (w) => setState(() => _highlighterWidth = w),
          onBookmarkColorTap: () async {
            final c = await ColorWheelDialog.show(context,
                initialColor: _ribbonColor, title: "Bookmark Ribbon Color");
            if (!mounted || c == null) return;
            setState(() => _ribbonColor = c);
          },
          // note handled above
          onHighlighterColorTap: () async {
            final c = await ColorWheelDialog.show(context,
                initialColor: _highlightColor, title: "Highlighter Color");
            if (!mounted || c == null) return;
            setState(() => _highlightColor = c);
          },
          onPenColorTap: () async {
            final c = await ColorWheelDialog.show(context,
                initialColor: _penColor, title: "Pen Ink Color");
            if (!mounted || c == null) return;
            setState(() => _penColor = c);
          },
          onMenuTap: _openSettingsDrawer,
          onToolSelected: (t) => setState(() => _activeTool = t),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenW = constraints.maxWidth;
              final double screenH = constraints.maxHeight;

              // BALANCED DESK MARGINS: Guarantees 34px dark wood table visible on both sides
              final double maxBookW = screenW - 68.0;
              final double maxBookH = screenH - 145.0;

              double targetW = maxBookW;
              double targetH = targetW * 1.40;

              if (targetH > maxBookH) {
                targetH = maxBookH;
                targetW = targetH / 1.40;
              }

              final double casingWidth = targetW.clamp(250.0, 480.0);
              final double casingHeight = targetH.clamp(370.0, 740.0);

              const double coverOverhang = 8.0;
              const double spineHingeWidth = 14.0;
              final double bookWidth =
                  casingWidth - (coverOverhang * 2) - spineHingeWidth;
              final double bookHeight = casingHeight - (coverOverhang * 2);

              _computedBookHeight = bookHeight;

              return Center(
                child: HardcoverView(
                  isCoverOpen: _isCoverOpen,
                  title: widget.book.title,
                  author: widget.book.author,
                  casingWidth: casingWidth,
                  casingHeight: casingHeight,
                  coverOverhang: coverOverhang,
                  spineHingeWidth: spineHingeWidth,
                  bookWidth: bookWidth,
                  bookHeight: bookHeight,
                  onOpen: _openHardCover,
                  onClose: _closeHardCover,
                  bookmarkWidget: RibbonBookmarkWidget(
                    ribbonColor: _ribbonColor,
                    bookHeight: bookHeight,
                    leftOffset: 4.0,
                    isCurrentPageBookmarked: isBookmarked,
                    isBookmarkedAhead: widget.book.bookmarkedPages.any((p) => p >= _currentPage) || !_isCoverOpen,
                    noteText: currentNote,
                    drapeProgress: _isCoverOpen ? 1.0 : 0.0,
                    onNoteTap: () => _showAddNoteDialog(),
                  ),
                  bookPagesContent: Container(
                    decoration: BoxDecoration(
                      color: solidPaperColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        _buildReaderContent(
                            total, bookHeight, isBookmarked, currentNote),
                        if (_activeTool != ActiveTool.none)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: _onDrawingPanStart,
                              onPanUpdate: _onDrawingPanUpdate,
                              onPanEnd: _onDrawingPanEnd,
                                              onPanCancel: SoundService.onWritingTouchUp,
                              child: CustomPaint(
                                painter: _LiveDrawingPainter(
                                  tool: _activeTool,
                                  color: _activeTool == ActiveTool.highlighter
                                      ? _highlightColor
                                      : _penColor,
                                  points: _activePoints,
                                  strokeWidth: _activeTool == ActiveTool.highlighter
                                      ? _highlighterWidth
                                      : _penWidth,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReaderContent(
      int total, double bookHeight, bool isBookmarked, String? currentNote) {
    return AnimatedBuilder(
      animation: _bookmarkDrapeAnimation,
      builder: (context, child) {
        final double drapeProg = _bookmarkDrapeAnimation.value;

        if (_currentMode == ReadingMode.vertical) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is OverscrollNotification &&
                  _verticalController.hasClients &&
                  _verticalController.offset <= 0 &&
                  notification.overscroll < -10) {
                _closeHardCover();
                return true;
              }
              return false;
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ListView.builder(
                  controller: _verticalController,
                  physics: _activeTool != ActiveTool.none
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  itemCount: total,
                  itemBuilder: (ctx, idx) => Container(
                    height: bookHeight,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: _pageBgColor.withAlpha(255),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: _buildPageContent(idx, total),
                  ),
                ),
                RibbonBookmarkWidget(
                  ribbonColor: _ribbonColor,
                  bookHeight: bookHeight,
                  leftOffset: 3.0,
                  isCurrentPageBookmarked: isBookmarked,
                  noteText: currentNote,
                  drapeProgress: drapeProg,
                ),
              ],
            ),
          );
        } else if (_currentMode == ReadingMode.horizontal) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is OverscrollNotification &&
                  _currentPage == 0 &&
                  notification.overscroll < -10) {
                _closeHardCover();
                return true;
              }
              return false;
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                PageView.builder(
                  controller: _horizontalController,
                  physics: const BouncingScrollPhysics(),
                  allowImplicitScrolling: true,
                  itemCount: total,
                  onPageChanged: _saveProgress,
                  itemBuilder: (ctx, idx) => _buildPageContent(idx, total),
                ),
                RibbonBookmarkWidget(
                  ribbonColor: _ribbonColor,
                  bookHeight: bookHeight,
                  leftOffset: 3.0,
                  isCurrentPageBookmarked: isBookmarked,
                  noteText: currentNote,
                  drapeProgress: drapeProg,
                ),
              ],
            ),
          );
        } else {
          return RealisticPageCurl(
            key: ValueKey('curl_page_$_currentPage'),
            pageCount: total,
            initialPage: _currentPage,
            onPageChanged: _saveProgress,
            onSwipeBeforeFirst: _closeHardCover,
            gesturesEnabled: _activeTool != ActiveTool.pen && _activeTool != ActiveTool.pencil && _activeTool != ActiveTool.highlighter ,
            paperColor: _pageBgColor.withAlpha(255),
            
            builder: (ctx, idx) => _buildPageContent(idx, total),
          );
        }
      },
    );
  }

  Widget _buildPageContent(int index, int total) {
    final page = _controller.getPage(index);
    final noteForThisPage = _getBookmarkNote(index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final topMargin = constraints.maxHeight * 0.055;
        final bottomMargin = constraints.maxHeight * 0.065;
        final sideMargin = constraints.maxWidth * 0.06;

        return Container(
          color: _pageBgColor.withAlpha(255),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: topMargin,
                  bottom: bottomMargin,
                  left: sideMargin,
                  right: sideMargin,
                ),
                child: page.status == PageStatus.ready
                    ? _buildPageVisuals(page)
                    : page.status == PageStatus.failed
                        ? Center(
                            child: Text(
                              page.errorMessage ?? "End of Content",
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF8D6E63))),
              ),
              CustomPaint(
                painter: _AnnotationPainter(
                  highlights: widget.book.highlights,
                  currentPage: index,
                ),
              ),
              if (noteForThisPage != null && noteForThisPage.isNotEmpty)
                Positioned(
                  top: 8,
                  right: sideMargin,
                  child: GestureDetector(
                    onTap: () => _showAddNoteDialog(targetPage: index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: const Color(0xFFD4AF37), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(1, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin,
                              color: Color(0xFF8D4E24), size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              noteForThisPage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: "serif",
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                right: sideMargin,
                child: Text(
                  "${index + 1} / $total",
                  style: const TextStyle(
                    fontSize: 10.0,
                    color: Color(0x772B221B),
                    fontFamily: "serif",
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageVisuals(ReconstructedPage page) {
    if (page.isImage && page.imageBytes != null) {
      return Center(
        child: ColorFiltered(
          colorFilter: _getPdfColorFilter(_pageBgColor),
          child: Image.memory(
            page.imageBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }

    return SelectableText(
      page.textContent ?? "",
      style: TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
        letterSpacing: 0.15,
        color: _pageBgColor.computeLuminance() > 0.3
            ? const Color(0xFF2B221B)
            : const Color(0xFFEDE0D4),
        fontFamily: "serif",
      ),
    );
  }
}

class _LiveDrawingPainter extends CustomPainter {
  final ActiveTool tool;
  final Color color;
  final List<Offset> points;
  final double strokeWidth;

  _LiveDrawingPainter({
    required this.tool,
    required this.color,
    required this.points,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (tool == ActiveTool.highlighter) {
      paint
        ..color = color.withAlpha(120)
        ..strokeWidth = strokeWidth;
    } else if (tool == ActiveTool.pen) {
      paint
        ..color = color
        ..strokeWidth = strokeWidth;
    } else if (tool == ActiveTool.pencil) {
      paint
        ..color = const Color(0xFF424242)
        ..strokeWidth = strokeWidth;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiveDrawingPainter old) => true;
}

class _AnnotationPainter extends CustomPainter {
  final List<String> highlights;
  final int currentPage;

  _AnnotationPainter({required this.highlights, required this.currentPage});

  @override
  void paint(Canvas canvas, Size size) {
    for (final raw in highlights) {
      final ann = PageAnnotation.fromHiveString(raw);
      if (ann != null &&
          ann.pageIndex == currentPage &&
          ann.tool != "bookmark_note" &&
          ann.tool != "note") {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        if (ann.tool == "highlighter") {
          paint
            ..color = Color(ann.colorValue).withAlpha(120)
            ..strokeWidth = 18.0;
        } else if (ann.tool == "pen") {
          paint
            ..color = Color(ann.colorValue)
            ..strokeWidth = 2.4;
        } else if (ann.tool == "pencil") {
          paint
            ..color = const Color(0xFF424242)
            ..strokeWidth = 1.4;
        }

        if (ann.points.length > 1) {
          final path = Path()..moveTo(ann.points.first.dx, ann.points.first.dy);
          for (int i = 1; i < ann.points.length; i++) {
            path.lineTo(ann.points[i].dx, ann.points[i].dy);
          }
          canvas.drawPath(path, paint);
        } else {
          canvas.drawLine(
              ann.boundingBox.bottomLeft, ann.boundingBox.bottomRight, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
