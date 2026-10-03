// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/container/container.clip_behavior.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Each tile renders the border visibility that its label describes',
    (WidgetTester tester) async {
      // Make the surface large enough to show both tiles side by side, so
      // that every probed pixel is within the captured image.
      tester.view.physicalSize = const Size(2400, 1800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const example.ContainerClipBehaviorExampleApp());

      for (final String key in <String>[
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

      // Both tiles are 140x140 with an 8-pixel border and a 56-pixel corner
      // radius. Along the top-left diagonal, the border ring spans from
      // 56 - 56 / sqrt(2), about (16.4, 16.4), to 56 - 48 / sqrt(2), about
      // (22.1, 22.1). Probe its midpoint: in the first tile the opaque child
      // covers the border there, while in the second tile the
      // foreground-painted border stays visible.
      const Offset ringProbe = Offset(19.2, 19.2);
      expect(pixelAt('covered-pitfall', ringProbe), example.fillColor);
      expect(pixelAt('covered-recommended', ringProbe), example.borderColor);
      // On the straight edges the border is visible in both tiles: the child
      // only covers the border near the corners.
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
