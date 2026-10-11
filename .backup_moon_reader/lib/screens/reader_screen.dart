import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/page_annotation.dart';
import '../services/progressive_document_controller.dart';
import '../services/sound_service.dart';
import '../widgets/page_curl_view.dart';
import '../widgets/wooden_desk_frame.dart';
import '../widgets/interactive_stationery.dart';

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

class _ReaderScreenState extends State<ReaderScreen> {
  late ProgressiveDocumentController _controller;
  late int _currentPage;
  late ReadingMode _currentMode;
  bool _loading = true;

  ActiveTool _activeTool =
      ActiveTool.none; // None by default so page curls freely
  Color _highlightColor = const Color(0xFFFFEB3B); // Yellow
  Rect? _activeTargetRect;

  // Direct finger touch drawing state
  Offset? _touchStart;
  Offset? _touchCurrent;

  final double _fontSize = 15.5;
  final double _lineHeight = 1.55;
  Color _pageBgColor = const Color(0xFFF5EACB); // Antique Warm Book Parchment

  final PageController _horizontalController = PageController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _currentPage = widget.book.lastPage;

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
            .split('/')
            .last;
        cleanTitle = fileName
            .replaceAll(RegExp(r'\.[^.]+$'), '')
            .replaceAll(RegExp(r'[\-_]+'), ' ')
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
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _saveProgress(int page) {
    if (_currentPage == page) return;
    setState(() => _currentPage = page);
    SoundService.playPageTurn();
    widget.book.lastPage = page;
    widget.book.lastRead = DateTime.now();
    widget.book.safeSave();
  }

  void _toggleBookmark() {
    setState(() {
      if (widget.book.bookmarkedPages.contains(_currentPage)) {
        widget.book.bookmarkedPages.remove(_currentPage);
      } else {
        widget.book.bookmarkedPages.add(_currentPage);
      }
      widget.book.safeSave();
    });
  }

  // --- TACTILE DIRECT TOUCH ANNOTATION HANDLERS ---
  void _onPanStart(DragStartDetails details) {
    if (_activeTool == ActiveTool.none) return;

    if (_activeTool == ActiveTool.eraser) {
      _eraseAtPoint(details.localPosition);
      return;
    }

    setState(() {
      _touchStart = details.localPosition;
      _touchCurrent = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeTool == ActiveTool.none) return;

    if (_activeTool == ActiveTool.eraser) {
      _eraseAtPoint(details.localPosition);
      return;
    }

    setState(() {
      _touchCurrent = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeTool == ActiveTool.none || _activeTool == ActiveTool.eraser)
      return;
    if (_touchStart == null || _touchCurrent == null) return;

    final left = math.min(_touchStart!.dx, _touchCurrent!.dx);
    final top = math.min(_touchStart!.dy, _touchCurrent!.dy);
    final width = (touchCurrent!.dx - _touchStart!.dx).abs();
    final height = math.max(22.0, (touchCurrent!.dy - _touchStart!.dy).abs());

    // Only save if meaningful stroke (>15px width)
    if (width > 15.0) {
      final rect = Rect.fromLTWH(left, top, width, height);

      setState(() {
        _activeTargetRect = rect;
      });

      final toolName = _activeTool == ActiveTool.highlighter
          ? 'highlighter'
          : _activeTool == ActiveTool.pen
              ? 'pen'
              : 'pencil';

      final annotation = PageAnnotation(
        pageIndex: _currentPage,
        tool: toolName,
        colorValue: _highlightColor.toARGB32(),
        boundingBox: rect,
        text: "Line Mark",
      );

      widget.book.highlights.add(annotation.toHiveString());
      widget.book.safeSave();
      SoundService.playToolGlide();
    }

    setState(() {
      _touchStart = null;
      _touchCurrent = null;
    });
  }

  void _eraseAtPoint(Offset point) {
    final toRemove = <String>[];
    for (final raw in widget.book.highlights) {
      final ann = PageAnnotation.fromHiveString(raw);
      if (ann != null && ann.pageIndex == _currentPage) {
        if (ann.boundingBox.inflate(20.0).contains(point)) {
          toRemove.add(raw);
        }
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

  void _openWoodenSettingsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22120A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wooden Desk Settings",
              style: TextStyle(
                color: Color(0xFFFFE0B2),
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Color(0xFF3E2723)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Paper Tone:  ",
                    style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
                _buildThemeButton(const Color(0xFFF5EACB), "Parchment"),
                const SizedBox(width: 8),
                _buildThemeButton(const Color(0xFFFAF6EE), "Linen"),
                const SizedBox(width: 8),
                _buildThemeButton(const Color(0xFFEFE2CE), "Vintage"),
                const SizedBox(width: 8),
                _buildThemeButton(const Color(0xFF231B15), "Night"),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Turn Style:  ",
                    style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
                ChoiceChip(
                  label: const Text("3D Page Curl"),
                  selected: _currentMode == ReadingMode.curl3d,
                  onSelected: (s) =>
                      setState(() => _currentMode = ReadingMode.curl3d),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Swipe"),
                  selected: _currentMode == ReadingMode.horizontal,
                  onSelected: (s) =>
                      setState(() => _currentMode = ReadingMode.horizontal),
                ),
              ],
            ),
          ],
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
            color: _pageBgColor == c ? Colors.white : Colors.black45,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _pickHighlightColor() {
    final colors = [
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF81C784), // Mint Green
      const Color(0xFFFF8A80), // Coral
      const Color(0xFF80D8FF), // Sky Blue
      const Color(0xFFEA80FC), // Lavender
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22120A),
      builder: (ctx) => Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () {
                setState(() => _highlightColor = c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _highlightColor == c ? Colors.white : Colors.black45,
                    width: 2.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Offset? get touchCurrent => _touchCurrent;

  @override
  Widget build(BuildContext context) {
    if (_loading || !_controller.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B1008),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD4A373)),
              const SizedBox(height: 16),
              Text(
                'Placing "${widget.book.title}" on Desk...',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, fontFamily: 'serif'),
              ),
            ],
          ),
        ),
      );
    }

    final isBookmarked = widget.book.bookmarkedPages.contains(_currentPage);
    final total = _controller.totalPages;

    return Scaffold(
      body: WoodenDeskFrame(
        activeTool: _activeTool,
        highlightColor: _highlightColor,
        isBookmarked: isBookmarked,
        currentPage: _currentPage,
        totalPages: total,
        onBookmarkTap: _toggleBookmark,
        onColorPickerTap: _pickHighlightColor,
        onMenuTap: _openWoodenSettingsDrawer,
        onToolSelected: (t) => setState(() => _activeTool = t),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: _pageBgColor,
              child: _buildReader(total),
            ),
            // Direct touch drawing line indicator
            if (_touchStart != null && _touchCurrent != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LiveDragStrokePainter(
                      tool: _activeTool,
                      color: _highlightColor,
                      start: _touchStart!,
                      end: _touchCurrent!,
                    ),
                  ),
                ),
              ),
            // 3D tool glide overlay
            InteractiveStationeryOverlay(
              tool: _activeTool,
              inkColor: _highlightColor,
              targetTextRect: _activeTargetRect,
              onAnimationComplete: () {
                setState(() => _activeTargetRect = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader(int total) {
    final curlGesturesActive = _activeTool == ActiveTool.none;

    if (_currentMode == ReadingMode.curl3d) {
      return RealisticPageCurl(
        pageCount: total,
        initialPage: _currentPage,
        onPageChanged: _saveProgress,
        gesturesEnabled: curlGesturesActive,
        builder: (ctx, idx) => _buildPageContent(idx, total),
      );
    } else if (_currentMode == ReadingMode.horizontal) {
      return PageView.builder(
        controller: _horizontalController,
        physics: curlGesturesActive
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: total,
        onPageChanged: _saveProgress,
        itemBuilder: (ctx, idx) => _buildPageContent(idx, total),
      );
    } else {
      return ListView.builder(
        controller: _verticalController,
        physics: curlGesturesActive
            ? const ScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: total,
        itemBuilder: (ctx, idx) => _buildPageContent(idx, total),
      );
    }
  }

  Widget _buildPageContent(int index, int total) {
    final page = _controller.getPage(index);

    return LayoutBuilder(
      builder: (context, constraints) {
        // STRICT BOOK MARGINS: Top 28px, Bottom 32px, Sides 24px
        const double topMargin = 28.0;
        const double bottomMargin = 32.0;
        const double sideMargin = 24.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            color: _pageBgColor,
            padding: const EdgeInsets.only(
              top: topMargin,
              bottom: bottomMargin,
              left: sideMargin,
              right: sideMargin,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Persistent Annotations
                CustomPaint(
                  painter: _AnnotationPainter(
                    highlights: widget.book.highlights,
                    currentPage: index,
                  ),
                ),

                // 2. Strict Zero-Scroll Text Box
                if (page.status == PageStatus.ready)
                  _buildZeroScrollContent(page)
                else if (page.status == PageStatus.failed)
                  Center(child: Text(page.errorMessage ?? "End of Content"))
                else
                  const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF8D6E63))),

                // 3. Physical Page Number
                Positioned(
                  bottom: -22,
                  right: 4,
                  child: Text(
                    '${index + 1} / $total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x662B221B),
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZeroScrollContent(ReconstructedPage page) {
    if (page.isImage && page.imageBytes != null) {
      final img = Image.memory(
        page.imageBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
      return Center(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(_pageBgColor, BlendMode.multiply),
          child: img,
        ),
      );
    }

    final pageText = page.textContent ?? "";

    // STRICT ZERO-SCROLL: Text renders directly inside container bounds
    return Text(
      pageText,
      style: TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
        color: _pageBgColor.computeLuminance() > 0.3
            ? const Color(0xFF2B221B)
            : const Color(0xFFEDE0D4),
        fontFamily: 'serif',
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// Live drag stroke while finger moves
class _LiveDragStrokePainter extends CustomPainter {
  final ActiveTool tool;
  final Color color;
  final Offset start;
  final Offset end;

  _LiveDragStrokePainter({
    required this.tool,
    required this.color,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    if (tool == ActiveTool.highlighter) {
      paint
        ..color = color.withAlpha(120)
        ..strokeWidth = 20.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, paint);
    } else if (tool == ActiveTool.pen) {
      paint
        ..color = const Color(0xFF1A237E)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, paint);
    } else if (tool == ActiveTool.pencil) {
      paint
        ..color = const Color(0xFF424242)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_LiveDragStrokePainter old) => true;
}

class _AnnotationPainter extends CustomPainter {
  final List<String> highlights;
  final int currentPage;

  _AnnotationPainter({required this.highlights, required this.currentPage});

  @override
  void paint(Canvas canvas, Size size) {
    for (final raw in highlights) {
      final ann = PageAnnotation.fromHiveString(raw);
      if (ann != null && ann.pageIndex == currentPage) {
        final paint = Paint()..strokeCap = StrokeCap.round;

        if (ann.tool == 'highlighter') {
          paint
            ..color = Color(ann.colorValue).withAlpha(120)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(ann.boundingBox, const Radius.circular(3)),
            paint,
          );
        } else if (ann.tool == 'pen') {
          paint
            ..color = const Color(0xFF1A237E)
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
              ann.boundingBox.bottomLeft, ann.boundingBox.bottomRight, paint);
        } else if (ann.tool == 'pencil') {
          paint
            ..color = const Color(0xFF424242)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
              ann.boundingBox.bottomLeft, ann.boundingBox.bottomRight, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
