import "dart:math" as math;
import "package:flutter/material.dart";
import "../services/sound_service.dart";

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
  final Widget? bookmarkWidget;
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
    this.bookmarkWidget,
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
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isCoverOpen) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HardcoverView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCoverOpen && !oldWidget.isCoverOpen) {
      if (_animController.value < 1.0 && !_animController.isAnimating) {
        _animController.forward(from: _dragProgress);
      }
    } else if (!widget.isCoverOpen && oldWidget.isCoverOpen) {
      if (_animController.value > 0.0 && !_animController.isAnimating) {
        _animController.reverse(from: _animController.value);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerOpen() {
    if (_animController.isAnimating || widget.isCoverOpen) return;
    SoundService.playBookOpenThud();
    _animController.forward(from: 0.0).then((_) {
      widget.onOpen();
    });
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
          width: 18,
          height: 18,
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

  Widget _buildFrontCoverBoard() {
    return Container(
      width: widget.casingWidth,
      height: widget.casingHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF381A0B),
            Color(0xFF241006),
            Color(0xFF140602),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5A2A12),
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xDD000000),
            blurRadius: 24,
            spreadRadius: 2,
            offset: Offset(4, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(7.0),
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
            width: 18,
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
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories,
                    color: Color(0xFFFFD59E),
                    size: 46,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD59E),
                      fontFamily: "serif",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 2),
                        ),
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
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x88FFD59E),
                        width: 1.1,
                      ),
                      color: const Color(0x33000000),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Color(0xFFFFD59E),
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Tap to Open Book",
                          style: TextStyle(
                            color: Color(0xFFFFD59E),
                            fontFamily: "serif",
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsideEndpaper() {
    return Container(
      width: widget.casingWidth,
      height: widget.casingHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF2A140A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5A2A12),
          width: 2.0,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E2BA),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: const Color(0x445A2A12),
              width: 1.2,
            ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5A2A12),
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xDD000000),
            blurRadius: 24,
            spreadRadius: 2,
            offset: Offset(4, 12),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Pages strictly locked inside boundaries (ZERO desk bleed)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      color: const Color(0xFFF5EACB),
                      child: (widget.isCoverOpen || _animController.value > 0.05 || _isDragging)
                          ? widget.bookPagesContent
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                // 2. Bookmark Ribbon drawn at unclipped book casing level
                if ((widget.isCoverOpen || _animController.value > 0.05) && widget.bookmarkWidget != null)
                  Positioned.fill(
                    child: widget.bookmarkWidget!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCoverOpen && !_animController.isAnimating && !_isDragging) {
      return _buildOpenBookCasing();
    }

    return SizedBox(
      width: widget.casingWidth,
      height: widget.casingHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerOpen,
        onHorizontalDragStart: (details) {
          if (_animController.isAnimating || widget.isCoverOpen) return;
          _isDragging = true;
          _dragProgress = _animController.value;
        },
        onHorizontalDragUpdate: (details) {
          if (!_isDragging || _animController.isAnimating || widget.isCoverOpen) return;
          setState(() {
            _dragProgress = (_dragProgress -
                    (details.primaryDelta ?? 0) / widget.casingWidth)
                .clamp(0.0, 1.0);
          });
        },
        onHorizontalDragEnd: (details) {
          if (!_isDragging || _animController.isAnimating || widget.isCoverOpen) return;
          _isDragging = false;
          final velocity = details.primaryVelocity ?? 0.0;
          if (_dragProgress > 0.18 || velocity < -180) {
            SoundService.playBookOpenThud();
            _animController.forward(from: _dragProgress).then((_) {
              widget.onOpen();
            });
          } else {
            _animController.reverse(from: _dragProgress);
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double progress = _isDragging ? _dragProgress : _animation.value;

            if (progress >= 0.99) {
              return _buildOpenBookCasing();
            }

            // OUTWARD 3D SWING: Negative perspective pushes front towards viewer
            final double angle = -progress * math.pi;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildOpenBookCasing(),
                Positioned(
                  left: 0,
                  top: 0,
                  width: widget.casingWidth,
                  height: widget.casingHeight,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, -0.0014)
                      ..rotateY(angle),
                    child: progress < 0.50
                        ? _buildFrontCoverBoard()
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildInsideEndpaper(),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
