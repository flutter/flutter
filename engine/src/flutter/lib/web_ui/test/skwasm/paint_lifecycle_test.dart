// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// The number of native paints currently alive.
///
/// The index matches `paintCount` in `SkwasmRenderer.dumpDebugInfo`.
int _livePaintCount() => withStackScope((StackScope scope) {
  final Pointer<Uint32> counts = scope.allocUint32Array(28);
  skwasmGetLiveObjectCounts(counts);
  return counts[18];
});

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('a backend paint is counted until it is disposed', () {
    final int baseline = _livePaintCount();

    final BackendPaint paint = EnginePaint().createBackendPaint();
    expect(paint, isA<SkwasmPaint>());
    expect((paint as SkwasmPaint).handle.address, isNot(0));
    expect(_livePaintCount(), baseline + 1);

    paint.dispose();
    expect(_livePaintCount(), baseline);

    // A second dispose must not free the native paint again.
    paint.dispose();
    expect(_livePaintCount(), baseline);
  });

  test('drawing with every paint consumer leaves no native paint alive', () async {
    final int baseline = _livePaintCount();

    final PaintConsumers consumers = await PaintConsumers.create();
    final ui.Picture picture = consumers.record();
    expect(
      _livePaintCount(),
      baseline,
      reason: 'Each draw call and paragraph builder frees the native paint it creates.',
    );

    final ui.Image rendered = await picture.toImage(20, 20);
    expect(
      _livePaintCount(),
      baseline,
      reason: 'Rendering a picture frees any native paint it creates.',
    );

    rendered.dispose();
    picture.dispose();
    consumers.dispose();
    expect(
      _livePaintCount(),
      baseline,
      reason: 'Pictures, images, paragraphs and vertices never own a native paint.',
    );
  });

  test('calls that fail in the backend still free the native paint they created', () {
    final int baseline = _livePaintCount();
    final foreignImage = EngineImage(ForeignBackendImage(), 4, 4);
    const rect = ui.Rect.fromLTRB(0, 0, 4, 4);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTRB(0, 0, 8, 8));

    final failingCalls = <String, void Function()>{
      'drawImage': () => canvas.drawImage(foreignImage, ui.Offset.zero, ui.Paint()),
      'drawImageRect': () => canvas.drawImageRect(foreignImage, rect, rect, ui.Paint()),
      'drawImageNine': () => canvas.drawImageNine(foreignImage, rect.deflate(1), rect, ui.Paint()),
      'drawAtlas': () => canvas.drawAtlas(
        foreignImage,
        <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
        const <ui.Rect>[rect],
        null,
        null,
        null,
        ui.Paint(),
      ),
      'drawRawAtlas': () => canvas.drawRawAtlas(
        foreignImage,
        Float32List.fromList(<double>[1, 0, 0, 0]),
        Float32List.fromList(<double>[0, 0, 4, 4]),
        null,
        null,
        null,
        ui.Paint(),
      ),
      'saveLayerWithFilter': () =>
          (canvas as LayerCanvas).saveLayerWithFilter(rect, ui.Paint(), ForeignImageFilter()),
      'drawPath': () => canvas.drawPath(ForeignPath(), ui.Paint()),
      'drawVertices': () =>
          canvas.drawVertices(ForeignVertices(), ui.BlendMode.srcOver, ui.Paint()),
      'drawRSuperellipse': () =>
          EngineCanvas(ThrowingBackendCanvas())
              .drawRSuperellipse(ui.RSuperellipse.fromRectXY(rect, 1, 1), ui.Paint()),
    };

    for (final MapEntry<String, void Function()>(key: String name, value: void Function() call)
        in failingCalls.entries) {
      expect(
        call,
        throwsA(anyOf(isA<ArgumentError>(), isA<StateError>(), isA<TypeError>())),
        reason: name,
      );
      expect(
        _livePaintCount(),
        baseline,
        reason: '$name must dispose its BackendPaint even when the backend throws.',
      );
    }

    recorder.endRecording().dispose();
    foreignImage.dispose();
  });
}
