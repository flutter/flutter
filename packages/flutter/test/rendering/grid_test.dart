// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Basic grid layout test', () {
    List<RenderBox> children = <RenderBox>[
      new RenderDecoratedBox(decoration: const BoxDecoration()),
      new RenderDecoratedBox(decoration: const BoxDecoration()),
      new RenderDecoratedBox(decoration: const BoxDecoration()),
      new RenderDecoratedBox(decoration: const BoxDecoration())
    ];

    RenderGrid grid = new RenderGrid(
      children: children,
      delegate: new MaxTileWidthGridDelegate(maxTileWidth: 100.0)
    );
    layout(grid, constraints: const BoxConstraints(maxWidth: 200.0));

    children.forEach((RenderBox child) {
      expect(child.size.width, equals(100.0), reason: "child width");
      expect(child.size.height, equals(100.0), reason: "child height");
    });

    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(200.0), reason: "grid height");

    expect(grid.debugNeedsLayout, false);
    grid.delegate = new MaxTileWidthGridDelegate(maxTileWidth: 60.0);
    expect(grid.debugNeedsLayout, true);

    pumpFrame();

    children.forEach((RenderBox child) {
      expect(child.size.width, equals(50.0), reason: "child width");
      expect(child.size.height, equals(50.0), reason: "child height");
    });

    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(50.0), reason: "grid height");
  });
}
