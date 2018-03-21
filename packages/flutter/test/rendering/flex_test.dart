// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('Overconstrained flex', () {
    final RenderDecoratedBox box = new RenderDecoratedBox(decoration: const BoxDecoration());
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr, children: <RenderBox>[box]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 200.0, maxWidth: 200.0, minHeight: 200.0, maxHeight: 200.0)
    );

    expect(flex.size.width, equals(200.0), reason: 'flex width');
    expect(flex.size.height, equals(200.0), reason: 'flex height');
  });

  test('Vertical Overflow', () {
    final RenderConstrainedBox flexible = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.expand()
    );
    final RenderFlex flex = new RenderFlex(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      children: <RenderBox>[
        new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(height: 200.0)),
        flexible,
      ]
    );
    final FlexParentData flexParentData = flexible.parentData;
    flexParentData.flex = 1;
    const BoxConstraints viewport = const BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(flex, constraints: viewport);
    expect(flexible.size.height, equals(0.0));
    expect(flex.getMinIntrinsicHeight(100.0), equals(200.0));
    expect(flex.getMaxIntrinsicHeight(100.0), equals(200.0));
    expect(flex.getMinIntrinsicWidth(100.0), equals(0.0));
    expect(flex.getMaxIntrinsicWidth(100.0), equals(0.0));
  });

  test('Horizontal Overflow', () {
    final RenderConstrainedBox flexible = new RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.expand()
    );
    final RenderFlex flex = new RenderFlex(
      direction: Axis.horizontal,
      textDirection: TextDirection.ltr,
      children: <RenderBox>[
        new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 200.0)),
        flexible,
      ]
    );
    final FlexParentData flexParentData = flexible.parentData;
    flexParentData.flex = 1;
    const BoxConstraints viewport = const BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    layout(flex, constraints: viewport);
    expect(flexible.size.width, equals(0.0));
    expect(flex.getMinIntrinsicHeight(100.0), equals(0.0));
    expect(flex.getMaxIntrinsicHeight(100.0), equals(0.0));
    expect(flex.getMinIntrinsicWidth(100.0), equals(200.0));
    expect(flex.getMaxIntrinsicWidth(100.0), equals(200.0));
  });

  test('Vertical Flipped Constraints', () {
    final RenderFlex flex = new RenderFlex(
      direction: Axis.vertical,
      verticalDirection: VerticalDirection.down,
      children: <RenderBox>[
        new RenderAspectRatio(aspectRatio: 1.0),
      ]
    );
    const BoxConstraints viewport = const BoxConstraints(maxHeight: 200.0, maxWidth: 1000.0);
    layout(flex, constraints: viewport);
    expect(flex.getMaxIntrinsicWidth(200.0), equals(0.0));
  });

  // We can't write a horizontal version of the above test due to
  // RenderAspectRatio being height-in, width-out.

  test('Defaults', () {
    final RenderFlex flex = new RenderFlex();
    expect(flex.crossAxisAlignment, equals(CrossAxisAlignment.center));
    expect(flex.direction, equals(Axis.horizontal));
    expect(flex, hasAGoodToStringDeep);
    expect(
      flex.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderFlex#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
        '   parentData: MISSING\n'
        '   constraints: MISSING\n'
        '   size: MISSING\n'
        '   direction: horizontal\n'
        '   mainAxisAlignment: start\n'
        '   mainAxisSize: max\n'
        '   crossAxisAlignment: center\n'
        '   verticalDirection: down\n'
      ),
    );
  });

  test('Parent data', () {
    final RenderDecoratedBox box1 = new RenderDecoratedBox(decoration: const BoxDecoration());
    final RenderDecoratedBox box2 = new RenderDecoratedBox(decoration: const BoxDecoration());
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr, children: <RenderBox>[box1, box2]);
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
    final RenderDecoratedBox box1 = new RenderDecoratedBox(decoration: const BoxDecoration());
    final RenderDecoratedBox box2 = new RenderDecoratedBox(decoration: const BoxDecoration());
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr);
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
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceEvenly);
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      final FlexParentData parentData = box.parentData;
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
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr, mainAxisAlignment: MainAxisAlignment.spaceBetween);
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      final FlexParentData parentData = box.parentData;
      return parentData.offset;
    }
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(100.0));
    expect(getOffset(box2).dx, equals(200.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));

    void setFit(RenderBox box, FlexFit fit) {
      final FlexParentData parentData = box.parentData;
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

    box1.additionalConstraints = const BoxConstraints.tightFor(width: 1000.0, height: 100.0);

    pumpFrame();
    expect(getOffset(box1).dx, equals(0.0));
    expect(box1.size.width, equals(300.0));
    expect(getOffset(box2).dx, equals(300.0));
    expect(box2.size.width, equals(100.0));
    expect(getOffset(box3).dx, equals(400.0));
    expect(box3.size.width, equals(100.0));
  });

  test('Flexible with MainAxisSize.min', () {
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0));
    final RenderFlex flex = new RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 0.0, maxWidth: 500.0, minHeight: 0.0, maxHeight: 400.0)
    );
    Offset getOffset(RenderBox box) {
      final FlexParentData parentData = box.parentData;
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
      final FlexParentData parentData = box.parentData;
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

  test('MainAxisSize.min inside unconstrained', () {
    FlutterError.onError = (FlutterErrorDetails details) => throw details.exception;
    const BoxConstraints square = const BoxConstraints.tightFor(width: 100.0, height: 100.0);
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderFlex flex = new RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
    );
    final RenderConstrainedOverflowBox parent = new RenderConstrainedOverflowBox(
      minWidth: 0.0,
      maxWidth: double.infinity,
      minHeight: 0.0,
      maxHeight: 400.0,
      child: flex,
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(parent);
    expect(flex.size, const Size(300.0, 100.0));
    final FlexParentData box2ParentData = box2.parentData;
    box2ParentData.flex = 1;
    box2ParentData.fit = FlexFit.loose;
    flex.markNeedsLayout();
    pumpFrame();
    expect(flex.size, const Size(300.0, 100.0));
    parent.maxWidth = 500.0; // NOW WITH CONSTRAINED BOUNDARIES
    pumpFrame();
    expect(flex.size, const Size(300.0, 100.0));
    flex.mainAxisSize = MainAxisSize.max;
    pumpFrame();
    expect(flex.size, const Size(500.0, 100.0));
    flex.mainAxisSize = MainAxisSize.min;
    box2ParentData.fit = FlexFit.tight;
    flex.markNeedsLayout();
    pumpFrame();
    expect(flex.size, const Size(500.0, 100.0));
    parent.maxWidth = 505.0;
    pumpFrame();
    expect(flex.size, const Size(505.0, 100.0));
  });

  test('MainAxisSize.min inside unconstrained', () {
    final List<dynamic> exceptions = <dynamic>[];
    FlutterError.onError = (FlutterErrorDetails details) {
      exceptions.add(details.exception);
    };
    const BoxConstraints square = const BoxConstraints.tightFor(width: 100.0, height: 100.0);
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderFlex flex = new RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
    );
    final RenderConstrainedOverflowBox parent = new RenderConstrainedOverflowBox(
      minWidth: 0.0,
      maxWidth: double.infinity,
      minHeight: 0.0,
      maxHeight: 400.0,
      child: flex,
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    final FlexParentData box2ParentData = box2.parentData;
    box2ParentData.flex = 1;
    expect(exceptions, isEmpty);
    layout(parent);
    expect(exceptions, isNotEmpty);
    expect(exceptions.first, const isInstanceOf<FlutterError>());
  });

  test('MainAxisSize.min inside unconstrained', () {
    final List<dynamic> exceptions = <dynamic>[];
    FlutterError.onError = (FlutterErrorDetails details) {
      exceptions.add(details.exception);
    };
    const BoxConstraints square = const BoxConstraints.tightFor(width: 100.0, height: 100.0);
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderFlex flex = new RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisSize: MainAxisSize.max,
    );
    final RenderConstrainedOverflowBox parent = new RenderConstrainedOverflowBox(
      minWidth: 0.0,
      maxWidth: double.infinity,
      minHeight: 0.0,
      maxHeight: 400.0,
      child: flex,
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    final FlexParentData box2ParentData = box2.parentData;
    box2ParentData.flex = 1;
    box2ParentData.fit = FlexFit.loose;
    expect(exceptions, isEmpty);
    layout(parent);
    expect(exceptions, isNotEmpty);
    expect(exceptions.first, const isInstanceOf<FlutterError>());
  });

  test('MainAxisSize.min inside tightly constrained', () {
    const BoxConstraints square = const BoxConstraints.tightFor(width: 100.0, height: 100.0);
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderFlex flex = new RenderFlex(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
    );
    flex.addAll(<RenderBox>[box1, box2, box3]);
    layout(flex);
    expect(flex.constraints.hasTightWidth, isTrue);
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 250.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 250.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 250.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));
  });

  test('Flex RTL', () {
    const BoxConstraints square = const BoxConstraints.tightFor(width: 100.0, height: 100.0);
    final RenderConstrainedBox box1 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box2 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderConstrainedBox box3 = new RenderConstrainedBox(additionalConstraints: square);
    final RenderFlex flex = new RenderFlex(textDirection: TextDirection.ltr, children: <RenderBox>[box1, box2, box3]);
    layout(flex);
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 250.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 250.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 250.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.mainAxisAlignment = MainAxisAlignment.end;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 250.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 250.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 250.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.textDirection = TextDirection.rtl;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(200.0, 250.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(100.0, 250.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 250.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.mainAxisAlignment = MainAxisAlignment.start;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 250.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 250.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 250.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.start; // vertical direction is down
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.end;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 500.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 500.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.verticalDirection = VerticalDirection.up;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 0.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 0.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.start;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(600.0, 500.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(500.0, 500.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.direction = Axis.vertical; // and main=start, cross=start, up, rtl
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 300.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.end;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.stretch;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(box1.size, const Size(800.0, 100.0));
    expect(box2.size, const Size(800.0, 100.0));
    expect(box3.size, const Size(800.0, 100.0));

    flex.textDirection = TextDirection.ltr;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(box1.size, const Size(800.0, 100.0));
    expect(box2.size, const Size(800.0, 100.0));
    expect(box3.size, const Size(800.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.start;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(0.0, 300.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.crossAxisAlignment = CrossAxisAlignment.end;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 500.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 300.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.verticalDirection = VerticalDirection.down;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 0.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 100.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 200.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));

    flex.mainAxisAlignment = MainAxisAlignment.end;
    pumpFrame();
    expect(box1.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 300.0));
    expect(box2.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 400.0));
    expect(box3.localToGlobal(const Offset(0.0, 0.0)), const Offset(700.0, 500.0));
    expect(box1.size, const Size(100.0, 100.0));
    expect(box2.size, const Size(100.0, 100.0));
    expect(box3.size, const Size(100.0, 100.0));
  });
}
