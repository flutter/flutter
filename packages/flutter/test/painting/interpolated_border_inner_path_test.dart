// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (double strokeAlign, double inset) in <(double, double)>[
    (BorderSide.strokeAlignInside, 10.0),
    (BorderSide.strokeAlignCenter, 5.0),
    (BorderSide.strokeAlignOutside, 0.0),
  ]) {
    final side = BorderSide(width: 10.0, strokeAlign: strokeAlign);
    for (final (OutlinedBorder start, OutlinedBorder end) in <(OutlinedBorder, OutlinedBorder)>[
      (StadiumBorder(side: side), RoundedRectangleBorder(side: side)),
      (RoundedRectangleBorder(side: side), CircleBorder(side: side)),
      (RoundedSuperellipseBorder(side: side), CircleBorder(side: side)),
    ]) {
      test(
        '${start.runtimeType} to ${end.runtimeType} inner path with strokeAlign $strokeAlign',
        () {
          const rect = Rect.fromLTWH(10.0, 20.0, 100.0, 100.0);
          for (final t in <double>[0.25, 0.5, 0.75]) {
            final ShapeBorder border = ShapeBorder.lerp(start, end, t)!;
            final Path innerPath = border.getInnerPath(rect);
            expect(innerPath.getBounds(), rect.deflate(inset));
            expect(innerPath.contains(Offset(rect.left + inset + 1.0, rect.center.dy)), isTrue);
            expect(innerPath.contains(Offset(rect.left + inset - 1.0, rect.center.dy)), isFalse);
          }
        },
      );
    }
  }
}
