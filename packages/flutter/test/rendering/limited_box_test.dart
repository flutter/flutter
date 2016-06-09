// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

class TestLayoutDelegate extends SingleChildLayoutDelegate {
  TestLayoutDelegate(this.childConstraints);

  final BoxConstraints childConstraints;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => childConstraints;

  @override
  bool shouldRelayout(TestLayoutDelegate oldDelegate) => childConstraints != oldDelegate.childConstraints;
}

void main() {
  test('parent max size is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderCustomSingleChildLayoutBox(
      delegate: new TestLayoutDelegate(const BoxConstraints()),
      child: new RenderLimitedBox(
        maxWidth: 100.0,
        maxHeight: 200.0,
        child: child
      )
    );
    layout(parent);
    expect(child.size.width, 100.0);
    expect(child.size.height, 200.0);
  });

  test('parent maxWidth is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderCustomSingleChildLayoutBox(
      delegate: new TestLayoutDelegate(const BoxConstraints.tightFor(height: 500.0)),
      child: new RenderLimitedBox(
        maxWidth: 100.0,
        maxHeight: 200.0,
        child: child
      )
    );
    layout(parent);
    expect(child.size.width, 100.0);
    expect(child.size.height, 500.0);
  });

  test('parent maxHeight is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderCustomSingleChildLayoutBox(
      delegate: new TestLayoutDelegate(const BoxConstraints.tightFor(width: 500.0)),
      child: new RenderLimitedBox(
        maxWidth: 100.0,
        maxHeight: 200.0,
        child: child
      )
    );
    layout(parent);

    expect(child.size.width, 500.0);
    expect(child.size.height, 200.0);
  });
}
