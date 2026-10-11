import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import 'wooden_desk_frame.dart';

class InteractiveStationeryOverlay extends StatefulWidget {
  final ActiveTool tool;
  final Color inkColor;
  final Rect? targetTextRect;
  final VoidCallback onAnimationComplete;

  const InteractiveStationeryOverlay({
    super.key,
    required this.tool,
    required this.inkColor,
    required this.targetTextRect,
    required this.onAnimationComplete,
  });

  @override
  State<InteractiveStationeryOverlay> createState() =>
      _InteractiveStationeryOverlayState();
}

class _InteractiveStationeryOverlayState
    extends State<InteractiveStationeryOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    if (widget.targetTextRect != null && widget.tool != ActiveTool.none) {
      SoundService.playToolGlide();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(InteractiveStationeryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetTextRect != null &&
        widget.targetTextRect != oldWidget.targetTextRect &&
        widget.tool != ActiveTool.none) {
      SoundService.playToolGlide();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tool == ActiveTool.none || widget.targetTextRect == null) {
      return const SizedBox.shrink();
    }

    final rect = widget.targetTextRect!;
    final progress = _controller.value;
    final currentX = rect.left + (rect.width * progress);
    final currentY = rect.bottom;

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _StationeryPainter(
          tool: widget.tool,
          inkColor: widget.inkColor,
          drawStart: rect.bottomLeft,
          currentTip: Offset(currentX, currentY),
          progress: progress,
        ),
      ),
    );
  }
}

class _StationeryPainter extends CustomPainter {
  final ActiveTool tool;
  final Color inkColor;
  final Offset drawStart;
  final Offset currentTip;
  final double progress;

  _StationeryPainter({
    required this.tool,
    required this.inkColor,
    required this.drawStart,
    required this.currentTip,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Live stroke being laid down
    final strokePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (tool == ActiveTool.highlighter) {
      strokePaint
        ..color = inkColor.withAlpha(95)
        ..strokeWidth = 18.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(drawStart.dx, currentTip.dy - 7),
        Offset(currentTip.dx, currentTip.dy - 7),
        strokePaint,
      );
    } else if (tool == ActiveTool.pen) {
      strokePaint
        ..color = const Color(0xFF1A237E)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(drawStart.dx, currentTip.dy),
        Offset(currentTip.dx, currentTip.dy),
        strokePaint,
      );
    } else if (tool == ActiveTool.pencil) {
      strokePaint
        ..color = const Color(0xFF424242)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(drawStart.dx, currentTip.dy),
        Offset(currentTip.dx, currentTip.dy),
        strokePaint,
      );
    }

    // 2. 3D Model with cast shadow
    canvas.save();
    canvas.translate(currentTip.dx, currentTip.dy);
    canvas.rotate(-math.pi / 4.2);

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, -8, 14, 110), const Radius.circular(3)),
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
      ..moveTo(-4, 0)
      ..lineTo(4, 0)
      ..lineTo(3, -12)
      ..lineTo(-3, -12)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = inkColor);

    canvas.drawRect(const Rect.fromLTWH(-5, -18, 10, 6),
        Paint()..color = const Color(0xFF212121));
    canvas.drawRect(const Rect.fromLTWH(-9, -95, 6, 77),
        Paint()..color = const Color(0xFFD4A017));
    canvas.drawRect(const Rect.fromLTWH(-3, -95, 6, 77),
        Paint()..color = const Color(0xFFFFE082));
    canvas.drawRect(const Rect.fromLTWH(3, -95, 6, 77),
        Paint()..color = const Color(0xFFFFCA28));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -108, 20, 13), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E1E1E),
    );
  }

  void _draw3DPencil(Canvas canvas) {
    final leadPath = Path()
      ..moveTo(-1, 0)
      ..lineTo(1, 0)
      ..lineTo(0, -6)
      ..close();
    canvas.drawPath(leadPath, Paint()..color = const Color(0xFF263238));

    final woodPath = Path()
      ..moveTo(-4, -6)
      ..lineTo(4, -6)
      ..lineTo(1, 0)
      ..lineTo(-1, 0)
      ..close();
    canvas.drawPath(woodPath, Paint()..color = const Color(0xFFD7CCC8));

    canvas.drawRect(const Rect.fromLTWH(-4, -90, 2.6, 84),
        Paint()..color = const Color(0xFFF57F17));
    canvas.drawRect(const Rect.fromLTWH(-1.4, -90, 2.8, 84),
        Paint()..color = const Color(0xFFFFF176));
    canvas.drawRect(const Rect.fromLTWH(1.4, -90, 2.6, 84),
        Paint()..color = const Color(0xFFFBC02D));
    canvas.drawRect(const Rect.fromLTWH(-4.5, -98, 9, 8),
        Paint()..color = const Color(0xFFFFD700));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -108, 8, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFFF48FB1),
    );
  }

  void _draw3DPen(Canvas canvas) {
    final nibPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-2.5, -8)
      ..lineTo(2.5, -8)
      ..close();
    canvas.drawPath(nibPath, Paint()..color = const Color(0xFFECEFF1));
    canvas.drawRect(const Rect.fromLTWH(-3.5, -22, 7, 14),
        Paint()..color = const Color(0xFF263238));
    canvas.drawRect(const Rect.fromLTWH(-4, -25, 8, 3),
        Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawRect(const Rect.fromLTWH(-4, -95, 3, 70),
        Paint()..color = const Color(0xFF0D47A1));
    canvas.drawRect(const Rect.fromLTWH(-1, -95, 2, 70),
        Paint()..color = const Color(0xFF90CAF9));
    canvas.drawRect(const Rect.fromLTWH(1, -95, 3, 70),
        Paint()..color = const Color(0xFF1565C0));
  }

  void _draw3DEraser(Canvas canvas) {
    final rubberPath = Path()
      ..moveTo(-8, 0)
      ..lineTo(8, 0)
      ..lineTo(11, -30)
      ..lineTo(-11, -30)
      ..close();
    canvas.drawPath(rubberPath, Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawRect(const Rect.fromLTWH(-11, -55, 22, 25),
        Paint()..color = const Color(0xFF1E88E5));
  }

  @override
  bool shouldRepaint(_StationeryPainter old) =>
      old.progress != progress || old.currentTip != currentTip;
}
