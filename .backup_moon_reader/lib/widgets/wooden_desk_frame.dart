import 'package:flutter/material.dart';

enum ActiveTool { none, pen, pencil, highlighter, eraser }

class WoodenDeskFrame extends StatelessWidget {
  final Widget child;
  final ActiveTool activeTool;
  final Color highlightColor;
  final ValueChanged<ActiveTool> onToolSelected;
  final VoidCallback onColorPickerTap;
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
    required this.onToolSelected,
    required this.onColorPickerTap,
    required this.onMenuTap,
    required this.onBookmarkTap,
    required this.isBookmarked,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C180E), // Rich Walnut Tabletop
            Color(0xFF1D0E07),
            Color(0xFF120703),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            final totalW = constraints.maxWidth;

            // Strict Dynamic Ratios
            final topDeskH = totalH * 0.15; // 15% Top Desk Toolbar
            final bookH = totalH * 0.70; // 70% Physical Book Viewport
            final bottomDeskH = totalH * 0.15; // 15% Bottom Desk Surface
            final sideMargin = totalW * 0.045; // 4.5% Lateral Desk Space

            // Remaining thickness ratio (Book page stack depth)
            final progressRemaining =
                totalPages > 0 ? (totalPages - currentPage) / totalPages : 0.5;
            final stackDepth = (progressRemaining * 6.0).clamp(1.5, 6.0);

            return Column(
              children: [
                // 1. TOP 15% WOODEN DESK & CARVED TOOLBAR
                SizedBox(
                  height: topDeskH,
                  width: totalW,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: totalW * 0.03, vertical: topDeskH * 0.12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0x1FFFFFFF), width: 0.8),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCarvedBtn(
                              icon: Icons.menu,
                              label: "Desk Menu",
                              isSelected: false,
                              onTap: onMenuTap,
                            ),
                            const SizedBox(width: 12),
                            _buildCarvedBtn(
                              icon: Icons.edit,
                              label: "Pen",
                              isSelected: activeTool == ActiveTool.pen,
                              onTap: () => onToolSelected(
                                  activeTool == ActiveTool.pen
                                      ? ActiveTool.none
                                      : ActiveTool.pen),
                            ),
                            const SizedBox(width: 10),
                            _buildCarvedBtn(
                              icon: Icons.create_outlined,
                              label: "Pencil",
                              isSelected: activeTool == ActiveTool.pencil,
                              onTap: () => onToolSelected(
                                  activeTool == ActiveTool.pencil
                                      ? ActiveTool.none
                                      : ActiveTool.pencil),
                            ),
                            const SizedBox(width: 10),
                            _buildCarvedBtn(
                              icon: Icons.brush,
                              label: "Highlighter",
                              isSelected: activeTool == ActiveTool.highlighter,
                              onTap: () => onToolSelected(
                                  activeTool == ActiveTool.highlighter
                                      ? ActiveTool.none
                                      : ActiveTool.highlighter),
                            ),
                            const SizedBox(width: 4),
                            // Quick Color Wheel Dot
                            GestureDetector(
                              onTap: onColorPickerTap,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: highlightColor,
                                  border: Border.all(
                                      color: const Color(0xFFD7A15C),
                                      width: 1.8),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 4,
                                        offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildCarvedBtn(
                              icon: Icons.auto_fix_normal,
                              label: "Eraser",
                              isSelected: activeTool == ActiveTool.eraser,
                              onTap: () => onToolSelected(
                                  activeTool == ActiveTool.eraser
                                      ? ActiveTool.none
                                      : ActiveTool.eraser),
                            ),
                            const SizedBox(width: 10),
                            _buildCarvedBtn(
                              icon: isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              label: "Bookmark",
                              isSelected: isBookmarked,
                              onTap: onBookmarkTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. MIDDLE 70% PHYSICAL BOOK (WITH TACTILE PAGE-STACK DEPTH)
                SizedBox(
                  height: bookH,
                  width: totalW,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          // Primary tabletop cast shadow
                          const BoxShadow(
                            color: Color(0xCC000000),
                            blurRadius: 22,
                            spreadRadius: 3,
                            offset: Offset(0, 12),
                          ),
                          // Lateral book stack depth simulation
                          BoxShadow(
                            color: const Color(0xFFDCD3C0),
                            offset: Offset(stackDepth, 2),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0x80000000),
                            offset: Offset(stackDepth + 2, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: child,
                      ),
                    ),
                  ),
                ),

                // 3. BOTTOM 15% VISIBLE DESK SURFACE
                SizedBox(
                  height: bottomDeskH,
                  width: totalW,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(
                              0x80080301), // Shadow cast from bottom book edge
                          Colors.transparent,
                        ],
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

  Widget _buildCarvedBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: isSelected ? const Color(0x55000000) : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: const Color(0xFFD4A373).withAlpha(160), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFFFFE0B2)
                  : const Color(0xFFCCA277),
              shadows: const [
                Shadow(
                    color: Colors.black, offset: Offset(0, -1), blurRadius: 1),
                Shadow(
                    color: Color(0x33FFDEAD),
                    offset: Offset(0, 1),
                    blurRadius: 1),
              ],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'serif',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFFFE5C4)
                    : const Color(0xFFBA8C5E),
                shadows: const [
                  Shadow(
                      color: Colors.black,
                      offset: Offset(0, -1),
                      blurRadius: 1),
                  Shadow(
                      color: Color(0x33FFDEAD),
                      offset: Offset(0, 1),
                      blurRadius: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
