import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:media_player/features/home/presentation/pages/navbar.dart';

import '../../../../core/widgets/responsive_builder.dart';
import '../../../audio_player/presentation/widgets/audio_mini_player.dart';
import '../../../playlist/domain/entities/media_item.dart';
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
  int        _index       = 0;
  MediaType? _libraryFilter; // null = show all

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
            ? _PhoneShell(index: _index)
            : _TabletShell(index: _index);
      },
    );
  }

  /// Called both by the bottom nav bar and by HomeTab's quick-action cards.
  void _onNav(int i, {MediaType? filter}) {
    setState(() {
      _index        = i;
      _libraryFilter = filter; // null when tapping nav directly
    });
  }

  Widget get _body {
    return switch (_index) {
      0 => HomeTab(
           onNavigateToTab: (tabIndex, {filter}) =>
               _onNav(tabIndex, filter: filter),
         ),
      1 => PlaylistPage(initialFilter: _libraryFilter),
      2 => const FavoritesTab(),
      3 => const SettingsTab(),
      _ => HomeTab(
           onNavigateToTab: (tabIndex, {filter}) =>
               _onNav(tabIndex, filter: filter),
         ),
    };
  }

  // ── Phone : bottom nav bar ────────────────────────────────

  Widget _PhoneShell({required int index}) {
    return Scaffold(
      extendBody: true, // lets content flow under translucent nav bar
      body: Stack(
        children: [
          Positioned.fill(child: _body),
          Positioned(
            left:   0,
            right:  0,
            bottom: kBottomNavigationBarHeight + 8,
            child:  const AudioMiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: AdvancedNavBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _onNav(i),
      ),
    );
  }




  // ── Tablet : side nav rail ────────────────────────────────

  Widget _TabletShell({required int index}) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => _onNav(i),
            labelType: NavigationRailLabelType.all,
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
