import "dart:math" as math;
import "package:flutter/material.dart";
import "color_wheel_picker.dart";

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

    // Exact 180 degree opposite color for embroidered text & borders
    final Color oppositeTextColor = ColorWheelMath.getOppositeWheelColor(ribbonColor);

    const double baseRibbonWidth = 17.0;
    const double extraTailLength = 46.0;
    final double fullLength = bookHeight + extraTailLength;
    final double currentLength = fullLength * drapeProgress.clamp(0.0, 1.0);

    double currentLeft = leftOffset;
    double currentWidth = baseRibbonWidth;
    double flexShiftX = 0.0;
    double flexShiftY = 0.0;
    double flexAngle = 0.0;
    double opacity = 1.0;

    if (isCurling && curlProgress > 0.005) {
      final double p = curlProgress.clamp(0.0, 1.0);
      final double flutter = math.sin(p * math.pi * 2.2);
      flexShiftX = -flutter * 8.0 - (p * 14.0);
      flexShiftY = -math.sin(p * math.pi) * 16.0;
      flexAngle = -math.sin(p * math.pi) * 0.12;

      currentLeft = leftOffset * (1.0 - (p * 1.15)).clamp(0.0, 1.0);
      currentWidth = baseRibbonWidth * (1.0 - (p * 1.2)).clamp(0.0, 1.0);
      opacity = (1.0 - (p * 1.35)).clamp(0.0, 1.0);
    }

    if (opacity <= 0.01 || currentWidth <= 0.5) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: currentLeft + flexShiftX,
      top: -8.0 + flexShiftY,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: flexAngle,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: baseRibbonWidth + 140.0,
            height: currentLength + 12.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(currentWidth, currentLength),
                  painter: _RealFabricClothRibbonPainter(
                    ribbonColor: ribbonColor,
                    oppositeColor: oppositeTextColor,
                    extraTail: extraTailLength,
                    drapeProgress: drapeProgress,
                    curlProgress: curlProgress,
                  ),
                ),
                // Text embroidered vertically on ribbon in 180° opposite color
                if (drapeProgress > 0.8 && !isCurling && currentWidth > 10.0)
                  Positioned(
                    top: 26.0,
                    left: 0,
                    width: currentWidth,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          "AK READER",
                          style: TextStyle(
                            color: oppositeTextColor,
                            fontSize: 7.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                    ),
                  ),
                // Attached bookmark note card with opposite color borders
                if (noteText != null &&
                    noteText!.isNotEmpty &&
                    drapeProgress > 0.7 &&
                    !isCurling)
                  Positioned(
                    left: currentWidth + 6.0,
                    top: bookHeight * 0.28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      constraints: const BoxConstraints(maxWidth: 130),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF0D7),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: oppositeTextColor.withAlpha(200), width: 1.0),
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
      ),
    );
  }
}

class _RealFabricClothRibbonPainter extends CustomPainter {
  final Color ribbonColor;
  final Color oppositeColor;
  final double extraTail;
  final double drapeProgress;
  final double curlProgress;

  _RealFabricClothRibbonPainter({
    required this.ribbonColor,
    required this.oppositeColor,
    required this.extraTail,
    required this.drapeProgress,
    required this.curlProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0.5 || h <= 2.0) return;

    final double notch = math.min(12.0, h * 0.2);
    final double drapeCurve = 2.4 * math.sin(h * 0.012);

    final hsl = HSLColor.fromColor(ribbonColor);
    final Color deepFabric =
        hsl.withLightness((hsl.lightness * 0.62).clamp(0.0, 1.0)).toColor();
    final Color highlightFabric =
        hsl.withLightness((hsl.lightness * 1.38).clamp(0.0, 1.0)).toColor();

    final Path clothPath = Path();
    clothPath.moveTo(0, 0);
    clothPath.cubicTo(
      -1.2,
      h * 0.25,
      1.8,
      h * 0.68,
      drapeCurve,
      h - notch,
    );
    clothPath.lineTo(drapeCurve, h);
    if (drapeProgress >= 0.88) {
      clothPath.lineTo(drapeCurve + w / 2, h - notch);
    }
    clothPath.lineTo(drapeCurve + w, h);
    clothPath.cubicTo(
      drapeCurve + w - 1.2,
      h * 0.68,
      w + 1.8,
      h * 0.25,
      w,
      0,
    );
    clothPath.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.save();
    canvas.translate(2.2, 3.0);
    canvas.drawPath(clothPath, shadowPaint);
    canvas.restore();

    final Paint fabricPaint = Paint()..style = PaintingStyle.fill;
    final Rect bounds = Rect.fromLTWH(0, 0, w + 4, h);
    fabricPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        deepFabric,
        ribbonColor,
        highlightFabric,
        ribbonColor,
        deepFabric,
      ],
      stops: const [0.0, 0.24, 0.50, 0.76, 1.0],
    ).createShader(bounds);

    canvas.drawPath(clothPath, fabricPaint);

    if (w > 6.0) {
      final threadWeft = Paint()
        ..color = Colors.black.withAlpha(22)
        ..strokeWidth = 0.5;
      for (double y = 4.0; y < h - notch; y += 3.0) {
        canvas.drawLine(Offset(0.8, y), Offset(w - 0.8, y + 0.6), threadWeft);
      }

      final threadWarp = Paint()
        ..color = Colors.white.withAlpha(18)
        ..strokeWidth = 0.5;
      for (double x = 2.0; x < w - 2.0; x += 2.4) {
        canvas.drawLine(
            Offset(x, 0), Offset(x + drapeCurve, h - notch), threadWarp);
      }

      // Edge stitches rendered in opposite color
      final stitchPaint = Paint()
        ..color = oppositeColor.withAlpha(190)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(1.0, 0), Offset(drapeCurve + 1.0, h - notch), stitchPaint);
      canvas.drawLine(Offset(w - 1.0, 0), Offset(drapeCurve + w - 1.0, h - notch), stitchPaint);
    }
  }

  @override
  bool shouldRepaint(_RealFabricClothRibbonPainter old) =>
      old.ribbonColor != ribbonColor ||
      old.oppositeColor != oppositeColor ||
      old.extraTail != extraTail ||
      old.drapeProgress != drapeProgress ||
      old.curlProgress != curlProgress;
}
