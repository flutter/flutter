// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  SemanticsTester semantics;

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('scrollable exposes the correct semantic actions', (WidgetTester tester) async {
    semantics = SemanticsTester(tester);

    final List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 80; i++)
      textWidgets.add(Text('$i'));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(children: textWidgets),
      ),
    );

    expect(semantics,includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp]));

    await flingUp(tester);
    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown]));

    await flingDown(tester, repetitions: 2);
    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp]));

    await flingUp(tester, repetitions: 5);
    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollDown]));

    await flingDown(tester);
    expect(semantics, includesNodeWith(actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown]));

    semantics.dispose();
  });

  testWidgets('showOnScreen works in scrollable', (WidgetTester tester) async {
    semantics = SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 40.0;

    final List<Widget> containers = <Widget>[];
    for (int i = 0; i < 80; i++)
      containers.add(MergeSemantics(child: Container(
        height: kItemHeight,
        child: Text('container $i', textDirection: TextDirection.ltr),
      )));

    final ScrollController scrollController = ScrollController(
      initialScrollOffset: kItemHeight / 2,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          controller: scrollController,
          children: containers,
        ),
      ),
    );

    expect(scrollController.offset, kItemHeight / 2);

    final int firstContainerId = tester.renderObject(find.byWidget(containers.first)).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(scrollController.offset, 0.0);

    semantics.dispose();
  });

  testWidgets('showOnScreen works with pinned app bar and sliver list', (WidgetTester tester) async {
    semantics = SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 100.0;
    const double kExpandedAppBarHeight = 56.0;

    final List<Widget> containers = <Widget>[];
    for (int i = 0; i < 80; i++)
      containers.add(MergeSemantics(child: Container(
        height: kItemHeight,
        child: Text('container $i'),
      )));

    final ScrollController scrollController = ScrollController(
      initialScrollOffset: kItemHeight / 2,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: MediaQuery(
          data: const MediaQueryData(),
            child: Scrollable(
            controller: scrollController,
            viewportBuilder: (BuildContext context, ViewportOffset offset) {
              return Viewport(
                offset: offset,
                slivers: <Widget>[
                  const SliverAppBar(
                    pinned: true,
                    expandedHeight: kExpandedAppBarHeight,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('App Bar'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(containers),
                  )
                ],
              );
            }),
          ),
      ),
    ));

    expect(scrollController.offset, kItemHeight / 2);

    final int firstContainerId = tester.renderObject(find.byWidget(containers.first)).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(containers.first)).dy, kExpandedAppBarHeight);

    semantics.dispose();
  });

  testWidgets('showOnScreen works with pinned app bar and individual slivers', (WidgetTester tester) async {
    semantics = SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 100.0;
    const double kExpandedAppBarHeight = 256.0;


    final List<Widget> children = <Widget>[];
    final List<Widget> slivers = List<Widget>.generate(30, (int i) {
      final Widget child = MergeSemantics(
        child: Container(
          child: Text('Item $i'),
          height: 72.0,
        ),
      );
      children.add(child);
      return SliverToBoxAdapter(
        child: child,
      );
    });

    final ScrollController scrollController = ScrollController(
      initialScrollOffset: 2.5 * kItemHeight,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Localizations(
          locale: const Locale('en', 'us'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          child: Scrollable(
            controller: scrollController,
            viewportBuilder: (BuildContext context, ViewportOffset offset) {
              return Viewport(
                offset: offset,
                slivers: <Widget>[
                  const SliverAppBar(
                    pinned: true,
                    expandedHeight: kExpandedAppBarHeight,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('App Bar'),
                    ),
                  ),
                ]..addAll(slivers),
              );
            },
          ),
        ),
      ),
    ));

    expect(scrollController.offset, 2.5 * kItemHeight);

    final int id0 = tester.renderObject(find.byWidget(children[0])).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(id0, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(children[0])).dy, kToolbarHeight);

    semantics.dispose();
  });

  testWidgets('correct scrollProgress', (WidgetTester tester) async {
    semantics = SemanticsTester(tester);

    final List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 80; i++)
      textWidgets.add(Text('$i'));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(children: textWidgets),
    ));

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 0.0,
      scrollExtentMax: 520.0,
      actions: <SemanticsAction>[
        SemanticsAction.scrollUp,
      ],
    ));

    await flingUp(tester);

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 380.2,
      scrollExtentMax: 520.0,
      actions: <SemanticsAction>[
        SemanticsAction.scrollUp,
        SemanticsAction.scrollDown,
      ],
    ));

    await flingUp(tester);

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 520.0,
      scrollExtentMax: 520.0,
      actions: <SemanticsAction>[
        SemanticsAction.scrollDown,
      ],
    ));

    semantics.dispose();
  });

  testWidgets('correct scrollProgress for unbound', (WidgetTester tester) async {
    semantics = SemanticsTester(tester);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        itemExtent: 20.0,
        itemBuilder: (BuildContext context, int index) {
          return Text('entry $index');
        },
      ),
    ));

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 0.0,
      scrollExtentMax: double.infinity,
      actions: <SemanticsAction>[
        SemanticsAction.scrollUp,
      ],
    ));

    await flingUp(tester);

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 380.2,
      scrollExtentMax: double.infinity,
      actions: <SemanticsAction>[
        SemanticsAction.scrollUp,
        SemanticsAction.scrollDown,
      ],
    ));

    await flingUp(tester);

    expect(semantics, includesNodeWith(
      scrollExtentMin: 0.0,
      scrollPosition: 760.4,
      scrollExtentMax: double.infinity,
      actions: <SemanticsAction>[
        SemanticsAction.scrollUp,
        SemanticsAction.scrollDown,
      ],
    ));

    semantics.dispose();
  });

  testWidgets('Semantics tree is populated mid-scroll', (WidgetTester tester) async {
    semantics = SemanticsTester(tester);

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < 80; i++)
      children.add(Container(
        child: Text('Item $i'),
        height: 40.0,
      ));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(children: children),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(const Offset(0.0, -40.0));
    await tester.pump();

    expect(semantics, includesNodeWith(label: 'Item 1'));
    expect(semantics, includesNodeWith(label: 'Item 2'));
    expect(semantics, includesNodeWith(label: 'Item 3'));

    semantics.dispose();
  });

  testWidgets('Can toggle semantics on, off, on without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          children: List<Widget>.generate(40, (int i) {
            return Container(
              child: Text('item $i'),
              height: 400.0,
            );
          }),
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.hasImplicitScrolling,
              ],
              actions: <SemanticsAction>[SemanticsAction.scrollUp],
              children: <TestSemantics>[
                TestSemantics(
                  label: r'item 0',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  label: r'item 1',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isHidden,
                  ],
                  label: r'item 2',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    // Start with semantics off.
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);

    // Semantics on
    semantics = SemanticsTester(tester);
    await tester.pumpAndSettle();
    expect(tester.binding.pipelineOwner.semanticsOwner, isNotNull);
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true));

    // Semantics off
    semantics.dispose();
    await tester.pumpAndSettle();
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);

    // Semantics on
    semantics = SemanticsTester(tester);
    await tester.pumpAndSettle();
    expect(tester.binding.pipelineOwner.semanticsOwner, isNotNull);
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true, ignoreRect: true, ignoreTransform: true));

    semantics.dispose();
  });

  group('showOnScreen', () {

    const double kItemHeight = 100.0;

    List<Widget> children;
    ScrollController scrollController;
    Widget widgetUnderTest;

    setUp(() {
      children = List<Widget>.generate(10, (int i) {
        return MergeSemantics(
          child: Container(
            height: kItemHeight,
            child: Text('container $i'),
          ),
        );
      });

      scrollController = ScrollController(
        initialScrollOffset: kItemHeight / 2,
      );

      widgetUnderTest = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 2 * kItemHeight,
            child: ListView(
              controller: scrollController,
              children: children,
            ),
          ),
        ),
      );

    });

    testWidgets('brings item above leading edge to leading edge', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, kItemHeight / 2);

      final int firstContainerId = tester.renderObject(find.byWidget(children.first)).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0.0);

      semantics.dispose();
    });

    testWidgets('brings item below trailing edge to trailing edge', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, kItemHeight / 2);

      final int firstContainerId = tester.renderObject(find.byWidget(children[2])).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, kItemHeight);

      semantics.dispose();
    });

    testWidgets('does not change position of items already fully on-screen', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, kItemHeight / 2);

      final int firstContainerId = tester.renderObject(find.byWidget(children[1])).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, kItemHeight / 2);

      semantics.dispose();
    });
  });

  group('showOnScreen with negative children', () {
    const double kItemHeight = 100.0;

    List<Widget> children;
    ScrollController scrollController;
    Widget widgetUnderTest;

    setUp(() {
      final Key center = GlobalKey();

      children = List<Widget>.generate(10, (int i) {
        return SliverToBoxAdapter(
          key: i == 5 ? center : null,
          child: MergeSemantics(
            key: ValueKey<int>(i),
            child: Container(
              height: kItemHeight,
              child: Text('container $i'),
            ),
          ),
        );
      });

      scrollController = ScrollController(
        initialScrollOffset: -2.5 * kItemHeight,
      );

      // 'container 0' is at offset -500
      // 'container 1' is at offset -400
      // 'container 2' is at offset -300
      // 'container 3' is at offset -200
      // 'container 4' is at offset -100
      // 'container 5' is at offset 0

      widgetUnderTest = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            height: 2 * kItemHeight,
            child: Scrollable(
              controller: scrollController,
              viewportBuilder: (BuildContext context, ViewportOffset offset) {
                return Viewport(
                  cacheExtent: 0.0,
                  offset: offset,
                  center: center,
                  slivers: children
                );
              },
            ),
          ),
        ),
      );

    });

    testWidgets('brings item above leading edge to leading edge', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, -250.0);

      final int firstContainerId = tester.renderObject(find.byKey(const ValueKey<int>(2))).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, -300.0);

      semantics.dispose();
    });

    testWidgets('brings item below trailing edge to trailing edge', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, -250.0);

      final int firstContainerId = tester.renderObject(find.byKey(const ValueKey<int>(4))).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, -200.0);

      semantics.dispose();
    });

    testWidgets('does not change position of items already fully on-screen', (WidgetTester tester) async {
      semantics = SemanticsTester(tester); // enables semantics tree generation

      await tester.pumpWidget(widgetUnderTest);

      expect(scrollController.offset, -250.0);

      final int firstContainerId = tester.renderObject(find.byKey(const ValueKey<int>(3))).debugSemantics.id;
      tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
      await tester.pumpAndSettle();

      expect(scrollController.offset, -250.0);

      semantics.dispose();
    });

  });


}

Future<void> flingUp(WidgetTester tester, { int repetitions = 1 }) => fling(tester, const Offset(0.0, -200.0), repetitions);

Future<void> flingDown(WidgetTester tester, { int repetitions = 1 }) => fling(tester, const Offset(0.0, 200.0), repetitions);

Future<void> flingRight(WidgetTester tester, { int repetitions = 1 }) => fling(tester, const Offset(200.0, 0.0), repetitions);

Future<void> flingLeft(WidgetTester tester, { int repetitions = 1 }) => fling(tester, const Offset(-200.0, 0.0), repetitions);

Future<void> fling(WidgetTester tester, Offset offset, int repetitions) async {
  while (repetitions-- > 0) {
    await tester.fling(find.byType(ListView), offset, 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  }
}
