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

ui.Paragraph _paragraph(ui.TextStyle style) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 10))
    ..pushStyle(style)
    ..addText('Paint');
  return builder.build()..layout(const ui.ParagraphConstraints(width: 100));
}

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
    final ui.Image image = await drawPicture((ui.Canvas canvas) {
      canvas.drawRect(
        const ui.Rect.fromLTRB(0, 0, 4, 4),
        ui.Paint()..color = const ui.Color(0xFF00FF00),
      );
    }).toImage(4, 4);
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(10, 0)
      ..lineTo(10, 10)
      ..close();
    final vertices = ui.Vertices(ui.VertexMode.triangles, const <ui.Offset>[
      ui.Offset.zero,
      ui.Offset(10, 0),
      ui.Offset(0, 10),
    ]);
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF0000FF)
      ..strokeWidth = 2
      ..shader = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(10, 0), const <ui.Color>[
        ui.Color(0xFFFF0000),
        ui.Color(0xFF00FF00),
      ])
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2)
      ..colorFilter = const ui.ColorFilter.mode(ui.Color(0x80FFFFFF), ui.BlendMode.srcOver)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1);

    final int baseline = _livePaintCount();

    final paragraphs = <ui.Paragraph>[
      _paragraph(
        ui.TextStyle(
          foreground: ui.Paint()..color = const ui.Color(0xFF00FF00),
          background: ui.Paint()..color = const ui.Color(0xFFFF0000),
        ),
      ),
      _paragraph(ui.TextStyle(foreground: ui.Paint()..color = const ui.Color(0xFF00FF00))),
      _paragraph(ui.TextStyle(background: ui.Paint()..color = const ui.Color(0xFFFF0000))),
    ];
    const rect = ui.Rect.fromLTRB(0, 0, 10, 10);
    final ui.Picture picture = drawPicture((ui.Canvas canvas) {
      canvas.drawRect(rect, paint);
      canvas.drawPath(path, paint);
      canvas.drawImage(image, ui.Offset.zero, paint);
      canvas.drawImageRect(image, const ui.Rect.fromLTRB(0, 0, 4, 4), rect, paint);
      canvas.drawImageNine(image, const ui.Rect.fromLTRB(1, 1, 3, 3), rect, paint);
      canvas.drawAtlas(
        image,
        <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
        const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
        const <ui.Color>[ui.Color(0xFFFFFFFF)],
        ui.BlendMode.srcOver,
        null,
        paint,
      );
      canvas.drawVertices(vertices, ui.BlendMode.srcOver, paint);
      canvas.drawPoints(ui.PointMode.points, const <ui.Offset>[ui.Offset(1, 1)], paint);
      canvas.saveLayer(rect, paint);
      canvas.restore();
      canvas.saveLayer(null, paint);
      canvas.restore();
      (canvas as LayerCanvas).saveLayerWithFilter(
        rect,
        paint,
        ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
      );
      canvas.restore();
      for (final paragraph in paragraphs) {
        canvas.drawParagraph(paragraph, ui.Offset.zero);
      }
    });
    expect(_livePaintCount(), baseline, reason: 'after recording');

    final ui.Image rendered = await picture.toImage(20, 20);
    expect(_livePaintCount(), baseline, reason: 'after rendering');

    rendered.dispose();
    picture.dispose();
    for (final paragraph in paragraphs) {
      paragraph.dispose();
    }
    vertices.dispose();
    image.dispose();
    expect(_livePaintCount(), baseline, reason: 'after disposing');
  });
}
