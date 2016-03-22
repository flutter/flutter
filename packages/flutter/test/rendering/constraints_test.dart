// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test("RenderFractionallySizedBox constraints", () {
    RenderBox root, leaf, test;
    root = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: new BoxConstraints.tight(const Size(200.0, 200.0)),
        child: test = new RenderFractionallySizedBox(
          widthFactor: 2.0,
          heightFactor: 0.5,
          child: leaf = new RenderConstrainedBox(
            additionalConstraints: const BoxConstraints.expand()
          )
        )
      )
    );
    layout(root);
    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));
    expect(test.size.width, equals(200.0));
    expect(test.size.height, equals(200.0));
    expect(leaf.size.width, equals(400.0));
    expect(leaf.size.height, equals(100.0));
  });
}
