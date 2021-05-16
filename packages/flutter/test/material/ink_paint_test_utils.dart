// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

PaintPatternPredicate _ripplePatternPredicate(Offset? expectedCenter, double? expectedRadius, Color? expectedColor, int? expectedAlpha, bool unique) {
  String formattedValues(Offset? center, double? radius, Color? color, int? alpha) => <String>[
        if (expectedCenter != null) 'center: $center',
        if (expectedRadius != null) 'radius: ${(radius! * 10).truncateToDouble() / 10}',
        if (expectedColor != null) 'color: $color',
        if (expectedAlpha != null) 'alpha: $alpha',
      ].join(', ');

  return (Symbol method, List<dynamic> arguments) {
    if (method != #drawCircle) {
      return unique; //
    }
    final Offset center = arguments[0] as Offset;
    final double radius = arguments[1] as double;
    final Color color = (arguments[2] as Paint).color;
    final int alpha = color.alpha;

    // Any alpha passed to this predicate overrides the alpha baked into the expected color.
    // This should make it easier to test that the color of ripples don't change, but the alphas do.
    final Color? expectedColorWithAlpha = expectedColor?.withAlpha(expectedAlpha ?? expectedColor.alpha);

    if ((expectedCenter == null || (center - expectedCenter).distanceSquared < 1.0) &&
        (expectedRadius == null || (radius - expectedRadius).abs() < 1.0) &&
        (expectedColorWithAlpha == null || color == expectedColorWithAlpha) &&
        (expectedAlpha == null || alpha == expectedAlpha)) {
      return true;
    }
    throw '''

Expected - ${formattedValues(expectedCenter, expectedRadius, expectedColorWithAlpha, expectedAlpha)}
   Found - ${formattedValues(center, radius, color, alpha)}''';
  };
}

PaintPattern paintsRipple({Offset? tapDown, Offset? center, double? radius, Color? color, int? alpha, bool unique = false}) {
  final PaintPattern pattern = paints;
  if (tapDown != null) {
    pattern.translate(x: 0, y: 0);
    pattern.translate(x: tapDown.dx, y: tapDown.dy);
  }
  final PaintPatternPredicate predicate = _ripplePatternPredicate(center, radius, color, alpha, unique);
  unique ? pattern.everything(predicate) : pattern.something(predicate);
  return pattern;
}

MaterialInkController getMaterialInkController<T>(WidgetTester tester) {
  return Material.of(tester.element(find.byType(T)))!;
}

RenderObject getInkFeatures(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
}
