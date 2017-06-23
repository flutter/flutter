// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

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

      window.onLocaleChanged();
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

      window.onBeginFrame(null);
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

      window.onDrawFrame();
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

      window.onPointerDataPacket(null);
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

      window.onSemanticsEnabledChanged();
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

      window.onSemanticsAction(null, null);
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

      window.onPlatformMessage(null, null, null);
      expect(runZone, isNotNull);
      expect(runZone, same(innerZone));
    });

    test('sendPlatformMessage preserves callback zone', () {
      runZoned(() {
        final Zone innerZone = Zone.current;
        window.sendPlatformMessage('test', new ByteData.view(new Uint8List(0).buffer), expectAsync1((ByteData data) {
          final Zone runZone = Zone.current;
          expect(runZone, isNotNull);
          expect(runZone, same(innerZone));
        }));
      });
    });
  });
}
