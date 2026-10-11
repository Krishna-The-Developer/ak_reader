#!/bin/bash
set -euo pipefail

echo "=========================================================="
echo " [1/5] Updating lib/widgets/ribbon_bookmark.dart          "
echo "=========================================================="
cat << 'DART_EOF' > lib/widgets/ribbon_bookmark.dart
import "dart:math" as math;
import "package:flutter/material.dart";

class RibbonBookmarkWidget extends StatelessWidget {
  final Color ribbonColor;
  final double bookHeight;
  final double leftOffset;
  final bool isCurrentPageBookmarked;
  final String? noteText;
  final double drapeProgress;
  final double curlProgress;
  final bool isCurling;

  const RibbonBookmarkWidget({
    super.key,
    required this.ribbonColor,
    required this.bookHeight,
    this.leftOffset = 22.0,
    required this.isCurrentPageBookmarked,
    this.noteText,
    this.drapeProgress = 1.0,
    this.curlProgress = 0.0,
    this.isCurling = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCurrentPageBookmarked || drapeProgress <= 0.01) {
      return const SizedBox.shrink();
    }

    const double baseRibbonWidth = 15.0;
    const double extraTailLength = 36.0;
    final double fullLength = bookHeight + extraTailLength;
    final double currentLength = fullLength * drapeProgress.clamp(0.0, 1.0);

    double currentLeft = leftOffset;
    double currentWidth = baseRibbonWidth;
    double opacity = 1.0;

    if (isCurling && curlProgress > 0.005) {
      final double p = curlProgress.clamp(0.0, 1.0);
      currentLeft = leftOffset * (1.0 - (p * 1.15)).clamp(0.0, 1.0);
      currentWidth = baseRibbonWidth * (1.0 - (p * 1.25)).clamp(0.0, 1.0);
      opacity = (1.0 - (p * 1.35)).clamp(0.0, 1.0);
    }

    if (opacity <= 0.01 || currentWidth <= 0.5) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: currentLeft,
      top: -6.0,
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: baseRibbonWidth + 140.0,
          height: currentLength + 8.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(currentWidth, currentLength),
                painter: _WovenFabricRibbonPainter(
                  ribbonColor: ribbonColor,
                  extraTail: extraTailLength,
                  drapeProgress: drapeProgress,
                ),
              ),
              if (noteText != null && noteText!.isNotEmpty && drapeProgress > 0.7 && !isCurling)
                Positioned(
                  left: currentWidth + 6.0,
                  top: bookHeight * 0.28,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    constraints: const BoxConstraints(maxWidth: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF0D7),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: const Color(0xFFC7A97B), width: 0.9),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4.0,
                          offset: Offset(1.5, 2.0),
                        ),
                      ],
                    ),
                    child: Text(
                      noteText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: "serif",
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WovenFabricRibbonPainter extends CustomPainter {
  final Color ribbonColor;
  final double extraTail;
  final double drapeProgress;

  _WovenFabricRibbonPainter({
    required this.ribbonColor,
    required this.extraTail,
    required this.drapeProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0.5 || h <= 2.0) return;

    final double notch = math.min(10.0, h * 0.2);

    final hsl = HSLColor.fromColor(ribbonColor);
    final Color deepShade = hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
    final Color sheenShade = hsl.withLightness((hsl.lightness * 1.32).clamp(0.0, 1.0)).toColor();

    final Path ribbonPath = Path();
    ribbonPath.moveTo(0, 0);
    ribbonPath.lineTo(0, h);
    if (drapeProgress >= 0.88) {
      ribbonPath.lineTo(w / 2, h - notch);
    }
    ribbonPath.lineTo(w, h);
    ribbonPath.lineTo(w, 0);
    ribbonPath.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.save();
    canvas.translate(1.5, 2.0);
    canvas.drawPath(ribbonPath, shadowPaint);
    canvas.restore();

    final Paint bodyPaint = Paint()..style = PaintingStyle.fill;
    final Rect bounds = Rect.fromLTWH(0, 0, w, h);
    bodyPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        deepShade,
        ribbonColor,
        sheenShade,
        ribbonColor,
        deepShade,
      ],
      stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
    ).createShader(bounds);

    canvas.drawPath(ribbonPath, bodyPaint);

    if (w > 6.0) {
      final threadPaint = Paint()
        ..color = Colors.black.withAlpha(20)
        ..strokeWidth = 0.5;
      for (double y = 4.0; y < h - notch; y += 3.2) {
        canvas.drawLine(Offset(1.0, y), Offset(w - 1.0, y + 0.6), threadPaint);
      }

      final warpPaint = Paint()
        ..color = Colors.white.withAlpha(16)
        ..strokeWidth = 0.5;
      for (double x = 2.0; x < w - 2.0; x += 2.6) {
        canvas.drawLine(Offset(x, 0), Offset(x, h - notch), warpPaint);
      }

      final stitchPaint = Paint()
        ..color = const Color(0xFFD4AF37).withAlpha(160)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(1.0, 0), Offset(1.0, h - notch), stitchPaint);
      canvas.drawLine(Offset(w - 1.0, 0), Offset(w - 1.0, h - notch), stitchPaint);
    }
  }

  @override
  bool shouldRepaint(_WovenFabricRibbonPainter old) =>
      old.ribbonColor != ribbonColor ||
      old.extraTail != extraTail ||
      old.drapeProgress != drapeProgress;
}
DART_EOF

echo "=========================================================="
echo " [2/5] Updating lib/widgets/hardcover_view.dart (Bounds)  "
echo "=========================================================="
cat << 'DART_EOF' > lib/widgets/hardcover_view.dart
import "dart:math" as math;
import "package:flutter/material.dart";

class HardcoverView extends StatefulWidget {
  final bool isCoverOpen;
  final String title;
  final String author;
  final double casingWidth;
  final double casingHeight;
  final double coverOverhang;
  final double spineHingeWidth;
  final double bookWidth;
  final double bookHeight;
  final Widget bookPagesContent;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const HardcoverView({
    super.key,
    required this.isCoverOpen,
    required this.title,
    required this.author,
    required this.casingWidth,
    required this.casingHeight,
    required this.coverOverhang,
    required this.spineHingeWidth,
    required this.bookWidth,
    required this.bookHeight,
    required this.bookPagesContent,
    required this.onOpen,
    required this.onClose,
  });

  @override
  State<HardcoverView> createState() => _HardcoverViewState();
}

class _HardcoverViewState extends State<HardcoverView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _dragProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });

    if (widget.isCoverOpen) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HardcoverView old) {
    super.didUpdateWidget(old);
    if (widget.isCoverOpen && !old.isCoverOpen) {
      if (_animController.value < 1.0) {
        _animController.forward();
      }
    } else if (!widget.isCoverOpen && old.isCoverOpen) {
      if (_animController.value > 0.0) {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildBrassCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int quarterTurns,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE599),
                Color(0xFFC5A059),
                Color(0xFF7A5822),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCoverOpen && _animController.value >= 0.98) {
      return _buildOpenBookCasing();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double progress = _animController.isAnimating
            ? _animation.value
            : (widget.isCoverOpen ? 1.0 : _dragProgress);

        if (progress >= 0.98) {
          return _buildOpenBookCasing();
        }

        final double angle = -progress * math.pi;
        final double forwardScale = 1.0 + 0.05 * math.sin(progress * math.pi);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (progress > 0.03) _buildOpenBookCasing(),
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0006)
                ..rotateY(angle),
              child: Transform.scale(
                scale: forwardScale,
                alignment: Alignment.centerLeft,
                child: progress < 0.5
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragProgress = (_dragProgress - (details.primaryDelta ?? 0) / widget.casingWidth).clamp(0.0, 1.0);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0.0;
                          if (_dragProgress > 0.25 || velocity < -250) {
                            widget.onOpen();
                          } else {
                            setState(() => _dragProgress = 0.0);
                          }
                        },
                        child: _buildClosedHardcoverBoard(),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildInsideCoverEndpaper(),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClosedHardcoverBoard() {
    return Container(
      width: widget.casingWidth,
      height: widget.casingHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF381A0B),
            Color(0xFF220E05),
            Color(0xFF140602),
          ],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF5A2A12),
          width: 2.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xEE000000),
            blurRadius: 28,
            spreadRadius: 3,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0x66C5A059),
                  width: 1.2,
                ),
              ),
            ),
          ),
          _buildBrassCorner(top: 2, left: 2, quarterTurns: 0),
          _buildBrassCorner(top: 2, right: 2, quarterTurns: 1),
          _buildBrassCorner(bottom: 2, right: 2, quarterTurns: 2),
          _buildBrassCorner(bottom: 2, left: 2, quarterTurns: 3),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 20,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0F0502),
                    Color(0xFF381A0B),
                    Color(0xFF140702),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories, color: Color(0xFFFFD59E), size: 44),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD59E),
                      fontFamily: "serif",
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.author,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7A878),
                      fontFamily: "serif",
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swipe_left, color: Color(0x99FFD59E), size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Swipe to Open",
                        style: TextStyle(
                          color: Color(0x99FFD59E),
                          fontFamily: "serif",
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsideCoverEndpaper() {
    return Container(
      width: widget.casingWidth,
      height: widget.casingHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF261208),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF5A2A12), width: 2.0),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5AB),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0x445A2A12), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenBookCasing() {
    return Container(
      width: widget.casingWidth,
      height: widget.casingHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1307),
            Color(0xFF1E0C04),
            Color(0xFF120602),
          ],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF5A2A12),
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xEE000000),
            blurRadius: 28,
            spreadRadius: 3,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBrassCorner(top: 2, left: 2, quarterTurns: 0),
          _buildBrassCorner(top: 2, right: 2, quarterTurns: 1),
          _buildBrassCorner(bottom: 2, right: 2, quarterTurns: 2),
          _buildBrassCorner(bottom: 2, left: 2, quarterTurns: 3),
          Positioned(
            left: widget.coverOverhang,
            top: widget.coverOverhang,
            bottom: widget.coverOverhang,
            width: widget.spineHingeWidth,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0F0502),
                    Color(0xFF381A0B),
                    Color(0xFF140702),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: widget.coverOverhang + widget.spineHingeWidth,
            top: widget.coverOverhang,
            width: widget.bookWidth,
            height: widget.bookHeight,
            child: widget.bookPagesContent,
          ),
        ],
      ),
    );
  }
}
DART_EOF

echo "=========================================================="
echo " [3/5] Updating lib/widgets/page_curl_view.dart (Cylindrical) "
echo "=========================================================="
cat << 'DART_EOF' > lib/widgets/page_curl_view.dart
import "dart:math" as math;
import "package:flutter/material.dart";

enum CurlCorner {
  topRight,
  bottomRight,
  center,
}

class RealisticPageCurl extends StatefulWidget {
  final int pageCount;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onSwipeBeforeFirst;
  final IndexedWidgetBuilder builder;
  final Color paperColor;
  final bool gesturesEnabled;
  final Widget Function(double curlProgress, bool isCurling)? bookmarkBuilder;

  const RealisticPageCurl({
    super.key,
    required this.pageCount,
    required this.initialPage,
    this.onPageChanged,
    this.onSwipeBeforeFirst,
    required this.builder,
    this.paperColor = const Color(0xFFF5EACB),
    this.gesturesEnabled = true,
    this.bookmarkBuilder,
  });

  @override
  State<RealisticPageCurl> createState() => _RealisticPageCurlState();
}

class _RealisticPageCurlState extends State<RealisticPageCurl>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _animController;
  late Animation<double> _animation;

  double _curlProgress = 0.0;
  bool _isForward = true;
  bool _isDragging = false;
  CurlCorner _activeCorner = CurlCorner.bottomRight;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_animController);

    _animController.addListener(() {
      setState(() {
        _curlProgress = _animation.value;
      });
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_curlProgress >= 0.99) {
          final newPage = _isForward ? _currentPage + 1 : _currentPage - 1;
          setState(() {
            _currentPage = newPage.clamp(0, widget.pageCount - 1);
            _curlProgress = 0.0;
            _isDragging = false;
          });
          widget.onPageChanged?.call(_currentPage);
        } else {
          setState(() {
            _curlProgress = 0.0;
            _isDragging = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details, double height) {
    if (!widget.gesturesEnabled || _animController.isAnimating) {
      return;
    }
    _isDragging = true;

    final dy = details.localPosition.dy;
    if (dy > height * 0.62) {
      _activeCorner = CurlCorner.bottomRight;
    } else if (dy < height * 0.38) {
      _activeCorner = CurlCorner.topRight;
    } else {
      _activeCorner = CurlCorner.center;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging || _animController.isAnimating || width <= 0) {
      return;
    }

    if (_curlProgress == 0.0) {
      final delta = details.primaryDelta ?? 0.0;
      if (delta < 0) {
        if (_currentPage < widget.pageCount - 1) {
          _isForward = true;
        } else {
          return;
        }
      } else if (delta > 0) {
        if (_currentPage > 0) {
          _isForward = false;
        } else {
          widget.onSwipeBeforeFirst?.call();
          _isDragging = false;
          return;
        }
      } else {
        return;
      }
    }

    final delta = details.primaryDelta ?? 0.0;
    final double change = _isForward ? -delta / width : delta / width;

    setState(() {
      _curlProgress = (_curlProgress + change).clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging || _animController.isAnimating) {
      return;
    }
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    bool shouldComplete = false;

    if (_isForward) {
      if (velocity < -260 || _curlProgress > 0.35) {
        shouldComplete = true;
      }
    } else {
      if (velocity > 260 || _curlProgress > 0.35) {
        shouldComplete = true;
      }
    }

    final target = shouldComplete ? 1.0 : 0.0;
    _animation = Tween<double>(
      begin: _curlProgress,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final solidPaper = widget.paperColor.withAlpha(255);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _onHorizontalDragStart(d, h),
          onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, w),
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Container(
            color: solidPaper,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                _buildBasePage(w, h, solidPaper),
                if (_curlProgress > 0.001)
                  _buildCurlingPage(w, h, solidPaper),
                if (widget.bookmarkBuilder != null)
                  widget.bookmarkBuilder!(_curlProgress, _curlProgress > 0.001),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasePage(double w, double h, Color solidPaper) {
    int baseIndex;
    if (_isForward) {
      baseIndex = _curlProgress > 0.001
          ? math.min(_currentPage + 1, widget.pageCount - 1)
          : _currentPage;
    } else {
      baseIndex = _currentPage;
    }

    return Container(
      width: w,
      height: h,
      color: solidPaper,
      child: widget.builder(context, baseIndex),
    );
  }

  Widget _buildCurlingPage(double w, double h, Color solidPaper) {
    final double p = _curlProgress;

    if (_isForward) {
      final int topPageIndex = _currentPage;
      return _buildForwardCurl(w, h, p, topPageIndex, solidPaper);
    } else {
      final int prevPageIndex = math.max(_currentPage - 1, 0);
      return _buildBackwardCurl(w, h, p, prevPageIndex, solidPaper);
    }
  }

  Widget _buildForwardCurl(double w, double h, double p, int pageIndex, Color solidPaper) {
    double foldXTop;
    double foldXBottom;

    if (_activeCorner == CurlCorner.bottomRight) {
      foldXBottom = w * (1.0 - (p * 1.15)).clamp(0.0, 1.0);
      foldXTop = w * (1.0 - (p * 0.85)).clamp(0.0, 1.0);
    } else if (_activeCorner == CurlCorner.topRight) {
      foldXTop = w * (1.0 - (p * 1.15)).clamp(0.0, 1.0);
      foldXBottom = w * (1.0 - (p * 0.85)).clamp(0.0, 1.0);
    } else {
      foldXTop = w * (1.0 - p);
      foldXBottom = w * (1.0 - p);
    }

    final double minFoldX = math.min(foldXTop, foldXBottom);
    final double maxFoldX = math.max(foldXTop, foldXBottom);
    final double rollWidth = math.min(26.0, math.min(minFoldX, w - maxFoldX));

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: minFoldX,
          top: 0,
          bottom: 0,
          width: math.min(38.0, w - minFoldX),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withAlpha((115 * (1.0 - p)).round()),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        ClipPath(
          clipper: _FoldClipper(foldXTop, foldXBottom),
          child: Container(
            width: w,
            height: h,
            color: solidPaper,
            child: widget.builder(context, pageIndex),
          ),
        ),
        if (rollWidth > 1.0)
          Positioned(
            left: math.max(0.0, minFoldX - rollWidth),
            top: 0,
            bottom: 0,
            width: (maxFoldX - minFoldX) + (rollWidth * 1.6),
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.alphaBlend(const Color(0xFFC7B69B), solidPaper),
                      solidPaper,
                      Colors.white.withAlpha(80),
                      Color.alphaBlend(const Color(0xFFB5A184), solidPaper),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackwardCurl(double w, double h, double p, int pageIndex, Color solidPaper) {
    final double foldX = w * p;
    final double rollWidth = math.min(26.0, math.min(foldX, w - foldX));

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: foldX,
          top: 0,
          bottom: 0,
          width: math.min(38.0, w - foldX),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withAlpha((115 * (1.0 - p)).round()),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          clipper: _RectClipper(0.0, foldX),
          child: Container(
            width: w,
            height: h,
            color: solidPaper,
            child: widget.builder(context, pageIndex),
          ),
        ),
        if (rollWidth > 1.0)
          Positioned(
            left: math.max(0.0, foldX - rollWidth),
            top: 0,
            bottom: 0,
            width: rollWidth * 1.6,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.alphaBlend(const Color(0xFFC7B69B), solidPaper),
                      solidPaper,
                      Colors.white.withAlpha(80),
                      Color.alphaBlend(const Color(0xFFB5A184), solidPaper),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  final double startX;
  final double endX;

  _RectClipper(this.startX, this.endX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(startX, 0, math.max(0.0, endX - startX), size.height);
  }

  @override
  bool shouldReclip(_RectClipper old) => old.startX != startX || old.endX != endX;
}

class _FoldClipper extends CustomClipper<Path> {
  final double foldXTop;
  final double foldXBottom;

  _FoldClipper(this.foldXTop, this.foldXBottom);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(foldXTop.clamp(0.0, size.width), 0);
    path.lineTo(foldXBottom.clamp(0.0, size.width), size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_FoldClipper old) =>
      old.foldXTop != foldXTop || old.foldXBottom != foldXBottom;
}
DART_EOF

echo "=========================================================="
echo " [4/5] Updating lib/screens/reader_screen.dart (Notes & Vert) "
echo "=========================================================="
cat << 'DART_EOF' > lib/screens/reader_screen.dart
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
  late ProgressiveDocumentController _controller;
  late int _currentPage;
  late ReadingMode _currentMode;
  bool _loading = true;
  bool _isCoverOpen = false;

  late AnimationController _bookmarkDrapeController;
  late Animation<double> _bookmarkDrapeAnimation;

  ActiveTool _activeTool = ActiveTool.none;
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
    if (_currentMode != ReadingMode.vertical || !_verticalController.hasClients) {
      return;
    }
    final double pageSlot = _computedBookHeight + 16.0;
    if (pageSlot <= 0) return;
    final int scrolledPage = (_verticalController.offset / pageSlot).round().clamp(0, _controller.totalPages - 1);
    if (scrolledPage != _currentPage) {
      _saveProgress(scrolledPage);
    }
  }

  Future<void> _initDocument() async {
    await _controller.initialize();
    if (!mounted) return;

    if (widget.book.title.trim().isEmpty || widget.book.title.toLowerCase() == "unknown") {
      String cleanTitle = _controller.bookTitle.trim();
      if (cleanTitle.isEmpty || cleanTitle.toLowerCase() == "unknown") {
        final fileName = widget.book.filePath.split(Platform.pathSeparator).last.split("/").last;
        cleanTitle = fileName.replaceAll(RegExp(r"\.[^.]+$"), "").replaceAll(RegExp(r"[\-_]+"), " ").trim();
      }
      if (cleanTitle.isNotEmpty) {
        widget.book.title = cleanTitle;
      }
    }

    if (widget.book.author.trim().isEmpty || widget.book.author.toLowerCase() == "unknown author") {
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
      if (a != null && a.pageIndex == pageIndex && (a.tool == "bookmark_note" || a.tool == "note")) {
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
                      child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D4E24),
                    ),
                    onPressed: () => Navigator.pop(ctx, textController.text.trim()),
                    child: const Text("Save", style: TextStyle(color: Colors.white)),
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
        return a != null && a.pageIndex == pageToNote && (a.tool == "bookmark_note" || a.tool == "note");
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
    if (_activeTool == ActiveTool.none || _activeTool == ActiveTool.eraser) return;
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
      boundingBox: Rect.fromLTWH(minX, minY, math.max(12.0, maxX - minX), math.max(12.0, maxY - minY)),
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
      if (ann != null && ann.pageIndex == _currentPage && ann.tool != "bookmark_note" && ann.tool != "note") {
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
        -0.85, 0, 0, 0, 235,
        0, -0.85, 0, 0, 230,
        0, 0, -0.85, 0, 220,
        0, 0, 0, 1, 0,
      ]);
    }
    return ColorFilter.mode(bgColor, BlendMode.multiply);
  }

  void _openSettingsDrawer() {
    final isPdfDoc = widget.book.format.toLowerCase() == "pdf";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22120A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    style: TextStyle(color: Color(0xFFFFE0B2), fontFamily: "serif", fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.sticky_note_2_outlined, color: Color(0xFFFFD59E), size: 16),
                    label: const Text("All Notes", style: TextStyle(color: Color(0xFFFFD59E), fontSize: 12)),
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
                    const Text("Font Size:", style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
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
                          _controller.rePaginateOnFontSizeChange(fontSize: val, lineHeight: _lineHeight);
                        },
                      ),
                    ),
                    Text("${_fontSize.toInt()}px", style: const TextStyle(color: Color(0xFFFFE0B2), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              Row(
                children: [
                  const Text("Paper Tone:  ", style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
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
                  const Text("Mode:  ", style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13)),
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
                        _horizontalController = PageController(initialPage: _currentPage);
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
                          initialScrollOffset: _currentPage * (_computedBookHeight + 16.0),
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
      if (a != null && (a.tool == "bookmark_note" || a.tool == "note") && a.text.isNotEmpty) {
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
                  Icon(Icons.bookmarks_outlined, color: Color(0xFFFFD59E), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "All Book Notes",
                    style: TextStyle(color: Color(0xFFFFD59E), fontFamily: "serif", fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3E2723)),
              if (noteList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text("No notes created yet.\nTap 'Mark' to create a note.",
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
                          child: Text("${n.pageIndex + 1}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        title: Text(n.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text("Page ${n.pageIndex + 1}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD59E), size: 12),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _saveProgress(n.pageIndex);
                            if (_currentMode == ReadingMode.horizontal) {
                              _horizontalController.jumpToPage(n.pageIndex);
                            } else if (_currentMode == ReadingMode.vertical && _verticalController.hasClients) {
                              _verticalController.jumpTo(n.pageIndex * (_computedBookHeight + 16.0));
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
                  child: const Text("Close", style: TextStyle(color: Colors.white70)),
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
          border: Border.all(color: _pageBgColor == c ? const Color(0xFFFFD59E) : Colors.black45, width: 2),
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
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: "serif"),
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
          currentPage: _currentPage,
          totalPages: total,
          onBookmarkTap: _toggleBookmark,
          onBookmarkColorTap: () async {
            final c = await ColorWheelDialog.show(context, initialColor: _ribbonColor, title: "Bookmark Ribbon Color");
            if (!mounted || c == null) return;
            setState(() => _ribbonColor = c);
          },
          onAddNoteTap: () => _showAddNoteDialog(),
          onHighlighterColorTap: () async {
            final c = await ColorWheelDialog.show(context, initialColor: _highlightColor, title: "Highlighter Color");
            if (!mounted || c == null) return;
            setState(() => _highlightColor = c);
          },
          onPenColorTap: () async {
            final c = await ColorWheelDialog.show(context, initialColor: _penColor, title: "Pen Ink Color");
            if (!mounted || c == null) return;
            setState(() => _penColor = c);
          },
          onMenuTap: _openSettingsDrawer,
          onToolSelected: (t) => setState(() => _activeTool = t),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenW = constraints.maxWidth;
              final double screenH = constraints.maxHeight;

              // Golden Book Proportions (Guarantees visible wooden desk margins on all sides)
              final double maxBookW = screenW - 56.0;
              final double maxBookH = screenH - 64.0;

              double targetW = maxBookW;
              double targetH = targetW * 1.42;

              if (targetH > maxBookH) {
                targetH = maxBookH;
                targetW = targetH / 1.42;
              }

              final double casingWidth = targetW.clamp(260.0, 520.0);
              final double casingHeight = targetH.clamp(380.0, 780.0);

              const double coverOverhang = 8.0;
              const double spineHingeWidth = 14.0;
              final double bookWidth = casingWidth - (coverOverhang * 2) - spineHingeWidth;
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
                        _buildReaderContent(total, bookHeight, isBookmarked, currentNote),
                        if (_activeTool != ActiveTool.none)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: _onDrawingPanStart,
                              onPanUpdate: _onDrawingPanUpdate,
                              onPanEnd: _onDrawingPanEnd,
                              child: CustomPaint(
                                painter: _LiveDrawingPainter(
                                  tool: _activeTool,
                                  color: _activeTool == ActiveTool.highlighter
                                      ? _highlightColor
                                      : _penColor,
                                  points: _activePoints,
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

  Widget _buildReaderContent(int total, double bookHeight, bool isBookmarked, String? currentNote) {
    return AnimatedBuilder(
      animation: _bookmarkDrapeAnimation,
      builder: (context, child) {
        final double drapeProg = _bookmarkDrapeAnimation.value;

        if (_currentMode == ReadingMode.vertical) {
          return Stack(
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
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: _buildPageContent(idx, total),
                ),
              ),
              RibbonBookmarkWidget(
                ribbonColor: _ribbonColor,
                bookHeight: bookHeight,
                leftOffset: 16.0,
                isCurrentPageBookmarked: isBookmarked,
                noteText: currentNote,
                drapeProgress: drapeProg,
              ),
            ],
          );
        } else if (_currentMode == ReadingMode.horizontal) {
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              PageView.builder(
                controller: _horizontalController,
                physics: const PageScrollPhysics(),
                itemCount: total,
                onPageChanged: _saveProgress,
                itemBuilder: (ctx, idx) => _buildPageContent(idx, total),
              ),
              RibbonBookmarkWidget(
                ribbonColor: _ribbonColor,
                bookHeight: bookHeight,
                leftOffset: 16.0,
                isCurrentPageBookmarked: isBookmarked,
                noteText: currentNote,
                drapeProgress: drapeProg,
              ),
            ],
          );
        } else {
          return RealisticPageCurl(
            pageCount: total,
            initialPage: _currentPage,
            onPageChanged: _saveProgress,
            onSwipeBeforeFirst: _closeHardCover,
            gesturesEnabled: _activeTool == ActiveTool.none,
            paperColor: _pageBgColor.withAlpha(255),
            bookmarkBuilder: (curlProgress, isCurling) {
              return RibbonBookmarkWidget(
                ribbonColor: _ribbonColor,
                bookHeight: bookHeight,
                leftOffset: 16.0,
                isCurrentPageBookmarked: isBookmarked,
                noteText: currentNote,
                drapeProgress: drapeProg,
                curlProgress: curlProgress,
                isCurling: isCurling,
              );
            },
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
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator(color: Color(0xFF8D6E63))),
              ),
              CustomPaint(
                painter: _AnnotationPainter(
                  highlights: widget.book.highlights,
                  currentPage: index,
                ),
              ),
              // Visible Page Note Pin Badge on the Page Canvas
              if (noteForThisPage != null && noteForThisPage.isNotEmpty)
                Positioned(
                  top: 8,
                  right: sideMargin,
                  child: GestureDetector(
                    onTap: () => _showAddNoteDialog(targetPage: index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin, color: Color(0xFF8D4E24), size: 12),
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
        color: _pageBgColor.computeLuminance() > 0.3 ? const Color(0xFF2B221B) : const Color(0xFFEDE0D4),
        fontFamily: "serif",
      ),
    );
  }
}

class _LiveDrawingPainter extends CustomPainter {
  final ActiveTool tool;
  final Color color;
  final List<Offset> points;

  _LiveDrawingPainter({
    required this.tool,
    required this.color,
    required this.points,
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
        ..strokeWidth = 18.0;
    } else if (tool == ActiveTool.pen) {
      paint
        ..color = color
        ..strokeWidth = 2.4;
    } else if (tool == ActiveTool.pencil) {
      paint
        ..color = const Color(0xFF424242)
        ..strokeWidth = 1.4;
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
      if (ann != null && ann.pageIndex == currentPage && ann.tool != "bookmark_note" && ann.tool != "note") {
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
          canvas.drawLine(ann.boundingBox.bottomLeft, ann.boundingBox.bottomRight, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
DART_EOF

echo "=========================================================="
echo " [5/5] Formatter, Analyzer, Tests & Release Build        "
echo "=========================================================="
dart fix --apply
dart format lib/widgets/ribbon_bookmark.dart lib/widgets/hardcover_view.dart lib/widgets/page_curl_view.dart lib/screens/reader_screen.dart

echo "[*] Checking project with flutter analyze..."
flutter analyze

echo "[*] Running test suite..."
flutter test

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
PKG_NAME="com.local.moonreader.moon_reader_flutter"

rm -f "$APK_PATH"

echo "[*] Compiling ARM64 Production Release APK..."
flutter build apk --release \
  --target-platform android-arm64 \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --no-tree-shake-icons \
  --android-skip-build-dependency-validation

if [ ! -f "$APK_PATH" ]; then
  echo "[-] Build failed: APK generate nahi hui!"
  exit 1
fi

APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
echo "[✓] Fresh ARM64 Release APK compiled successfully: $APK_SIZE"

if adb devices | grep -q "device$"; then
  echo "[*] Phone connected. Clean installing package ($PKG_NAME)..."
  adb uninstall "$PKG_NAME" 2>/dev/null || true

  TEMP_REMOTE_APK="/data/local/tmp/ak_reader_install.apk"
  echo "[*] Pushing APK to device temp storage..."
  adb push "$APK_PATH" "$TEMP_REMOTE_APK"

  echo "[*] Installing APK via Package Manager..."
  adb shell pm install -r -d -g "$TEMP_REMOTE_APK"
  adb shell rm -f "$TEMP_REMOTE_APK"

  echo "[*] Launching AK Reader on phone..."
  adb shell monkey -p "$PKG_NAME" -c android.intent.category.LAUNCHER 1
  echo ""
  echo "=========================================================="
  echo " [✓] AK Reader 100% Production Ready & Launched on Phone! "
  echo "=========================================================="
else
  echo "[-] Phone USB se connect nahi tha."
  echo "Release APK ready at: $APK_PATH ($APK_SIZE)"
fi
