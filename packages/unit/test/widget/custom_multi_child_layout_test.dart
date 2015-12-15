// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestMultiChildLayoutDelegate extends MultiChildLayoutDelegate {
  BoxConstraints getSizeConstraints;

  Size getSize(BoxConstraints constraints) {
    getSizeConstraints = constraints;
    return new Size(200.0, 300.0);
  }

  Size performLayoutSize;
  BoxConstraints performLayoutConstraints;
  Size performLayoutSize0;
  Size performLayoutSize1;
  bool performLayoutIsChild;

  void performLayout(Size size, BoxConstraints constraints) {
    expect(() {
      performLayoutSize = size;
      performLayoutConstraints = constraints;
      performLayoutSize0 = layoutChild(0, constraints);
      performLayoutSize1 = layoutChild(1, constraints);
      performLayoutIsChild = isChild('fred');
    }, returnsNormally);
  }

  bool shouldRelayoutCalled = false;
  bool shouldRelayoutValue = false;
  bool shouldRelayout(_) {
    shouldRelayoutCalled = true;
    return shouldRelayoutValue;
  }
}

Widget buildFrame(MultiChildLayoutDelegate delegate) {
  return new Center(
    child: new CustomMultiChildLayout([
        new LayoutId(id: 0, child: new Container(width: 150.0, height: 100.0)),
        new LayoutId(id: 1, child: new Container(width: 100.0, height: 200.0)),
      ],
      delegate: delegate
    )
  );
}


void main() {
  test('Control test for CustomMultiChildLayout', () {
    testWidgets((WidgetTester tester) {
      TestMultiChildLayoutDelegate delegate = new TestMultiChildLayoutDelegate();
      tester.pumpWidget(buildFrame(delegate));

      expect(delegate.getSizeConstraints.minWidth, 0.0);
      expect(delegate.getSizeConstraints.maxWidth, 800.0);
      expect(delegate.getSizeConstraints.minHeight, 0.0);
      expect(delegate.getSizeConstraints.maxHeight, 600.0);

      expect(delegate.performLayoutSize.width, 200.0);
      expect(delegate.performLayoutSize.height, 300.0);
      expect(delegate.performLayoutConstraints.minWidth, 0.0);
      expect(delegate.performLayoutConstraints.maxWidth, 800.0);
      expect(delegate.performLayoutConstraints.minHeight, 0.0);
      expect(delegate.performLayoutConstraints.maxHeight, 600.0);
      expect(delegate.performLayoutSize0.width, 150.0);
      expect(delegate.performLayoutSize0.height, 100.0);
      expect(delegate.performLayoutSize1.width, 100.0);
      expect(delegate.performLayoutSize1.height, 200.0);
      expect(delegate.performLayoutIsChild, false);
    });
  });

  test('Test MultiChildDelegate shouldRelayout method', () {
    testWidgets((WidgetTester tester) {
      TestMultiChildLayoutDelegate delegate = new TestMultiChildLayoutDelegate();
      tester.pumpWidget(buildFrame(delegate));

      // Layout happened because the delegate was set.
      expect(delegate.performLayoutSize, isNotNull); // i.e. layout happened
      expect(delegate.shouldRelayoutCalled, isFalse);

      // Layout did not happen because shouldRelayout() returned false.
      delegate = new TestMultiChildLayoutDelegate();
      delegate.shouldRelayoutValue = false;
      tester.pumpWidget(buildFrame(delegate));
      expect(delegate.shouldRelayoutCalled, isTrue);
      expect(delegate.performLayoutSize, isNull);

      // Layout happened because shouldRelayout() returned true.
      delegate = new TestMultiChildLayoutDelegate();
      delegate.shouldRelayoutValue = true;
      tester.pumpWidget(buildFrame(delegate));
      expect(delegate.shouldRelayoutCalled, isTrue);
      expect(delegate.performLayoutSize, isNotNull);
    });
  });

  test('Nested CustomMultiChildLayouts', () {
    testWidgets((WidgetTester tester) {
      TestMultiChildLayoutDelegate delegate = new TestMultiChildLayoutDelegate();
      tester.pumpWidget(new Center(
        child: new CustomMultiChildLayout([
          new LayoutId(
            id: 0,
            child: new CustomMultiChildLayout([
              new LayoutId(id: 0, child: new Container(width: 150.0, height: 100.0)),
              new LayoutId(id: 1, child: new Container(width: 100.0, height: 200.0)),
            ], delegate: delegate)
          ),
          new LayoutId(id: 1, child: new Container(width: 100.0, height: 200.0)),
        ], delegate: delegate)
      ));

    });
  });
}
