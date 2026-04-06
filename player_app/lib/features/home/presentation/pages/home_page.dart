import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;

import '../../../../core/widgets/responsive_builder.dart';
import '../../../audio_player/presentation/widgets/audio_mini_player.dart';
import '../../../playlist/presentation/pages/playlist_page.dart';
import '_favorites_tab.dart';
import '_home_tab.dart';
import '_settings_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon:         Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label:        'Home',
    ),
    NavigationDestination(
      icon:         Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label:        'Library',
    ),
    NavigationDestination(
      icon:         Icon(Icons.favorite_border_rounded),
      selectedIcon: Icon(Icons.favorite_rounded),
      label:        'Favorites',
    ),
    NavigationDestination(
      icon:         Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label:        'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, device) {
        return device == DeviceType.phone
            ? _PhoneShell(index: _index, onNav: _onNav)
            : _TabletShell(index: _index, onNav: _onNav);
      },
    );
  }

  void _onNav(int i) => setState(() => _index = i);

  Widget get _body {
    return switch (_index) {
      0 => const HomeTab(),
      1 => const PlaylistPage(),
      2 => const FavoritesTab(),
      3 => const SettingsTab(),
      _ => const HomeTab(),
    };
  }

  // ── Phone : bottom nav bar ────────────────────────────────

  Widget _PhoneShell({required int index, required ValueChanged<int> onNav}) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content — padded so mini player never covers it
          Positioned.fill(child: _body),

          // Mini player floats above bottom nav
          const Positioned(
            left:   0,
            right:  0,
            bottom: kBottomNavigationBarHeight + 8,
            child:  AudioMiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onNav,
        destinations: _destinations,
        height: kBottomNavigationBarHeight.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  // ── Tablet : side nav rail ────────────────────────────────

  Widget _TabletShell({required int index, required ValueChanged<int> onNav}) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex:    index,
            onDestinationSelected: onNav,
            labelType:        NavigationRailLabelType.all,
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon:         d.icon,
                      selectedIcon: d.selectedIcon,
                      label:        Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _body),
                const AudioMiniPlayer(),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
