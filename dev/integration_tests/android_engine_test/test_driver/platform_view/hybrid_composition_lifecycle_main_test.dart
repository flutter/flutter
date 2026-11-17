// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

Future<Map<String, Object?>> _requestState(
  FlutterDriver driver, [
  String command = 'get_state',
]) async {
  return json.decode(await driver.requestData(command)) as Map<String, Object?>;
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
    final Map<String, Object?> initialState = await _requestState(flutterDriver);
    final initialWidth = initialState['flutterViewWidth']! as int;
    final initialHeight = initialState['flutterViewHeight']! as int;

    expect(initialWidth, greaterThan(0));
    expect(initialHeight, greaterThan(0));
    expect(initialState['flutterImageViewCount'], 1);
    expect(initialState['overlayViewCount'], 1);
    expect(initialState['overlayLayerViewsCount'], 1);
    expect(initialState['visibleMutatorViewCount'], greaterThan(0));

    final int compactHeight = (initialHeight * 0.65).round();
    final int mediumHeight = (initialHeight * 0.85).round();
    const resizeCycles = 4;

    try {
      for (var i = 0; i < resizeCycles; i++) {
        final targetHeight = i.isEven ? compactHeight : mediumHeight;
        await _requestState(flutterDriver, 'resize_flutter_view:$targetHeight');
        final Map<String, Object?> stateAfterResize = await _requestState(flutterDriver);
        expect(
          stateAfterResize['flutterViewHeight'],
          targetHeight,
          reason: 'FlutterView should resize to $targetHeight on iteration $i',
        );
        expect(
          stateAfterResize['overlayLayerViewsCount'],
          1,
          reason:
              'Destroyed PlatformOverlayView entries must be pruned from overlayLayerViews after resize $i',
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

    final Map<String, Object?> restoredState = await _requestState(flutterDriver);
    expect(restoredState['flutterViewHeight'], initialHeight);
    expect(restoredState['overlayLayerViewsCount'], 1);
  }, timeout: Timeout.none);

  test('reverting FlutterImageView while surface is destroyed stops rendering cleanly', () async {
    final Map<String, Object?> activeState = await _requestState(
      flutterDriver,
      'show_platform_view',
    );
    expect(activeState['isDisplayingFlutterUi'], isTrue);
    expect(activeState['flutterImageViewCount'], 1);
    expect(activeState['surfaceAvailable'], isTrue);

    await nativeDriver.backgroundApp();

    final Map<String, Object?> backgroundState = await _requestState(flutterDriver);
    expect(
      backgroundState['surfaceAvailable'],
      isFalse,
      reason: 'Backgrounding the activity should destroy the FlutterSurfaceView surface',
    );

    final Map<String, Object?> revertedState = await _requestState(
      flutterDriver,
      'hide_platform_view',
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
    // the closed FlutterImageView.
    final Map<String, Object?> backgroundFrameState = await _requestState(
      flutterDriver,
      'toggle_overlay_color',
    );
    expect(backgroundFrameState['isDisplayingFlutterUi'], isFalse);

    await nativeDriver.resumeApp(appName: 'com.example.android_engine_test');
    await flutterDriver.waitUntilFirstFrameRasterized();
    await _requestState(flutterDriver, 'toggle_overlay_color');

    final Map<String, Object?> resumedState = await _requestState(flutterDriver);
    expect(resumedState['surfaceAvailable'], isTrue);
    expect(resumedState['isDisplayingFlutterUi'], isTrue);

    // Restore HC platform view after resume and verify it still renders cleanly.
    final Map<String, Object?> restoredHcState = await _requestState(
      flutterDriver,
      'show_platform_view',
    );
    expect(restoredHcState['flutterImageViewCount'], 1);
    expect(restoredHcState['visibleMutatorViewCount'], greaterThan(0));
  }, timeout: Timeout.none);
}
