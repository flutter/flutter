// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Default timeout (`10` seconds) and polling cadence (`50` milliseconds) while
/// waiting for asynchronous rasterization and Android UI view presentation.
const Duration _kDefaultSettleTimeout = Duration(seconds: 10);
const Duration _kDefaultPollInterval = Duration(milliseconds: 50);

/// Fractional height multipliers (`65%` and `85%`) and resize cycle count (`4`)
/// used to alternate `FlutterView` dimensions during active Hybrid Composition.
const double _kCompactHeightFraction = 0.65;
const double _kMediumHeightFraction = 0.85;
const int _kResizeCycleCount = 4;

/// Number of rapid back-to-back `0 -> 1 -> 0 -> 1` show/hide iterations (`3`)
/// exercising single-frame Hybrid Composition entry and exit transitions.
const int _kRapidToggleCycles = 3;

Future<Map<String, Object?>> _requestState(
  FlutterDriver driver, [
  String command = 'get_state',
]) async {
  return json.decode(await driver.requestData(command)) as Map<String, Object?>;
}

/// Polls native Hybrid Composition state until [predicate] holds or [timeout]
/// expires.
///
/// Pumping UI frames (`SchedulerBinding.endOfFrame`) only waits for the Dart UI
/// build phase, not for the raster thread and platform-thread presentation pass
/// to complete. Polling until the expected native view hierarchy settles avoids
/// racing against asynchronous rasterization and presentation while still
/// letting the `expect(...)` checks fail with the last observed state on
/// timeout.
Future<Map<String, Object?>> _waitForState(
  FlutterDriver driver,
  bool Function(Map<String, Object?> state) predicate, {
  Duration timeout = _kDefaultSettleTimeout,
  Duration pollInterval = _kDefaultPollInterval,
}) async {
  final stopwatch = Stopwatch()..start();
  Map<String, Object?> state = await _requestState(driver);
  while (!predicate(state) && stopwatch.elapsed < timeout) {
    await Future<void>.delayed(pollInterval);
    state = await _requestState(driver);
  }
  return state;
}

void main() {
  late final FlutterDriver flutterDriver;
  late final AndroidNativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await flutterDriver.waitUntilFirstFrameRasterized();
    await nativeDriver.waitUntilFirstFrameDisplayed();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('FlutterView resizes do not leak overlay surfaces or hide platform views', () async {
    final Map<String, Object?> initialState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          (s['flutterViewWidth'] as int? ?? 0) > 0 &&
          (s['flutterViewHeight'] as int? ?? 0) > 0 &&
          s['flutterImageViewCount'] == 1 &&
          s['overlayViewCount'] == 1 &&
          s['overlayLayerViewsCount'] == 1 &&
          (s['visibleMutatorViewCount'] as int? ?? 0) > 0,
    );
    final initialWidth = initialState['flutterViewWidth']! as int;
    final initialHeight = initialState['flutterViewHeight']! as int;

    expect(initialWidth, greaterThan(0));
    expect(initialHeight, greaterThan(0));
    expect(initialState['flutterImageViewCount'], 1);
    expect(initialState['overlayViewCount'], 1);
    expect(initialState['overlayLayerViewsCount'], 1);
    expect(initialState['visibleMutatorViewCount'], greaterThan(0));
    expect(initialState['flutterSurfaceViewAlpha'], 0.0);

    final int compactHeight = (initialHeight * _kCompactHeightFraction).round();
    final int mediumHeight = (initialHeight * _kMediumHeightFraction).round();

    try {
      for (var i = 0; i < _kResizeCycleCount; i++) {
        final targetHeight = i.isEven ? compactHeight : mediumHeight;
        await _requestState(flutterDriver, 'resize_flutter_view:$targetHeight');
        final Map<String, Object?> stateAfterResize = await _waitForState(
          flutterDriver,
          (Map<String, Object?> s) =>
              s['flutterViewHeight'] == targetHeight &&
              s['overlayLayerViewsCount'] == 1 &&
              s['overlayViewCount'] == 1 &&
              s['flutterImageViewCount'] == 1 &&
              (s['visibleMutatorViewCount'] as int? ?? 0) > 0,
        );
        expect(
          stateAfterResize['flutterViewHeight'],
          targetHeight,
          reason: 'FlutterView should resize to $targetHeight on iteration $i',
        );
        expect(
          stateAfterResize['overlayLayerViewsCount'],
          1,
          reason:
              'Destroyed PlatformOverlayView entries must be pruned from overlay maps after resize $i',
        );
        expect(
          stateAfterResize['overlayViewCount'],
          1,
          reason: 'FlutterView should retain only the active PlatformOverlayView after resize $i',
        );
        expect(
          stateAfterResize['flutterImageViewCount'],
          1,
          reason: 'FlutterView should retain one background FlutterImageView after resize $i',
        );
        expect(
          stateAfterResize['visibleMutatorViewCount'],
          greaterThan(0),
          reason: 'Platform view should remain visible after resize $i',
        );
      }
    } finally {
      await _requestState(flutterDriver, 'resize_flutter_view:-1');
    }

    final Map<String, Object?> restoredState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          s['flutterViewHeight'] == initialHeight && s['overlayLayerViewsCount'] == 1,
    );
    expect(restoredState['flutterViewHeight'], initialHeight);
    expect(restoredState['overlayLayerViewsCount'], 1);
  }, timeout: Timeout.none);

  test(
    'multi-overlay interleaved z-order and unused overlay pruning keep views in lockstep',
    () async {
      await _requestState(flutterDriver, 'show_second_platform_view');
      final Map<String, Object?> twoViewState = await _waitForState(
        flutterDriver,
        (Map<String, Object?> s) =>
            s['visibleMutatorViewCount'] == 2 &&
            s['overlayViewCount'] == 2 &&
            s['overlayLayerViewsCount'] == 2,
      );
      expect(twoViewState['visibleMutatorViewCount'], 2);
      expect(twoViewState['overlayViewCount'], 2);
      expect(twoViewState['overlayLayerViewsCount'], 2);
      expect(
        twoViewState['visibleChildKinds'],
        <Object?>[
          'FlutterImageView',
          'FlutterMutatorView',
          'PlatformOverlayView',
          'FlutterMutatorView',
          'PlatformOverlayView',
        ],
        reason: 'Hybrid Composition views and overlays must interleave in exact composition order',
      );

      // Hide only the second overlay while keeping both platform views visible:
      // unused overlay 1 must be pruned immediately (`2 -> 1`).
      await _requestState(flutterDriver, 'hide_second_overlay_only');
      final Map<String, Object?> prunedOneOverlayState = await _waitForState(
        flutterDriver,
        (Map<String, Object?> s) =>
            s['visibleMutatorViewCount'] == 2 &&
            s['overlayViewCount'] == 1 &&
            s['overlayLayerViewsCount'] == 1,
      );
      expect(prunedOneOverlayState['visibleMutatorViewCount'], 2);
      expect(prunedOneOverlayState['overlayViewCount'], 1);
      expect(prunedOneOverlayState['overlayLayerViewsCount'], 1);
      expect(prunedOneOverlayState['visibleChildKinds'], <Object?>[
        'FlutterImageView',
        'FlutterMutatorView',
        'PlatformOverlayView',
        'FlutterMutatorView',
      ]);

      // Remove the second platform view to return to the single-PV baseline.
      await _requestState(flutterDriver, 'hide_second_platform_view');
      final Map<String, Object?> singleViewState = await _waitForState(
        flutterDriver,
        (Map<String, Object?> s) =>
            s['visibleMutatorViewCount'] == 1 &&
            s['overlayViewCount'] == 1 &&
            s['overlayLayerViewsCount'] == 1,
      );
      expect(singleViewState['visibleMutatorViewCount'], 1);
      expect(singleViewState['overlayViewCount'], 1);
      expect(singleViewState['overlayLayerViewsCount'], 1);
    },
    timeout: Timeout.none,
  );

  test(
    'rapid per-frame 0 -> 1 -> 0 -> 1 toggling transitions root alpha and background cleanly',
    () async {
      for (var i = 0; i < _kRapidToggleCycles; i++) {
        await _requestState(flutterDriver, 'rapid_hide_platform_view');
        await _requestState(flutterDriver, 'rapid_show_platform_view');
      }

      // Verify exit (`1 -> 0`) restores FlutterSurfaceView alpha to 1.0 and removes
      // hcBackgroundImageView and all overlays after the exit traversal commit.
      await _requestState(flutterDriver, 'rapid_hide_platform_view');
      final Map<String, Object?> exitedState = await _waitForState(
        flutterDriver,
        (Map<String, Object?> s) =>
            s['flutterImageViewCount'] == 0 &&
            s['overlayViewCount'] == 0 &&
            s['overlayLayerViewsCount'] == 0 &&
            s['visibleMutatorViewCount'] == 0 &&
            s['flutterSurfaceViewAlpha'] == 1.0,
      );
      expect(exitedState['flutterImageViewCount'], 0);
      expect(exitedState['overlayViewCount'], 0);
      expect(exitedState['overlayLayerViewsCount'], 0);
      expect(exitedState['visibleMutatorViewCount'], 0);
      expect(exitedState['flutterSurfaceViewAlpha'], 1.0);
      expect(exitedState['visibleChildKinds'], <Object?>['FlutterSurfaceView']);

      // Re-enter (`0 -> 1`) on a single pumped frame and verify HC background +
      // overlay return with FlutterSurfaceView hidden at alpha 0.0.
      await _requestState(flutterDriver, 'rapid_show_platform_view');
      final Map<String, Object?> reenteredState = await _waitForState(
        flutterDriver,
        (Map<String, Object?> s) =>
            s['flutterImageViewCount'] == 1 &&
            s['overlayViewCount'] == 1 &&
            s['visibleMutatorViewCount'] == 1 &&
            s['flutterSurfaceViewAlpha'] == 0.0,
      );
      expect(reenteredState['flutterImageViewCount'], 1);
      expect(reenteredState['overlayViewCount'], 1);
      expect(reenteredState['visibleMutatorViewCount'], 1);
      expect(reenteredState['flutterSurfaceViewAlpha'], 0.0);
    },
    timeout: Timeout.none,
  );

  test('reverting FlutterImageView while surface is destroyed stops rendering cleanly', () async {
    await _requestState(flutterDriver, 'show_platform_view');
    final Map<String, Object?> activeState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          s['isDisplayingFlutterUi'] == true &&
          s['flutterImageViewCount'] == 1 &&
          s['surfaceAvailable'] == true,
    );
    expect(activeState['isDisplayingFlutterUi'], isTrue);
    expect(activeState['flutterImageViewCount'], 1);
    expect(activeState['surfaceAvailable'], isTrue);

    await nativeDriver.backgroundApp();

    final Map<String, Object?> backgroundState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) => s['surfaceAvailable'] == false,
    );
    expect(
      backgroundState['surfaceAvailable'],
      isFalse,
      reason: 'Backgrounding the activity should destroy the FlutterSurfaceView surface',
    );

    await _requestState(flutterDriver, 'hide_platform_view');
    final Map<String, Object?> revertedState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          s['flutterImageViewCount'] == 0 && s['isDisplayingFlutterUi'] == false,
    );
    expect(
      revertedState['flutterImageViewCount'],
      0,
      reason: 'Hiding the platform view while backgrounded should release FlutterImageView',
    );
    expect(
      revertedState['isDisplayingFlutterUi'],
      isFalse,
      reason: 'Reverting to a destroyed render surface must stop rendering cleanly so isDisplayingFlutterUi becomes false',
    );

    // Draw another Flutter frame while still backgrounded to ensure no native rendering targets
    // a closed ImageReader.
    final Map<String, Object?> backgroundFrameState = await _requestState(
      flutterDriver,
      'toggle_overlay_color',
    );
    expect(backgroundFrameState['isDisplayingFlutterUi'], isFalse);

    await nativeDriver.resumeApp(appName: 'com.example.android_engine_test');
    await flutterDriver.waitUntilFirstFrameRasterized();
    await _requestState(flutterDriver, 'toggle_overlay_color');

    final Map<String, Object?> resumedState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          s['surfaceAvailable'] == true && s['isDisplayingFlutterUi'] == true,
    );
    expect(resumedState['surfaceAvailable'], isTrue);
    expect(resumedState['isDisplayingFlutterUi'], isTrue);

    // Restore HC platform view after resume and verify it still renders cleanly.
    await _requestState(flutterDriver, 'show_platform_view');
    final Map<String, Object?> restoredHcState = await _waitForState(
      flutterDriver,
      (Map<String, Object?> s) =>
          s['flutterImageViewCount'] == 1 &&
          s['overlayLayerViewsCount'] == 1 &&
          (s['visibleMutatorViewCount'] as int? ?? 0) > 0,
    );
    expect(restoredHcState['flutterImageViewCount'], 1);
    expect(restoredHcState['overlayLayerViewsCount'], 1);
    expect(restoredHcState['visibleMutatorViewCount'], greaterThan(0));
  }, timeout: Timeout.none);
}
