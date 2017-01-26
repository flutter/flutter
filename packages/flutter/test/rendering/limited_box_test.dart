// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('LimitedBox: parent max size is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderConstrainedOverflowBox(
      minWidth: 0.0,
      maxWidth: double.INFINITY,
      minHeight: 0.0,
      maxHeight: double.INFINITY,
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

  test('LimitedBox: parent maxWidth is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderConstrainedOverflowBox(
      minWidth: 0.0,
      maxWidth: double.INFINITY,
      minHeight: 500.0,
      maxHeight: 500.0,
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

  test('LimitedBox: parent maxHeight is unconstrained', () {
    RenderBox child = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 300.0, height: 400.0)
    );
    RenderBox parent = new RenderConstrainedOverflowBox(
      minWidth: 500.0,
      maxWidth: 500.0,
      minHeight: 0.0,
      maxHeight: double.INFINITY,
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

  test('LimitedBox: no child', () {
    RenderBox box;
    RenderBox parent = new RenderConstrainedOverflowBox(
      minWidth: 10.0,
      maxWidth: 500.0,
      minHeight: 0.0,
      maxHeight: double.INFINITY,
      child: box = new RenderLimitedBox(
        maxWidth: 100.0,
        maxHeight: 200.0,
      )
    );
    layout(parent);
    expect(box.size, const Size(10.0, 0.0));
  });
}
