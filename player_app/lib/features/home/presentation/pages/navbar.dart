import 'package:flutter/material.dart';

class AdvancedNavBar extends StatelessWidget {
  const AdvancedNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,             label: 'Home'),
    _NavItem(icon: Icons.library_music_outlined, activeIcon: Icons.library_music_rounded,    label: 'Library'),
    _NavItem(icon: Icons.favorite_border_rounded,activeIcon: Icons.favorite_rounded,          label: 'Favorites'),
    _NavItem(icon: Icons.settings_outlined,      activeIcon: Icons.settings_rounded,          label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final surface = scheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = i == selectedIndex;
              return _NavButton(
                item:     item,
                selected: selected,
                onTap:    () => onDestinationSelected(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Single nav button ─────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme     = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Pill indicator + icon ─────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width:  40,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size:  20,
                    color: selected ? activeColor : scheme.onSurfaceVariant,
                  ),
                  if (item.badge)
                    Positioned(
                      top:   3,
                      right: 4,
                      child: Container(
                        width:  7,
                        height: 7,
                        decoration: BoxDecoration(
                          color:        scheme.error,
                          shape:        BoxShape.circle,
                          border: Border.all(
                            color: scheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            // ── Label ─────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize:   10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color:      selected ? activeColor : scheme.onSurfaceVariant,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    // ignore: unused_element_parameter
    this.badge = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final bool     badge;
}