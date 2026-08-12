import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_pocket/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: MusicPocketApp()));
    await tester.pumpAndSettle();

    expect(find.text('资料库'), findsWidgets);
    expect(find.text('导入音乐'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(find.text('导入'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('存储占用'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
  });
}
