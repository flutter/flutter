// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

import '../common/matchers.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CkPaint', () {
    setUpCanvasKitTest();

    test('lifecycle', () {
      final CkPaint paint = CkPaint();
      expect(paint.skiaObject, isNotNull);
      expect(paint.debugRef.isDisposed, isFalse);
      paint.dispose();
      expect(paint.debugRef.isDisposed, isTrue);
      expect(
        reason: 'Cannot dispose more than once',
        () => paint.dispose(),
        throwsA(isAssertionError),
      );
    });
  });
}
