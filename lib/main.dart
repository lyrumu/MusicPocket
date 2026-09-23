import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'app.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'screens/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    StartupScreen(
      initialization: _initializeAudio(),
      child: const ProviderScope(child: MusicPocketApp()),
    ),
  );
}

Future<void> _initializeAudio() async {
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized();
  }
  final handler = await AudioService.init(
    builder: () => MusicPocketAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musicpocket.channel.audio',
      androidNotificationChannelName: 'Music Pocket playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  AudioPlayerService.instance.attachHandler(handler);
}
