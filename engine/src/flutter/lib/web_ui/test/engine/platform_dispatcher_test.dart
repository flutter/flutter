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

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('PlatformDispatcher', () {
    test('high contrast in accessibilityFeatures has the correct value', () {
      final MockHighContrastSupport mockHighContrast =
          MockHighContrastSupport();
      HighContrastSupport.instance = mockHighContrast;
      final EnginePlatformDispatcher engineDispatcher =
          EnginePlatformDispatcher();

      expect(engineDispatcher.accessibilityFeatures.highContrast, isTrue);
      mockHighContrast.isEnabled = false;
      mockHighContrast.invokeListeners(mockHighContrast.isEnabled);
      expect(engineDispatcher.accessibilityFeatures.highContrast, isFalse);

      engineDispatcher.dispose();
    });

    test('responds to flutter/skia Skia.setResourceCacheMaxBytes', () async {
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/skia',
        codec.encodeMethodCall(const MethodCall(
          'Skia.setResourceCacheMaxBytes',
          512 * 1000 * 1000,
        )),
        completer.complete,
      );

      final ByteData? response = await completer.future;
      expect(response, isNotNull);
      expect(
        codec.decodeEnvelope(response!),
        <bool>[true],
      );
    });

    test('responds to flutter/platform HapticFeedback.vibrate', () async {
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(const MethodCall(
          'HapticFeedback.vibrate',
        )),
        completer.complete,
      );

      final ByteData? response = await completer.future;
      expect(response, isNotNull);
      expect(
        codec.decodeEnvelope(response!),
        true,
      );
    });

    test('responds correctly to flutter/platform Clipboard.getData failure',
        () async {
      // Patch browser so that clipboard api is not available.
      final Object? originalClipboard =
          js_util.getProperty<Object?>(domWindow.navigator, 'clipboard');
      js_util.setProperty(domWindow.navigator, 'clipboard', null);
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(const MethodCall(
          'Clipboard.getData',
        )),
        completer.complete,
      );
      final ByteData? response = await completer.future;
      if (response != null) {
        expect(
              () => codec.decodeEnvelope(response),
          throwsA(isA<PlatformException>()),
        );
      }
      js_util.setProperty(
          domWindow.navigator, 'clipboard', originalClipboard);
    });

    test('can find text scale factor', () async {
      const double deltaTolerance = 1e-5;

      final DomElement root = domDocument.documentElement!;
      final String oldFontSize = root.style.fontSize;

      addTearDown(() {
        root.style.fontSize = oldFontSize;
      });

      root.style.fontSize = '16px';
      expect(findBrowserTextScaleFactor(), 1.0);

      root.style.fontSize = '20px';
      expect(findBrowserTextScaleFactor(), 1.25);

      root.style.fontSize = '24px';
      expect(findBrowserTextScaleFactor(), 1.5);

      root.style.fontSize = '14.4px';
      expect(findBrowserTextScaleFactor(), closeTo(0.9, deltaTolerance));

      root.style.fontSize = '12.8px';
      expect(findBrowserTextScaleFactor(), closeTo(0.8, deltaTolerance));

      root.style.fontSize = '';
      expect(findBrowserTextScaleFactor(), 1.0);
    });

    test(
        'calls onTextScaleFactorChanged when the <html> element\'s font-size changes',
        () async {
      final DomElement root = domDocument.documentElement!;
      final String oldFontSize = root.style.fontSize;
      final ui.VoidCallback? oldCallback = ui.PlatformDispatcher.instance.onTextScaleFactorChanged;

      addTearDown(() {
        root.style.fontSize = oldFontSize;
        ui.PlatformDispatcher.instance.onTextScaleFactorChanged = oldCallback;
      });

      root.style.fontSize = '16px';

      bool isCalled = false;
      ui.PlatformDispatcher.instance.onTextScaleFactorChanged = () {
        isCalled = true;
      };

      root.style.fontSize = '20px';
      await Future<void>.delayed(Duration.zero);
      expect(root.style.fontSize, '20px');
      expect(isCalled, isTrue);
      expect(ui.PlatformDispatcher.instance.textScaleFactor, findBrowserTextScaleFactor());

      isCalled = false;

      root.style.fontSize = '16px';
      await Future<void>.delayed(Duration.zero);
      expect(root.style.fontSize, '16px');
      expect(isCalled, isTrue);
      expect(ui.PlatformDispatcher.instance.textScaleFactor, findBrowserTextScaleFactor());
    });
  });
}

class MockHighContrastSupport implements HighContrastSupport {
  bool isEnabled = true;

  final List<HighContrastListener> _listeners = <HighContrastListener>[];

  @override
  bool get isHighContrastEnabled => isEnabled;


  void invokeListeners(bool val) {
    for (final HighContrastListener listener in _listeners) {
      listener(val);
    }
  }

  @override
  void addListener(HighContrastListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(HighContrastListener listener) {
    _listeners.remove(listener);
  }
}
