// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('readViewportFit', () {
    test('reads each of the values of the specification', () {
      expect(readViewportFit('viewport-fit=auto'), ViewportFit.auto);
      expect(readViewportFit('viewport-fit=contain'), ViewportFit.contain);
      expect(readViewportFit('viewport-fit=cover'), ViewportFit.cover);
    });

    test('returns null when there is nothing to read', () {
      expect(readViewportFit(null), isNull);
      expect(readViewportFit(''), isNull);
      expect(readViewportFit('width=device-width, initial-scale=1.0'), isNull);
    });

    test('ignores a value that is not in the specification', () {
      expect(readViewportFit('viewport-fit=coverr'), isNull);
      expect(readViewportFit('viewport-fit=none'), isNull);
    });

    test('does not match a descriptor that merely ends in `viewport-fit`', () {
      expect(readViewportFit('x-viewport-fit=cover'), isNull);
    });

    test('tolerates the separators and spacing that browsers tolerate', () {
      expect(readViewportFit('width=device-width,viewport-fit=cover'), ViewportFit.cover);
      expect(readViewportFit('width=device-width;viewport-fit=cover'), ViewportFit.cover);
      expect(readViewportFit('width=device-width viewport-fit=cover'), ViewportFit.cover);
      expect(readViewportFit('viewport-fit = cover'), ViewportFit.cover);
    });

    test('is case-insensitive, like the browser', () {
      expect(readViewportFit('VIEWPORT-FIT=COVER'), ViewportFit.cover);
    });

    test('takes the last declaration, like the browser', () {
      expect(readViewportFit('viewport-fit=contain, viewport-fit=cover'), ViewportFit.cover);
      expect(readViewportFit('viewport-fit=cover, viewport-fit=contain'), ViewportFit.contain);
    });

    test('reads back the descriptor that `ViewportFit` writes', () {
      for (final ViewportFit fit in ViewportFit.values) {
        expect(readViewportFit(fit.descriptor), fit);
      }
    });
  });

  group('parseViewportContent', () {
    test('splits descriptors on every separator a browser accepts', () {
      expect(parseViewportContent('width=device-width, initial-scale=1.0'), <String, String>{
        'width': 'device-width',
        'initial-scale': '1.0',
      });
      expect(parseViewportContent('width=400;initial-scale=1'), <String, String>{
        'width': '400',
        'initial-scale': '1',
      });
    });

    test('tolerates spaces around the separator, like `readViewportFit`', () {
      expect(parseViewportContent('width = device-width, user-scalable = no'), <String, String>{
        'width': 'device-width',
        'user-scalable': 'no',
      });
    });

    test('lower-cases both halves of a descriptor', () {
      expect(parseViewportContent('Width=Device-Width'), <String, String>{'width': 'device-width'});
    });

    test('returns nothing for content that declares nothing', () {
      expect(parseViewportContent(null), isEmpty);
      expect(parseViewportContent(''), isEmpty);
      expect(parseViewportContent('user-scalable'), isEmpty);
      expect(parseViewportContent('=cover'), isEmpty);
    });
  });
}
