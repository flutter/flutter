// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../canvaskit/canvaskit_api.dart';
import 'paragraph.dart';

class BidiRun {
  BidiRun(this.clusterRange, this.bidiLevel);

  final int bidiLevel;
  final ClusterRange clusterRange;

  bool get isLtr => bidiLevel.isEven;
  bool get isRtl => !isLtr;
}

extension VisualOrder on List<BidiRun> {
  /// Returns a sublist of [BidiRun] that's ordered visually.
  ///
  /// [start] inclusive, [end] exclusive.
  Iterable<BidiRun> inVisualOrder(int start, int end) {
    final levels = Uint8List(end - start);
    for (int i = 0; i < levels.length; i++) {
      levels[i] = this[start + i].bidiLevel;
    }
    // TODO(jlavrova): We need to think about how to support this for Skwasm without calling Canvaskit.
    final visuals = canvasKit.Bidi.reorderVisual(levels);
    return visuals.map((BidiIndex visual) => this[start + visual.index]);
  }
}
