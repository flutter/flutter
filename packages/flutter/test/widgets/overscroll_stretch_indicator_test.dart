// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTest(
    Key box1Key,
    Key box2Key,
    Key box3Key,
    ScrollController controller, {
    Axis? axis,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: StretchingOverscrollIndicator(
          axisDirection: axis == null ? AxisDirection.down : AxisDirection.right,
          child: CustomScrollView(
            scrollDirection: axis ?? Axis.vertical,
            controller: controller,
            slivers: <Widget>[
              SliverToBoxAdapter(child: Container(
                color: const Color(0xD0FF0000),
                key: box1Key,
                height: 250.0,
                width: 300.0,
              )),
              SliverToBoxAdapter(child: Container(
                color: const Color(0xFFFFFF00),
                key: box2Key,
                height: 250.0,
                width: 300.0,
              )),
              SliverToBoxAdapter(child: Container(
                color: const Color(0xFF6200EA),
                key: box3Key,
                height: 250.0,
                width: 300.0,
              )),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Stretch overscroll vertically', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.start.png'),
    );

    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero).dy, greaterThan(255.0));
    expect(box3.localToGlobal(Offset.zero).dy, greaterThan(510.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.top.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    expect(controller.offset, 150.0);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.end.png'),
    );

    gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the end
    await gesture.moveBy(const Offset(0.0, -200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dy, lessThan(-165));
    expect(box2.localToGlobal(Offset.zero).dy, lessThan(90.0));
    expect(box3.localToGlobal(Offset.zero).dy, lessThan(350.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.bottom.png'),
    );
  });

  testWidgets('Stretch overscroll horizontally', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller, axis: Axis.horizontal)
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(300.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(600.0, 0.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.start.png'),
    );

    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start
    await gesture.moveBy(const Offset(200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero).dx, greaterThan(305.0));
    expect(box3.localToGlobal(Offset.zero).dx, greaterThan(610.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.left.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(300.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(600.0, 0.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    expect(controller.offset, 100.0);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.end.png'),
    );

    gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the end
    await gesture.moveBy(const Offset(-200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dx, lessThan(-116.0));
    expect(box2.localToGlobal(Offset.zero).dx, lessThan(190.0));
    expect(box3.localToGlobal(Offset.zero).dx, lessThan(500.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.right.png'),
    );
  });
}
