// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

void main() {
  test('onTextScaleFactorChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onTextScaleFactorChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onTextScaleFactorChanged, same(callback));
    });

    window.invokeOnTextScaleFactorChanged();
  });

  test('onPlatformBrightnessChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onPlatformBrightnessChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPlatformBrightnessChanged, same(callback));
    });

    window.invokeOnPlatformBrightnessChanged();
  });

  test('onMetricsChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onMetricsChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onMetricsChanged, same(callback));
    });

    window.invokeOnMetricsChanged();
  });

  test('onLocaleChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onLocaleChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onLocaleChanged, same(callback));
    });

    window.invokeOnLocaleChanged();
  });

  test('onBeginFrame preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.FrameCallback callback = (_) {
        expect(Zone.current, innerZone);
      };
      window.onBeginFrame = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onBeginFrame, same(callback));
    });

    window.invokeOnBeginFrame(null);
  });

  test('onReportTimings preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.TimingsCallback callback = (_) {
        expect(Zone.current, innerZone);
      };
      window.onReportTimings = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onReportTimings, same(callback));
    });

    window.invokeOnReportTimings(null);
  });

  test('onDrawFrame preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onDrawFrame = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onDrawFrame, same(callback));
    });

    window.invokeOnDrawFrame();
  });

  test('onPointerDataPacket preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.PointerDataPacketCallback callback = (_) {
        expect(Zone.current, innerZone);
      };
      window.onPointerDataPacket = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPointerDataPacket, same(callback));
    });

    window.invokeOnPointerDataPacket(null);
  });

  test('onSemanticsEnabledChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onSemanticsEnabledChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onSemanticsEnabledChanged, same(callback));
    });

    window.invokeOnSemanticsEnabledChanged();
  });

  test('onSemanticsAction preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.SemanticsActionCallback callback = (_, __, ___) {
        expect(Zone.current, innerZone);
      };
      window.onSemanticsAction = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onSemanticsAction, same(callback));
    });

    window.invokeOnSemanticsAction(null, null, null);
  });

  test('onAccessibilityFeaturesChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.VoidCallback callback = () {
        expect(Zone.current, innerZone);
      };
      window.onAccessibilityFeaturesChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onAccessibilityFeaturesChanged, same(callback));
    });

    window.invokeOnAccessibilityFeaturesChanged();
  });

  test('onPlatformMessage preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ui.PlatformMessageCallback callback = (_, __, ___) {
        expect(Zone.current, innerZone);
      };
      window.onPlatformMessage = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPlatformMessage, same(callback));
    });

    window.invokeOnPlatformMessage(null, null, null);
  });

  test('sendPlatformMessage preserves the zone', () async {
    final Completer<void> completer = Completer<void>();
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      final ByteData inputData = ByteData(4);
      inputData.setUint32(0, 42);
      window.sendPlatformMessage(
        'flutter/debug-echo',
        inputData,
        (outputData) {
          expect(Zone.current, innerZone);
          completer.complete();
        },
      );
    });

    await completer.future;
  });
}
