import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../platform_features.dart';
import '../source_test_data.dart';
import '../test_utils.dart';
import 'source_tab.dart';
import 'stream_tab.dart';

Future<void> testControlsTab(
  WidgetTester tester,
  SourceTestData audioSourceTestData,
  PlatformFeatures features,
) async {
  printOnFailure('Test Controls Tab');
  await tester.tap(find.byKey(const Key('controlsTab')));
  await tester.pumpAndSettle();

  if (features.hasVolume) {
    await tester.testVolume('0.0');
    await tester.testVolume('0.5');
    await tester.testVolume('1.0');
    // No tests for volume > 1
  }

  if (features.hasBalance) {
    await tester.testBalance('-1.0');
    await tester.testBalance('1.0');
    await tester.testBalance('0.0');
  }

  if (features.hasPlaybackRate && !audioSourceTestData.isLiveStream) {
    // TODO(Gustl22): also test for playback rate in streams
    await tester.testRate('0.5');
    await tester.testRate('2.0');
    await tester.testRate('1.0');
  }

  if (features.hasSeek && !audioSourceTestData.isLiveStream) {
    // TODO(Gustl22): also test seeking in streams
    final isImmediateDurationSupported = features.hasMp3Duration ||
        !audioSourceTestData.sourceKey.contains('mp3');

    // Linux cannot complete seek if duration is not present.
    await tester.testSeek('0.5', isResume: false);
    await tester.tap(find.byKey(const Key('streamsTab')));
    await tester.pumpAndSettle();

    if (isImmediateDurationSupported) {
      await tester.testPosition(
        Duration(seconds: audioSourceTestData.duration.inSeconds ~/ 2),
        matcher: greaterThanOrEqualTo,
      );
    }
    await tester.tap(find.byKey(const Key('controlsTab')));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));
    await tester.testSeek('1.0');
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('control-stop')));
    await tester.pumpAndSettle();
  }

  final isBytesSource = audioSourceTestData.sourceKey.contains('bytes');
  if (features.hasLowLatency &&
      !audioSourceTestData.isLiveStream &&
      !isBytesSource) {
    await tester.testPlayerMode(PlayerMode.lowLatency);

    // Test resume
    await tester.tap(find.byKey(const Key('control-resume')));
    await tester.pump(const Duration(seconds: 1));
    // Test pause
    await tester.tap(find.byKey(const Key('control-pause')));
    await tester.tap(find.byKey(const Key('control-resume')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('control-stop')));
    await tester.pumpAndSettle();

    // Test volume
    await tester.testVolume('0.5');
    await tester.testVolume('1.0');

    // Test release mode: loop
    await tester.testReleaseMode(ReleaseMode.loop);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('control-stop')));
    await tester.testReleaseMode(ReleaseMode.stop, isResume: false);
    await tester.pumpAndSettle();

    // Reset to media player
    await tester.testPlayerMode(PlayerMode.mediaPlayer);
    await tester.pumpAndSettle();
  }

  if (audioSourceTestData.duration < const Duration(seconds: 2) &&
      !audioSourceTestData.isLiveStream) {
    if (features.hasReleaseModeLoop) {
      await tester.testReleaseMode(ReleaseMode.loop);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(const Key('control-stop')));
      await tester.testReleaseMode(ReleaseMode.stop, isResume: false);
      await tester.pumpAndSettle();
    }

    if (features.hasReleaseModeRelease) {
      await tester.testReleaseMode(ReleaseMode.release);
      await tester.pump(const Duration(seconds: 3));
      // No need to call stop, as it should be released by now
      // TODO(Gustl22): test if source was released

      // Reinitialize source
      await tester.tap(find.byKey(const Key('sourcesTab')));
      await tester.pumpAndSettle();
      await tester.testSource(audioSourceTestData.sourceKey);

      await tester.tap(find.byKey(const Key('controlsTab')));
      await tester.pumpAndSettle();

      await tester.testReleaseMode(ReleaseMode.stop, isResume: false);
      await tester.pumpAndSettle();
    }
  }
}

extension ControlsWidgetTester on WidgetTester {
  Future<void> testVolume(
    String volume, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    printOnFailure('Test Volume: $volume');
    await tap(find.byKey(Key('control-volume-$volume')));
    await tap(find.byKey(const Key('control-resume')));
    // TODO(Gustl22): get volume from native implementation
    await pump(timeout);
    await tap(find.byKey(const Key('control-stop')));
    await pumpAndSettle();
  }

  Future<void> testBalance(
    String balance, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    printOnFailure('Test Balance: $balance');
    await tap(find.byKey(Key('control-balance-$balance')));
    await tap(find.byKey(const Key('control-resume')));
    // TODO(novikov): get balance from native implementation
    await pump(timeout);
    await tap(find.byKey(const Key('control-stop')));
    await pumpAndSettle();
  }

  Future<void> testRate(
    String rate, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    printOnFailure('Test Rate: $rate');
    await tap(find.byKey(Key('control-rate-$rate')));
    await tap(find.byKey(const Key('control-resume')));
    // TODO(Gustl22): get rate from native implementation
    await pump(timeout);
    await tap(find.byKey(const Key('control-stop')));
    await pumpAndSettle();
  }

  Future<void> testSeek(
    String seek, {
    bool isResume = true,
  }) async {
    printOnFailure('Test Seek: $seek');
    await tap(find.byKey(Key('control-seek-$seek')));

    // Wait until appearance and disappearance
    await waitFor(
      () async => expect(
        find.byKey(const Key('toast-seek-complete-0')),
        findsOneWidget,
      ),
    );
    await waitFor(
      () async => expect(
        find.byKey(const Key('toast-seek-complete-0')),
        findsNothing,
      ),
    );

    if (isResume) {
      await tap(find.byKey(const Key('control-resume')));
    }
  }

  Future<void> testPlayerMode(PlayerMode mode) async {
    printOnFailure('Test Player Mode: ${mode.name}');
    await tap(find.byKey(Key('control-player-mode-${mode.name}')));
    await waitFor(
      () async => expectEnumToggleHasSelected(
        const Key('control-player-mode'),
        matcher: equals(mode),
      ),
    );
  }

  Future<void> testReleaseMode(ReleaseMode mode, {bool isResume = true}) async {
    printOnFailure('Test Release Mode: ${mode.name}');
    await tap(find.byKey(Key('control-release-mode-${mode.name}')));
    await waitFor(
      () async => expectEnumToggleHasSelected(
        const Key('control-release-mode'),
        matcher: equals(mode),
      ),
    );
    if (isResume) {
      await tap(find.byKey(const Key('control-resume')));
    }
    // TODO(Gustl22): get release mode from native implementation
  }
}
