// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('ui.Canvas is an EngineCanvas over a BackendCanvas', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(canvas, isA<EngineCanvas>());
    expect((canvas as EngineCanvas).debugBackend, isA<BackendCanvas>());
    recorder.endRecording().dispose();
  });

  test('ui.Canvas rejects a recorder that is already recording', () {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);

    expect(
      () => ui.Canvas(recorder),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError e) => e.message,
          'message',
          '"recorder" must not already be associated with another Canvas.',
        ),
      ),
    );
    recorder.endRecording().dispose();
  });

  test('drawAtlas with empty colors draws the same pixels as null colors', () async {
    const green = ui.Color(0xFF00FF00);
    final ui.Image atlas = await drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint()..color = green);
    }).toImage(4, 4);

    Future<Uint8List> drawAtlasPixels(List<ui.Color>? colors) async {
      final ui.Picture picture = drawPicture((ui.Canvas canvas) {
        canvas.drawAtlas(
          atlas,
          <ui.RSTransform>[ui.RSTransform(1, 0, 2, 2)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          colors,
          null,
          null,
          ui.Paint(),
        );
      });
      final ui.Image image = await picture.toImage(8, 8);
      final ByteData bytes = (await image.toByteData())!;
      image.dispose();
      picture.dispose();
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    }

    final Uint8List withNullColors = await drawAtlasPixels(null);
    final Uint8List withEmptyColors = await drawAtlasPixels(<ui.Color>[]);
    atlas.dispose();

    // The sprite covers (2, 2)-(6, 6) and is opaque green; the corner is blank.
    int offsetOf(int x, int y) => (y * 8 + x) * 4;
    expect(withNullColors.sublist(offsetOf(3, 3), offsetOf(3, 3) + 4), <int>[0, 255, 0, 255]);
    expect(withNullColors.sublist(offsetOf(0, 0), offsetOf(0, 0) + 4), <int>[0, 0, 0, 0]);
    expect(withEmptyColors, withNullColors);
  });

  test('drawPicture retains the image sources of the drawn picture', () async {
    final ui.Image image = renderer.createImageFromImageBitmap(
      await createImageBitmap(createBlankDomImageData(4, 4)),
    );
    final ImageSource? source = (image as EngineImage).imageSource;
    expect(source, isNotNull);

    final ui.Picture inner = drawPicture((ui.Canvas canvas) {
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    });
    final ui.Picture outer = drawPicture((ui.Canvas canvas) {
      canvas.drawPicture(inner);
    });

    final PictureImageTracker? tracker = (outer as LayerPicture).imageTracker;
    expect(tracker, isNotNull);
    expect(tracker!.isEmpty, isFalse);

    // Only the outer picture keeps the source alive now.
    image.dispose();
    inner.dispose();
    expect(source!.debugIsClosed, isFalse);

    outer.dispose();
    expect(source.debugIsClosed, isTrue);
  });
}
