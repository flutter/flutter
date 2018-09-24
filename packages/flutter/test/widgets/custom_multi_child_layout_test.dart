// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TestMultiChildLayoutDelegate extends MultiChildLayoutDelegate {
  BoxConstraints getSizeConstraints;

  @override
  Size getSize(BoxConstraints constraints) {
    if (!RenderObject.debugCheckingIntrinsics)
      getSizeConstraints = constraints;
    return const Size(200.0, 300.0);
  }

  Size performLayoutSize;
  Size performLayoutSize0;
  Size performLayoutSize1;
  bool performLayoutIsChild;

  @override
  void performLayout(Size size) {
    assert(!RenderObject.debugCheckingIntrinsics);
    expect(() {
      performLayoutSize = size;
      final BoxConstraints constraints = BoxConstraints.loose(size);
      performLayoutSize0 = layoutChild(0, constraints);
      performLayoutSize1 = layoutChild(1, constraints);
      performLayoutIsChild = hasChild('fred');
    }, returnsNormally);
  }

  bool shouldRelayoutCalled = false;
  bool shouldRelayoutValue = false;

  @override
  bool shouldRelayout(_) {
    assert(!RenderObject.debugCheckingIntrinsics);
    shouldRelayoutCalled = true;
    return shouldRelayoutValue;
  }
}

Widget buildFrame(MultiChildLayoutDelegate delegate) {
  return Center(
    child: CustomMultiChildLayout(
      children: <Widget>[
        LayoutId(id: 0, child: Container(width: 150.0, height: 100.0)),
        LayoutId(id: 1, child: Container(width: 100.0, height: 200.0)),
      ],
      delegate: delegate
    )
  );
}

class PreferredSizeDelegate extends MultiChildLayoutDelegate {
  PreferredSizeDelegate({ this.preferredSize });

  final Size preferredSize;

  @override
  Size getSize(BoxConstraints constraints) => preferredSize;

  @override
  void performLayout(Size size) { }

  @override
  bool shouldRelayout(PreferredSizeDelegate oldDelegate) {
    return preferredSize != oldDelegate.preferredSize;
  }
}

void main() {
  testWidgets('Control test for CustomMultiChildLayout', (WidgetTester tester) async {
    final TestMultiChildLayoutDelegate delegate = TestMultiChildLayoutDelegate();
    await tester.pumpWidget(buildFrame(delegate));

    expect(delegate.getSizeConstraints.minWidth, 0.0);
    expect(delegate.getSizeConstraints.maxWidth, 800.0);
    expect(delegate.getSizeConstraints.minHeight, 0.0);
    expect(delegate.getSizeConstraints.maxHeight, 600.0);

    expect(delegate.performLayoutSize.width, 200.0);
    expect(delegate.performLayoutSize.height, 300.0);
    expect(delegate.performLayoutSize0.width, 150.0);
    expect(delegate.performLayoutSize0.height, 100.0);
    expect(delegate.performLayoutSize1.width, 100.0);
    expect(delegate.performLayoutSize1.height, 200.0);
    expect(delegate.performLayoutIsChild, false);
  });

  testWidgets('Test MultiChildDelegate shouldRelayout method', (WidgetTester tester) async {
    TestMultiChildLayoutDelegate delegate = TestMultiChildLayoutDelegate();
    await tester.pumpWidget(buildFrame(delegate));

    // Layout happened because the delegate was set.
    expect(delegate.performLayoutSize, isNotNull); // i.e. layout happened
    expect(delegate.shouldRelayoutCalled, isFalse);

    // Layout did not happen because shouldRelayout() returned false.
    delegate = TestMultiChildLayoutDelegate();
    delegate.shouldRelayoutValue = false;
    await tester.pumpWidget(buildFrame(delegate));
    expect(delegate.shouldRelayoutCalled, isTrue);
    expect(delegate.performLayoutSize, isNull);

    // Layout happened because shouldRelayout() returned true.
    delegate = TestMultiChildLayoutDelegate();
    delegate.shouldRelayoutValue = true;
    await tester.pumpWidget(buildFrame(delegate));
    expect(delegate.shouldRelayoutCalled, isTrue);
    expect(delegate.performLayoutSize, isNotNull);
  });

  testWidgets('Nested CustomMultiChildLayouts', (WidgetTester tester) async {
    final TestMultiChildLayoutDelegate delegate = TestMultiChildLayoutDelegate();
    await tester.pumpWidget(Center(
      child: CustomMultiChildLayout(
        children: <Widget>[
          LayoutId(
            id: 0,
            child: CustomMultiChildLayout(
              children: <Widget>[
                LayoutId(id: 0, child: Container(width: 150.0, height: 100.0)),
                LayoutId(id: 1, child: Container(width: 100.0, height: 200.0)),
              ],
              delegate: delegate
            )
          ),
          LayoutId(id: 1, child: Container(width: 100.0, height: 200.0)),
        ],
        delegate: delegate
      )
    ));

  });

  testWidgets('Loose constraints', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(Center(
      child: CustomMultiChildLayout(
        key: key,
        delegate: PreferredSizeDelegate(preferredSize: const Size(300.0, 200.0))
      )
    ));

    final RenderBox box = tester.renderObject(find.byKey(key));
    expect(box.size.width, equals(300.0));
    expect(box.size.height, equals(200.0));

    await tester.pumpWidget(Center(
      child: CustomMultiChildLayout(
        key: key,
        delegate: PreferredSizeDelegate(preferredSize: const Size(350.0, 250.0))
      )
    ));

    expect(box.size.width, equals(350.0));
    expect(box.size.height, equals(250.0));
  });
}
