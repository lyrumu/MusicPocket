import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_pocket/screens/startup_screen.dart';

void main() {
  testWidgets('Startup waits for audio and exposes initialization failure', (
    tester,
  ) async {
    final initialization = Completer<void>();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    var childBuilds = 0;
    await tester.pumpWidget(
      StartupScreen(
        initialization: initialization.future,
        child: Builder(
          builder: (_) {
            childBuilds++;
            return const SizedBox(key: Key('ready'));
          },
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(childBuilds, 0);
    expect(
      Theme.of(tester.element(find.byType(Image))).scaffoldBackgroundColor,
      const Color(0xFFEEECE6),
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      Theme.of(tester.element(find.byType(Image))).scaffoldBackgroundColor,
      const Color(0xFF171614),
    );
    initialization.complete();
    await tester.pump();
    expect(find.byKey(const Key('ready')), findsOneWidget);
    expect(childBuilds, 1);

    final failure = Completer<void>();
    await tester.pumpWidget(
      StartupScreen(
        key: const Key('failure'),
        initialization: failure.future,
        child: const SizedBox(key: Key('ready')),
      ),
    );
    failure.completeError(StateError('audio unavailable'));
    await tester.pump();
    expect(find.text('音频服务启动失败，请关闭应用后重试。'), findsOneWidget);
    expect(find.byKey(const Key('ready')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
