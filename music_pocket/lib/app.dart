import 'dart:async';

import 'package:flutter/material.dart';
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

class _MusicPocketAppState extends ConsumerState<MusicPocketApp> {
  StreamSubscription? _trackSub;

  @override
  void initState() {
    super.initState();
    ref.read(appDatabaseProvider);
    _trackSub = AudioPlayerService.instance.currentTrackStream.listen((
      track,
    ) async {
      if (track == null) return;
      if (track.id <= 0) return;
      await ref.read(trackRepositoryProvider).markPlayed(track.id);
    });
  }

  @override
  void dispose() {
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
      home: const HomeScreen(),
    );
  }
}
