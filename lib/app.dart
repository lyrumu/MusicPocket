import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/database_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/audio_player_service.dart';

class MusicPocketApp extends ConsumerStatefulWidget {
  const MusicPocketApp({super.key});

  @override
  ConsumerState<MusicPocketApp> createState() => _MusicPocketAppState();
}

class _MusicPocketAppState extends ConsumerState<MusicPocketApp>
    with WidgetsBindingObserver {
  StreamSubscription? _trackSub;

  final Map<ShortcutActivator, Intent> _shortcuts = {
    ...WidgetsApp.defaultShortcuts,
    const SingleActivator(LogicalKeyboardKey.arrowLeft): const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowUp): const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown): const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const DoNothingAndStopPropagationIntent(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(appDatabaseProvider);
    unawaited(
      AudioPlayerService.instance.init(
        ref.read(trackRepositoryProvider),
        ref.read(playlistRepositoryProvider),
      ),
    );
    _trackSub = AudioPlayerService.instance.currentTrackStream.listen((
      track,
    ) async {
      if (track == null) return;
      if (track.id <= 0) return;
      await ref.read(trackRepositoryProvider).markPlayed(track.id);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      unawaited(AudioPlayerService.instance.persistNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkThemeProvider);
    return MaterialApp(
      title: 'Music Pocket',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      shortcuts: _shortcuts,
      home: const HomeScreen(),
    );
  }
}
