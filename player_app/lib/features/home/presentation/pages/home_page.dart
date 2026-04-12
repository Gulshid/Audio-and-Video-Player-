// ignore_for_file: unnecessary_underscores

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
  int        _index         = 0;
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

  // FIX #4: _body is now a method that receives the current index and filter
  // explicitly instead of relying on the getter closing over mutable state.
  Widget _buildBody(int index, MediaType? filter) {
    return switch (index) {
      0 => HomeTab(
           onNavigateToTab: (tabIndex, {filter}) =>
               _onNav(tabIndex, filter: filter),
         ),
      1 => PlaylistPage(initialFilter: filter),
      2 => const FavoritesTab(),
      3 => const SettingsTab(),
      _ => HomeTab(
           onNavigateToTab: (tabIndex, {filter}) =>
               _onNav(tabIndex, filter: filter),
         ),
    };
  }

  /// Called by the bottom nav bar AND by HomeTab's quick-action cards.
  void _onNav(int i, {MediaType? filter}) {
    setState(() {
      _index         = i;
      _libraryFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, device) {
        final body = _buildBody(_index, _libraryFilter);
        return device == DeviceType.phone
            ? _PhoneShell(
                index:   _index,
                body:    body,
                onNav:   _onNav,
              )
            : _TabletShell(
                index:       _index,
                body:        body,
                destinations: _destinations,
                onNav:       _onNav,
              );
      },
    );
  }
}

// ── Phone shell ───────────────────────────────────────────────
// FIX #1: AudioMiniPlayer is rendered ONLY here (and in _TabletShell).
// FIX #2: Mini player is positioned above the nav bar using a Column
//         with intrinsic sizing, respecting SafeArea insets properly.

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({
    required this.index,
    required this.body,
    required this.onNav,
  });

  final int                                         index;
  final Widget                                      body;
  final void Function(int, {MediaType? filter})     onNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX #2: extendBody lets content scroll behind the translucent nav bar
      // but we no longer rely on it for mini player placement.
      extendBody: false,
      body: body,
      // FIX #1 & #2: Mini player sits between the body and the nav bar
      // inside the Scaffold's bottomNavigationBar slot using a Column.
      // This approach respects SafeArea automatically and cannot overlap.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX: AudioMiniPlayer handles its own BlocBuilder + visibility
          // internally. Wrapping it in another BlocBuilder caused double
          // rebuilds on every position tick.
          const AudioMiniPlayer(),
          // Bottom nav bar.
          AdvancedNavBar(
            selectedIndex:        index,
            onDestinationSelected: (i) => onNav(i),
          ),
        ],
      ),
    );
  }
}

// ── Tablet shell ──────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.index,
    required this.body,
    required this.destinations,
    required this.onNav,
  });

  final int                                          index;
  final Widget                                       body;
  final List<NavigationDestination>                  destinations;
  final void Function(int, {MediaType? filter})      onNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex:         index,
            onDestinationSelected: (i) => onNav(i),
            labelType:             NavigationRailLabelType.all,
            destinations: destinations
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
                Expanded(child: body),
                // FIX: AudioMiniPlayer manages its own visibility internally.
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
