// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderPositionedBox expands', () {
    final RenderConstrainedBox sizer = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      child: RenderDecoratedBox(decoration: const BoxDecoration())
    );
    final RenderPositionedBox positioner = RenderPositionedBox(child: sizer);
    layout(positioner, constraints: BoxConstraints.loose(const Size(200.0, 200.0)));

    expect(positioner.size.width, equals(200.0), reason: 'positioner width');
    expect(positioner.size.height, equals(200.0), reason: 'positioner height');
  });

  test('RenderPositionedBox shrink wraps', () {
    final RenderConstrainedBox sizer = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      child: RenderDecoratedBox(decoration: const BoxDecoration())
    );
    final RenderPositionedBox positioner = RenderPositionedBox(child: sizer, widthFactor: 1.0);
    layout(positioner, constraints: BoxConstraints.loose(const Size(200.0, 200.0)));

    expect(positioner.size.width, equals(100.0), reason: 'positioner width');
    expect(positioner.size.height, equals(200.0), reason: 'positioner height');

    positioner.widthFactor = null;
    positioner.heightFactor = 1.0;
    pumpFrame();

    expect(positioner.size.width, equals(200.0), reason: 'positioner width');
    expect(positioner.size.height, equals(100.0), reason: 'positioner height');

    positioner.widthFactor = 1.0;
    pumpFrame();

    expect(positioner.size.width, equals(100.0), reason: 'positioner width');
    expect(positioner.size.height, equals(100.0), reason: 'positioner height');
  });

  test('RenderPositionedBox width and height factors', () {
    final RenderConstrainedBox sizer = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      child: RenderDecoratedBox(decoration: const BoxDecoration())
    );
    final RenderPositionedBox positioner = RenderPositionedBox(child: sizer, widthFactor: 1.0, heightFactor: 0.0);
    layout(positioner, constraints: BoxConstraints.loose(const Size(200.0, 200.0)));

    expect(positioner.size.width, equals(100.0));
    expect(positioner.size.height, equals(0.0));

    positioner.widthFactor = 0.5;
    positioner.heightFactor = 0.5;
    pumpFrame();

    expect(positioner.size.width, equals(50.0));
    expect(positioner.size.height, equals(50.0));

    positioner.widthFactor = null;
    positioner.heightFactor = null;
    pumpFrame();

    expect(positioner.size.width, equals(200.0));
    expect(positioner.size.height, equals(200.0));
  });
}
