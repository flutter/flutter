// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:js/js_util.dart' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/matchers.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('FlutterConfiguration', () {
    test('initializes with null', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(null);

      expect(config.canvasKitMaximumSurfaces, 8); // _defaultCanvasKitMaximumSurfaces
    });

    test('legacy constructor initializes with a Js Object', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(
        js_util.jsify(<String, Object?>{
          'canvasKitMaximumSurfaces': 16,
        }) as JsFlutterConfiguration);

      expect(config.canvasKitMaximumSurfaces, 16);
    });

    test('merge', () {
      final FlutterConfiguration originalConfig = FlutterConfiguration.legacy(
        js_util.jsify(<String, Object?>{
          'useColorEmoji': false,
          'canvasKitMaximumSurfaces': 99,
        }) as JsFlutterConfiguration,
      );
      final FlutterConfiguration mergedConfig = originalConfig.merge(
        js_util.jsify(<String, Object?>{
          'useColorEmoji': true,
        }) as JsFlutterConfiguration,
      );

      // `useColorEmoji` should've been overriden.
      expect(mergedConfig.useColorEmoji, isTrue);
      // `canvasKitMaximumSurfaces` should've been preserved.
      expect(mergedConfig.canvasKitMaximumSurfaces, 99);

      // Original config should not have been mutated.
      expect(originalConfig.useColorEmoji, isFalse);
      expect(originalConfig.canvasKitMaximumSurfaces, 99);
    });
  });

  group('setUserConfiguration', () {
    test('throws assertion error if already initialized from JS', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(
        js_util.jsify(<String, Object?>{
          'canvasKitMaximumSurfaces': 12,
        }) as JsFlutterConfiguration);

      expect(() {
        config.setUserConfiguration(
          js_util.jsify(<String, Object?>{
            'canvasKitMaximumSurfaces': 16,
          }) as JsFlutterConfiguration);
      }, throwsAssertionError);
    });

    test('stores config if JS configuration was null', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(null);

      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{
          'canvasKitMaximumSurfaces': 16,
        }) as JsFlutterConfiguration);

      expect(config.canvasKitMaximumSurfaces, 16);
    });
  });

  group('CanvasKit config', () {
    test('default canvasKitVariant', () {
      final FlutterConfiguration config = FlutterConfiguration();

      expect(config.canvasKitVariant, CanvasKitVariant.auto);
    });

    test('default canvasKitVariant when it is undefined', () {
      final FlutterConfiguration config = FlutterConfiguration();
      config.setUserConfiguration(
        // With an empty map, the canvasKitVariant is undefined in JS.
        js_util.jsify(<String, Object?>{}) as JsFlutterConfiguration,
      );

      expect(config.canvasKitVariant, CanvasKitVariant.auto);
    });

    test('validates canvasKitVariant', () {
      final FlutterConfiguration config = FlutterConfiguration();

      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{'canvasKitVariant': 'foo'}) as JsFlutterConfiguration,
      );
      expect(() => config.canvasKitVariant, throwsArgumentError);

      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{'canvasKitVariant': 'auto'}) as JsFlutterConfiguration,
      );
      expect(config.canvasKitVariant, CanvasKitVariant.auto);

      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{'canvasKitVariant': 'full'}) as JsFlutterConfiguration,
      );
      expect(config.canvasKitVariant, CanvasKitVariant.full);

      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{'canvasKitVariant': 'chromium'}) as JsFlutterConfiguration,
      );
      expect(config.canvasKitVariant, CanvasKitVariant.chromium);
    });
  });

  group('useColorEmoji', () {
    test('defaults to false', () {
      final FlutterConfiguration config = FlutterConfiguration();
      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{}) as JsFlutterConfiguration,
      );
      expect(config.useColorEmoji, isFalse);
    });

    test('can be set to true', () {
      final FlutterConfiguration config = FlutterConfiguration();
      config.setUserConfiguration(
        js_util.jsify(<String, Object?>{'useColorEmoji': true}) as JsFlutterConfiguration,
      );
      expect(config.useColorEmoji, isTrue);
    });
  });
}
