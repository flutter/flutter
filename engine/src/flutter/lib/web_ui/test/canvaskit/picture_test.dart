// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CkPicture', () {
    setUpCanvasKitTest();

    group('in browsers that do not support FinalizationRegistry', () {
      test('can be disposed of manually', () {
        browserSupportsFinalizationRegistry = false;

        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final ui.Canvas canvas = ui.Canvas(recorder);
        canvas.drawPaint(ui.Paint());
        final CkPicture picture = recorder.endRecording() as CkPicture;
        expect(picture.rawSkiaObject, isNotNull);
        expect(picture.debugDisposed, isFalse);
        picture.debugCheckNotDisposed('Test.'); // must not throw
        picture.dispose();
        expect(picture.rawSkiaObject, isNull);
        expect(picture.debugDisposed, isTrue);

        StateError? actualError;
        try {
          picture.debugCheckNotDisposed('Test.');
        } on StateError catch (error) {
          actualError = error;
        }

        expect(actualError, isNotNull);

        // TODO(yjbanov): cannot test precise message due to https://github.com/flutter/flutter/issues/96298
        expect('$actualError', allOf(
          startsWith(
            'Bad state: Test.\n'
            'The picture has been disposed. '
            'When the picture was disposed the stack trace was:\n'
          ),
          contains('StackTrace_current'),
        ));

        // Emulate SkiaObjectCache deleting the picture
        picture.delete();
        picture.didDelete();
        expect(picture.rawSkiaObject, isNull);

        // A Picture that's been disposed of can no longer be resurrected
        expect(() => picture.resurrect(), throwsStateError);
        expect(() => picture.toImage(10, 10), throwsStateError);
        expect(() => picture.dispose(), throwsStateError);
      });

      test('can be deleted by SkiaObjectCache', () {
        browserSupportsFinalizationRegistry = false;

        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final ui.Canvas canvas = ui.Canvas(recorder);
        canvas.drawPaint(ui.Paint());
        final CkPicture picture = recorder.endRecording() as CkPicture;
        expect(picture.rawSkiaObject, isNotNull);

        // Emulate SkiaObjectCache deleting the picture
        picture.delete();
        picture.didDelete();
        expect(picture.rawSkiaObject, isNull);

        // Deletion is softer than disposal. An object may still be resurrected
        // if it was deleted prematurely.
        expect(picture.debugDisposed, isFalse);
        expect(picture.resurrect(), isNotNull);
      });
    });
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
