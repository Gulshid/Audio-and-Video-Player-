import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../playlist/bloc/playlist_bloc.dart';
import '../../../playlist/bloc/playlist_event.dart';

// FIX #8: Removed unused `scheme` variable and its suppress comment.

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          // ── Appearance ─────────────────────────────────
          _SectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, mode) {
                    return ListTile(
                      leading: const Icon(Icons.brightness_6_rounded),
                      title:   const Text('Theme'),
                      trailing: SegmentedButton<ThemeMode>(
                        selected:   {mode},
                        onSelectionChanged: (s) =>
                            themeCubit.setTheme(s.first),
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.light,
                              icon:  Icon(Icons.light_mode_rounded, size: 16)),
                          ButtonSegment(
                              value: ThemeMode.system,
                              icon:  Icon(Icons.auto_mode_rounded, size: 16)),
                          ButtonSegment(
                              value: ThemeMode.dark,
                              icon:  Icon(Icons.dark_mode_rounded, size: 16)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ── Library ────────────────────────────────────
          _SectionHeader('Library'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent),
              title: const Text('Clear all media'),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title:   const Text('Clear library?'),
                  content: const Text(
                      'This removes all items from the list. Your files are not deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:     const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<PlaylistBloc>()
                            .add(const PlaylistClearEvent());
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // ── About ──────────────────────────────────────
          _SectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title:   const Text('Version'),
                  trailing: Text('1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title:   const Text('Built with Flutter + BLoC'),
                  trailing: const Icon(Icons.favorite_rounded,
                      color: Colors.pinkAccent, size: 18),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 0, 6.h),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: .08,
            ),
      ),
    );
  }
}
