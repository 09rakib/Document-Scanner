import 'dart:io';

import 'package:docscan/features/settings/presentation/startup_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/phase2_smoke.dart' as smoke;

void main() {
  test(
    'Smoke files use an existing cache parent and a unique child folder',
    () async {
      final testRoot = await Directory.systemTemp.createTemp(
        'docscan_startup_',
      );
      try {
        final cache = Directory('${testRoot.path}/cache');
        final first = await smoke.createSmokeDirectory(cache);
        final second = await smoke.createSmokeDirectory(cache);
        expect(await first.exists(), isTrue);
        expect(await second.exists(), isTrue);
        expect(first.path, isNot(second.path));
        expect(
          await first.parent.resolveSymbolicLinks(),
          await cache.resolveSymbolicLinks(),
        );
      } finally {
        await testRoot.delete(recursive: true);
      }
    },
  );
  testWidgets('Native diagnostic failure does not block the first app screen', (
    tester,
  ) async {
    // Native channels are unavailable in this test. Diagnostics must fail
    // safely after the app has mounted, rather than leaving a black surface.
    smoke.main();
    await tester.pumpAndSettle();
    expect(find.byType(StartupGate), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    // Also advance through the diagnostic deadline: the UI must remain mounted
    // after a native channel that never replies, with no pending timeout timer.
    await tester.pump(const Duration(seconds: 46));
    await tester.pumpAndSettle();
    expect(find.byType(StartupGate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
