import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../platform_features.dart';
import '../source_test_data.dart';
import '../test_utils.dart';

Future<void> testStreamsTab(
  WidgetTester tester,
  SourceTestData audioSourceTestData,
  PlatformFeatures features,
) async {
  printOnFailure('Test Streams Tab');
  await tester.tap(find.byKey(const Key('streamsTab')));
  await tester.pumpAndSettle();

  // Stream position is tracked as soon as source is loaded
  if (features.hasPositionEvent && !audioSourceTestData.isLiveStream) {
    // Display position before playing
    await tester.testPosition(Duration.zero);
  }

  final isImmediateDurationSupported =
      features.hasMp3Duration || !audioSourceTestData.sourceKey.contains('mp3');

  if (features.hasDurationEvent && isImmediateDurationSupported) {
    // Display duration before playing
    await tester.testDuration(audioSourceTestData.duration);
  }

  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('play_button')));
  await tester.pumpAndSettle();

  // Cannot test more precisely as it is dependent on pollInterval
  // and updateInterval of native implementation.
  if (audioSourceTestData.isLiveStream ||
      audioSourceTestData.duration > const Duration(seconds: 2)) {
    // Test player state: playing
    if (features.hasPlayerStateEvent) {
      // Only test, if there's enough time to be able to check playing state.
      await tester.testPlayerState(PlayerState.playing);
      await tester.testOnPlayerState(PlayerState.playing);
    }

    // Test if onPositionText is set.
    if (features.hasPositionEvent) {
      await tester.testPosition(Duration.zero, matcher: greaterThan);
      await tester.testOnPosition(Duration.zero, matcher: greaterThan);
    }
  }

  if (features.hasDurationEvent && !audioSourceTestData.isLiveStream) {
    // Test if onDurationText is set.
    await tester.testOnDuration(audioSourceTestData.duration);
  }

  const sampleDuration = Duration(seconds: 3);
  await tester.pump(sampleDuration);

  // Test player states: pause, stop, completed
  if (features.hasPlayerStateEvent) {
    if (!audioSourceTestData.isLiveStream) {
      if (audioSourceTestData.duration < const Duration(seconds: 2)) {
        await tester.testPlayerState(PlayerState.completed);
        await tester.testOnPlayerState(PlayerState.completed);
      } else if (audioSourceTestData.duration > const Duration(seconds: 5)) {
        await tester.tap(find.byKey(const Key('pause_button')));
        await tester.testPlayerState(PlayerState.paused);
        await tester.testOnPlayerState(PlayerState.paused);

        await tester.tap(find.byKey(const Key('stop_button')));
        await tester.testPlayerState(PlayerState.stopped);
        await tester.testOnPlayerState(PlayerState.stopped);
      } else {
        // Cannot say for sure, if it's stopped or completed, so we just stop
        await tester.tap(find.byKey(const Key('stop_button')));
      }
    } else {
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.testPlayerState(PlayerState.stopped);
      await tester.testOnPlayerState(PlayerState.stopped);
    }
  }

  // Display duration & position after completion / stop
  // FIXME(Gustl22): Linux does not support duration after completion event
  if (features.hasDurationEvent && (kIsWeb || !Platform.isLinux)) {
    await tester.testDuration(audioSourceTestData.duration);
    if (!audioSourceTestData.isLiveStream) {
      await tester.testOnDuration(audioSourceTestData.duration);
    }
  }
  if (features.hasPositionEvent && !audioSourceTestData.isLiveStream) {
    await tester.testPosition(Duration.zero);
  }
}

extension StreamWidgetTester on WidgetTester {
  // Precision for duration & position:
  // Android: two tenth of a second
  // Windows: second
  // Linux: second
  // Web: second

  // Update interval for duration & position:
  // Android: two tenth of a second
  // Windows: second
  // Linux: second
  // Web: second

  bool _durationRangeMatcher(
    Duration? actual,
    Duration? expected, {
    Duration deviation = const Duration(seconds: 1),
  }) {
    if (actual == null && expected == null) {
      return true;
    }
    if (actual == null || expected == null) {
      return false;
    }
    return actual >= (expected - deviation) && actual <= (expected + deviation);
  }

  Future<void> testDuration(Duration duration) async {
    printOnFailure('Test Duration: $duration');
    final st = StackTrace.current.toString();
    await waitFor(
      () async {
        await tap(find.byKey(const Key('getDuration')));
        await pump();
        expectWidgetHasDuration(
          const Key('durationText'),
          matcher: (Duration? actual) =>
              _durationRangeMatcher(actual, duration),
        );
      },
      timeout: const Duration(seconds: 4),
      stackTrace: st,
    );
  }

  Future<void> testPosition(
    Duration position, {
    Matcher Function(Duration) matcher = equals,
  }) async {
    printOnFailure('Test Position: $position');
    final st = StackTrace.current.toString();
    await waitFor(
      () async {
        await tap(find.byKey(const Key('getPosition')));
        await pump();
        expectWidgetHasDuration(
          const Key('positionText'),
          matcher: matcher(position),
        );
      },
      timeout: const Duration(seconds: 4),
      stackTrace: st,
    );
  }

  Future<void> testPlayerState(PlayerState playerState) async {
    printOnFailure('Test PlayerState: $playerState');
    final st = StackTrace.current.toString();
    await waitFor(
      () async {
        await tap(find.byKey(const Key('getPlayerState')));
        await pump();
        expectWidgetHasText(
          const Key('playerStateText'),
          matcher: contains(playerState.toString()),
        );
      },
      timeout: const Duration(seconds: 4),
      stackTrace: st,
    );
  }

  Future<void> testOnDuration(Duration duration) async {
    printOnFailure('Test OnDuration: $duration');
    final st = StackTrace.current.toString();
    await waitFor(
      () async => expectWidgetHasDuration(
        const Key('onDurationText'),
        matcher: (Duration? actual) => _durationRangeMatcher(actual, duration),
      ),
      stackTrace: st,
    );
  }

  Future<void> testOnPosition(
    Duration position, {
    Matcher Function(Duration) matcher = equals,
  }) async {
    printOnFailure('Test OnPosition: $position');
    final st = StackTrace.current.toString();
    await waitFor(
      () async => expectWidgetHasDuration(
        const Key('onPositionText'),
        matcher: matcher(position),
      ),
      pollInterval: const Duration(milliseconds: 250),
      stackTrace: st,
    );
  }

  Future<void> testOnPlayerState(PlayerState playerState) async {
    printOnFailure('Test OnState: $playerState');
    final st = StackTrace.current.toString();
    await waitFor(
      () async => expectWidgetHasText(
        const Key('onStateText'),
        matcher: contains('Stream State: $playerState'),
      ),
      pollInterval: const Duration(milliseconds: 250),
      stackTrace: st,
    );
  }
}
