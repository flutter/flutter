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

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(new CupertinoPageRoute<void>(
        title: fromTitle,
        builder: (BuildContext context) => scaffoldForNavBar(from),
      ));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(new CupertinoPageRoute<void>(
        title: toTitle,
        builder: (BuildContext context) => scaffoldForNavBar(to),
      ));

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

Finder flying(WidgetTester tester, Finder finder) {
  final RenderObjectWithChildMixin<RenderStack> theater =
      tester.renderObject(find.byType(Overlay));
  final RenderStack theaterStack = theater.child;
  final Finder lastOverlayFinder = find.byElementPredicate((Element element) {
    return element is RenderObjectElement &&
        element.renderObject == theaterStack.lastChild;
  });

  assert(
      find
          .descendant(
              of: lastOverlayFinder,
              matching: find.byType(CupertinoPageScaffold))
          .evaluate()
          .isEmpty,
      'The last overlay in the navigator was not a flying hero');

  return find.descendant(
    of: lastOverlayFinder,
    matching: finder,
  );
}

void main() {
  testWidgets('Bottom middle moves between middle and back label',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // There's 2 of them. One from the top route's back label and one from the
    // bottom route's middle widget.
    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    // Since they have the same text, they should be more or less at the same
    // place.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(331.0724935531616, 13.5),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(331.0724935531616, 13.5),
    );
  });

  testWidgets('Bottom middle and top back label transitions their font',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // The transition's stack is ordered. The bottom middle is inserted first.
    RenderParagraph bottomMiddle =
        tester.renderObject(flying(tester, find.text('Page 1')).first);
    expect(bottomMiddle.text.style.color, const Color(0xFF00070F));
    expect(bottomMiddle.text.style.fontWeight, FontWeight.w600);
    expect(bottomMiddle.text.style.fontFamily, '.SF UI Text');
    expect(bottomMiddle.text.style.letterSpacing, -0.08952957153320312);

    expect(
      tester
          .renderObject<RenderAnimatedOpacity>(find.ancestor(
            of: flying(tester, find.text('Page 1')).first,
            matching: find.byType(FadeTransition),
          ))
          .opacity
          .value,
      0.8609542846679688,
    );

    // The top back label is styled exactly the same way. But the opacity tweens
    // are flipped.
    RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style.color, const Color(0xFF00070F));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w600);
    expect(topBackLabel.text.style.fontFamily, '.SF UI Text');
    expect(topBackLabel.text.style.letterSpacing, -0.08952957153320312);

    expect(
      tester
          .renderObject<RenderAnimatedOpacity>(find.ancestor(
            of: flying(tester, find.text('Page 1')).last,
            matching: find.byType(FadeTransition),
          ))
          .opacity
          .value,
      0.0,
    );

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomMiddle.text.style.color, const Color(0xFF0073F0));
    expect(bottomMiddle.text.style.fontWeight, FontWeight.w400);
    expect(bottomMiddle.text.style.fontFamily, '.SF UI Text');
    expect(bottomMiddle.text.style.letterSpacing, -0.231169798374176);

    expect(
      tester
          .renderObject<RenderAnimatedOpacity>(find.ancestor(
            of: flying(tester, find.text('Page 1')).first,
            matching: find.byType(FadeTransition),
          ))
          .opacity
          .value,
      0.0,
    );

    expect(topBackLabel.text.style.color, const Color(0xFF0073F0));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w400);
    expect(topBackLabel.text.style.fontFamily, '.SF UI Text');
    expect(topBackLabel.text.style.letterSpacing, -0.231169798374176);

    expect(
      tester
          .renderObject<RenderAnimatedOpacity>(find.ancestor(
            of: flying(tester, find.text('Page 1')).last,
            matching: find.byType(FadeTransition),
          ))
          .opacity
          .value,
      0.8733493089675903,
    );
  });

  testWidgets('Fullscreen dialogs do not create heroes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const Placeholder(),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(new CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(new CupertinoPageRoute<void>(
          title: 'Page 2',
          fullscreenDialog: true,
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Only the first (non-fullscreen-dialog) page has a Hero.
    expect(find.byType(Hero), findsOneWidget);
    // No Hero transition happened.
    expect(() => flying(tester, find.text('Page 2')), throwsAssertionError);
  });

  testWidgets('Turning off transition works', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: const Text('Page 1'),
      ),
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    // Only the second page that doesn't have the transitionBetweenRoutes
    // override off has a Hero.
    expect(find.byType(Hero), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Hero), matching: find.text('Page 2')),
      findsOneWidget,
    );

    // No Hero transition happened.
    expect(() => flying(tester, find.text('Page 2')), throwsAssertionError);
  });
}
