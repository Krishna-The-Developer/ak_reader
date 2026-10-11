import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class RealisticPageCurl extends StatefulWidget {
  final int pageCount;
  final int initialPage;
  final Widget Function(BuildContext context, int pageIndex) builder;
  final ValueChanged<int> onPageChanged;
  final Color paperColor;
  final bool enablePaperTransparency;
  final bool gesturesEnabled;

  const RealisticPageCurl({
    super.key,
    required this.pageCount,
    required this.initialPage,
    required this.builder,
    required this.onPageChanged,
    this.paperColor = const Color(0xFFF5EACB),
    this.enablePaperTransparency = true,
    this.gesturesEnabled = true,
  });

  @override
  State<RealisticPageCurl> createState() => _RealisticPageCurlState();
}

typedef PageCurlView = RealisticPageCurl;

class _RealisticPageCurlState extends State<RealisticPageCurl>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late int _currentPage;
  double _dragProgress = 0.0;
  bool _isForward = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )
      ..addListener(() {
        setState(() {
          _dragProgress = _animController.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final nextIndex = _isForward ? _currentPage + 1 : _currentPage - 1;
          _isDragging = false;
          _dragProgress = 0.0;
          _animController.reset();
          if (nextIndex >= 0 && nextIndex < widget.pageCount) {
            setState(() {
              _currentPage = nextIndex;
            });
            widget.onPageChanged(nextIndex);
          }
        } else if (status == AnimationStatus.dismissed) {
          _isDragging = false;
          _dragProgress = 0.0;
        }
      });
  }

  @override
  void didUpdateWidget(RealisticPageCurl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPage != _currentPage &&
        !_isDragging &&
        !_animController.isAnimating) {
      setState(() {
        _currentPage = widget.initialPage;
      });
    }
  }

  @override
  void disposeInvoice() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.gesturesEnabled || _animController.isAnimating) return;
    final width = MediaQuery.of(context).size.width;
    final touchX = details.localPosition.dx;

    if (touchX > width * 0.5) {
      if (_currentPage < widget.pageCount - 1) {
        _isForward = true;
        _isDragging = true;
        _dragProgress = 0.0;
      }
    } else {
      if (_currentPage > 0) {
        _isForward = false;
        _isDragging = true;
        _dragProgress = 0.0;
      }
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final width = MediaQuery.of(context).size.width;
    final delta = details.primaryDelta ?? 0.0;

    setState(() {
      if (_isForward) {
        _dragProgress = (_dragProgress - (delta / width)).clamp(0.0, 1.0);
      } else {
        _dragProgress = (_dragProgress + (delta / width)).clamp(0.0, 1.0);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    final velocity = details.primaryVelocity ?? 0.0;

    if (_isForward) {
      if (_dragProgress > 0.3 || velocity < -400) {
        _animController.forward(from: _dragProgress);
      } else {
        _animController.reverse(from: _dragProgress);
      }
    } else {
      if (_dragProgress > 0.3 || velocity > 400) {
        _animController.forward(from: _dragProgress);
      } else {
        _animController.reverse(from: _dragProgress);
      }
    }
  }

  Widget _buildPaperSheet(BuildContext context, int pageIndex) {
    final reverseSideIndex = pageIndex + 1;
    final hasReversePage = reverseSideIndex < widget.pageCount;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: widget.paperColor),
        if (widget.enablePaperTransparency && hasReversePage)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.09,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..setEntry(0, 0, -1.0),
                    child: widget.builder(context, reverseSideIndex),
                  ),
                ),
              ),
            ),
          ),
        widget.builder(context, pageIndex),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (!_isDragging)
          _buildPaperSheet(context, _currentPage)
        else ...[
          if (_isForward)
            _buildForwardLayers(context, width, height)
          else
            _buildBackwardLayers(context, width, height),
        ],
      ],
    );

    if (!widget.gesturesEnabled) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: content,
    );
  }

  Widget _buildForwardLayers(BuildContext context, double w, double h) {
    final nextPageIndex = _currentPage + 1;
    final foldX = w * (1.0 - _dragProgress);
    final flapWidth = math.min(w * 0.28, (w - foldX) * 0.6);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          clipper: _RectClipper(Rect.fromLTRB(foldX, 0, w, h)),
          child: _buildPaperSheet(context, nextPageIndex),
        ),
        Positioned(
          left: foldX,
          top: 0,
          width: math.min(28.0, w - foldX),
          height: h,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x42000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          clipper: _RectClipper(Rect.fromLTRB(0, 0, foldX, h)),
          child: _buildPaperSheet(context, _currentPage),
        ),
        Positioned(
          left: math.max(0.0, foldX - 16.0),
          top: 0,
          width: 16.0,
          height: h,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0x29000000)],
                ),
              ),
            ),
          ),
        ),
        if (flapWidth > 1.0)
          Positioned(
            left: foldX - flapWidth,
            top: 0,
            width: flapWidth,
            height: h,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: widget.paperColor.withAlpha(250)),
                  if (widget.enablePaperTransparency)
                    Opacity(
                      opacity: 0.12,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(0, 0, -1.0),
                        child: widget.builder(context, _currentPage),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0x33000000),
                          const Color(0x4DFFFFFF),
                          widget.paperColor,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackwardLayers(BuildContext context, double w, double h) {
    final prevPageIndex = _currentPage - 1;
    final foldX = w * _dragProgress;
    final flapWidth = math.min(w * 0.28, foldX * 0.6);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          clipper: _RectClipper(Rect.fromLTRB(foldX, 0, w, h)),
          child: _buildPaperSheet(context, _currentPage),
        ),
        Positioned(
          left: foldX,
          top: 0,
          width: math.min(28.0, w - foldX),
          height: h,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x42000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          clipper: _RectClipper(
              Rect.fromLTRB(0, 0, math.max(0.0, foldX - flapWidth), h)),
          child: _buildPaperSheet(context, prevPageIndex),
        ),
        if (flapWidth > 1.0)
          Positioned(
            left: foldX - flapWidth,
            top: 0,
            width: flapWidth,
            height: h,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: widget.paperColor.withAlpha(250)),
                  if (widget.enablePaperTransparency)
                    Opacity(
                      opacity: 0.12,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(0, 0, -1.0),
                        child: widget.builder(context, prevPageIndex),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.paperColor,
                          const Color(0x4DFFFFFF),
                          const Color(0x33000000),
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  final Rect clipRect;
  _RectClipper(this.clipRect);

  @override
  Rect getClip(Size size) => clipRect;

  @override
  bool shouldReclip(_RectClipper oldClipper) => oldClipper.clipRect != clipRect;
}
