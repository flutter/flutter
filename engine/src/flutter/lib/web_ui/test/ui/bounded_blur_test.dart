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
///
/// The default probe sits 3px inside the blue half, where an unbounded
/// sigma-8 blur visibly mixes in red from across the edge.
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
  try {
    final ui.Image image = await picture.toImage(100, 100);
    try {
      final ByteData data = (await image.toByteData())!;
      final int offset = (50 * 100 + probeX) * 4;
      return List<int>.generate(4, (int i) => data.getUint8(offset + i));
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

/// Expects the probe to be (nearly) pure opaque blue. The small tolerances
/// absorb blur renormalization rounding.
void _expectNoBleed(List<int> rgba) {
  const reason = 'a blur bounded to the blue half never samples the red half';
  expect(rgba[0], lessThanOrEqualTo(8), reason: reason);
  expect(rgba[2], greaterThanOrEqualTo(247), reason: reason);
  expect(rgba[3], 255, reason: reason);
}

/// Expects [actual] to match [expected] within 2 per channel, for the given
/// [reason].
void _expectSameAs(List<int> actual, List<int> expected, {required String reason}) {
  for (var i = 0; i < 4; i++) {
    expect(actual[i], closeTo(expected[i], 2), reason: reason);
  }
}

void testMain() {
  setUpUnitTests();

  test('control: unbounded blur bleeds red across the edge', () async {
    final List<int> rgba = await _probe(_blur());
    expect(
      rgba[0],
      greaterThan(40),
      reason: 'an unbounded sigma-8 blur mixes red into pixels 3px across the edge',
    );
  });

  test('zero-sigma blur with bounds draws content unblurred and unmasked', () async {
    final filter = ui.ImageFilter.blur(tileMode: ui.TileMode.decal, bounds: _blueRect);
    expect(await _probe(filter, probeX: 47), <int>[255, 0, 0, 255]);
    expect(await _probe(filter), <int>[0, 0, 255, 255]);
  });

  // Like native Impeller, empty or inverted bounds are not normalized and do
  // not mask the output.
  test('blur with empty or inverted bounds renders like an unbounded blur', () async {
    final List<int> unbounded = await _probe(_blur());
    for (final bounds in <ui.Rect>[ui.Rect.zero, const ui.Rect.fromLTRB(100, 100, 50, 0)]) {
      _expectSameAs(
        await _probe(_blur(bounds: bounds)),
        unbounded,
        reason: 'empty or inverted bounds ($bounds) do not mask the blur',
      );
    }
  });

  group('wimp', () {
    test('bounded blur does not bleed outside bounds', () async {
      _expectNoBleed(await _probe(_blur(bounds: _blueRect)));
    });

    test('bounded blur honors the canvas transform', () async {
      _expectNoBleed(await _probe(_blur(bounds: _blueRect), translateX: 10, probeX: 63));
    });

    test('a reused bounded blur stays bounded after backing a backdrop filter', () async {
      final filter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8, bounds: _blueRect);
      _expectNoBleed(await _probe(filter));

      final ui.Picture greenPicture = drawPicture((ui.Canvas canvas) {
        canvas.drawRect(_blueRect, ui.Paint()..color = const ui.Color(0xFF00FF00));
      });
      final builder = ui.SceneBuilder();
      builder.pushBackdropFilter(filter);
      builder.addPicture(ui.Offset.zero, greenPicture);
      builder.pop();
      final ui.Scene scene = builder.build();
      final ui.Image backdropImage = await scene.toImage(100, 100);
      backdropImage.dispose();
      scene.dispose();
      greenPicture.dispose();

      _expectNoBleed(await _probe(filter));
    });

    test('bounded blur stays bounded inside ImageFilter.compose', () async {
      final filter = ui.ImageFilter.compose(
        outer: ui.ImageFilter.matrix(
          Float64List.fromList(<double>[
            1, 0, 0, 0, //
            0, 1, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1, //
          ]),
        ),
        inner: _blur(bounds: _blueRect),
      );
      _expectNoBleed(await _probe(filter));
    });
  }, skip: !isWimp);

  // CanvasKit and skwasm-Skia draw bounded blurs as unbounded, like native
  // Skia (https://github.com/flutter/flutter/issues/175899).
  group('fallback backends', () {
    test('render bounded blur as unbounded', () async {
      final List<int> bounded = await _probe(_blur(bounds: _blueRect));
      final List<int> unbounded = await _probe(_blur());
      _expectSameAs(
        bounded,
        unbounded,
        reason: 'fallback backends ignore blur bounds, like native Skia',
      );
    });
  }, skip: isWimp);
}
