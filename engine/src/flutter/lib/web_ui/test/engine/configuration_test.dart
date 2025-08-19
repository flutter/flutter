// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:js_interop';

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

      expect(config.canvasKitBaseUrl, 'canvaskit/'); // _defaultCanvasKitBaseUrl
    });

    test('legacy constructor initializes with a Js Object', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(
        <String, Object?>{'canvasKitBaseUrl': '/some_other_url/'}.jsify()!
            as JsFlutterConfiguration,
      );

      expect(config.canvasKitBaseUrl, '/some_other_url/');
    });
  });

  group('setUserConfiguration', () {
    test('throws assertion error if already initialized from JS', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(
        <String, Object?>{'canvasKitBaseUrl': '/some_other_url/'}.jsify()!
            as JsFlutterConfiguration,
      );

      expect(() {
        config.setUserConfiguration(
          <String, Object?>{'canvasKitBaseUrl': '/yet_another_url/'}.jsify()!
              as JsFlutterConfiguration,
        );
      }, throwsAssertionError);
    });

    test('stores config if JS configuration was null', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(null);

      config.setUserConfiguration(
        <String, Object?>{'canvasKitBaseUrl': '/one_more_url/'}.jsify()! as JsFlutterConfiguration,
      );

      expect(config.canvasKitBaseUrl, '/one_more_url/');
    });

    test('can receive non-existing properties without crashing', () async {
      final FlutterConfiguration config = FlutterConfiguration.legacy(null);

      expect(() {
        config.setUserConfiguration(
          <String, Object?>{'nonexistentProperty': 32.0}.jsify()! as JsFlutterConfiguration,
        );
      }, returnsNormally);
    });
  });

  group('Default configuration values', () {
    late FlutterConfiguration defaultConfig;
    setUp(() {
      defaultConfig = FlutterConfiguration();
      defaultConfig.setUserConfiguration(<String, Object?>{}.jsify()! as JsFlutterConfiguration);
    });

    test('canvasKitVariant', () {
      expect(defaultConfig.canvasKitVariant, CanvasKitVariant.auto);
    });

    test('multiViewEnabled', () {
      expect(defaultConfig.multiViewEnabled, isFalse);
    });
  });

  group('setUserConfiguration (values)', () {
    group('canvasKitVariant', () {
      test('value undefined - defaults to "auto"', () {
        final FlutterConfiguration config = FlutterConfiguration();
        config.setUserConfiguration(
          // With an empty map, the canvasKitVariant is undefined in JS.
          <String, Object?>{}.jsify()! as JsFlutterConfiguration,
        );

        expect(config.canvasKitVariant, CanvasKitVariant.auto);
      });

      test('value - converts to CanvasKitVariant enum (or throw)', () {
        final FlutterConfiguration config = FlutterConfiguration();

        config.setUserConfiguration(
          <String, Object?>{'canvasKitVariant': 'foo'}.jsify()! as JsFlutterConfiguration,
        );
        expect(() => config.canvasKitVariant, throwsArgumentError);

        config.setUserConfiguration(
          <String, Object?>{'canvasKitVariant': 'auto'}.jsify()! as JsFlutterConfiguration,
        );
        expect(config.canvasKitVariant, CanvasKitVariant.auto);

        config.setUserConfiguration(
          <String, Object?>{'canvasKitVariant': 'full'}.jsify()! as JsFlutterConfiguration,
        );
        expect(config.canvasKitVariant, CanvasKitVariant.full);

        config.setUserConfiguration(
          <String, Object?>{'canvasKitVariant': 'chromium'}.jsify()! as JsFlutterConfiguration,
        );
        expect(config.canvasKitVariant, CanvasKitVariant.chromium);
      });
    });

    test('multiViewEnabled', () {
      final FlutterConfiguration config = FlutterConfiguration();
      config.setUserConfiguration(
        <String, Object?>{'multiViewEnabled': true}.jsify()! as JsFlutterConfiguration,
      );
      expect(config.multiViewEnabled, isTrue);
    });
  });
}
