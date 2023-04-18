// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSingleChildLayoutDelegate extends SingleChildLayoutDelegate {
  late BoxConstraints constraintsFromGetSize;
  BoxConstraints? constraintsFromGetConstraintsForChild;
  late Size sizeFromGetPositionForChild;
  late Size childSizeFromGetPositionForChild;

  @override
  Size getSize(final BoxConstraints constraints) {
    if (!RenderObject.debugCheckingIntrinsics) {
      constraintsFromGetSize = constraints;
    }
    return const Size(200.0, 300.0);
  }

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) {
    assert(!RenderObject.debugCheckingIntrinsics);
    constraintsFromGetConstraintsForChild = constraints;
    return const BoxConstraints(minWidth: 100.0, maxWidth: 150.0, minHeight: 200.0, maxHeight: 400.0);
  }

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    assert(!RenderObject.debugCheckingIntrinsics);
    sizeFromGetPositionForChild = size;
    childSizeFromGetPositionForChild = childSize;
    return Offset.zero;
  }

  bool shouldRelayoutCalled = false;
  bool shouldRelayoutValue = false;

  @override
  bool shouldRelayout(final _) {
    assert(!RenderObject.debugCheckingIntrinsics);
    shouldRelayoutCalled = true;
    return shouldRelayoutValue;
  }
}

class FixedSizeLayoutDelegate extends SingleChildLayoutDelegate {
  FixedSizeLayoutDelegate(this.size);

  final Size size;

  @override
  Size getSize(final BoxConstraints constraints) => size;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) {
    return BoxConstraints.tight(size);
  }

  @override
  bool shouldRelayout(final FixedSizeLayoutDelegate oldDelegate) {
    return size != oldDelegate.size;
  }
}

class NotifierLayoutDelegate extends SingleChildLayoutDelegate {
  NotifierLayoutDelegate(this.size) : super(relayout: size);

  final ValueNotifier<Size> size;

  @override
  Size getSize(final BoxConstraints constraints) => size.value;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) {
    return BoxConstraints.tight(size.value);
  }

  @override
  bool shouldRelayout(final NotifierLayoutDelegate oldDelegate) {
    return size != oldDelegate.size;
  }
}

Widget buildFrame(final SingleChildLayoutDelegate delegate) {
  return Center(
    child: CustomSingleChildLayout(
      delegate: delegate,
      child: Container(),
    ),
  );
}

void main() {
  testWidgets('Control test for CustomSingleChildLayout', (final WidgetTester tester) async {
    final TestSingleChildLayoutDelegate delegate = TestSingleChildLayoutDelegate();
    await tester.pumpWidget(buildFrame(delegate));

    expect(delegate.constraintsFromGetSize.minWidth, 0.0);
    expect(delegate.constraintsFromGetSize.maxWidth, 800.0);
    expect(delegate.constraintsFromGetSize.minHeight, 0.0);
    expect(delegate.constraintsFromGetSize.maxHeight, 600.0);

    expect(delegate.constraintsFromGetConstraintsForChild!.minWidth, 0.0);
    expect(delegate.constraintsFromGetConstraintsForChild!.maxWidth, 800.0);
    expect(delegate.constraintsFromGetConstraintsForChild!.minHeight, 0.0);
    expect(delegate.constraintsFromGetConstraintsForChild!.maxHeight, 600.0);

    expect(delegate.sizeFromGetPositionForChild.width, 200.0);
    expect(delegate.sizeFromGetPositionForChild.height, 300.0);

    expect(delegate.childSizeFromGetPositionForChild.width, 150.0);
    expect(delegate.childSizeFromGetPositionForChild.height, 400.0);
  });

  testWidgets('Test SingleChildDelegate shouldRelayout method', (final WidgetTester tester) async {
    TestSingleChildLayoutDelegate delegate =
        TestSingleChildLayoutDelegate();
    await tester.pumpWidget(buildFrame(delegate));

    // Layout happened because the delegate was set.
    expect(delegate.constraintsFromGetConstraintsForChild, isNotNull); // i.e. layout happened
    expect(delegate.shouldRelayoutCalled, isFalse);

    // Layout did not happen because shouldRelayout() returned false.
    delegate = TestSingleChildLayoutDelegate();
    delegate.shouldRelayoutValue = false;
    await tester.pumpWidget(buildFrame(delegate));
    expect(delegate.shouldRelayoutCalled, isTrue);
    expect(delegate.constraintsFromGetConstraintsForChild, isNull);

    // Layout happened because shouldRelayout() returned true.
    delegate = TestSingleChildLayoutDelegate();
    delegate.shouldRelayoutValue = true;
    await tester.pumpWidget(buildFrame(delegate));
    expect(delegate.shouldRelayoutCalled, isTrue);
    expect(delegate.constraintsFromGetConstraintsForChild, isNotNull);
  });

  testWidgets('Delegate can change size', (final WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(FixedSizeLayoutDelegate(const Size(100.0, 200.0))));

    RenderBox box = tester.renderObject(find.byType(CustomSingleChildLayout));
    expect(box.size, equals(const Size(100.0, 200.0)));

    await tester.pumpWidget(buildFrame(FixedSizeLayoutDelegate(const Size(150.0, 240.0))));

    box = tester.renderObject(find.byType(CustomSingleChildLayout));
    expect(box.size, equals(const Size(150.0, 240.0)));
  });

  testWidgets('Can use listener for relayout', (final WidgetTester tester) async {
    final ValueNotifier<Size> size = ValueNotifier<Size>(const Size(100.0, 200.0));

    await tester.pumpWidget(buildFrame(NotifierLayoutDelegate(size)));

    RenderBox box = tester.renderObject(find.byType(CustomSingleChildLayout));
    expect(box.size, equals(const Size(100.0, 200.0)));

    size.value = const Size(150.0, 240.0);
    await tester.pump();

    box = tester.renderObject(find.byType(CustomSingleChildLayout));
    expect(box.size, equals(const Size(150.0, 240.0)));
  });
}
