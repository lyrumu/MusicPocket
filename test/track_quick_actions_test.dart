import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_pocket/data/database/app_database.dart';
import 'package:music_pocket/widgets/library/track_quick_actions.dart';

void main() {
  testWidgets('quick actions contain four correctly labelled actions', (
    tester,
  ) async {
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TrackQuickActions(track: track)),
        ),
      ),
    );

    expect(find.text('作为下一首播放'), findsNothing);
    expect(find.text('加入播放列表'), findsNothing);
    expect(_iconFor(tester, '加入歌单'), Icons.playlist_add_rounded);
    expect(_iconFor(tester, '加入播放队列'), Icons.queue_music_rounded);
    expect(_iconFor(tester, '编辑信息'), Icons.edit_outlined);
    expect(_iconFor(tester, '删除歌曲'), Icons.delete_outline);
  });
}

IconData? _iconFor(WidgetTester tester, String label) {
  final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, label));
  return (tile.leading! as Icon).icon;
}
