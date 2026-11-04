// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const ui.Rect _blueRect = ui.Rect.fromLTRB(50, 0, 100, 100);

ui.ImageFilter _blur({ui.Rect? bounds}) =>
    ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8, tileMode: ui.TileMode.decal, bounds: bounds);

/// Blurs red over the left half and blue over the right half of a 100x100
/// picture with [filter], optionally shifted right by [translateX], and
/// returns the RGBA of the pixel at ([probeX], 50).
Future<List<int>> _probe(ui.ImageFilter filter, {double translateX = 0, int probeX = 53}) async {
  final ui.Picture picture = drawPicture((ui.Canvas canvas) {
    canvas.translate(translateX, 0);
    canvas.saveLayer(null, ui.Paint()..imageFilter = filter);
    canvas.drawRect(
      const ui.Rect.fromLTRB(0, 0, 50, 100),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );
    canvas.drawRect(_blueRect, ui.Paint()..color = const ui.Color(0xFF0000FF));
    canvas.restore();
  });
  final ui.Image image = await picture.toImage(100, 100);
  try {
    final ByteData data = (await image.toByteData())!;
    final int offset = (50 * 100 + probeX) * 4;
    return List<int>.generate(4, (int i) => data.getUint8(offset + i));
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void _expectNoBleed(List<int> rgba) {
  final reason = 'probe RGBA: $rgba';
  expect(rgba[0], lessThanOrEqualTo(8), reason: reason);
  expect(rgba[2], greaterThanOrEqualTo(247), reason: reason);
  expect(rgba[3], 255, reason: reason);
}

void testMain() {
  setUpUnitTests();

  test('control: unbounded blur bleeds red across the edge', () async {
    final List<int> rgba = await _probe(_blur());
    expect(rgba[0], greaterThan(40), reason: 'probe RGBA: $rgba');
  });

  // CanvasKit and skwasm-Skia draw bounded blurs as unbounded, like native
  // Skia (https://github.com/flutter/flutter/issues/175899).
  test('bounded blur does not bleed outside bounds', () async {
    _expectNoBleed(await _probe(_blur(bounds: _blueRect)));
  }, skip: !isWimp);

  test('bounded blur honors the canvas transform', () async {
    _expectNoBleed(await _probe(_blur(bounds: _blueRect), translateX: 10, probeX: 63));
  }, skip: !isWimp);

  test('fallback backends render bounded blur as unbounded', () async {
    final List<int> bounded = await _probe(_blur(bounds: _blueRect));
    final List<int> unbounded = await _probe(_blur());
    for (var i = 0; i < 4; i++) {
      expect(
        bounded[i],
        closeTo(unbounded[i], 2),
        reason: 'bounded $bounded vs unbounded $unbounded',
      );
    }
  }, skip: isWimp);
}
