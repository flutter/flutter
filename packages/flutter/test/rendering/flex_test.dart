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

  test('Vertical Overflow', () {
    RenderConstrainedBox flexible = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.expand()
    );
    RenderFlex flex = new RenderFlex(
      direction: Axis.vertical,
      children: <RenderBox>[
        new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(height: 200.0)),
        flexible,
      ]
    );
    FlexParentData flexParentData = flexible.parentData;
    flexParentData.flex = 1;
    BoxConstraints viewport = new BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(flex, constraints: viewport);
    expect(flexible.size.height, equals(0.0));
    expect(flex.getMinIntrinsicHeight(100.0), equals(200.0));
    expect(flex.getMaxIntrinsicHeight(100.0), equals(200.0));
    expect(flex.getMinIntrinsicWidth(100.0), equals(0.0));
    expect(flex.getMaxIntrinsicWidth(100.0), equals(0.0));
  });

  test('Horizontal Overflow', () {
    RenderConstrainedBox flexible = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.expand()
    );
    RenderFlex flex = new RenderFlex(
      direction: Axis.horizontal,
      children: <RenderBox>[
        new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 200.0)),
        flexible,
      ]
    );
    FlexParentData flexParentData = flexible.parentData;
    flexParentData.flex = 1;
    BoxConstraints viewport = new BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(flex, constraints: viewport);
    expect(flexible.size.width, equals(0.0));
    expect(flex.getMinIntrinsicHeight(100.0), equals(0.0));
    expect(flex.getMaxIntrinsicHeight(100.0), equals(0.0));
    expect(flex.getMinIntrinsicWidth(100.0), equals(200.0));
    expect(flex.getMaxIntrinsicWidth(100.0), equals(200.0));
  });

  test('Vertical Flipped Constraints', () {
    RenderFlex flex = new RenderFlex(
      direction: Axis.vertical,
      children: <RenderBox>[
        new RenderAspectRatio(aspectRatio: 1.0),
      ]
    );
    BoxConstraints viewport = new BoxConstraints(maxHeight: 200.0, maxWidth: 1000.0);
    layout(flex, constraints: viewport);
    expect(flex.getMaxIntrinsicWidth(200.0), equals(0.0));
  });

  // We can't right a horizontal version of the above test due to
  // RenderAspectRatio being height-in, width-out.

  test('Defaults', () {
    RenderFlex flex = new RenderFlex();
    expect(flex.crossAxisAlignment, equals(CrossAxisAlignment.center));
    expect(flex.direction, equals(Axis.horizontal));
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

    flex.crossAxisAlignment = CrossAxisAlignment.stretch;
    pumpFrame();
    expect(box1.size.width, equals(0.0));
    expect(box1.size.height, equals(100.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(100.0));

    flex.direction = Axis.vertical;
    pumpFrame();
    expect(box1.size.width, equals(100.0));
    expect(box1.size.height, equals(0.0));
    expect(box2.size.width, equals(100.0));
    expect(box2.size.height, equals(100.0));
  });

  test('Space evenly', () {
    RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderFlex flex = new RenderFlex(mainAxisAlignment: MainAxisAlignment.spaceEvenly);
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      FlexParentData parentData = box.parentData;
      return parentData.offset;
    }
    expect(getOffset(box1).dx, equals(50.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(200.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(350.0));
    expect(box3.size.width, equals(100.0));

    flex.direction = Axis.vertical;
    pumpFrame();
    expect(getOffset(box1).dy, equals(25.0));
    expect(box1.size.height, equals(100.0));
    expect(getOffset(box2).dy, equals(150.0));
    expect(box2.size.height, equals(100.0));
    expect(getOffset(box3).dy, equals(275.0));
    expect(box3.size.height, equals(100.0));
  });

  test('Fit.loose', () {
    RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderFlex flex = new RenderFlex(mainAxisAlignment: MainAxisAlignment.spaceBetween);
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      FlexParentData parentData = box.parentData;
      return parentData.offset;
    }
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(200.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));

    void setFit(RenderBox box, FlexFit fit) {
      FlexParentData parentData = box.parentData;
      parentData.flex = 1;
      parentData.fit = fit;
    }

    setFit(box1, FlexFit.loose);
    flex.markNeedsLayout();

    pumpFrame();
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(200.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));

    box1.additionalConstraints = new BoxConstraints.tightFor(width: 1000.0, height: 100.0);

    pumpFrame();
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(300.0));
    expect(getOffset(box2).dx, equals(300.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));
  });

  test('Flexible with MainAxisSize.min', () {
    RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: new BoxConstraints.tightFor(width: 100.0, height: 100.0));
    RenderFlex flex = new RenderFlex(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      FlexParentData parentData = box.parentData;
      return parentData.offset;
    }
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(100.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(200.0));
    expect(box3.size.width, equals(100.0));
    expect(flex.size.width, equals(300.0));

    void setFit(RenderBox box, FlexFit fit) {
      FlexParentData parentData = box.parentData;
      parentData.flex = 1;
      parentData.fit = fit;
    }

    setFit(box1, FlexFit.tight);
    flex.markNeedsLayout();

    pumpFrame();
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(300.0));
    expect(getOffset(box2).dx, equals(300.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));
    expect(flex.size.width, equals(500.0));

    setFit(box1, FlexFit.loose);
    flex.markNeedsLayout();

    pumpFrame();
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(100.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(200.0));
    expect(box3.size.width, equals(100.0));
    expect(flex.size.width, equals(300.0));
  });
}
