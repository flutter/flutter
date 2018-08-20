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
                matching: find.byWidgetPredicate(
                  (Widget widget) =>
                      widget.runtimeType.toString() ==
                      '_NavigationBarTransition',
                ),
              )
              .evaluate()
              .length ==
          1,
      'The last overlay in the navigator was not a flying hero',);

  return find.descendant(
    of: lastOverlayFinder,
    matching: finder,
  );
}

void checkBackgroundBoxHeight(WidgetTester tester, double height) {
  Widget transitionBackgroundBox =
      tester.widget<Stack>(flying(tester, find.byType(Stack))).children[0];
  expect(
    tester
        .widget<SizedBox>(
          find.descendant(
            of: find.byWidget(transitionBackgroundBox),
            matching: find.byType(SizedBox),
          ),
        )
        .height,
    height,
  );
}

void checkOpacity(WidgetTester tester, Finder finder, double opacity) {
  expect(
    tester
        .renderObject<RenderAnimatedOpacity>(find.ancestor(
          of: finder,
          matching: find.byType(FadeTransition),
        ))
        .opacity
        .value,
    opacity,
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

  testWidgets('Popping mid-transition is symmetrical',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    void checkColorAndPositionAt50ms() {
      // The transition's stack is ordered. The bottom middle is inserted first.
      RenderParagraph bottomMiddle =
          tester.renderObject(flying(tester, find.text('Page 1')).first);
      expect(bottomMiddle.text.style.color, const Color(0xFF00070F));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).first),
        const Offset(331.0724935531616, 13.5),
      );

      // The top back label is styled exactly the same way. But the opacity tweens
      // are flipped.
      RenderParagraph topBackLabel =
          tester.renderObject(flying(tester, find.text('Page 1')).last);
      expect(topBackLabel.text.style.color, const Color(0xFF00070F));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).last),
        const Offset(331.0724935531616, 13.5),
      );
    }

    checkColorAndPositionAt50ms();

    // Advance more.
    await tester.pump(const Duration(milliseconds: 100));

    // Pop and reverse the same amount of time.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Check that everything's the same as on the way in.
    checkColorAndPositionAt50ms();
  });

  testWidgets('There should be no global keys in the hero flight',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      flying(
        tester,
        find.byWidgetPredicate((Widget widget) => widget.key != null),
      ),
      findsNothing,
    );
  });

  testWidgets('Transition box grows to large title size',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      to: const CupertinoSliverNavigationBar(),
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 47.097110748291016);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 61.0267448425293);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 78.68475294113159);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 88.32722091674805);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 93.13018447160721);
  });

  testWidgets('Large transition box shrinks to standard nav bar size',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 92.90288925170898);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 78.9732551574707);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 61.31524705886841);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 51.67277908325195);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 46.86981552839279);
  });

  testWidgets('Hero flight removed at the end of page transition',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    await tester.pump(const Duration(milliseconds: 50));

    // There's 2 of them. One from the top route's back label and one from the
    // bottom route's middle widget.
    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    // End the transition.
    await tester.pump(const Duration(milliseconds: 500));

    expect(() => flying(tester, find.text('Page 1')), throwsAssertionError);
  });

  testWidgets('Exact widget is reused to build inside the transition',
      (WidgetTester tester) async {
    Widget userMiddle = const Placeholder();
    await startTransitionBetween(
      tester,
      from: CupertinoSliverNavigationBar(
        middle: userMiddle,
      ),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.byWidget(userMiddle)), findsOneWidget);
  });

  testWidgets('First appearance of back chevron fades in from the right',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: scaffoldForNavBar(null),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(new CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    Finder backChevron = flying(tester,
        find.text(new String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevron,
      // Only one exists from the top page. The bottom page has no back chevron.
      findsOneWidget,
    );

    checkOpacity(tester, backChevron, 0.0);
    expect(tester.getTopLeft(backChevron), const Offset(71.94993209838867, 5.0));

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, backChevron, 0.32467134296894073);
    expect(tester.getTopLeft(backChevron), const Offset(18.033634185791016, 5.0));
  });
}
