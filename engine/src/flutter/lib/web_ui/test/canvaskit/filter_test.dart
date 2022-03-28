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
       const EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.srcOver) as CkColorFilter,
       const EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.dstOver) as CkColorFilter,
       const EngineColorFilter.mode(ui.Color(0x87654321), ui.BlendMode.dstOver) as CkColorFilter,
       const EngineColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
       ]) as CkColorFilter,
       EngineColorFilter.matrix(Float32List.fromList(<double>[
          2, 0, 0, 0, 0,
          0, 2, 0, 0, 0,
          0, 0, 2, 0, 0,
          0, 0, 0, 2, 0,
       ])) as CkColorFilter,
       const EngineColorFilter.linearToSrgbGamma() as CkColorFilter,
       const EngineColorFilter.srgbToLinearGamma() as CkColorFilter,
    ];
  }

  List<CkImageFilter> createImageFilters() {
    return <CkImageFilter>[
      CkImageFilter.blur(sigmaX: 5, sigmaY: 6, tileMode: ui.TileMode.clamp),
      CkImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.clamp),
      CkImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.decal),
      for (final CkColorFilter colorFilter in createColorFilters()) CkImageFilter.color(colorFilter: colorFilter),
    ];
  }

  // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  if (!isIosSafari) {
    setUpCanvasKitTest();
  }

  group('ImageFilters', () {
    test('can be constructed', () {
      final CkImageFilter imageFilter = CkImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);
      expect(imageFilter, isA<CkImageFilter>());
      expect(imageFilter.createDefault(), isNotNull);
      expect(imageFilter.resurrect(), isNotNull);
    });


    test('== operator', () {
      final List<ui.ImageFilter> filters1 = <ui.ImageFilter>[
        ...createImageFilters(),
        ...createColorFilters(),
      ];
      final List<ui.ImageFilter> filters2 = <ui.ImageFilter>[
        ...createImageFilters(),
        ...createColorFilters(),
      ];

      for (int index1 = 0; index1 < filters1.length; index1 += 1) {
        final ui.ImageFilter imageFilter1 = filters1[index1];
        expect(imageFilter1 == imageFilter1, isTrue);
        for (int index2 = 0; index2 < filters2.length; index2 += 1) {
          final ui.ImageFilter imageFilter2 = filters2[index2];
          expect(imageFilter1 == imageFilter2, imageFilter2 == imageFilter1);
          expect(imageFilter1 == imageFilter2, index1 == index2);
        }
      }
    });

    test('reuses the Skia filter', () {
      final CkPaint paint = CkPaint();
      paint.imageFilter = CkImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);

      final ManagedSkiaObject<Object> managedFilter = paint.imageFilter! as ManagedSkiaObject<Object>;
      final Object skiaFilter = managedFilter.skiaObject;

      paint.imageFilter = CkImageFilter.blur(sigmaX: 5, sigmaY: 10, tileMode: ui.TileMode.clamp);
      expect((paint.imageFilter! as ManagedSkiaObject<Object>).skiaObject, same(skiaFilter));
    });

  // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);

  group('MaskFilter', () {
    test('with 0 sigma can be set on a Paint', () {
      final ui.Paint paint = ui.Paint();
      const ui.MaskFilter filter = ui.MaskFilter.blur(ui.BlurStyle.normal, 0);

      expect(() => paint.maskFilter = filter, isNot(throwsException));
    });

  // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
