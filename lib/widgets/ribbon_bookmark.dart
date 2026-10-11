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
              if (noteText != null &&
                  noteText!.isNotEmpty &&
                  drapeProgress > 0.7 &&
                  !isCurling)
                Positioned(
                  left: currentWidth + 6.0,
                  top: bookHeight * 0.28,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    constraints: const BoxConstraints(maxWidth: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF0D7),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                          color: const Color(0xFFC7A97B), width: 0.9),
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
    final Color deepShade =
        hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
    final Color sheenShade =
        hsl.withLightness((hsl.lightness * 1.32).clamp(0.0, 1.0)).toColor();

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
      canvas.drawLine(
          const Offset(1.0, 0), Offset(1.0, h - notch), stitchPaint);
      canvas.drawLine(
          Offset(w - 1.0, 0), Offset(w - 1.0, h - notch), stitchPaint);
    }
  }

  @override
  bool shouldRepaint(_WovenFabricRibbonPainter old) =>
      old.ribbonColor != ribbonColor ||
      old.extraTail != extraTail ||
      old.drapeProgress != drapeProgress;
}
