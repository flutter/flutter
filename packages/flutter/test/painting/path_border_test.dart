// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('PathBorder', () {
    final Rect testRect = Rect.fromLTWH(0, 0, 20, 20);
    final List<Offset> testRectOffsets = <Offset>[
      testRect.topCenter,
      testRect.topLeft,
      testRect.topRight,
      testRect.bottomCenter,
      testRect.bottomLeft,
      testRect.bottomRight,
    ];
    final PathBorder p10 = PathBorder(
      pathBuilder: (Rect boundary, TextDirection textDirection) => Path()..addRect(boundary),
      border: const BorderSide(width: 10.0),
    );
    final PathBorder p20 = PathBorder.withPaint(
      pathBuilder: (Rect boundary, TextDirection textDirection) => Path()..addRect(boundary),
      pathPaint: Paint()..strokeWidth = 20.0..style = PaintingStyle.stroke,
    );
    expect(p10.dimensions, const EdgeInsets.all(10.0));
    expect(p10.scale(2.0).dimensions, p20.dimensions);
    expect(p20.scale(0.5).dimensions, p10.dimensions);
    expect(p10.getInnerPath(testRect), isPathThat(includes: testRectOffsets));
    expect(p10.getOuterPath(testRect), isPathThat(includes: testRectOffsets));
    expect(
      (Canvas canvas) => p10.paint(canvas, testRect),
      paints
        ..path(includes: testRectOffsets, strokeWidth: 10.0, style: PaintingStyle.stroke),
    );
  });
}
