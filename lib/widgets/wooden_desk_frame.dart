import 'package:flutter/material.dart';

import '../services/sound_service.dart';

enum ActiveTool { none, pen, pencil, highlighter, eraser }

class WoodenDeskFrame extends StatelessWidget {
  final Widget child;
  final ActiveTool activeTool;
  final Color highlightColor;
  final Color penColor;
  final Color ribbonColor;
  final ValueChanged<ActiveTool> onToolSelected;
  final VoidCallback onHighlighterColorTap;
  final VoidCallback onPenColorTap;
  final VoidCallback onBookmarkColorTap;
  final VoidCallback onAddNoteTap;
  final VoidCallback onMenuTap;
  final VoidCallback onBookmarkTap;
  final bool isBookmarked;
  final int currentPage;
  final int totalPages;

  const WoodenDeskFrame({
    super.key,
    required this.child,
    required this.activeTool,
    required this.highlightColor,
    required this.penColor,
    required this.ribbonColor,
    required this.onToolSelected,
    required this.onHighlighterColorTap,
    required this.onPenColorTap,
    required this.onBookmarkColorTap,
    required this.onAddNoteTap,
    required this.onMenuTap,
    required this.onBookmarkTap,
    required this.isBookmarked,
    required this.currentPage,
    required this.totalPages,
  });

  static const Color lightBrown = Color(0xFFD7A878);
  static const Color lightBrownSelected = Color(0xFFFFD59E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/wood_texture.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            final totalW = constraints.maxWidth;

            final topDeskH = totalH * 0.17;
            final bookH = totalH * 0.66;
            final bottomDeskH = totalH * 0.17;
            final sideMargin = totalW * 0.055;

            final progress =
                totalPages > 0 ? (totalPages - currentPage) / totalPages : 0.5;
            final stackThickness = (progress * 5.0).clamp(2.5, 5.0);

            return Column(
              children: [
                // 1. TOP WOODEN TABLE TOOLS (WOOD TAP SOUND ONLY ON TABLE AREA)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: SoundService.playWoodTap,
                  child: SizedBox(
                    height: topDeskH,
                    width: totalW,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildMenuBtn(),
                          _buildRestingTool(
                            tool: ActiveTool.pen,
                            name: "Pen",
                            icon: const Icon(
                              Icons.edit,
                              color: lightBrown,
                              size: 23,
                            ),
                            badgeColor: penColor,
                            onBadgeTap: onPenColorTap,
                          ),
                          _buildRestingTool(
                            tool: ActiveTool.pencil,
                            name: "Pencil",
                            icon: const Icon(
                              Icons.create,
                              color: lightBrown,
                              size: 23,
                            ),
                          ),
                          _buildRestingTool(
                            tool: ActiveTool.highlighter,
                            name: "Highlighter",
                            icon: const Icon(
                              Icons.brush,
                              color: lightBrown,
                              size: 23,
                            ),
                            badgeColor: highlightColor,
                            onBadgeTap: onHighlighterColorTap,
                          ),
                          _buildRestingTool(
                            tool: ActiveTool.eraser,
                            name: "Eraser",
                            icon: const Icon(
                              Icons.auto_fix_normal,
                              color: lightBrown,
                              size: 23,
                            ),
                          ),
                          _buildBookmarkSection(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. BOOK CONTAINER (100% SILENT ON TOUCH, NO WOOD TAP SOUND)
                SizedBox(
                  height: bookH,
                  width: totalW,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xCC000000),
                            blurRadius: 24,
                            spreadRadius: 3,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFFEADBCE),
                            offset: Offset(
                              stackThickness,
                              stackThickness * 0.5,
                            ),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFC7B198),
                            offset: Offset(
                              stackThickness + 1.0,
                              stackThickness * 0.5 + 0.8,
                            ),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFF4A2C18),
                            offset: Offset(
                              stackThickness + 2.0,
                              stackThickness * 0.5 + 1.5,
                            ),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0x66000000),
                            offset: Offset(
                              stackThickness + 5,
                              stackThickness * 0.5 + 7,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.none,
                      child: child,
                    ),
                  ),
                ),

                // 3. BOTTOM VISIBLE WOODEN TABLE (WOOD TAP SOUND HERE)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: SoundService.playWoodTap,
                  child: SizedBox(
                    height: bottomDeskH,
                    width: totalW,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x770A0402), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRestingTool({
    required ActiveTool tool,
    required String name,
    required Widget icon,
    Color? badgeColor,
    VoidCallback? onBadgeTap,
  }) {
    final bool isLifted = activeTool == tool;
    final double scale = isLifted ? 1.15 : 1.0;
    final double dy = isLifted ? -9.0 : 0.0;

    return GestureDetector(
      onTap: () => onToolSelected(isLifted ? ActiveTool.none : tool),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            transform: Matrix4.diagonal3Values(scale, scale, 1.0)
              ..setTranslationRaw(0.0, dy, 0.0),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color:
                  isLifted ? const Color(0x66000000) : const Color(0x38000000),
              border: Border.all(
                color: isLifted ? lightBrownSelected : lightBrown,
                width: 1.4,
              ),
              boxShadow: isLifted
                  ? const [
                      BoxShadow(
                        color: Color(0xDD000000),
                        blurRadius: 14,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 3,
                        offset: Offset(0, 1.5),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                // ENLARGED EASY-TO-CLICK COLOR WHEEL TRIGGER BADGE
                if (badgeColor != null)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBadgeTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.transparent, width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x88000000),
                                blurRadius: 4,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'serif',
              fontWeight: isLifted ? FontWeight.w900 : FontWeight.w700,
              color: isLifted ? lightBrownSelected : lightBrown,
              shadows: const [
                Shadow(
                  color: Color(0xDD000000),
                  offset: Offset(0, 1.2),
                  blurRadius: 2.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn() {
    return GestureDetector(
      onTap: onMenuTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0x38000000),
          border: Border.all(color: lightBrown, width: 1.4),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: lightBrown, size: 21),
            SizedBox(height: 2),
            Text(
              "Desk",
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                color: lightBrown,
                shadows: [
                  Shadow(
                    color: Color(0xDD000000),
                    offset: Offset(0, 1.2),
                    blurRadius: 2.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onBookmarkTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isBookmarked
                      ? const Color(0x66000000)
                      : const Color(0x38000000),
                  border: Border.all(
                    color: isBookmarked ? lightBrownSelected : lightBrown,
                    width: 1.4,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.redAccent : lightBrown,
                      size: 21,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Mark",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'serif',
                        fontWeight:
                            isBookmarked ? FontWeight.w900 : FontWeight.w700,
                        color: isBookmarked ? lightBrownSelected : lightBrown,
                        shadows: const [
                          Shadow(
                            color: Color(0xDD000000),
                            offset: Offset(0, 1.2),
                            blurRadius: 2.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ENLARGED EASY-TO-CLICK BOOKMARK COLOR WHEEL TRIGGER
            Positioned(
              right: -10,
              top: -10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBookmarkColorTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ribbonColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.transparent, width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88000000),
                          blurRadius: 4,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isBookmarked) ...[
          const SizedBox(height: 3),
          GestureDetector(
            onTap: onAddNoteTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xAA2B1408),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: lightBrown, width: 0.9),
              ),
              child: const Text(
                "Add Note",
                style: TextStyle(
                  fontSize: 8.5,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  color: lightBrownSelected,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
