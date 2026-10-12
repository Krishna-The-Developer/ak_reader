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

        return ClipRect(
          clipBehavior: Clip.hardEdge,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _onHorizontalDragStart(d, h),
            onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, w),
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Container(
              color: solidPaper,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  _buildBasePage(w, h, solidPaper),
                  if (_curlProgress > 0.001) _buildCurlingPage(w, h, solidPaper),
                  if (widget.bookmarkBuilder != null)
                    widget.bookmarkBuilder!(_curlProgress, _curlProgress > 0.001),
                ],
              ),
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

  Widget _buildForwardCurl(
      double w, double h, double p, int pageIndex, Color solidPaper) {
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

  Widget _buildBackwardCurl(
      double w, double h, double p, int pageIndex, Color solidPaper) {
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
  bool shouldReclip(_RectClipper old) =>
      old.startX != startX || old.endX != endX;
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
