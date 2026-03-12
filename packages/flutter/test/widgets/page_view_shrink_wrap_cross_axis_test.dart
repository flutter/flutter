// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('PageView.shrinkWrapCrossAxis sizes to the current page after swipes', (
    WidgetTester tester,
  ) async {
    final PageController controller = PageController();
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
              _HorizontalPage(height: 100.0, label: 'Page 1'),
              _HorizontalPage(height: 220.0, label: 'Page 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder pageView = find.byType(PageView);
    expect(find.text('Page 1'), findsOneWidget);
    expect(tester.getSize(pageView), const Size(800.0, 100.0));

    await tester.fling(pageView, const Offset(-800.0, 0.0), 3000.0);
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.getSize(pageView), const Size(800.0, 220.0));
  });

  testWidgets('PageView.builder shrinkWrapCrossAxis honors initialPage on first layout', (
    WidgetTester tester,
  ) async {
    final controller = PageController(initialPage: 1);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView.builder(
            controller: controller,
            shrinkWrapCrossAxis: true,
            itemCount: 3,
            itemBuilder: (BuildContext context, int index) {
              return _HorizontalPage(
                height: switch (index) {
                  0 => 100.0,
                  1 => 220.0,
                  _ => 340.0,
                },
                label: 'Page ${index + 1}',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 220.0));
  });

  testWidgets('PageView.custom shrinkWrapCrossAxis supports lazy delegates', (
    WidgetTester tester,
  ) async {
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
            childrenDelegate: SliverChildBuilderDelegate((BuildContext context, int index) {
              return _HorizontalPage(
                height: switch (index) {
                  0 => 100.0,
                  1 => 220.0,
                  _ => 340.0,
                },
                label: 'Page ${index + 1}',
              );
            }, childCount: 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 100.0));

    controller.jumpToPage(2);
    await tester.pumpAndSettle();

    expect(find.text('Page 3'), findsOneWidget);
    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 340.0));
  });

  testWidgets('PageView.shrinkWrapCrossAxis interpolates the midpoint size', (
    WidgetTester tester,
  ) async {
    final PageController controller = PageController(viewportFraction: 0.8);
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
              _HorizontalPage(height: 100.0, label: 'Page 1'),
              _HorizontalPage(height: 200.0, label: 'Page 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final double halfPageOffset =
        controller.position.viewportDimension * controller.viewportFraction / 2;
    controller.jumpTo(halfPageOffset);
    await tester.pump();

    expect(tester.getSize(find.byType(PageView)).height, closeTo(137.5, 0.001));
  });

  testWidgets('PageView.shrinkWrapCrossAxis does not interpolate inside leading pad', (
    WidgetTester tester,
  ) async {
    final PageController controller = PageController(viewportFraction: 0.8);
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
              _HorizontalPage(height: 100.0, label: 'Page 1'),
              _HorizontalPage(height: 200.0, label: 'Page 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final double leadingPad =
        controller.position.viewportDimension * (1 - controller.viewportFraction) / 2;
    controller.jumpTo(leadingPad / 2);
    await tester.pump();

    expect(tester.getSize(find.byType(PageView)).height, 100.0);
  });

  testWidgets(
    'PageView.shrinkWrapCrossAxis with padEnds false uses the max-scroll-clamped trailing size',
    (WidgetTester tester) async {
      final PageController controller = PageController(viewportFraction: 0.8);
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
              children: const <Widget>[
                _HorizontalPage(height: 100.0, label: 'Page 1', key: ValueKey<String>('page-1')),
                _HorizontalPage(height: 220.0, label: 'Page 2', key: ValueKey<String>('page-2')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With padEnds: false and viewportFraction < 1.0, pages are narrower than
      // the viewport. The first page starts at x=0, but the trailing page is
      // limited by the max scroll extent and may never reach its full-page size.
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('page-1'))).dx, 0.0);
      expect(tester.getSize(find.byType(PageView)).height, 100.0);

      controller.jumpToPage(1);
      await tester.pumpAndSettle();

      // With viewportFraction: 0.8, max scroll = 2*640-800 = 480 < 640 (page 1 offset).
      // At scroll 480, rawPage = 480/640 = 0.75, so interpolated height = 100 + 120*0.75 = 190.
      expect(tester.getSize(find.byType(PageView)).height, 190.0);
    },
  );

  testWidgets('PageView.shrinkWrapCrossAxis supports implicit accessibility scrolling', (
    WidgetTester tester,
  ) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final PageController controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: controller,
            allowImplicitScrolling: true,
            shrinkWrapCrossAxis: true,
            children: <Widget>[
              Semantics(
                key: ValueKey<String>('page-1-semantics'),
                container: true,
                child: _HorizontalPage(height: 100.0, label: 'Page 1'),
              ),
              Semantics(
                key: ValueKey<String>('page-2-semantics'),
                container: true,
                child: _HorizontalPage(height: 220.0, label: 'Page 2'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.page, 0.0);
    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 100.0));
    expect(semantics, includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling]));
    expect(semantics, includesNodeWith(label: 'Page 1'));
    expect(
      semantics,
      includesNodeWith(label: 'Page 2', flags: <SemanticsFlag>[SemanticsFlag.isHidden]),
    );

    final int secondPageId = tester
        .renderObject(find.byKey(const ValueKey<String>('page-2-semantics'), skipOffstage: false))
        .debugSemantics!
        .id;
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      secondPageId,
      SemanticsAction.showOnScreen,
    );
    await tester.pumpAndSettle();

    expect(controller.page, 1.0);
    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 220.0));
    expect(
      semantics,
      includesNodeWith(label: 'Page 1', flags: <SemanticsFlag>[SemanticsFlag.isHidden]),
    );
    expect(semantics, includesNodeWith(label: 'Page 2'));

    semantics.dispose();
  });

  testWidgets('Vertical PageView with shrinkWrapCrossAxis adapts width', (
    WidgetTester tester,
  ) async {
    final PageController controller = PageController();
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
            children: const <Widget>[
              _VerticalPage(width: 120.0, label: 'Page 1'),
              _VerticalPage(width: 260.0, label: 'Page 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder pageView = find.byType(PageView);
    expect(tester.getSize(pageView), const Size(120.0, 600.0));

    controller.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(tester.getSize(pageView), const Size(260.0, 600.0));
  });

  testWidgets('PageView.shrinkWrapCrossAxis with reverse selects the right page size', (
    WidgetTester tester,
  ) async {
    final PageController controller = PageController();
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
            children: const <Widget>[
              _HorizontalPage(height: 90.0, label: 'Page 1'),
              _HorizontalPage(height: 210.0, label: 'Page 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)).height, 90.0);

    controller.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.getSize(find.byType(PageView)).height, 210.0);
  });

  testWidgets('PageView.shrinkWrapCrossAxis false preserves existing behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800.0,
            height: 500.0,
            child: PageView(
              children: const <Widget>[
                SizedBox(height: 100.0, child: ColoredBox(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageView)), const Size(800.0, 500.0));
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
                width: 800.0,
                height: 400.0,
                child: PageView(
                  shrinkWrapCrossAxis: shrinkWrapCrossAxis,
                  children: const <Widget>[
                    _HorizontalPage(height: 100.0, label: 'Page 1'),
                    _HorizontalPage(height: 220.0, label: 'Page 2'),
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
      await gesture.moveBy(const Offset(-200.0, 0.0));
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
                width: 800.0,
                height: 400.0,
                child: PageView(
                  shrinkWrapCrossAxis: shrinkWrapCrossAxis,
                  children: <Widget>[
                    ListView(
                      children: List<Widget>.generate(
                        20,
                        (int index) => SizedBox(height: 80.0, child: Text('Item $index')),
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

      await tester.drag(find.byType(ListView), const Offset(0.0, -200.0));
      await tester.pumpAndSettle();

      expect(depth, isNotNull);
      return depth!;
    }

    final int baselineDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: false);
    final int adaptiveDepth = await pumpAndGetDepth(shrinkWrapCrossAxis: true);

    expect(adaptiveDepth, baselineDepth);
  });

  testWidgets('PageView.shrinkWrapCrossAxis debugFillProperties includes shrinkWrapCrossAxis', (
    WidgetTester tester,
  ) async {
    final PageView pageView = PageView(
      shrinkWrapCrossAxis: true,
      children: const <Widget>[SizedBox(height: 100.0)],
    );

    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topCenter, child: pageView),
      ),
    );
    await tester.pumpAndSettle();

    final State<StatefulWidget> state = tester.state(find.byType(PageView));
    state.debugFillProperties(builder);
    final Iterable<FlagProperty> flagProperties = builder.properties
        .whereType<FlagProperty>()
        .where((FlagProperty property) => property.name == 'shrinkWrapCrossAxis');
    expect(flagProperties, isNotEmpty);
  });
}

class _HorizontalPage extends StatelessWidget {
  const _HorizontalPage({required this.height, required this.label, super.key});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: Colors.blue,
        child: Center(child: Text(label)),
      ),
    );
  }
}

class _VerticalPage extends StatelessWidget {
  const _VerticalPage({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: Colors.green,
        child: Center(child: Text(label)),
      ),
    );
  }
}
