// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CkPaint', () {
    setUpCanvasKitTest();

    test('createBackendPaint builds an SkPaint that dispose deletes once', () {
      final paint =
          (EnginePaint()..color = const ui.Color(0xFF00FF00)).createBackendPaint() as CkPaint;
      final JSObject skPaint = paint.skiaObject;
      expect(skPaint.callMethod<JSFloat32Array>('getColor'.toJS).toDart, <double>[0, 1, 0, 1]);
      expect(skPaint.callMethod<JSBoolean>('isDeleted'.toJS).toDart, isFalse);

      paint.dispose();
      expect(skPaint.callMethod<JSBoolean>('isDeleted'.toJS).toDart, isTrue);

      // Disposing again must not delete the SkPaint a second time.
      expect(paint.dispose, returnsNormally);
    });
  });
}
