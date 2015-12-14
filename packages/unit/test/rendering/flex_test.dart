// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Overconstrained flex', () {
    RenderDecoratedBox box = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderFlex flex = new RenderFlex(children: <RenderBox>[box]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 200.0, maxWidth: 200.0, minHeight: 200.0, maxHeight: 200.0)
    );

    expect(flex.size.width, equals(200.0), reason: "flex width");
    expect(flex.size.height, equals(200.0), reason: "flex height");
  });

  test('Defaults', () {
    RenderFlex flex = new RenderFlex();
    expect(flex.alignItems, equals(FlexAlignItems.center));
    expect(flex.direction, equals(FlexDirection.horizontal));
  });

  test('Parent data', () {
    RenderDecoratedBox box1 = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderDecoratedBox box2 = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderFlex flex = new RenderFlex(children: <RenderBox>[box1, box2]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 100.0, minHeight: 0.0, maxHeight: 100.0)
    );
    expect(box1.size.width, equals(0.0));
    expect(box1.size.height, equals(0.0));
    expect(box2.size.width, equals(0.0));
    expect(box2.size.height, equals(0.0));

    final FlexParentData box2ParentData = box2.parentData;
    box2ParentData.flex = 1;
    flex.markNeedsLayout();
    pumpFrame();
    expect(box1.size.width, equals(0.0));
    expect(box1.size.height, equals(0.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(0.0));
  });

  test('Stretch', () {
    RenderDecoratedBox box1 = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderDecoratedBox box2 = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderFlex flex = new RenderFlex();
    flex.setupParentData(box2);
    final FlexParentData box2ParentData = box2.parentData;
    box2ParentData.flex = 2;
    flex.addAll(<RenderBox>[box1, box2]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 100.0, minHeight: 0.0, maxHeight: 100.0)
    );
    expect(box1.size.width, equals(0.0));
    expect(box1.size.height, equals(0.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(0.0));

    flex.alignItems = FlexAlignItems.stretch;
    pumpFrame();
    expect(box1.size.width, equals(0.0));
    expect(box1.size.height, equals(100.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(100.0));

    flex.direction = FlexDirection.vertical;
    pumpFrame();
    expect(box1.size.width, equals(100.0));
    expect(box1.size.height, equals(0.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(100.0));
  });
}
