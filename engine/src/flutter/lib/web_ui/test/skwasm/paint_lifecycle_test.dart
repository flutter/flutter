// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

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
    expect(_livePaintCount(), baseline, reason: 'after recording');

    final ui.Image rendered = await picture.toImage(20, 20);
    expect(_livePaintCount(), baseline, reason: 'after rendering');

    rendered.dispose();
    picture.dispose();
    consumers.dispose();
    expect(_livePaintCount(), baseline, reason: 'after disposing');
  });
}
