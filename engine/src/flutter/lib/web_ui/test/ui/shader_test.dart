// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

Future<EngineImage> createTestImage() async {
  final completer = Completer<EngineImage>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List<int>.filled(16, 0)),
    2,
    2,
    ui.PixelFormat.rgba8888,
    (ui.Image image) {
      completer.complete(image as EngineImage);
    },
  );
  return completer.future;
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  group('ui.Shader', () {
    test('Sweep gradient', () {
      final gradient = ui.Gradient.sweep(ui.Offset.zero, testColors) as EngineGradient;
      expect(gradient.getBackendShader(ui.FilterQuality.none), isA<BackendGradient>());
      expect(gradient.getBackendShader(ui.FilterQuality.none).isGradient, isTrue);
    });

    test('Linear gradient', () {
      final gradient =
          ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, 1), testColors) as EngineGradient;
      expect(gradient.getBackendShader(ui.FilterQuality.none), isA<BackendGradient>());
      expect(gradient.getBackendShader(ui.FilterQuality.none).isGradient, isTrue);
    });

    test('Radial gradient', () {
      final gradient = ui.Gradient.radial(ui.Offset.zero, 10, testColors) as EngineGradient;
      expect(gradient.getBackendShader(ui.FilterQuality.none), isA<BackendGradient>());
      expect(gradient.getBackendShader(ui.FilterQuality.none).isGradient, isTrue);
    });

    test('Conical gradient', () {
      final gradient =
          ui.Gradient.radial(
                ui.Offset.zero,
                10,
                testColors,
                null,
                ui.TileMode.clamp,
                null,
                const ui.Offset(10, 10),
                40,
              )
              as EngineGradient;
      expect(gradient.getBackendShader(ui.FilterQuality.none), isA<BackendGradient>());
      expect(gradient.getBackendShader(ui.FilterQuality.none).isGradient, isTrue);
    });

    test('Image shader isGradient is false', () async {
      final EngineImage image = await createTestImage();
      final imageShader =
          ui.ImageShader(
                image,
                ui.TileMode.clamp,
                ui.TileMode.repeated,
                Float64List.fromList(Matrix4.diagonal3Values(1, 2, 3).storage),
              )
              as EngineImageShader;
      expect(imageShader.getBackendShader(ui.FilterQuality.none), isA<BackendImageShader>());
      expect(imageShader.getBackendShader(ui.FilterQuality.none).isGradient, isFalse);
      imageShader.dispose();
    });

    test('Image shader filterQuality delegate caching', () async {
      final EngineImage image = await createTestImage();
      final imageShader =
          ui.ImageShader(
                image,
                ui.TileMode.clamp,
                ui.TileMode.repeated,
                Float64List.fromList(Matrix4.diagonal3Values(1, 2, 3).storage),
              )
              as EngineImageShader;
      final BackendShader backendShader1 = imageShader.getBackendShader(ui.FilterQuality.none);
      expect(backendShader1, isA<BackendImageShader>());

      // Request the same quality as the default quality (none).
      final BackendShader backendShader2 = imageShader.getBackendShader(ui.FilterQuality.none);
      expect(backendShader1, same(backendShader2));

      // Change quality to medium.
      final BackendShader backendShader3 = imageShader.getBackendShader(ui.FilterQuality.medium);
      expect(backendShader1, isNot(same(backendShader3)));

      // Ask for medium again.
      final BackendShader backendShader4 = imageShader.getBackendShader(ui.FilterQuality.medium);
      expect(backendShader3, same(backendShader4));

      // Done with the shader.
      imageShader.dispose();
    });

    test('Gradient validates color stops count', () {
      final threeColors = <ui.Color>[
        const ui.Color(0xFF000000),
        const ui.Color(0xFF888888),
        const ui.Color(0xFFFFFFFF),
      ];
      final twoStops = <double>[0.0, 1.0];

      // Throws if colorStops is omitted but colors does not have length 2.
      expect(
        () => ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, 1), threeColors),
        throwsArgumentError,
      );
      expect(() => ui.Gradient.radial(ui.Offset.zero, 10, threeColors), throwsArgumentError);
      expect(() => ui.Gradient.sweep(ui.Offset.zero, threeColors), throwsArgumentError);

      // Throws if colors and colorStops have mismatched lengths.
      expect(
        () => ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, 1), threeColors, twoStops),
        throwsArgumentError,
      );
      expect(
        () => ui.Gradient.radial(ui.Offset.zero, 10, threeColors, twoStops),
        throwsArgumentError,
      );
      expect(() => ui.Gradient.sweep(ui.Offset.zero, threeColors, twoStops), throwsArgumentError);
    });
  });
}

const List<ui.Color> testColors = <ui.Color>[ui.Color(0xFFFFFF00), ui.Color(0xFFFFFFFF)];
