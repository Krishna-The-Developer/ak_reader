import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorWheelMath {
  /// Color wheel par exact 180 degree samne (Opposite Hue) ka color nikalta hai
  static Color getOppositeWheelColor(Color ribbonColor) {
    final hsv = HSVColor.fromColor(ribbonColor);

    // 180° Diametrical Opposite Hue
    final double oppositeHue = (hsv.hue + 180.0) % 360.0;

    // Contrast balance: Ribbon dark hai toh text bright, ribbon light hai toh text dark
    final double textValue = hsv.value > 0.65 ? 0.15 : 0.95;
    final double textSaturation = hsv.saturation < 0.25 ? 0.85 : hsv.saturation;

    return HSVColor.fromAHSV(1.0, oppositeHue, textSaturation, textValue).toColor();
  }
}

class ColorWheelDialog extends StatefulWidget {
  final Color initialColor;
  final String title;
  final ValueChanged<Color>? onColorChanged;

  const ColorWheelDialog({
    super.key,
    required this.initialColor,
    this.title = "Color Picker",
    this.onColorChanged,
  });

  /// Static helper method jo reader_screen.dart call karti hai
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = "Color Picker",
  }) async {
    Color selected = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => ColorWheelDialog(
        initialColor: selected,
        title: title,
        onColorChanged: (c) => selected = c,
      ),
    );
  }

  @override
  State<ColorWheelDialog> createState() => _ColorWheelDialogState();
}

class _ColorWheelDialogState extends State<ColorWheelDialog> {
  late Color _selectedColor;
  late double _currentHue;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _currentHue = HSVColor.fromColor(widget.initialColor).hue;
  }

  void _updateColor(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    double angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    setState(() {
      _currentHue = angle;
      _selectedColor = HSVColor.fromAHSV(1.0, _currentHue, 0.88, 0.88).toColor();
    });
    widget.onColorChanged?.call(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    final oppositeColor = ColorWheelMath.getOppositeWheelColor(_selectedColor);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 360 Degree Touch Wheel
          GestureDetector(
            onPanDown: (d) => _updateColor(d.localPosition, const Size(200, 200)),
            onPanUpdate: (d) => _updateColor(d.localPosition, const Size(200, 200)),
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _WheelPainter(selectedHue: _currentHue),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Live Ribbon + Opposite Text Preview
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withAlpha(90),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark, color: oppositeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "180° OPPOSITE COLOR TEXT",
                  style: TextStyle(
                    color: oppositeColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text("Apply Color", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final double selectedHue;
  _WheelPainter({required this.selectedHue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepGradient = SweepGradient(
      colors: List.generate(
        361,
        (deg) => HSVColor.fromAHSV(1.0, deg.toDouble(), 0.88, 0.88).toColor(),
      ),
    );

    final trackPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26;

    canvas.drawCircle(center, radius - 15, trackPaint);

    final rad = selectedHue * math.pi / 180;
    final handleDistance = radius - 15;
    final handleCenter = Offset(
      center.dx + handleDistance * math.cos(rad),
      center.dy + handleDistance * math.sin(rad),
    );

    final handleBorder = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;
    final handleFill = Paint()..color = HSVColor.fromAHSV(1.0, selectedHue, 0.88, 0.88).toColor();

    canvas.drawCircle(handleCenter, 11, handleFill);
    canvas.drawCircle(handleCenter, 11, handleBorder);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => oldDelegate.selectedHue != selectedHue;
}
