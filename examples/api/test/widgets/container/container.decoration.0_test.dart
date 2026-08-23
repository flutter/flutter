// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/container/container.decoration.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Each tile renders the corner geometry that its label describes',
    (WidgetTester tester) async {
      // Make the surface tall enough to show both sections at once, so that
      // every probed pixel is within the captured image.
      tester.view.physicalSize = const Size(2400, 3300);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const example.ContainerDecorationExampleApp());

      for (final String key in <String>[
        'gap-pitfall',
        'gap-recommended',
        'covered-pitfall',
        'covered-recommended',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }

      final ui.Image image = (await tester.binding.runAsync<ui.Image>(
        () => captureImage(tester.element(find.byType(MaterialApp))),
      ))!;
      addTearDown(image.dispose);
      final ByteData bytes = (await tester.binding.runAsync<ByteData?>(
        () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
      ))!;

      // Samples the rendered pixel at an offset within the tile identified by
      // the given key.
      Color pixelAt(String key, Offset offset) {
        final Offset position =
            (tester.getTopLeft(find.byKey(Key(key))) + offset) *
            tester.view.devicePixelRatio;
        final int index =
            (position.dx.round() + position.dy.round() * image.width) * 4;
        return Color.fromARGB(
          bytes.getUint8(index + 3),
          bytes.getUint8(index + 0),
          bytes.getUint8(index + 1),
          bytes.getUint8(index + 2),
        );
      }

      // Samples pixels along the tile's top-left diagonal, from (28, 28) to
      // (40, 40), which crosses the region between the border's inner edge
      // and the child's clipped corner.
      List<Color> cornerDiagonal(String key) {
        return List<Color>.generate(
          13,
          (int i) => pixelAt(key, Offset(28.0 + i, 28.0 + i)),
        );
      }

      // Section 1: both tiles are 160x160 with a 20-pixel border and a
      // 56-pixel corner radius. Along the top-left diagonal, the inside of
      // the border reaches 56 - 36 / sqrt(2), about (30.5, 30.5). In the
      // pitfall tile, the child's corner, clipped with the outer 56-pixel
      // radius, only reaches 76 - 56 / sqrt(2), about (36.4, 36.4), so the
      // band between the two curves shows the background: a visible gap.
      expect(cornerDiagonal('gap-pitfall'), contains(example.backgroundColor));
      expect(
        pixelAt('gap-pitfall', const Offset(33.5, 33.5)),
        example.backgroundColor,
      );
      // In the recommended tile, the child's 36-pixel corner radius matches
      // the inside of the border exactly: no background shows through
      // anywhere along the diagonal, and the gap midpoint is filled by the
      // child.
      expect(
        cornerDiagonal('gap-recommended'),
        isNot(contains(example.backgroundColor)),
      );
      expect(
        pixelAt('gap-recommended', const Offset(33.5, 33.5)),
        example.fillColor,
      );
      // The straight edges and the center are unaffected in both tiles.
      for (final String key in <String>['gap-pitfall', 'gap-recommended']) {
        expect(pixelAt(key, const Offset(10.0, 80.0)), example.borderColor);
        expect(pixelAt(key, const Offset(80.0, 80.0)), example.fillColor);
      }

      // Section 2: both tiles are 160x160 with an 8-pixel border and a
      // 56-pixel corner radius. Along the top-left diagonal, the border ring
      // spans from 56 - 56 / sqrt(2), about (16.4, 16.4), to
      // 56 - 48 / sqrt(2), about (22.1, 22.1). Probe its midpoint: in the
      // pitfall tile the opaque child covers the border there, while in the
      // recommended tile the foreground-painted border stays visible.
      const Offset ringProbe = Offset(19.2, 19.2);
      expect(pixelAt('covered-pitfall', ringProbe), example.fillColor);
      expect(pixelAt('covered-recommended', ringProbe), example.borderColor);
      // On the straight edges the border is visible in both tiles: the
      // pitfall only destroys the border near the corners.
      for (final String key in <String>[
        'covered-pitfall',
        'covered-recommended',
      ]) {
        expect(pixelAt(key, const Offset(4.0, 80.0)), example.borderColor);
        expect(pixelAt(key, const Offset(80.0, 80.0)), example.fillColor);
      }
    },
    // [intended] Test relies on captureImage, which is not supported on web
    // currently.
    skip: !canCaptureImage,
  );
}
