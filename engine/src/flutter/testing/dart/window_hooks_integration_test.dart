// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:nativewrappers';

import 'package:test/test.dart';

// HACK: these parts are to get access to private functions tested here.
part '../../lib/ui/compositing.dart';
part '../../lib/ui/geometry.dart';
part '../../lib/ui/hash_codes.dart';
part '../../lib/ui/hooks.dart';
part '../../lib/ui/lerp.dart';
part '../../lib/ui/natives.dart';
part '../../lib/ui/painting.dart';
part '../../lib/ui/pointer.dart';
part '../../lib/ui/semantics.dart';
part '../../lib/ui/text.dart';
part '../../lib/ui/window.dart';

void main() {
  group('window callback zones', () {
    VoidCallback originalOnMetricsChanged;
    VoidCallback originalOnLocaleChanged;
    FrameCallback originalOnBeginFrame;
    VoidCallback originalOnDrawFrame;
    PointerDataPacketCallback originalOnPointerDataPacket;
    VoidCallback originalOnSemanticsEnabledChanged;
    SemanticsActionCallback originalOnSemanticsAction;
    PlatformMessageCallback originalOnPlatformMessage;

    setUp(() {
      originalOnMetricsChanged = window.onMetricsChanged;
      originalOnLocaleChanged = window.onLocaleChanged;
      originalOnBeginFrame = window.onBeginFrame;
      originalOnDrawFrame = window.onDrawFrame;
      originalOnPointerDataPacket = window.onPointerDataPacket;
      originalOnSemanticsEnabledChanged = window.onSemanticsEnabledChanged;
      originalOnSemanticsAction = window.onSemanticsAction;
      originalOnPlatformMessage = window.onPlatformMessage;
    });

    tearDown(() {
      window.onMetricsChanged = originalOnMetricsChanged;
      window.onLocaleChanged = originalOnLocaleChanged;
      window.onBeginFrame = originalOnBeginFrame;
      window.onDrawFrame = originalOnDrawFrame;
      window.onPointerDataPacket = originalOnPointerDataPacket;
      window.onSemanticsEnabledChanged = originalOnSemanticsEnabledChanged;
      window.onSemanticsAction = originalOnSemanticsAction;
      window.onPlatformMessage = originalOnPlatformMessage;
    });

    test('onMetricsChanged preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onMetricsChanged = () {
          runZone = Zone.current;
        };
      });

      window.onMetricsChanged();
      _updateWindowMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onLocaleChanged preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onLocaleChanged = () {
          runZone = Zone.current;
        };
      });

      _updateLocale('en', 'US');
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onBeginFrame preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onBeginFrame = (_) {
          runZone = Zone.current;
        };
      });

      _beginFrame(0);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onDrawFrame preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onDrawFrame = () {
          runZone = Zone.current;
        };
      });

      _drawFrame();
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onPointerDataPacket preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onPointerDataPacket = (_) {
          runZone = Zone.current;
        };
      });

      _dispatchPointerDataPacket(new ByteData.view(new Uint8List(0).buffer));
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onSemanticsEnabledChanged preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onSemanticsEnabledChanged = () {
          runZone = Zone.current;
        };
      });

      _updateSemanticsEnabled(window._semanticsEnabled);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onSemanticsAction preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onSemanticsAction = (_, __) {
          runZone = Zone.current;
        };
      });

      _dispatchSemanticsAction(0, 0);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('onPlatformMessage preserves callback zone', () {
      Zone innerZone;
      Zone runZone;

      runZoned(() {
        innerZone = Zone.current;
        window.onPlatformMessage = (_, __, ___) {
          runZone = Zone.current;
        };
      });

      _dispatchPlatformMessage(null, null, null);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });
  });
}
