// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
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
        child: new Text('container $i'),
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