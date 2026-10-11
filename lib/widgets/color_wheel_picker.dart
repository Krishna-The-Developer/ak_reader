import 'dart:math' as math;

import 'package:flutter/material.dart';

class ColorWheelDialog extends StatefulWidget {
  final Color initialColor;
  final String title;
  final ValueChanged<Color>? onColorChanged;

  const ColorWheelDialog({
    super.key,
    required this.initialColor,
    required this.title,
    this.onColorChanged,
  });

  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    required String title,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) =>
          ColorWheelDialog(initialColor: initialColor, title: title),
    );
  }

  @override
  State<ColorWheelDialog> createState() => _ColorWheelDialogState();
}

class _ColorWheelDialogState extends State<ColorWheelDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  void _updateWheel(Offset localPos, double radius) {
    final dx = localPos.dx - radius;
    final dy = localPos.dy - radius;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0) {
      return;
    }

    double angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) {
      angle += 360;
    }

    final sat = (dist / radius).clamp(0.0, 1.0);
    setState(() {
      _hsv = _hsv.withHue(angle).withSaturation(sat);
    });
    widget.onColorChanged?.call(_hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    const radius = size / 2;

    return Dialog(
      backgroundColor: const Color(0xFF22130B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFFFFD59E),
                fontFamily: 'serif',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onPanDown: (d) => _updateWheel(d.localPosition, radius),
              onPanUpdate: (d) => _updateWheel(d.localPosition, radius),
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(painter: _WheelPainter(hsv: _hsv)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.brightness_6,
                  color: Color(0xFFD7A878),
                  size: 18,
                ),
                Expanded(
                  child: Slider(
                    value: _hsv.value,
                    min: 0.1,
                    max: 1.0,
                    activeColor: const Color(0xFFD7A878),
                    inactiveColor: const Color(0xFF3E2723),
                    onChanged: (v) {
                      setState(() {
                        _hsv = _hsv.withValue(v);
                      });
                      widget.onColorChanged?.call(_hsv.toColor());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _hsv.toColor(),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _hsv.toColor()),
                  child: const Text(
                    "Apply Color",
                    style: TextStyle(
                      color: Color(0xFFFFD59E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final HSVColor hsv;
  _WheelPainter({required this.hsv});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sweep = 2.5 * math.pi / 180;

    for (int i = 0; i < 360; i += 2) {
      final rad = i * math.pi / 180;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromAHSV(1.0, i.toDouble(), 0.0, hsv.value).toColor(),
            HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, hsv.value).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          rad,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    final thumbAngle = hsv.hue * math.pi / 180;
    final thumbDist = hsv.saturation * radius;
    final thumbX = center.dx + thumbDist * math.cos(thumbAngle);
    final thumbY = center.dy + thumbDist * math.sin(thumbAngle);

    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbPaint);
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      6,
      Paint()..color = hsv.toColor(),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.hsv != hsv;
}
