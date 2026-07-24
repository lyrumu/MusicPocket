import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/track_provider.dart';
import '../../widgets/player/mini_player.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(theme),
          Expanded(
            child: Stack(
              children: [
                _buildBody(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    reverseDuration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: anim.drive(
                        Tween(begin: const Offset(0, 1), end: Offset.zero),
                      ),
                      child: child,
                    ),
                    child: currentTrack == null
                        ? const SizedBox.shrink()
                        : MiniPlayer(
                            key: const ValueKey('mini'),
                            onTap: () => _openFullPlayer(context),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: '资料库',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_play_outlined),
            selectedIcon: Icon(Icons.playlist_play),
            label: '播放列表',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    final isDark = ref.watch(isDarkThemeProvider);
    return ClipRect(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withAlpha(40),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              'MusicPocket',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                ),
              ),
              tooltip: isDark ? '切换到浅色' : '切换到深色',
              onPressed: () {
                ref.read(isDarkThemeProvider.notifier).state = !isDark;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const LibraryScreen();
      case 1:
        return _buildPlaceholder(
          icon: Icons.playlist_play_outlined,
          title: '播放列表',
          subtitle: '歌单功能后续实现',
        );
      case 2:
        return _buildPlaceholder(
          icon: Icons.search_outlined,
          title: '搜索',
          subtitle: '搜歌功能后续实现',
        );
      case 3:
        return _buildSettingsPage();
      default:
        return const LibraryScreen();
    }
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('设置', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('关于'),
            subtitle: const Text('Music Pocket v1.0.0'),
            leading: const Icon(Icons.info_outline),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
