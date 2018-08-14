// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

Future<void> startTransitionBetween(
  WidgetTester tester, {
  Widget from,
  Widget to,
  String fromTitle,
  String toTitle,
}) async {
  await tester.pumpWidget(
    new CupertinoApp(
      home: const Placeholder(),
    ),
  );

  tester.state<NavigatorState>(find.byType(Navigator)).push(
    new CupertinoPageRoute<void>(
      title: fromTitle,
      builder: (BuildContext context) => scaffoldForNavBar(from),
    )
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  tester.state<NavigatorState>(find.byType(Navigator)).push(
    new CupertinoPageRoute<void>(
      title: toTitle,
      builder: (BuildContext context) => scaffoldForNavBar(to),
    )
  );

  await tester.pump();
}

CupertinoPageScaffold scaffoldForNavBar(Widget navBar) {
  if (navBar is CupertinoNavigationBar || navBar == null) {
    return new CupertinoPageScaffold(
      navigationBar: navBar ?? const CupertinoNavigationBar(),
      child: const Placeholder(),
    );
  } else if (navBar is CupertinoSliverNavigationBar) {
    return new CupertinoPageScaffold(
      child: new CustomScrollView(
        slivers: <Widget>[
          navBar,
          // Add filler so it's scrollable.
          const SliverToBoxAdapter(
            child: Placeholder(fallbackHeight: 1000.0),
          ),
        ],
      ),
    );
  }
}

Finder inHero(WidgetTester tester, Finder finder) {
  final RenderObjectWithChildMixin<RenderStack> theater =
      tester.renderObject(find.byType(Overlay));
  final RenderStack theaterStack = theater.child;
  return find.descendant(
    of: find.byElementPredicate(
      (Element element) => element.renderObject == theaterStack.lastChild,
    ),
    matching: finder,
  );
}

void main() {
  testWidgets('Middle moves between middle and back label', (
      WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 100));

    // There's 2 of them. One from the top route's back label and one from the
    // bottom route's middle widget.
    expect(inHero(tester, find.text('Page 1')), findsNWidgets(2));
    debugDumpApp();

    // Since they have the same text, they should be more or less at the same
    // place.
    expect(
      tester.getTopLeft(inHero(tester, find.text('Page 1')).first),
      const Offset(235.13582849502563, 13.5),
    );
    expect(
      tester.getTopLeft(inHero(tester, find.text('Page 1')).last),
      const Offset(235.13582849502563, 13.5),
    );
  });
}
