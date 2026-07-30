import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'app.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const ProviderScope(child: MusicPocketApp()));
}
