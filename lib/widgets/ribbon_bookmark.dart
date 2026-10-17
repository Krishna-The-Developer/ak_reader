import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'color_wheel_picker.dart';

class RibbonBookmarkWidget extends StatelessWidget {
  final Color ribbonColor;
  final double bookHeight;
  final double leftOffset;
  final bool isCurrentPageBookmarked;
  final bool isBookmarkedAhead;
  final String? noteText;
  final double drapeProgress;
  final double curlProgress;
  final bool isCurling;
  final VoidCallback? onNoteTap;

  const RibbonBookmarkWidget({
    super.key,
    required this.ribbonColor,
    required this.bookHeight,
    this.leftOffset = 4.0,
    required this.isCurrentPageBookmarked,
    this.isBookmarkedAhead = false,
    this.noteText,
    this.drapeProgress = 1.0,
    this.curlProgress = 0.0,
    this.isCurling = false,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCurrentPageBookmarked && !isBookmarkedAhead) {
      return const SizedBox.shrink();
    }

    final double actualBookH = bookHeight > 50.0 ? bookHeight : 620.0;
    const double ribbonW = 16.0;
    const double extraDeskTail = 110.0;
    final Color oppositeTextColor = ColorWheelMath.getOppositeWheelColor(ribbonColor);

    // CASE 1: Bookmark aage ke page par hai -> Sirf desk par tail latkegi
    if (!isCurrentPageBookmarked && isBookmarkedAhead) {
      return Positioned(
        left: leftOffset,
        top: actualBookH - 4.0,
        width: ribbonW + 20.0,
        height: extraDeskTail,
        child: CustomPaint(
          size: const Size(ribbonW, extraDeskTail),
          painter: _StableTailPainter(
            color: ribbonColor,
            oppositeColor: oppositeTextColor,
          ),
        ),
      );
    }

    // CASE 2: Bookmark isi page par hai -> Top spine se book cross karke desk tak
    final double totalLen = actualBookH + extraDeskTail;
    final double visibleLen = totalLen * (drapeProgress > 0.05 ? drapeProgress : 1.0).clamp(0.1, 1.0);

    return Positioned(
      left: leftOffset,
      top: 0.0,
      width: ribbonW + 160.0,
      height: visibleLen + 10.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ribbon Body + Hanging Desk Tail
          CustomPaint(
            size: Size(ribbonW, visibleLen),
            painter: _StableDevelopableRibbonPainter(
              color: ribbonColor,
              oppositeColor: oppositeTextColor,
              curlProgress: isCurling ? curlProgress : 0.0,
            ),
          ),

          // AK Monogram
          if (visibleLen > 100.0)
            Positioned(
              top: 28.0,
              left: 0,
              width: ribbonW,
              height: 60.0,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    "AK",
                    style: TextStyle(
                      color: oppositeTextColor.withAlpha(220),
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontFamily: "monospace",
                    ),
                  ),
                ),
              ),
            ),

          // Parchment Note
          if (noteText != null && noteText!.isNotEmpty && visibleLen > 140.0)
            Positioned(
              left: ribbonW + 4.0,
              top: actualBookH * 0.16,
              child: GestureDetector(
                onTap: onNoteTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  constraints: const BoxConstraints(maxWidth: 135),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBCAAA4), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 4.0,
                        offset: Offset(1.5, 2.0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border, size: 9, color: ribbonColor),
                          const SizedBox(width: 3),
                          const Text(
                            "NOTE",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noteText!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "serif",
                          fontSize: 9.5,
                          height: 1.2,
                          color: Color(0xFF2E1C0C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StableDevelopableRibbonPainter extends CustomPainter {
  final Color color;
  final Color oppositeColor;
  final double curlProgress;

  _StableDevelopableRibbonPainter({
    required this.color,
    required this.oppositeColor,
    required this.curlProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 1.0 || h <= 5.0) return;

    const double notch = 14.0;
    // Bending offset during curl: theta = theta_max * sin^2(pi*t/2)
    final double theta = (curlProgress > 0)
        ? 18.0 * math.pow(math.sin(curlProgress * math.pi * 0.5), 2)
        : 0.0;

    final Path path = Path();
    path.moveTo(0, 0);
    path.cubicTo(theta * 0.4, h * 0.3, theta * 0.9, h * 0.7, theta, h - notch);
    path.lineTo(w * 0.5 + theta, h - notch - 10.0);
    path.lineTo(w + theta, h - notch);
    path.cubicTo(w + theta * 0.9, h * 0.7, w + theta * 0.4, h * 0.3, w, 0);
    path.close();

    // 1. Drop shadow on page & desk
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.save();
    canvas.translate(2.0, 3.0);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. Silk Shading
    final hsl = HSLColor.fromColor(color);
    final deep = hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor();
    final shine = hsl.withLightness((hsl.lightness * 1.4).clamp(0.0, 1.0)).toColor();

    final Paint fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(theta, 0),
        Offset(w + theta, 0),
        [deep, color, shine, color, deep],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    canvas.drawPath(path, fill);

    // 3. Stitched Edge
    final stitch = Paint()
      ..color = oppositeColor.withAlpha(180)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(1.0, 0), Offset(1.0 + theta, h - notch), stitch);
    canvas.drawLine(Offset(w - 1.0, 0), Offset(w - 1.0 + theta, h - notch), stitch);
  }

  @override
  bool shouldRepaint(_StableDevelopableRibbonPainter old) =>
      old.color != color || old.curlProgress != curlProgress;
}

class _StableTailPainter extends CustomPainter {
  final Color color;
  final Color oppositeColor;

  _StableTailPainter({required this.color, required this.oppositeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    const double notch = 14.0;

    final Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, h);
    path.lineTo(w * 0.5, h - notch);
    path.lineTo(w, h);
    path.lineTo(w, 0);
    path.close();

    final shadow = Paint()
      ..color = Colors.black.withAlpha(130)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.save();
    canvas.translate(2.0, 2.5);
    canvas.drawPath(path, shadow);
    canvas.restore();

    final hsl = HSLColor.fromColor(color);
    final deep = hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor();
    final shine = hsl.withLightness((hsl.lightness * 1.4).clamp(0.0, 1.0)).toColor();

    final Paint fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [deep, color, shine, color, deep],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(_StableTailPainter old) => old.color != color;
}
