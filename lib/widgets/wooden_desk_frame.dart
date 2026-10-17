import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

enum ActiveTool { none, pen, pencil, highlighter, eraser }

class WoodenDeskFrame extends StatefulWidget {
  final ActiveTool activeTool;
  final ValueChanged<ActiveTool> onToolSelected;
  final VoidCallback onMenuTap;
  final Color highlightColor;
  final Color penColor;
  final Color ribbonColor;
  final bool isBookmarked;
  final bool hasBookmarks;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onJumpToBookmark;
  final VoidCallback? onAddNoteTap;
  final VoidCallback? onBookmarkColorTap;
  final VoidCallback? onHighlighterColorTap;
  final VoidCallback? onPenColorTap;
  final double penWidth;
  final double highlighterWidth;
  final ValueChanged<double>? onPenWidthChanged;
  final ValueChanged<double>? onHighlighterWidthChanged;
  final int currentPage;
  final int totalPages;
  final Widget child;

  const WoodenDeskFrame({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    required this.onMenuTap,
    required this.highlightColor,
    required this.penColor,
    required this.ribbonColor,
    required this.isBookmarked,
    this.hasBookmarks = false,
    required this.onBookmarkTap,
    this.onJumpToBookmark,
    this.onAddNoteTap,
    this.onBookmarkColorTap,
    this.onHighlighterColorTap,
    this.onPenColorTap,
    this.penWidth = 2.0,
    this.highlighterWidth = 12.0,
    this.onPenWidthChanged,
    this.onHighlighterWidthChanged,
    required this.currentPage,
    required this.totalPages,
    required this.child,
  });

  @override
  State<WoodenDeskFrame> createState() => _WoodenDeskFrameState();
}

class _WoodenDeskFrameState extends State<WoodenDeskFrame>
    with TickerProviderStateMixin {
  final GlobalKey _bookKey = GlobalKey();
  bool _isMenuExpanded = true;
  ActiveTool? _expandedSubTool;

  late AnimationController _menuController;
  late Animation<double> _menuAnimation;

  late AnimationController _subPetalController;
  late Animation<double> _subPetalAnimation;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
    );
    if (_isMenuExpanded) {
      _menuController.value = 1.0;
    }

    _subPetalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _subPetalAnimation = CurvedAnimation(
      parent: _subPetalController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    _subPetalController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    SoundService.triggerWoodKnock();
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
      if (_isMenuExpanded) {
        _menuController.forward();
      } else {
        _menuController.reverse();
        _expandedSubTool = null;
        _subPetalController.reverse();
      }
    });
  }

  void _toggleSubPetal(ActiveTool tool) {
    SoundService.triggerWoodKnock();
    setState(() {
      if (_expandedSubTool == tool) {
        _expandedSubTool = null;
        _subPetalController.reverse();
      } else {
        _expandedSubTool = tool;
        _subPetalController.forward(from: 0.0);
      }
    });
  }

  void _handleDeskPointerDown(PointerDownEvent event) {
    // 1. Check if tap is inside bottom radial menu area
    final screenH = MediaQuery.of(context).size.height;
    if (event.position.dy > screenH - 190) {
      return; // Handled by bottom menu petals
    }

    // 2. Check if tap is inside Book bounding box
    final renderBox = _bookKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final bookTopLeft = renderBox.localToGlobal(Offset.zero);
      final bookRect = bookTopLeft & renderBox.size;

      if (bookRect.contains(event.position)) {
        return; // Tap is INSIDE the book -> NEVER play wood sound!
      }
    }

    // 3. Tap is STRICTLY ON THE WOODEN DESK
    SoundService.triggerWoodKnock();
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isSelected = false,
    bool isEnabled = true,
    Color? iconColor,
    Color? activeBorderColor,
    String? tooltip,
    double size = 44.0,
    Widget? customChild,
  }) {
    final Color bgColor = !isEnabled
        ? const Color(0xFF1E1108).withAlpha(190)
        : isSelected
            ? const Color(0xFFE5A93C)
            : const Color(0xFF3E1F0C);

    final Color effectiveIconColor = !isEnabled
        ? Colors.white24
        : isSelected
            ? const Color(0xFF220E03)
            : (iconColor ?? const Color(0xFFFFE0B2));

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: !isEnabled
                  ? Colors.white12
                  : isSelected
                      ? Colors.white
                      : (activeBorderColor ?? const Color(0xFFD4AF37)),
              width: 1.6,
            ),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: isSelected
                      ? const Color(0x66E5A93C)
                      : const Color(0x66000000),
                  blurRadius: isSelected ? 8 : 5,
                  offset: const Offset(1.5, 2.5),
                ),
            ],
          ),
          child: Center(
            child: customChild ??
                Icon(icon, color: effectiveIconColor, size: size * 0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowerPetal({
    required double angleInDegrees,
    required double distance,
    required Widget child,
  }) {
    final double rad = angleInDegrees * (math.pi / 180.0);
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, _) {
        final double currentDist = distance * _menuAnimation.value;
        final double x = currentDist * math.cos(rad);
        final double y = -currentDist * math.sin(rad);

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _menuAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildRadialSubPetal({
    required double parentAngleInDegrees,
    required double parentDistance,
    required double subAngleInDegrees,
    required double subDistance,
    required Widget child,
  }) {
    final double parentRad = parentAngleInDegrees * (math.pi / 180.0);
    final double subRad = subAngleInDegrees * (math.pi / 180.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_menuAnimation, _subPetalAnimation]),
      builder: (context, _) {
        final double parentX =
            parentDistance * _menuAnimation.value * math.cos(parentRad);
        final double parentY =
            -parentDistance * _menuAnimation.value * math.sin(parentRad);

        final double subDist = subDistance * _subPetalAnimation.value;
        final double subX = subDist * math.cos(subRad);
        final double subY = -subDist * math.sin(subRad);

        return Transform.translate(
          offset: Offset(parentX + subX, parentY + subY),
          child: Opacity(
            opacity: _subPetalAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 126.0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleDeskPointerDown,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wood_table_texture.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Book Container wrapped with Key for strict boundary hit-testing
            KeyedSubtree(
              key: _bookKey,
              child: widget.child,
            ),

            // Bottom Toolbar Menu
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 340,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // LEFT 3 OPTIONS:
                      // 1. Desk Settings (165°)
                      _buildFlowerPetal(
                        angleInDegrees: 165,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.table_restaurant_outlined,
                          tooltip: "Desk Settings",
                          onTap: () {
                            SoundService.triggerWoodKnock();
                            widget.onMenuTap();
                          },
                        ),
                      ),

                      // 2. Pen (140°)
                      _buildFlowerPetal(
                        angleInDegrees: 140,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.edit,
                          tooltip: "Pen",
                          isSelected: widget.activeTool == ActiveTool.pen,
                          onTap: () {
                            widget.onToolSelected(
                              widget.activeTool == ActiveTool.pen
                                  ? ActiveTool.none
                                  : ActiveTool.pen,
                            );
                            _toggleSubPetal(ActiveTool.pen);
                          },
                        ),
                      ),

                      // Pen Sub-Petals (Fine & Thick)
                      if (_expandedSubTool == ActiveTool.pen) ...[
                        _buildRadialSubPetal(
                          parentAngleInDegrees: 140,
                          parentDistance: radius,
                          subAngleInDegrees: 160,
                          subDistance: 50,
                          child: _buildCircleButton(
                            icon: Icons.circle,
                            tooltip: "Fine",
                            size: 34,
                            customChild: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            onTap: () {
                              SoundService.triggerWoodKnock();
                              widget.onPenWidthChanged?.call(1.5);
                            },
                          ),
                        ),
                        _buildRadialSubPetal(
                          parentAngleInDegrees: 140,
                          parentDistance: radius,
                          subAngleInDegrees: 120,
                          subDistance: 50,
                          child: _buildCircleButton(
                            icon: Icons.circle,
                            tooltip: "Thick",
                            size: 34,
                            customChild: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            onTap: () {
                              SoundService.triggerWoodKnock();
                              widget.onPenWidthChanged?.call(3.5);
                            },
                          ),
                        ),
                      ],

                      // 3. Highlighter (115°)
                      _buildFlowerPetal(
                        angleInDegrees: 115,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.brush,
                          tooltip: "Highlighter",
                          isSelected: widget.activeTool == ActiveTool.highlighter,
                          onTap: () {
                            widget.onToolSelected(
                              widget.activeTool == ActiveTool.highlighter
                                  ? ActiveTool.none
                                  : ActiveTool.highlighter,
                            );
                            _toggleSubPetal(ActiveTool.highlighter);
                          },
                        ),
                      ),

                      // TOP CENTER:
                      // 4. Bookmark (90°)
                      _buildFlowerPetal(
                        angleInDegrees: 90,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: widget.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          tooltip: widget.isBookmarked
                              ? "Remove Bookmark"
                              : "Bookmark Page",
                          isSelected: widget.isBookmarked,
                          iconColor: widget.ribbonColor,
                          onTap: () {
                            SoundService.triggerWoodKnock();
                            widget.onBookmarkTap();
                          },
                        ),
                      ),

                      // RIGHT 3 OPTIONS:
                      // 5. Page Note (65°)
                      _buildFlowerPetal(
                        angleInDegrees: 65,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.note_alt_outlined,
                          tooltip: "Page Note",
                          iconColor: const Color(0xFFFFD54F),
                          onTap: () {
                            SoundService.triggerWoodKnock();
                            widget.onAddNoteTap?.call();
                          },
                        ),
                      ),

                      // 6. Eraser (40°)
                      _buildFlowerPetal(
                        angleInDegrees: 40,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.auto_fix_normal,
                          tooltip: "Eraser",
                          isSelected: widget.activeTool == ActiveTool.eraser,
                          iconColor: const Color(0xFFFFCC80),
                          onTap: () {
                            SoundService.triggerWoodKnock();
                            widget.onToolSelected(
                              widget.activeTool == ActiveTool.eraser
                                  ? ActiveTool.none
                                  : ActiveTool.eraser,
                            );
                          },
                        ),
                      ),

                      // 7. Open at Bookmark (15°)
                      _buildFlowerPetal(
                        angleInDegrees: 15,
                        distance: radius,
                        child: _buildCircleButton(
                          icon: Icons.auto_stories,
                          tooltip: widget.hasBookmarks
                            ? "Open at Bookmarked Page"
                            : "No Bookmark Set",
                          isEnabled: widget.hasBookmarks,
                          isSelected: widget.hasBookmarks,
                          iconColor: widget.hasBookmarks
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                          activeBorderColor: widget.hasBookmarks
                              ? const Color(0xFFFFD700)
                              : null,
                          onTap: widget.hasBookmarks
                              ? () {
                                  SoundService.triggerWoodKnock();
                                  widget.onJumpToBookmark?.call();
                                }
                              : null,
                        ),
                      ),

                      // Central Menu Button (+)
                      GestureDetector(
                        onTap: _toggleMenu,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF381A08),
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                              width: 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: AnimatedRotation(
                            turns: _isMenuExpanded ? 0.125 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFFFFD54F),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
