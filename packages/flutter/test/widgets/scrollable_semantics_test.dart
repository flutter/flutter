// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('scrollable exposes the correct semantic actions', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 80; i++)
      textWidgets.add(new Text('$i'));
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(children: textWidgets),
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
  });

  testWidgets('showOnScreen works in scrollable', (WidgetTester tester) async {
    new SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 40.0;

    final List<Widget> containers = <Widget>[];
    for (int i = 0; i < 80; i++)
      containers.add(new MergeSemantics(child: new Container(
        height: kItemHeight,
        child: new Text('container $i', textDirection: TextDirection.ltr),
      )));

    final ScrollController scrollController = new ScrollController(
      initialScrollOffset: kItemHeight / 2,
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
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
  });

  testWidgets('showOnScreen works with pinned app bar and sliver list', (WidgetTester tester) async {
    new SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 100.0;
    const double kExpandedAppBarHeight = 56.0;

    final List<Widget> containers = <Widget>[];
    for (int i = 0; i < 80; i++)
      containers.add(new MergeSemantics(child: new Container(
        height: kItemHeight,
        child: new Text('container $i'),
      )));

    final ScrollController scrollController = new ScrollController(
      initialScrollOffset: kItemHeight / 2,
    );

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
      data: const MediaQueryData(),
        child: new Scrollable(
        controller: scrollController,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return new Viewport(
            offset: offset,
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                expandedHeight: kExpandedAppBarHeight,
                flexibleSpace: const FlexibleSpaceBar(
                  title: const Text('App Bar'),
                ),
              ),
              new SliverList(
                delegate: new SliverChildListDelegate(containers),
              )
            ],
          );
        }),
      ),
    ));

    expect(scrollController.offset, kItemHeight / 2);

    final int firstContainerId = tester.renderObject(find.byWidget(containers.first)).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(firstContainerId, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(containers.first)).dy, kExpandedAppBarHeight);

    final int secondContainerId = tester.renderObject(find.byWidget(containers[1])).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(secondContainerId, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(containers[1])).dy, kExpandedAppBarHeight);
  });

  testWidgets('showOnScreen works with pinned app bar and individual slivers', (WidgetTester tester) async {
    new SemanticsTester(tester); // enables semantics tree generation

    const double kItemHeight = 100.0;
    const double kExpandedAppBarHeight = 256.0;


    final List<Widget> semantics = <Widget>[];
    final List<Widget> slivers = new List<Widget>.generate(30, (int i) {
      final Widget child = new MergeSemantics(
        child: new Container(
          child: new Text('Item $i'),
          height: 72.0,
        ),
      );
      semantics.add(child);
      return new SliverToBoxAdapter(
        child: child,
      );
    });

    final ScrollController scrollController = new ScrollController(
      initialScrollOffset: kItemHeight / 2,
    );

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child:new MediaQuery(
        data: const MediaQueryData(),
        child: new Scrollable(
          controller: scrollController,
          viewportBuilder: (BuildContext context, ViewportOffset offset) {
            return new Viewport(
              offset: offset,
              slivers: <Widget>[
                const SliverAppBar(
                  pinned: true,
                  expandedHeight: kExpandedAppBarHeight,
                  flexibleSpace: const FlexibleSpaceBar(
                    title: const Text('App Bar'),
                  ),
                ),
              ]..addAll(slivers),
            );
          },
        ),
      ),
    ));

    expect(scrollController.offset, kItemHeight / 2);

    final int id0 = tester.renderObject(find.byWidget(semantics[0])).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(id0, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(semantics[0])).dy, kToolbarHeight);

    final int id1 = tester.renderObject(find.byWidget(semantics[1])).debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(id1, SemanticsAction.showOnScreen);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getTopLeft(find.byWidget(semantics[1])).dy, kToolbarHeight);
  });

  testWidgets('scrolling sends ScrollCompletedSemanticsEvent', (WidgetTester tester) async {
    final List<dynamic> messages = <dynamic>[];
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) {
      messages.add(message);
    });

    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 80; i++)
      textWidgets.add(new Text('$i'));
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new ListView(children: textWidgets),
    ));

    await flingUp(tester);

    expect(messages, isNot(hasLength(0)));
    expect(messages.every((dynamic message) => message['type'] == 'scroll'), isTrue);

    messages.clear();
    await flingDown(tester);

    expect(messages, isNot(hasLength(0)));
    expect(messages.every((dynamic message) => message['type'] == 'scroll'), isTrue);

    semantics.dispose();
  });

  testWidgets('Semantics tree is populated mid-scroll', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < 80; i++)
      children.add(new Container(
        child: new Text('Item $i'),
        height: 40.0,
      ));
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(children: children),
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
}

Future<Null> flingUp(WidgetTester tester, { int repetitions: 1 }) async {
  while (repetitions-- > 0) {
    await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  }
}

Future<Null> flingDown(WidgetTester tester, { int repetitions: 1 }) async {
  while (repetitions-- > 0) {
    await tester.fling(find.byType(ListView), const Offset(0.0, 200.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  }
}
