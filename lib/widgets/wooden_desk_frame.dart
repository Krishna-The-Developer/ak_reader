import "package:flutter/material.dart";
import "../services/sound_service.dart";

enum ActiveTool { none, pen, pencil, highlighter, eraser }

class WoodenDeskFrame extends StatelessWidget {
  final ActiveTool activeTool;
  final ValueChanged<ActiveTool> onToolSelected;
  final VoidCallback onMenuTap;
  final Color highlightColor;
  final Color penColor;
  final Color ribbonColor;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onBookmarkColorTap;
  final VoidCallback? onAddNoteTap;
  final VoidCallback? onHighlighterColorTap;
  final VoidCallback? onPenColorTap;
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
    required this.onBookmarkTap,
    this.onBookmarkColorTap,
    this.onAddNoteTap,
    this.onHighlighterColorTap,
    this.onPenColorTap,
    required this.currentPage,
    required this.totalPages,
    required this.child,
  });

  Widget _buildVerticalToolbarButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? indicatorColor,
    VoidCallback? onIndicatorTap,
  }) {
    const Color goldText = Color(0xFFFFD59E);
    const Color activeGold = Color(0xFFFFE082);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundService.playWoodTap();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xEE441E0A) : const Color(0x99241006),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeGold : const Color(0x55C5A059),
              width: isActive ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? activeGold : goldText,
                  ),
                  if (indicatorColor != null)
                    Positioned(
                      top: -2,
                      right: -5,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          SoundService.playWoodTap();
                          onIndicatorTap?.call();
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 0.9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeGold : goldText,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontFamily: "serif",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAndNoteSlot() {
    const Color goldText = Color(0xFFFFD59E);
    const Color activeGold = Color(0xFFFFE082);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: isBookmarked ? const Color(0xEE441E0A) : const Color(0x99241006),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBookmarked ? activeGold : const Color(0x55C5A059),
            width: isBookmarked ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top: Bookmark (Mark)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SoundService.playWoodTap();
                onBookmarkTap();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 13,
                    color: isBookmarked ? activeGold : goldText,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "Mark",
                    style: TextStyle(
                      color: isBookmarked ? activeGold : goldText,
                      fontSize: 9.5,
                      fontWeight: isBookmarked ? FontWeight.bold : FontWeight.w600,
                      fontFamily: "serif",
                    ),
                  ),
                  if (isBookmarked) ...[
                    const SizedBox(width: 3),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        SoundService.playWoodTap();
                        onBookmarkColorTap?.call();
                      },
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ribbonColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 1),
            Container(height: 0.5, color: const Color(0x44C5A059)),
            const SizedBox(height: 1),
            // Bottom: Dedicated Note Button below Mark
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SoundService.playWoodTap();
                onAddNoteTap?.call();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 13,
                    color: goldText,
                  ),
                  SizedBox(width: 2),
                  Text(
                    "Note",
                    style: TextStyle(
                      color: goldText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: "serif",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xF2160903),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x88C5A059),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xBB000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVerticalToolbarButton(
            icon: Icons.table_restaurant,
            label: "Desk",
            isActive: false,
            onTap: onMenuTap,
          ),
          _buildVerticalToolbarButton(
            icon: Icons.edit,
            label: "Pen",
            isActive: activeTool == ActiveTool.pen,
            indicatorColor: penColor,
            onIndicatorTap: onPenColorTap,
            onTap: () {
              if (activeTool == ActiveTool.pen) {
                onPenColorTap?.call();
              } else {
                onToolSelected(ActiveTool.pen);
              }
            },
          ),
          _buildVerticalToolbarButton(
            icon: Icons.create,
            label: "Pencil",
            isActive: activeTool == ActiveTool.pencil,
            onTap: () {
              onToolSelected(
                activeTool == ActiveTool.pencil
                    ? ActiveTool.none
                    : ActiveTool.pencil,
              );
            },
          ),
          _buildVerticalToolbarButton(
            icon: Icons.brush,
            label: "Highlight",
            isActive: activeTool == ActiveTool.highlighter,
            indicatorColor: highlightColor,
            onIndicatorTap: onHighlighterColorTap,
            onTap: () {
              if (activeTool == ActiveTool.highlighter) {
                onHighlighterColorTap?.call();
              } else {
                onToolSelected(ActiveTool.highlighter);
              }
            },
          ),
          _buildVerticalToolbarButton(
            icon: Icons.auto_fix_normal,
            label: "Eraser",
            isActive: activeTool == ActiveTool.eraser,
            onTap: () {
              onToolSelected(
                activeTool == ActiveTool.eraser
                    ? ActiveTool.none
                    : ActiveTool.eraser,
              );
            },
          ),
          _buildMarkAndNoteSlot(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Dark Walnut Base
        Positioned.fill(
          child: Container(
            color: const Color(0xFF1E0E05),
          ),
        ),

        // 2. High-Res Wood Table Texture (WOOD SOUND ONLY ON DESK TABLE)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: SoundService.playWoodTap,
            child: Image.asset(
              "assets/images/wood_table_texture.jpg",
              fit: BoxFit.cover,
              cacheWidth: 1080,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),

        // 3. Desk Ambient Vignette
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.25,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Centered Book Area (NO WOOD TAP SOUND ON BOOK)
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
            child: Center(
              child: child,
            ),
          ),
        ),

        // 5. Top Floating Toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildTopToolbar(),
          ),
        ),
      ],
    );
  }
}
