import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_pocket/data/database/app_database.dart';
import 'package:music_pocket/widgets/library/track_list_tile.dart';

void main() {
  testWidgets('left swipe stays bounded and adds the track as next', (
    tester,
  ) async {
    var playNextCalls = 0;
    final track = Track(
      id: 1,
      title: 'Song',
      artist: 'Artist',
      album: '',
      albumArtist: '',
      genre: '',
      durationMs: 120000,
      filePath: '/tmp/song.mp3',
      addedAt: DateTime(2026),
      playCount: 0,
      isFavorite: false,
      isUserEdited: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackListTile(track: track, onPlayNext: () => playNextCalls++),
        ),
      ),
    );

    expect(find.byTooltip('作为下一首播放'), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TrackListTile)),
    );
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();

    final content = tester.widget<Transform>(
      find.byKey(const ValueKey('track_swipe_content_1')),
    );
    expect(content.transform.storage[12], -112);
    expect(playNextCalls, 0);

    await gesture.up();
    await tester.pump();

    expect(playNextCalls, 1);
    expect(find.text('已加入'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('已加入'), findsNothing);
    expect(find.byType(TrackListTile), findsOneWidget);
  });
}
