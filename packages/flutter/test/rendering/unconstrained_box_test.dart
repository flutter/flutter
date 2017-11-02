// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('expands to fit children', () {
    final RenderUnconstrainedBox unconstrained = new RenderUnconstrainedBox(
      textDirection: TextDirection.ltr,
      child: new RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 200.0, height: 200.0),
      ),
      alignment: Alignment.center,
    );
    layout(
      unconstrained,
      constraints: const BoxConstraints(
        minWidth: 200.0,
        maxWidth: 200.0,
        minHeight: 200.0,
        maxHeight: 200.0,
      ),
    );

    expect(unconstrained.size.width, equals(200.0), reason: 'unconstrained width');
    expect(unconstrained.size.height, equals(200.0), reason: 'unconstrained height');
  });

  test('handles vertical overflow', () {
    final RenderUnconstrainedBox unconstrained = new RenderUnconstrainedBox(
      textDirection: TextDirection.ltr,
      child: new RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(height: 200.0),
      ),
      alignment: Alignment.center,
    );
    final BoxConstraints viewport = const BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(unconstrained, constraints: viewport);
    expect(unconstrained.getMinIntrinsicHeight(100.0), equals(200.0));
    expect(unconstrained.getMaxIntrinsicHeight(100.0), equals(200.0));
    expect(unconstrained.getMinIntrinsicWidth(100.0), equals(0.0));
    expect(unconstrained.getMaxIntrinsicWidth(100.0), equals(0.0));
  });

  test('handles horizontal overflow', () {
    final RenderUnconstrainedBox unconstrained = new RenderUnconstrainedBox(
      textDirection: TextDirection.ltr,
      child: new RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 200.0),
      ),
      alignment: Alignment.center,
    );
    final BoxConstraints viewport = const BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(unconstrained, constraints: viewport);
    expect(unconstrained.getMinIntrinsicHeight(100.0), equals(0.0));
    expect(unconstrained.getMaxIntrinsicHeight(100.0), equals(0.0));
    expect(unconstrained.getMinIntrinsicWidth(100.0), equals(200.0));
    expect(unconstrained.getMaxIntrinsicWidth(100.0), equals(200.0));
  });

  test('toStringDeep returns useful information', () {
    final RenderUnconstrainedBox unconstrained = new RenderUnconstrainedBox(
      textDirection: TextDirection.ltr,
      alignment: Alignment.center,
    );
    expect(unconstrained.alignment, Alignment.center);
    expect(unconstrained.textDirection, TextDirection.ltr);
    expect(unconstrained, hasAGoodToStringDeep);
    expect(
      unconstrained.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
          'RenderUnconstrainedBox#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
          '   parentData: MISSING\n'
          '   constraints: MISSING\n'
          '   size: MISSING\n'
          '   alignment: center\n'
          '   textDirection: ltr\n'),
    );
  });
}
