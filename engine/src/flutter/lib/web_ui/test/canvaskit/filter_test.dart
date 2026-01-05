// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  List<CkColorFilter> createColorFilters() {
    return <CkColorFilter>[
      createCkColorFilter(
        const EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.srcOver),
      )!,
      createCkColorFilter(
        const EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.dstOver),
      )!,
      createCkColorFilter(
        const EngineColorFilter.mode(ui.Color(0x87654321), ui.BlendMode.dstOver),
      )!,
      createCkColorFilter(
        const EngineColorFilter.matrix(<double>[
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
      )!,
      createCkColorFilter(
        EngineColorFilter.matrix(
          Float32List.fromList(<double>[
            2,
            0,
            0,
            0,
            0,
            0,
            2,
            0,
            0,
            0,
            0,
            0,
            2,
            0,
            0,
            0,
            0,
            0,
            2,
            0,
          ]),
        ),
      )!,
      createCkColorFilter(const EngineColorFilter.linearToSrgbGamma())!,
      createCkColorFilter(const EngineColorFilter.srgbToLinearGamma())!,
      createCkColorFilter(EngineColorFilter.saturation(0.5))!,
    ];
  }

  List<CkImageFilter> createImageFilters() {
    final filters = <CkImageFilter>[
      CkImageFilter.blur(sigmaX: 5, sigmaY: 6, tileMode: ui.TileMode.clamp),
      CkImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.clamp),
      CkImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.decal),
      CkImageFilter.dilate(radiusX: 5, radiusY: 6),
      CkImageFilter.erode(radiusX: 7, radiusY: 8),
      for (final CkColorFilter colorFilter in createColorFilters())
        CkImageFilter.color(colorFilter: colorFilter),
    ];
    filters.add(CkImageFilter.compose(outer: filters[0], inner: filters[1]));
    filters.add(CkImageFilter.compose(outer: filters[1], inner: filters[3]));
    return filters;
  }

  setUpCanvasKitTest(withImplicitView: true);

  group('ImageFilters', () {
    {
      final List<CkImageFilter> testFilters = createImageFilters();
      for (final imageFilter in testFilters) {
        test('${imageFilter.runtimeType}.withSkImageFilter creates temp SkImageFilter', () {
          expect(imageFilter, isA<CkImageFilter>());
          SkImageFilter? skFilter;
          imageFilter.withSkImageFilter((value) {
            expect(value.isDeleted(), isFalse);
            skFilter = value;
          });
          expect(skFilter, isNotNull);
          expect(
            reason: 'Because the SkImageFilter instance is temporary',
            skFilter!.isDeleted(),
            isTrue,
          );
        });
      }
    }

    test('reuses the Skia filter', () {
      final paint = CkPaint();
      paint.imageFilter = CkImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);

      final managedFilter1 = paint.imageFilter! as CkManagedSkImageFilterConvertible;

      paint.imageFilter = CkImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);
      final managedFilter2 = paint.imageFilter! as CkManagedSkImageFilterConvertible;

      expect(managedFilter1, same(managedFilter2));
    });
  });
}
