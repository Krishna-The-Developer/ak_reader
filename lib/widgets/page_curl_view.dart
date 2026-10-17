import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

/* =====================================================================
 * LEGACY METHOD (UNIDIRECTIONAL DRAG APPROXIMATION) - COMMENTED OUT
 * =====================================================================
 * void legacyPaint(Canvas canvas, Size size, bool isForward) {
 *   // Simple symmetric clipping without sign-based curvature mirror
 * }
 * ===================================================================== */

enum CurlDragMode { none, edgePull, cornerPull }

typedef BookmarkCurlBuilder = Widget Function(double curlProgress, bool isCurling);

class RealisticPageCurl extends StatefulWidget {
  final int pageCount;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onSwipeBeforeFirst;
  final bool gesturesEnabled;
  final Color paperColor;
  final BookmarkCurlBuilder? bookmarkBuilder;
  final Widget Function(BuildContext context, int pageIndex) builder;

  const RealisticPageCurl({
    super.key,
    required this.pageCount,
    this.initialPage = 0,
    this.onPageChanged,
    this.onSwipeBeforeFirst,
    this.gesturesEnabled = true,
    this.paperColor = const Color(0xFFF6F0E0),
    this.bookmarkBuilder,
    required this.builder,
  });

  @override
  State<RealisticPageCurl> createState() => _RealisticPageCurlState();
}

class _RealisticPageCurlState extends State<RealisticPageCurl>
    with SingleTickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _animController;

  Offset _dragOrigin = Offset.zero;
  Offset _dragCurrent = Offset.zero;
  CurlDragMode _dragMode = CurlDragMode.none;
  int _sigma = 1; // +1: Right -> Left (Forward), -1: Left -> Right (Backward)

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void didUpdateWidget(covariant RealisticPageCurl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPage != _currentPage) {
      _currentPage = widget.initialPage;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragDownDetails details, Size size) {
    if (!widget.gesturesEnabled || _animController.isAnimating) return;

    final pos = details.localPosition;
    _dragOrigin = pos;
    _dragCurrent = pos;

    // Corner detection: Top or Bottom 25% boundary
    final double cornerThreshold = size.height * 0.25;
    if (pos.dy <= cornerThreshold || pos.dy >= size.height - cornerThreshold) {
      _dragMode = CurlDragMode.cornerPull;
    } else {
      _dragMode = CurlDragMode.edgePull;
    }

    // Direction sign determination:
    // Touch on right half -> dragging left (R -> L, sigma = +1)
    // Touch on left half  -> dragging right (L -> R, sigma = -1)
    if (pos.dx >= size.width * 0.5) {
      _sigma = 1;
    } else {
      _sigma = -1;
    }

    // Boundary conditions
    if (_sigma == 1 && _currentPage >= widget.pageCount - 1) {
      _dragMode = CurlDragMode.none;
      return;
    }
    if (_sigma == -1 && _currentPage <= 0) {
      widget.onSwipeBeforeFirst?.call();
      _dragMode = CurlDragMode.none;
      return;
    }

    SoundService.onPageTouchDown();
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_dragMode == CurlDragMode.none || !widget.gesturesEnabled) return;
    
    // Calculate instantaneous velocity: v = delta_x / dt
    final double deltaX = (details.delta.dx).abs();
    final double normV = (deltaX / (size.width * 0.05)).clamp(0.0, 1.0);
    SoundService.onPageTouchMove(normV);

    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    // Exact Hand Lift: Silence page rustle immediately
    SoundService.onPageTouchUp();
    if (_dragMode == CurlDragMode.none || !widget.gesturesEnabled) return;

    final double totalW = size.width;
    final double displacement = (_dragCurrent.dx - _dragOrigin.dx);
    final double effectiveDragDist = (_sigma == 1) ? -displacement : displacement;
    final double velocity = details.velocity.pixelsPerSecond.dx;
    final double signedVelocity = (_sigma == 1) ? -velocity : velocity;

    // Turn threshold: > 26% width or snappy flick in flip direction
    final bool completeTurn = effectiveDragDist > totalW * 0.26 || signedVelocity > 400.0;
    final double startVal = (effectiveDragDist / totalW).clamp(0.0, 1.0);
    final double endVal = completeTurn ? 1.0 : 0.0;

    // Directional easing duration:
    // Forward (R->L): Fast dynamic flick (220-340ms)
    // Backward (L->R): Deliberate controlled sweep (260-380ms)
    final int baseDuration = (_sigma == 1) ? 310 : 360;
    _animController.duration = Duration(
      milliseconds: ((1.0 - startVal * 0.7) * baseDuration).clamp(180, 400).toInt(),
    );

    // Directional Easing curve:
    // Forward (R->L): easeOutCubic with snappy damping
    // Backward (L->R): smoothstep / easeInOutCubic (hand controlled)
    final Curve directionalCurve = (_sigma == 1) ? Curves.easeOutCubic : Curves.easeInOutCubic;
    final CurvedAnimation smoothAnim = CurvedAnimation(
      parent: _animController,
      curve: directionalCurve,
    );

    _animController.reset();
    final Animation<double> anim = Tween<double>(begin: startVal, end: endVal).animate(smoothAnim);

    double lastVal = startVal;
    anim.addListener(() {
      final double currentVal = anim.value;
      // Angular velocity |dTheta/dt|
      final double thetaDot = (currentVal - lastVal).abs() * 3.5;
      
      lastVal = currentVal;

      setState(() {
        final double dist = anim.value * totalW;
        if (_sigma == 1) {
          _dragCurrent = Offset(_dragOrigin.dx - dist, _dragCurrent.dy);
        } else {
          _dragCurrent = Offset(_dragOrigin.dx + dist, _dragCurrent.dy);
        }
      });
    });

    anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (completeTurn) {
          SoundService.triggerLandingThump(); // EXACT THETA = PI BURST
          setState(() {
            _currentPage = (_sigma == 1) ? _currentPage + 1 : _currentPage - 1;
            widget.onPageChanged?.call(_currentPage);
          });
        } else {
          
        }
        _dragMode = CurlDragMode.none;
        _animController.reset();
      }
    });

    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);

        final int activeIndex = _currentPage;
        final int underneathIndex = (_sigma == 1)
            ? (_currentPage + 1).clamp(0, widget.pageCount - 1)
            : (_currentPage - 1).clamp(0, widget.pageCount - 1);

        final bool isDragging = _dragMode != CurlDragMode.none;
        final double dragDist = (_dragCurrent.dx - _dragOrigin.dx).abs();
        final double curlProgress = isDragging ? (dragDist / size.width).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: (d) => _onPanStart(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: (d) => _onPanEnd(d, size),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // 1. Underneath destination page
              widget.builder(context, underneathIndex),

              // 2. Exact Directional Developable Curl Mesh
              if (isDragging)
                CustomPaint(
                  size: size,
                  painter: _DirectionalDevelopableCurlPainter(
                    dragOrigin: _dragOrigin,
                    dragCurrent: _dragCurrent,
                    mode: _dragMode,
                    sigma: _sigma,
                    currentPage: _currentPage,
                    totalPages: widget.pageCount,
                    paperColor: widget.paperColor,
                  ),
                ),

              // 3. Resting page
              if (!isDragging)
                widget.builder(context, activeIndex),

              // 4. Bookmark Sync Layer
              if (widget.bookmarkBuilder != null)
                widget.bookmarkBuilder!(curlProgress, isDragging),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================================
/// DIRECTIONAL DEVELOPABLE CURL PAINTER
/// Uses exact mathematical sign sigma = +-1:
/// theta(s, t) = sigma * Theta(t) * [1 - (1 - s/L)^2]
/// kappa(s, t) = sigma * (2*Theta(t)/L) * (1 - s/L)
/// Mirror transform Mx = diag(-1, 1, 1) for Left -> Right flips
/// Stack landing incline epsilon = arcsin(h / W)
/// ============================================================================
class _DirectionalDevelopableCurlPainter extends CustomPainter {
  final Offset dragOrigin;
  final Offset dragCurrent;
  final CurlDragMode mode;
  final int sigma; // +1: Forward (R->L), -1: Backward (L->R)
  final int currentPage;
  final int totalPages;
  final Color paperColor;

  _DirectionalDevelopableCurlPainter({
    required this.dragOrigin,
    required this.dragCurrent,
    required this.mode,
    required this.sigma,
    required this.currentPage,
    required this.totalPages,
    required this.paperColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double totalW = size.width;
    final double totalH = size.height;

    final double displacement = (dragCurrent.dx - dragOrigin.dx);
    final double effectiveDist = (sigma == 1) ? -displacement : displacement;
    final double rawProgress = (effectiveDist / totalW).clamp(0.001, 0.999);

    // Landing Stack Height angle epsilon = arcsin(stackHeight / bookWidth)
    final double leftStackHeight = (currentPage / totalPages) * 12.0; // mm equivalent
    final double rightStackHeight = ((totalPages - currentPage) / totalPages) * 12.0;
    final double epsilon = math.asin(((sigma == 1 ? leftStackHeight : rightStackHeight) / totalW).clamp(0.0, 0.15));

    // Directional Time-Theta Profile:
    // R->L (sigma = +1): Flick overshoot settling
    // L->R (sigma = -1): Smoothstep (3t^2 - 2t^3)
    final double thetaT;
    if (sigma == 1) {
      // theta(t) with damped landing settling
      thetaT = (math.pi + epsilon) * math.pow(math.sin(rawProgress * math.pi * 0.5), 1.85);
    } else {
      // theta(t) with controlled smoothstep
      thetaT = (math.pi + epsilon) * (rawProgress * rawProgress * (3.0 - 2.0 * rawProgress));
    }

    if (mode == CurlDragMode.edgePull) {
      _paintCylindricalEdge(canvas, size, rawProgress, thetaT);
    } else {
      _paintConicalCorner(canvas, size, rawProgress, thetaT);
    }
  }

  void _paintCylindricalEdge(Canvas canvas, Size size, double progress, double thetaT) {
    final double w = size.width;
    final double h = size.height;

    // kappa(s) = sigma * (2*Theta/L) * (1 - s/L)
    // Radius of curvature R at crease line
    final double baseR = (22.0 + 32.0 * (1.0 - progress)).clamp(14.0, 58.0);
    final double foldX = (sigma == 1) ? (w * (1.0 - progress)) : (w * progress);

    // Apply Mirror Transform Mx = diag(-1, 1, 1) when sigma == -1
    canvas.save();
    if (sigma == -1) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // Mirror-normalized fold coordinate (always acts as right-to-left in transformed frame)
    final double normFoldX = (sigma == 1) ? foldX : (w - foldX);

    // 1. Flat Base Sheet Boundary
    final Path flatSheet = Path()..addRect(Rect.fromLTWH(0, 0, normFoldX, h));

    // 2. Drop Shadow onto underneath sheet
    final double shadowWidth = baseR * 2.5;
    final Paint shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(normFoldX, 0),
        Offset(normFoldX + shadowWidth, 0),
        [
          Colors.black.withAlpha(165),
          Colors.black.withAlpha(65),
          Colors.transparent,
        ],
        const [0.0, 0.4, 1.0],
      );

    canvas.drawRect(Rect.fromLTWH(normFoldX, 0, shadowWidth, h), shadowPaint);

    // Draw Resting Flat Surface
    final Paint paperPaint = Paint()..color = paperColor;
    canvas.drawPath(flatSheet, paperPaint);

    // 3. Curled Boundary (Euler Spiral via Clamped BC tangents)
    final double rollSpan = (math.pi * baseR).clamp(12.0, w * 0.42);
    final Path spiralLip = Path();
    spiralLip.moveTo(normFoldX, 0);

    // Asymmetric cubic Bezier: P1 clamped at fold, P2 relaxed at zero-moment tip
    spiralLip.cubicTo(
      normFoldX + baseR * 0.70, h * 0.18,
      normFoldX + baseR * 0.40, h * 0.48,
      normFoldX, h * 0.5,
    );
    spiralLip.cubicTo(
      normFoldX - baseR * 0.22, h * 0.52,
      normFoldX + baseR * 0.62, h * 0.82,
      normFoldX, h,
    );
    spiralLip.lineTo(normFoldX - rollSpan * 0.52, h);
    spiralLip.lineTo(normFoldX - rollSpan * 0.52, 0);
    spiralLip.close();

    // Verso (back-side) Shading with Specular Crest
    final Paint surfaceShading = Paint()
      ..shader = ui.Gradient.linear(
        Offset(normFoldX - rollSpan * 0.6, 0),
        Offset(normFoldX + rollSpan * 0.6, 0),
        [
          paperColor.withAlpha(200),
          Colors.white.withAlpha(245),
          const Color(0xFFDDD2BC),
          const Color(0xFF8A7763),
        ],
        const [0.0, 0.32, 0.70, 1.0],
      );

    canvas.drawPath(spiralLip, surfaceShading);

    // Thin realistic edge border
    final Paint rimLine = Paint()
      ..color = Colors.black.withAlpha(32)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(spiralLip, rimLine);

    canvas.restore();
  }

  void _paintConicalCorner(Canvas canvas, Size size, double progress, double thetaT) {
    final double w = size.width;
    final double h = size.height;
    final bool isTopCorner = dragOrigin.dy < h * 0.5;

    canvas.save();
    if (sigma == -1) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    // Normalized frame coordinates
    final Offset normCorner = Offset(w, isTopCorner ? 0.0 : h);

    // Conical half-angle alpha(t) variation
    final double alpha = (math.pi / 9.0) + (math.pi / 3.4) * progress;
    final double sectorBeta = 2.0 * math.pi * math.sin(alpha);

    final double foldHypot = math.sqrt(w * w + h * h) * progress * (0.85 + 0.15 * (sectorBeta / (2.0 * math.pi)));
    final double thetaAspect = math.atan2(h, w);

    final double foldX = (foldHypot * math.cos(thetaAspect)).clamp(12.0, w);
    final double foldY = (foldHypot * math.sin(thetaAspect)).clamp(12.0, h);

    final Offset ptEdgeH = Offset(w - foldX, isTopCorner ? 0.0 : h);
    final Offset ptEdgeV = Offset(w, isTopCorner ? foldY : h - foldY);

    // Conical Drop Shadow
    final Path shadowArea = Path()
      ..moveTo(normCorner.dx, normCorner.dy)
      ..lineTo(ptEdgeH.dx, ptEdgeH.dy)
      ..lineTo(ptEdgeV.dx, ptEdgeV.dy)
      ..close();

    final Paint coneShadow = Paint()
      ..color = Colors.black.withAlpha(145)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
    canvas.drawPath(shadowArea, coneShadow);

    // Conical Peeling Flap
    final Path conicalFlap = Path()..moveTo(ptEdgeH.dx, ptEdgeH.dy);

    // Normalized drag destination
    final double normCurrentX = (sigma == 1) ? dragCurrent.dx : (w - dragCurrent.dx);
    final Offset normP3 = Offset(normCurrentX, dragCurrent.dy);

    final Offset p1 = Offset(
      ptEdgeH.dx + (normP3.dx - ptEdgeH.dx) * (0.32 + 0.08 * math.sin(alpha)),
      ptEdgeH.dy + (normP3.dy - ptEdgeH.dy) * 0.12,
    );
    final Offset p2 = Offset(
      normP3.dx - (normP3.dx - ptEdgeV.dx) * 0.22,
      normP3.dy - (normP3.dy - ptEdgeV.dy) * (0.38 + 0.12 * math.cos(alpha)),
    );

    conicalFlap.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, normP3.dx, normP3.dy);
    conicalFlap.lineTo(ptEdgeV.dx, ptEdgeV.dy);
    conicalFlap.close();

    // Verso surface lighting gradient
    final Paint flapShading = Paint()
      ..shader = ui.Gradient.linear(
        ptEdgeH,
        normP3,
        [
          const Color(0xFFDCD0BA),
          paperColor,
          Colors.white.withAlpha(235),
          const Color(0xFFC4B69E),
        ],
        const [0.0, 0.38, 0.72, 1.0],
      );

    canvas.drawPath(conicalFlap, flapShading);

    final Paint flapBorder = Paint()
      ..color = Colors.black.withAlpha(35)
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke;
    canvas.drawPath(conicalFlap, flapBorder);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DirectionalDevelopableCurlPainter old) {
    return old.dragCurrent != dragCurrent ||
        old.mode != mode ||
        old.sigma != sigma ||
        old.currentPage != currentPage;
  }
}
