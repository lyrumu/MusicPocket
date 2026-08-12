import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/track_provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/pocket_brand_mark.dart';
import '../../widgets/common/volume_control.dart';
import '../../widgets/player/mini_player.dart';
import '../import/import_screen.dart';
import '../library/library_screen.dart';
import '../player/play_queue_screen.dart';
import '../player/player_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _desktopBreakpoint = 840;
  int _currentIndex = 0;
  Future<StorageUsage>? _storageUsage;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_isTextFieldFocused()) return false;
      AudioPlayerService.instance.togglePlay();
      return true;
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        AudioPlayerService.instance.playPrevious();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        AudioPlayerService.instance.playNext();
        return true;
      }
    }
    return false;
  }

  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    return focus.context?.widget is EditableText;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final currentTrack = ref.watch(currentTrackProvider).asData?.value;
    final content = Column(
      children: [
        _buildTopBar(isDesktop),
        Expanded(child: _buildBody()),
        if (currentTrack != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 1), end: Offset.zero),
              ),
              child: child,
            ),
            child: MiniPlayer(
              key: const ValueKey('home_mini_player'),
              onTap: () => _openFullPlayer(context),
            ),
          ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: isDesktop,
        child: isDesktop
            ? Row(
                children: [
                  _buildDesktopSidebar(),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildTopBar(bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = ref.watch(isDarkThemeProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 18, 12, 10, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            const PocketBrandMark(size: 30),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectionTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '仅在本机 · Music Pocket',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          VolumeControl(compact: !isDesktop),
          const SizedBox(width: 4),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
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
    );
  }

  Widget _buildDesktopSidebar() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const PocketBrandMark(size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Music Pocket',
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: -0.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              _SideDestination(
                icon: Icons.library_music_outlined,
                selectedIcon: Icons.library_music_rounded,
                label: '资料库',
                selected: _currentIndex == 0,
                onTap: () => _selectSection(0),
              ),
              _SideDestination(
                icon: Icons.playlist_play_outlined,
                selectedIcon: Icons.playlist_play_rounded,
                label: '播放队列',
                selected: _currentIndex == 1,
                onTap: () => _selectSection(1),
              ),
              _SideDestination(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search_rounded,
                label: '搜索',
                selected: _currentIndex == 2,
                onTap: () => _selectSection(2),
              ),
              _SideDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: '设置',
                selected: _currentIndex == 3,
                onTap: () => _selectSection(3),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _openImportScreen(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('导入音乐'),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'LOCAL ONLY',
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _currentIndex < 2 ? _currentIndex : _currentIndex + 1,
      onDestinationSelected: (index) {
        if (index == 2) {
          _openImportScreen(context);
          return;
        }
        _selectSection(index < 2 ? index : index - 1);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music_rounded),
          label: '资料库',
        ),
        NavigationDestination(
          icon: Icon(Icons.playlist_play_outlined),
          selectedIcon: Icon(Icons.playlist_play_rounded),
          label: '队列',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          selectedIcon: Icon(Icons.add_circle_rounded),
          label: '导入',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded),
          label: '搜索',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: '设置',
        ),
      ],
    );
  }

  String get _sectionTitle {
    switch (_currentIndex) {
      case 0:
        return '我的口袋';
      case 1:
        return '播放队列';
      case 2:
        return '搜索';
      case 3:
        return '设置';
      default:
        return '我的口袋';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const LibraryScreen();
      case 1:
        return const PlayQueueScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return _buildSettingsPage();
      default:
        return const LibraryScreen();
    }
  }

  Widget _buildSettingsPage() {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text('设备与存储', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('存储占用'),
                    subtitle: FutureBuilder<StorageUsage>(
                      future: _storageUsage ??= _loadStorageUsage(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Text('无法读取存储占用');
                        final usage = snapshot.data;
                        if (usage == null) return const Text('正在计算…');
                        return Text(
                          '${StorageService.instance.formatSize(usage.totalBytes)} · 查看明细',
                        );
                      },
                    ),
                    leading: const Icon(Icons.storage_rounded),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showStorageUsageDialog(context),
                  ),
                  const Divider(indent: 56),
                  const ListTile(
                    title: Text('关于'),
                    subtitle: Text('Music Pocket v1.0.0'),
                    leading: Icon(Icons.info_outline_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      if (index == 3) {
        _storageUsage = _loadStorageUsage();
      }
    });
  }

  Future<void> _showStorageUsageDialog(BuildContext context) async {
    final future = _loadStorageUsage();
    setState(() {
      _storageUsage = future;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存储占用'),
        content: SizedBox(
          width: 340,
          child: FutureBuilder<StorageUsage>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('无法读取存储占用，请稍后重试');
              }
              final usage = snapshot.data;
              if (usage == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _storageRow(context, '音频文件', usage.audioBytes),
                  _storageRow(context, '歌曲封面', usage.coverBytes),
                  _storageRow(context, '资料库数据库', usage.databaseBytes),
                  const Divider(height: 24),
                  _storageRow(
                    context,
                    '总计',
                    usage.totalBytes,
                    emphasized: true,
                  ),
                  if (usage.orphanedFileCount > 0) ...[
                    const Divider(height: 24),
                    _storageRow(
                      context,
                      '未引用文件（${usage.orphanedFileCount} 个）',
                      usage.orphanedBytes,
                      emphasized: true,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    '这些空间用于保存已导入的歌曲、封面和歌单信息，不属于缓存。删除资料库歌曲时，对应的托管文件会一并清理。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (usage.orphanedFileCount > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmClearOrphanedFiles(context, usage),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('清理未引用文件'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Future<StorageUsage> _loadStorageUsage() async {
    final tracks = await ref.read(trackRepositoryProvider).getAll();
    return StorageService.instance.getUsage(
      referencedAudioPaths: tracks.map((track) => track.filePath),
      referencedCoverPaths: tracks.expand(
        (track) => [
          ?track.coverPath,
          ?track.originalCoverPath,
          ?track.customCoverPath,
        ],
      ),
    );
  }

  Future<void> _confirmClearOrphanedFiles(
    BuildContext dialogContext,
    StorageUsage usage,
  ) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('清理未引用文件'),
        content: Text(
          '将删除 ${usage.orphanedFileCount} 个未被资料库使用的应用托管文件，'
          '预计释放 ${StorageService.instance.formatSize(usage.orphanedBytes)}。'
          '当前歌曲和最初导入位置的原文件不会受影响。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final tracks = await ref.read(trackRepositoryProvider).getAll();
    final result = await StorageService.instance.clearOrphanedFiles(
      candidatePaths: usage.orphanedPaths,
      referencedAudioPaths: tracks.map((track) => track.filePath),
      referencedCoverPaths: tracks.expand(
        (track) => [
          ?track.coverPath,
          ?track.originalCoverPath,
          ?track.customCoverPath,
        ],
      ),
    );
    if (!mounted) return;
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    setState(() {
      _storageUsage = _loadStorageUsage();
    });

    final message = result.failedFileCount == 0
        ? result.deletedFileCount == 0
              ? '没有需要清理的未引用文件'
              : '已清理 ${result.deletedFileCount} 个文件，释放 ${StorageService.instance.formatSize(result.freedBytes)}'
        : '已清理 ${result.deletedFileCount} 个文件，${result.failedFileCount} 个清理失败';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _storageRow(
    BuildContext context,
    String label,
    int bytes, {
    bool emphasized = false,
  }) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(StorageService.instance.formatSize(bytes), style: style),
        ],
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PlayerScreen(),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _openImportScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
  }
}

class _SideDestination extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
