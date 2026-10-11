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
      duration: const Duration(milliseconds: 520),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isCoverOpen) {
      _animController.value = 1.0;
      _dragProgress = 0.0;
    }

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
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
    // ROOT CAUSE FIX: If book is open, unmount the swinging cover entirely.
    // Absolutely no endpaper or transform can ever leak onto the desk.
    if (widget.isCoverOpen &&
        !_animController.isAnimating &&
        _dragProgress == 0.0) {
      return _buildOpenBookCasing();
    }
    if (_animController.value >= 0.96) {
      return _buildOpenBookCasing();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double progress = _animController.isAnimating
            ? _animation.value
            : (widget.isCoverOpen ? 1.0 : _dragProgress);

        if (progress >= 0.96) {
          return _buildOpenBookCasing();
        }

        final double angle = -progress * math.pi;
        final double forwardScale = 1.0 + 0.04 * math.sin(progress * math.pi);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (progress > 0.04) _buildOpenBookCasing(),

            // Strict ClipRect so no 3D polygon can ever bleed outside book boundaries
            ClipRect(
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0005)
                  ..rotateY(angle),
                child: Transform.scale(
                  scale: forwardScale,
                  alignment: Alignment.centerLeft,
                  child: progress < 0.5
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _dragProgress = (_dragProgress -
                                      (details.primaryDelta ?? 0) /
                                          widget.casingWidth)
                                  .clamp(0.0, 1.0);
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
                  const Icon(Icons.auto_stories,
                      color: Color(0xFFFFD59E), size: 44),
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
                        Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(1, 2)),
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
                      Icon(Icons.swipe_left,
                          color: Color(0x99FFD59E), size: 16),
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
