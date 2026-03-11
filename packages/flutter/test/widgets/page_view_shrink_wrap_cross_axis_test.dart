// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageView.shrinkWrapCrossAxis sizes height to current child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 200, child: Container(color: Colors.green)),
              SizedBox(height: 300, child: Container(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The PageView should size itself to the first child's height (100).
    final Size size = tester.getSize(find.byType(PageView));
    expect(size.height, 100.0);
    // Width should fill available space (800 in test environment).
    expect(size.width, 800.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis interpolates height during page transition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 300, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 100.0);

    // Start dragging to the second page (drag left for a horizontal PageView).
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    // Drag half a page width (400 of 800).
    await gesture.moveBy(const Offset(-400, 0));
    await tester.pump();

    // At 50% transition: height should be interpolated between 100 and 300.
    final double midHeight = tester.getSize(find.byType(PageView)).height;
    expect(midHeight, greaterThan(100.0));
    expect(midHeight, lessThan(300.0));

    // Complete the gesture and settle on the second page.
    await gesture.moveBy(const Offset(-400, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 300.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with different child heights', (
    WidgetTester tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 150, child: Container(color: Colors.red)),
              SizedBox(height: 250, child: Container(color: Colors.green)),
              SizedBox(height: 50, child: Container(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 150.0);

    // Jump to second page.
    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 250.0);

    // Jump to third page.
    controller.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 50.0);
  });

  testWidgets('PageView.builder with shrinkWrapCrossAxis', (WidgetTester tester) async {
    final heights = <double>[100, 200, 300, 400];
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView.builder(
            controller: controller,
            shrinkWrapCrossAxis: true,
            itemCount: heights.length,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: heights[index],
                child: Container(color: Colors.primaries[index % Colors.primaries.length]),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 100.0);

    controller.jumpToPage(3);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 400.0);
  });

  testWidgets('PageView.custom with shrinkWrapCrossAxis', (WidgetTester tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView.custom(
            controller: controller,
            shrinkWrapCrossAxis: true,
            childrenDelegate: SliverChildListDelegate(<Widget>[
              SizedBox(height: 80, child: Container(color: Colors.red)),
              SizedBox(height: 160, child: Container(color: Colors.green)),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 80.0);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 160.0);
  });

  testWidgets('Vertical PageView with shrinkWrapCrossAxis adapts width', (
    WidgetTester tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.centerLeft,
          child: PageView(
            controller: controller,
            scrollDirection: Axis.vertical,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(width: 100, child: Container(color: Colors.red)),
              SizedBox(width: 300, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size size = tester.getSize(find.byType(PageView));
    expect(size.width, 100.0);
    // Height should fill available space (600 in test environment).
    expect(size.height, 600.0);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).width, 300.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with single child', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            shrinkWrapCrossAxis: true,
            children: <Widget>[SizedBox(height: 123, child: Container(color: Colors.red))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 123.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with identical child sizes', (
    WidgetTester tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 200, child: Container(color: Colors.red)),
              SizedBox(height: 200, child: Container(color: Colors.green)),
              SizedBox(height: 200, child: Container(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 200.0);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 200.0);

    controller.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 200.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with animateToPage', (WidgetTester tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 300, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 100.0);

    controller.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.linear);

    // Kick off the animation and advance to ~50%.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final double midHeight = tester.getSize(find.byType(PageView)).height;
    expect(midHeight, greaterThan(100.0));
    expect(midHeight, lessThan(300.0));

    // After the animation completes, height should match the second child.
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 300.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis false preserves existing behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 500,
            width: 800,
            child: PageView(
              children: <Widget>[SizedBox(height: 100, child: Container(color: Colors.red))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // With shrinkWrapCrossAxis: false (default), PageView fills the parent.
    expect(tester.getSize(find.byType(PageView)).height, 500.0);
    expect(tester.getSize(find.byType(PageView)).width, 800.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis in a Column', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageView(
              shrinkWrapCrossAxis: true,
              children: <Widget>[
                SizedBox(height: 120, child: Container(color: Colors.red)),
                SizedBox(height: 240, child: Container(color: Colors.green)),
              ],
            ),
            const Expanded(child: Placeholder()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PageView should take the current child's natural height directly.
    expect(tester.getSize(find.byType(PageView)).height, 120.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with viewportFraction < 1.0', (
    WidgetTester tester,
  ) async {
    final controller = PageController(viewportFraction: 0.8);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 200, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // First page is current; viewport should adapt to its height.
    // With viewportFraction < 1.0, edges of adjacent pages may be visible,
    // but the effective height should still be based on the current page.
    final Size size = tester.getSize(find.byType(PageView));
    expect(size.height, 100.0);

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await gesture.moveBy(const Offset(-400, 0));
    await tester.pump();
    expect(tester.getSize(find.byType(PageView)).height, 150.0);
    await gesture.up();
  });

  testWidgets('PageView.shrinkWrapCrossAxis preserves scroll notification depth', (
    WidgetTester tester,
  ) async {
    Future<int> pumpAndGetDepth({required bool shrinkWrapCrossAxis}) async {
      int? depth;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (ScrollUpdateNotification notification) {
              if (notification.metrics is PageMetrics) {
                depth ??= notification.depth;
              }
              return false;
            },
            child: Center(
              child: SizedBox(
                width: 800,
                height: 400,
                child: PageView(
                  shrinkWrapCrossAxis: shrinkWrapCrossAxis,
                  children: <Widget>[
                    SizedBox(height: 100, child: Container(color: Colors.red)),
                    SizedBox(height: 200, child: Container(color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(depth, isNotNull);
      return depth!;
    }

    final int baselineDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: false);
    final int adaptiveDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: true);

    expect(adaptiveDepth, baselineDepth);
  });

  testWidgets('PageView.shrinkWrapCrossAxis preserves nested scroll notification depth', (
    WidgetTester tester,
  ) async {
    Future<int> pumpAndGetDepth({required bool shrinkWrapCrossAxis}) async {
      int? depth;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (ScrollUpdateNotification notification) {
              if (notification.metrics is! PageMetrics) {
                depth ??= notification.depth;
              }
              return false;
            },
            child: Center(
              child: SizedBox(
                width: 800,
                height: 400,
                child: PageView(
                  shrinkWrapCrossAxis: shrinkWrapCrossAxis,
                  children: <Widget>[
                    ListView(
                      children: List<Widget>.generate(
                        20,
                        (int index) => SizedBox(height: 80, child: Text('Item $index')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(depth, isNotNull);
      return depth!;
    }

    final int baselineDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: false);
    final int adaptiveDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: true);

    expect(adaptiveDepth, baselineDepth);
  });

  testWidgets('PageView.shrinkWrapCrossAxis: child fills main axis (width)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            shrinkWrapCrossAxis: true,
            children: <Widget>[Container(height: 100, color: Colors.red)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The child should fill the viewport width (main axis for horizontal scroll).
    final Size container = tester.getSize(find.byType(Container));
    expect(container.width, 800.0);
    expect(container.height, 100.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with reverse', (WidgetTester tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            reverse: true,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 200, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 100.0);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)).height, 200.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis with padEnds: false', (WidgetTester tester) async {
    final controller = PageController(viewportFraction: 0.8);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            shrinkWrapCrossAxis: true,
            padEnds: false,
            children: <Widget>[
              SizedBox(height: 100, child: Container(color: Colors.red)),
              SizedBox(height: 200, child: Container(color: Colors.green)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // With padEnds: false, the first page should align to the leading edge.
    // Height should still adapt.
    expect(tester.getSize(find.byType(PageView)).height, greaterThanOrEqualTo(100.0));
  });

  testWidgets('PageView.shrinkWrapCrossAxis debugFillProperties includes shrinkWrapCrossAxis', (
    WidgetTester tester,
  ) async {
    final pageView = PageView(
      shrinkWrapCrossAxis: true,
      children: const <Widget>[SizedBox(height: 100)],
    );

    final builder = DiagnosticPropertiesBuilder();
    // PageView is a StatefulWidget, so we test via its State's debugFillProperties
    // by rendering it and then checking the diagnostics.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topCenter, child: pageView),
      ),
    );
    await tester.pumpAndSettle();

    // Find the state and verify debug properties include shrinkWrapCrossAxis.
    final State<StatefulWidget> state = tester.state(find.byType(PageView));
    state.debugFillProperties(builder);
    final Iterable<FlagProperty> flagProperties = builder.properties
        .whereType<FlagProperty>()
        .where((FlagProperty p) => p.name == 'shrinkWrapCrossAxis');
    expect(flagProperties, isNotEmpty);
  });
}
