// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/matchers.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CkPicture', () {
    setUpCanvasKitTest();

    group('lifecycle', () {
      test('can be disposed of manually', () {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final ui.Canvas canvas = ui.Canvas(recorder);
        canvas.drawPaint(ui.Paint());
        final CkPicture picture = recorder.endRecording() as CkPicture;
        expect(picture.skiaObject, isNotNull);
        expect(picture.debugDisposed, isFalse);
        picture.debugCheckNotDisposed('Test.'); // must not throw
        picture.dispose();
        expect(() => picture.skiaObject, throwsA(isAssertionError));
        expect(picture.debugDisposed, isTrue);

        StateError? actualError;
        try {
          picture.debugCheckNotDisposed('Test.');
        } on StateError catch (error) {
          actualError = error;
        }

        expect(actualError, isNotNull);

        // TODO(yjbanov): cannot test precise message due to https://github.com/flutter/flutter/issues/96298
        expect('$actualError', startsWith(
            'Bad state: Test.\n'
            'The picture has been disposed. '
            'When the picture was disposed the stack trace was:\n'
        ));
      });
    });

    test('toImageSync', () async {
      const ui.Color color = ui.Color(0xFFAAAAAA);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawPaint(ui.Paint()..color = color);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = picture.toImageSync(10, 15);

      expect(image.width, 10);
      expect(image.height, 15);

      final ByteData? data = await image.toByteData();
      expect(data, isNotNull);
      expect(data!.lengthInBytes, 10 * 15 * 4);
      expect(data.buffer.asUint32List().first, color.value);
    });
  // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
