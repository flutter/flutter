// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTest(
    GlobalKey box1Key,
    GlobalKey box2Key,
    GlobalKey box3Key,
    ScrollController controller, {
    Axis axis = Axis.vertical,
    bool reverse = false,
  }) {
    final AxisDirection axisDirection;
    switch (axis) {
      case Axis.horizontal:
        axisDirection = reverse ? AxisDirection.left : AxisDirection.right;
        break;
      case Axis.vertical:
        axisDirection = reverse ? AxisDirection.up : AxisDirection.down;
        break;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: StretchingOverscrollIndicator(
            axisDirection: axisDirection,
            child: CustomScrollView(
              reverse: reverse,
              scrollDirection: axis,
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
      ),
    );
  }

  testWidgets('Stretch overscroll vertically', (WidgetTester tester) async {
    final GlobalKey box1Key = GlobalKey();
    final GlobalKey box2Key = GlobalKey();
    final GlobalKey box3Key = GlobalKey();
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
      matchesGoldenFile('overscroll_stretch.vertical.start.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(controller.offset, 150.0);
    expect(box1.localToGlobal(Offset.zero).dy, -150.0);
    expect(box2.localToGlobal(Offset.zero).dy, 100.0);
    expect(box3.localToGlobal(Offset.zero).dy, 350.0);
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
      matchesGoldenFile('overscroll_stretch.vertical.end.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back
    expect(box1.localToGlobal(Offset.zero).dy, -150.0);
    expect(box2.localToGlobal(Offset.zero).dy, 100.0);
    expect(box3.localToGlobal(Offset.zero).dy, 350.0);
  });

  testWidgets('Stretch overscroll works in reverse - vertical', (WidgetTester tester) async {
    final GlobalKey box1Key = GlobalKey();
    final GlobalKey box2Key = GlobalKey();
    final GlobalKey box3Key = GlobalKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller, reverse: true),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), const Offset(0.0, 350.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 100.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, -150.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll
    await gesture.moveBy(const Offset(0.0, -200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dy, lessThan(350.0));
    expect(box2.localToGlobal(Offset.zero).dy, lessThan(100.0));
    expect(box3.localToGlobal(Offset.zero).dy, lessThan(-150.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.reverse.png'),
    );
  });

  testWidgets('Stretch overscroll works in reverse - horizontal', (WidgetTester tester) async {
    final GlobalKey box1Key = GlobalKey();
    final GlobalKey box2Key = GlobalKey();
    final GlobalKey box3Key = GlobalKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
        buildTest(
          box1Key,
          box2Key,
          box3Key,
          controller,
          axis: Axis.horizontal,
          reverse: true,
        ),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), const Offset(500.0, 0.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(200.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(-100.0, 0.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll
    await gesture.moveBy(const Offset(-200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dx, lessThan(500.0));
    expect(box2.localToGlobal(Offset.zero).dx, lessThan(200.0));
    expect(box3.localToGlobal(Offset.zero).dx, lessThan(-100.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.reverse.png'),
    );
  });

  testWidgets('Stretch overscroll horizontally', (WidgetTester tester) async {
    final GlobalKey box1Key = GlobalKey();
    final GlobalKey box2Key = GlobalKey();
    final GlobalKey box3Key = GlobalKey();
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
      matchesGoldenFile('overscroll_stretch.horizontal.start.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(300.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(600.0, 0.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(controller.offset, 100.0);
    expect(box1.localToGlobal(Offset.zero).dx, -100.0);
    expect(box2.localToGlobal(Offset.zero).dx, 200.0);
    expect(box3.localToGlobal(Offset.zero).dx, 500.0);
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
      matchesGoldenFile('overscroll_stretch.horizontal.end.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back
    expect(box1.localToGlobal(Offset.zero).dx, -100.0);
    expect(box2.localToGlobal(Offset.zero).dx, 200.0);
    expect(box3.localToGlobal(Offset.zero).dx, 500.0);
  });

  testWidgets('Disallow stretching overscroll', (WidgetTester tester) async {
    final GlobalKey box1Key = GlobalKey();
    final GlobalKey box2Key = GlobalKey();
    final GlobalKey box3Key = GlobalKey();
    final ScrollController controller = ScrollController();
    double indicatorNotification =0;
    await tester.pumpWidget(
      NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification notification) {
          notification.disallowIndicator();
          indicatorNotification += 1;
          return false;
        },
        child: buildTest(box1Key, box2Key, box3Key, controller),
      )
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(indicatorNotification, 0.0);
    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start, should not stretch
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(indicatorNotification, 1.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Stretch does not overflow bounds of container', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/90197
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: Column(
            children: <Widget>[
              StretchingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                child: SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder: (BuildContext context, int index){
                      return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text('Index $index'),
                      );
                    },
                  ),
                ),
              ),
              Opacity(
                opacity: 0.5,
                child: Container(
                  color: const Color(0xD0FF0000),
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll the start.
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
    // Image should not show the text overlapping the red area below the list.
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('overscroll_stretch.no_overflow.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Clip behavior is updated as needed', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/97867
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800.0, 600.0)),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: Column(
              children: <Widget>[
                StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  child: SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (BuildContext context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text('Index $index'),
                        );
                      },
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.5,
                  child: Container(
                    color: const Color(0xD0FF0000),
                    height: 100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);
    RenderClipRect renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
    // Currently not clipping
    expect(renderClip.clipBehavior, equals(Clip.none));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll the start.
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
    renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
    // Now clipping
    expect(renderClip.clipBehavior, equals(Clip.hardEdge));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('clipBehavior parameter updates overscroll clipping behavior', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/103491

    Widget buildFrame(Clip clipBehavior) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800.0, 600.0)),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: Column(
              children: <Widget>[
                StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  clipBehavior: clipBehavior,
                  child: SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (BuildContext context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text('Index $index'),
                        );
                      },
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.5,
                  child: Container(
                    color: const Color(0xD0FF0000),
                    height: 100,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Clip.none));

    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);
    RenderClipRect renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
    // Currently not clipping
    expect(renderClip.clipBehavior, equals(Clip.none));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll the start.
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
    renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
    // Now clipping
    expect(renderClip.clipBehavior, equals(Clip.none));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Stretch limit', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/99264
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: StretchingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index){
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text('Index $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        )
      )
    );
    const double maxStretchLocation = 52.63178407049861;

    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);

    TestGesture pointer = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll beyond the limit (the viewport is 600.0).
    await pointer.moveBy(const Offset(0.0, 610.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, maxStretchLocation);

    pointer = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll way way beyond the limit
    await pointer.moveBy(const Offset(0.0, 1000.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, maxStretchLocation);

    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Multiple pointers wll not exceed stretch limit', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/99264
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: StretchingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index){
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text('Index $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        )
      )
    );
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);

    final TestGesture pointer1 = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll the start.
    await pointer1.moveBy(const Offset(0.0, 210.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    double lastStretchedLocation = tester.getCenter(find.text('Index 1')).dy;
    expect(lastStretchedLocation, greaterThan(51.0));

    final TestGesture pointer2 = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Add overscroll from an additional pointer
    await pointer2.moveBy(const Offset(0.0, 210.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(lastStretchedLocation));
    lastStretchedLocation = tester.getCenter(find.text('Index 1')).dy;

    final TestGesture pointer3 = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Add overscroll from an additional pointer, exceeding the max stretch (600)
    await pointer3.moveBy(const Offset(0.0, 210.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(lastStretchedLocation));
    lastStretchedLocation = tester.getCenter(find.text('Index 1')).dy;

    final TestGesture pointer4 = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Since we have maxed out the overscroll, it should not have stretched
    // further, regardless of the number of pointers.
    await pointer4.moveBy(const Offset(0.0, 210.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, lastStretchedLocation);

    await pointer1.up();
    await pointer2.up();
    await pointer3.up();
    await pointer4.up();
    await tester.pumpAndSettle();
  });
}
