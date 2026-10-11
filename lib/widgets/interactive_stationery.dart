import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wooden_desk_frame.dart';

class InteractiveStationeryOverlay extends StatelessWidget {
  final ActiveTool tool;
  final Color inkColor;
  final Offset? activeFingerPosition;

  const InteractiveStationeryOverlay({
    super.key,
    required this.tool,
    required this.inkColor,
    required this.activeFingerPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (tool == ActiveTool.none || activeFingerPosition == null) {
      return const SizedBox.shrink();
    }

    final pos = activeFingerPosition!;

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _Floating3DToolPainter(
            tool: tool,
            inkColor: inkColor,
            tipPosition: pos,
          ),
        ),
      ),
    );
  }
}

class _Floating3DToolPainter extends CustomPainter {
  final ActiveTool tool;
  final Color inkColor;
  final Offset tipPosition;

  _Floating3DToolPainter({
    required this.tool,
    required this.inkColor,
    required this.tipPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(tipPosition.dx, tipPosition.dy);
    canvas.rotate(-math.pi / 4.0); // 45 degree natural handwriting tilt

    // Dynamic Cast Shadow on Book Paper
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, -6, 14, 115),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    switch (tool) {
      case ActiveTool.highlighter:
        _draw3DHighlighter(canvas);
        break;
      case ActiveTool.pen:
        _draw3DPen(canvas);
        break;
      case ActiveTool.pencil:
        _draw3DPencil(canvas);
        break;
      case ActiveTool.eraser:
        _draw3DEraser(canvas);
        break;
      case ActiveTool.none:
        break;
    }

    canvas.restore();
  }

  void _draw3DHighlighter(Canvas canvas) {
    final tipPath = Path()
      ..moveTo(-5, 0)
      ..lineTo(5, 0)
      ..lineTo(3.5, -14)
      ..lineTo(-3.5, -14)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = inkColor);

    canvas.drawRect(
      const Rect.fromLTWH(-6, -20, 12, 6),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-10, -96, 6, 76),
      Paint()..color = const Color(0xFFD4A017),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-4, -96, 7, 76),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawRect(
      const Rect.fromLTWH(3, -96, 7, 76),
      Paint()..color = const Color(0xFFFFCA28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -110, 22, 14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1E1E1E),
    );
  }

  void _draw3DPencil(Canvas canvas) {
    final leadPath = Path()
      ..moveTo(-1.5, 0)
      ..lineTo(1.5, 0)
      ..lineTo(0, -6)
      ..close();
    canvas.drawPath(leadPath, Paint()..color = const Color(0xFF263238));

    final woodPath = Path()
      ..moveTo(-5, -7)
      ..lineTo(5, -7)
      ..lineTo(1.5, 0)
      ..lineTo(-1.5, 0)
      ..close();
    canvas.drawPath(woodPath, Paint()..color = const Color(0xFFD7CCC8));

    canvas.drawRect(
      const Rect.fromLTWH(-5, -92, 3.2, 85),
      Paint()..color = const Color(0xFFF57F17),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-1.8, -92, 3.6, 85),
      Paint()..color = const Color(0xFFFFF176),
    );
    canvas.drawRect(
      const Rect.fromLTWH(1.8, -92, 3.2, 85),
      Paint()..color = const Color(0xFFFBC02D),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-5.5, -100, 11, 8),
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -112, 10, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF48FB1),
    );
  }

  void _draw3DPen(Canvas canvas) {
    final nibPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-3, -10)
      ..lineTo(3, -10)
      ..close();
    canvas.drawPath(nibPath, Paint()..color = const Color(0xFFECEFF1));
    canvas.drawRect(
      const Rect.fromLTWH(-4, -26, 8, 16),
      Paint()..color = const Color(0xFF263238),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-4.5, -29, 9, 3),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-4.5, -98, 3.5, 69),
      Paint()..color = const Color(0xFF0D47A1),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-1, -98, 2.5, 69),
      Paint()..color = const Color(0xFF90CAF9),
    );
    canvas.drawRect(
      const Rect.fromLTWH(1.5, -98, 3.5, 69),
      Paint()..color = const Color(0xFF1565C0),
    );
  }

  void _draw3DEraser(Canvas canvas) {
    final rubberPath = Path()
      ..moveTo(-10, 0)
      ..lineTo(10, 0)
      ..lineTo(13, -34)
      ..lineTo(-13, -34)
      ..close();
    canvas.drawPath(rubberPath, Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawRect(
      const Rect.fromLTWH(-13, -62, 26, 28),
      Paint()..color = const Color(0xFF1E88E5),
    );
  }

  @override
  bool shouldRepaint(_Floating3DToolPainter old) =>
      old.tipPosition != tipPosition;
}
