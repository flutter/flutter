// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

const int kPhysicalKeyA = 0x00070004;
const int kLogicalKeyA = 0x00000000061;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  await ui.webOnlyInitializePlatform();

  test('onTextScaleFactorChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onTextScaleFactorChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onTextScaleFactorChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnTextScaleFactorChanged();
  });

  test('onPlatformBrightnessChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onPlatformBrightnessChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPlatformBrightnessChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnPlatformBrightnessChanged();
  });

  test('onMetricsChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onMetricsChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onMetricsChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnMetricsChanged();
  });

  test('onLocaleChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onLocaleChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onLocaleChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnLocaleChanged();
  });

  test('onBeginFrame preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback(Duration _) {
        expect(Zone.current, innerZone);
      }
      window.onBeginFrame = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onBeginFrame, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnBeginFrame(Duration.zero);
  });

  test('onReportTimings preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback(List<dynamic> _) {
        expect(Zone.current, innerZone);
      }
      window.onReportTimings = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onReportTimings, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnReportTimings(<ui.FrameTiming>[]);
  });

  test('onDrawFrame preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onDrawFrame = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onDrawFrame, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnDrawFrame();
  });

  test('onPointerDataPacket preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback(ui.PointerDataPacket _) {
        expect(Zone.current, innerZone);
      }
      window.onPointerDataPacket = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPointerDataPacket, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnPointerDataPacket(const ui.PointerDataPacket());
  });

  test('invokeOnKeyData returns normally when onKeyData is null', () {
    const  ui.KeyData keyData = ui.KeyData(
      timeStamp: Duration(milliseconds: 1),
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
      synthesized: true,
    );
    expect(() {
      EnginePlatformDispatcher.instance.invokeOnKeyData(keyData, (bool result) {
        expect(result, isFalse);
      });
    }, returnsNormally);
  });

  test('onKeyData preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      bool onKeyData(ui.KeyData _) {
        expect(Zone.current, innerZone);
        return false;
      }
      window.onKeyData = onKeyData;

      // Test that the getter returns the exact same onKeyData, e.g. it doesn't
      // wrap it.
      expect(window.onKeyData, same(onKeyData));
    });

    const  ui.KeyData keyData = ui.KeyData(
      timeStamp: Duration(milliseconds: 1),
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
      synthesized: true,
    );
    EnginePlatformDispatcher.instance.invokeOnKeyData(keyData, (bool result) {
      expect(result, isFalse);
    });

    window.onKeyData = null;
  });

  test('onSemanticsEnabledChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onSemanticsEnabledChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onSemanticsEnabledChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnSemanticsEnabledChanged();
  });

  test('onSemanticsAction preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback(int _, ui.SemanticsAction __, ByteData? ___) {
        expect(Zone.current, innerZone);
      }
      window.onSemanticsAction = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onSemanticsAction, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnSemanticsAction(0, ui.SemanticsAction.tap, null);
  });

  test('onAccessibilityFeaturesChanged preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback() {
        expect(Zone.current, innerZone);
      }
      window.onAccessibilityFeaturesChanged = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onAccessibilityFeaturesChanged, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnAccessibilityFeaturesChanged();
  });

  test('onPlatformMessage preserves the zone', () {
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      void callback(String _, ByteData? __, void Function(ByteData?)? ___) {
        expect(Zone.current, innerZone);
      }
      window.onPlatformMessage = callback;

      // Test that the getter returns the exact same callback, e.g. it doesn't wrap it.
      expect(window.onPlatformMessage, same(callback));
    });

    EnginePlatformDispatcher.instance.invokeOnPlatformMessage('foo', null, (ByteData? data) {
      // Not testing anything here.
    });
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
        (ByteData? outputData) {
          expect(Zone.current, innerZone);
          completer.complete();
        },
      );
    });

    await completer.future;
  });

  test('sendPlatformMessage responds even when channel is unknown', () async {
    bool responded = false;

    final ByteData inputData = ByteData(4);
    inputData.setUint32(0, 42);
    window.sendPlatformMessage(
      'flutter/__unknown__channel__',
      null,
      (ByteData? outputData) {
        responded = true;
        expect(outputData, isNull);
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(responded, isTrue);
  });

  /// Regression test for https://github.com/flutter/flutter/issues/66128.
  test('setPreferredOrientation responds even if browser doesn\'t support api', () async {
    final DomScreen screen = domWindow.screen!;
    js_util.setProperty(screen, 'orientation', null);

    final Completer<bool> completer = Completer<bool>();
    final ByteData inputData = const JSONMethodCodec().encodeMethodCall(const MethodCall(
        'SystemChrome.setPreferredOrientations',
        <dynamic>[]))!;

    window.sendPlatformMessage(
      'flutter/platform',
          inputData,
          (ByteData? outputData) {
        completer.complete(true);
      },
    );

    expect(await completer.future, isTrue);
  });

  test('SingletonFlutterWindow implements locale, locales, and locale change notifications', () async {
    // This will count how many times we notified about locale changes.
    int localeChangedCount = 0;
    window.onLocaleChanged = () {
      localeChangedCount += 1;
    };

    ensureFlutterViewEmbedderInitialized();

    // We populate the initial list of locales automatically (only test that we
    // got some locales; some contributors may be in different locales, so we
    // can't test the exact contents).
    expect(window.locale, isA<ui.Locale>());
    expect(window.locales, isNotEmpty);

    // Trigger a change notification (reset locales because the notification
    // doesn't actually change the list of languages; the test only observes
    // that the list is populated again).
    EnginePlatformDispatcher.instance.debugResetLocales();
    expect(window.locales, isEmpty);
    expect(window.locale, equals(const ui.Locale.fromSubtags()));
    expect(localeChangedCount, 0);
    domWindow.dispatchEvent(createDomEvent('Event', 'languagechange'));
    expect(window.locales, isNotEmpty);
    expect(localeChangedCount, 1);
  });

  test('dispatches browser event on flutter/service_worker channel', () async {
    final Completer<void> completer = Completer<void>();
    domWindow.addEventListener('flutter-first-frame',
        allowInterop(completer.complete));
    final Zone innerZone = Zone.current.fork();

    innerZone.runGuarded(() {
      window.sendPlatformMessage(
        'flutter/service_worker',
        ByteData(0),
        (ByteData? outputData) { },
      );
    });

    await expectLater(completer.future, completes);
  });
}
