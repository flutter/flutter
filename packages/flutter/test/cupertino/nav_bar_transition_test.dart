// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> startTransitionBetween(
  WidgetTester tester, {
  Widget from,
  Widget to,
  String fromTitle,
  String toTitle,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      builder: (BuildContext context, Widget navigator) {
        return Directionality(
          textDirection: textDirection,
          child: navigator,
        );
      },
      home: const Placeholder(),
    ),
  );

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(CupertinoPageRoute<void>(
        title: fromTitle,
        builder: (BuildContext context) => scaffoldForNavBar(from),
      ));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(CupertinoPageRoute<void>(
        title: toTitle,
        builder: (BuildContext context) => scaffoldForNavBar(to),
      ));

  await tester.pump();
}

CupertinoPageScaffold scaffoldForNavBar(Widget navBar) {
  if (navBar is CupertinoNavigationBar || navBar == null) {
    return CupertinoPageScaffold(
      navigationBar: navBar ?? const CupertinoNavigationBar(),
      child: const Placeholder(),
    );
  } else if (navBar is CupertinoSliverNavigationBar) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
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
  assert(false, 'Unexpected nav bar type ${navBar.runtimeType}');
  return null;
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
  final Widget transitionBackgroundBox =
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

  testWidgets('Bottom middle moves between middle and back label RTL',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      textDirection: TextDirection.rtl,
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    // Same as LTR but more to the right now.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(366.9275064468384, 13.5),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(366.9275064468384, 13.5),
    );
  });

  testWidgets('Bottom middle and top back label transitions their font',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // The transition's stack is ordered. The bottom middle is inserted first.
    final RenderParagraph bottomMiddle =
        tester.renderObject(flying(tester, find.text('Page 1')).first);
    expect(bottomMiddle.text.style.color, const Color(0xFF00070F));
    expect(bottomMiddle.text.style.fontWeight, FontWeight.w600);
    expect(bottomMiddle.text.style.fontFamily, '.SF UI Text');
    expect(bottomMiddle.text.style.letterSpacing, -0.08952957153320312);

    checkOpacity(
        tester, flying(tester, find.text('Page 1')).first, 0.8609542846679688);

    // The top back label is styled exactly the same way. But the opacity tweens
    // are flipped.
    final RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style.color, const Color(0xFF00070F));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w600);
    expect(topBackLabel.text.style.fontFamily, '.SF UI Text');
    expect(topBackLabel.text.style.letterSpacing, -0.08952957153320312);

    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.0);

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomMiddle.text.style.color, const Color(0xFF0073F0));
    expect(bottomMiddle.text.style.fontWeight, FontWeight.w400);
    expect(bottomMiddle.text.style.fontFamily, '.SF UI Text');
    expect(bottomMiddle.text.style.letterSpacing, -0.231169798374176);

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.0);

    expect(topBackLabel.text.style.color, const Color(0xFF0073F0));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w400);
    expect(topBackLabel.text.style.fontFamily, '.SF UI Text');
    expect(topBackLabel.text.style.letterSpacing, -0.231169798374176);

    checkOpacity(
        tester, flying(tester, find.text('Page 1')).last, 0.8733493089675903);
  });

  testWidgets('Fullscreen dialogs do not create heroes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
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
        middle: Text('Page 1'),
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
      final RenderParagraph bottomMiddle =
          tester.renderObject(flying(tester, find.text('Page 1')).first);
      expect(bottomMiddle.text.style.color, const Color(0xFF00070F));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).first),
        const Offset(331.0724935531616, 13.5),
      );

      // The top back label is styled exactly the same way. But the opacity tweens
      // are flipped.
      final RenderParagraph topBackLabel =
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

  testWidgets('Popping mid-transition is symmetrical RTL',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      textDirection: TextDirection.rtl,
    );

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    void checkColorAndPositionAt50ms() {
      // The transition's stack is ordered. The bottom middle is inserted first.
      final RenderParagraph bottomMiddle =
          tester.renderObject(flying(tester, find.text('Page 1')).first);
      expect(bottomMiddle.text.style.color, const Color(0xFF00070F));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).first),
        const Offset(366.9275064468384, 13.5),
      );

      // The top back label is styled exactly the same way. But the opacity tweens
      // are flipped.
      final RenderParagraph topBackLabel =
          tester.renderObject(flying(tester, find.text('Page 1')).last);
      expect(topBackLabel.text.style.color, const Color(0xFF00070F));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).last),
        const Offset(366.9275064468384, 13.5),
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

  testWidgets('Multiple nav bars tags do not conflict if in different navigators',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.search),
                title: Text('Tab 1'),
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                title: Text('Tab 2'),
              ),
            ],
          ),
          tabBuilder: (BuildContext context, int tab) {
            return CupertinoTabView(
              builder: (BuildContext context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Tab ${tab + 1} Page 1'),
                  ),
                  child: Center(
                    child: CupertinoButton(
                      child: const Text('Next'),
                      onPressed: () {
                        Navigator.push<void>(context, CupertinoPageRoute<void>(
                          title: 'Tab ${tab + 1} Page 2',
                          builder: (BuildContext context) {
                            return const CupertinoPageScaffold(
                              navigationBar: CupertinoNavigationBar(),
                              child: Placeholder(),
                            );
                          }
                        ));
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Tab 2'));
    await tester.pump();

    expect(find.text('Tab 1 Page 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Tab 2 Page 1'), findsOneWidget);

    // At this point, there are 2 nav bars seeded with the same _defaultHeroTag.
    // But they're inside different navigators.

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // One is inside the flight shuttle and another is invisible in the
    // incoming route in case a new flight needs to be created midflight.
    expect(find.text('Tab 2 Page 2'), findsNWidgets(2));

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tab 2 Page 2'), findsOneWidget);
    // Offstaged by tab 2's navigator.
    expect(find.text('Tab 2 Page 1', skipOffstage: false), findsOneWidget);
    // Offstaged by the CupertinoTabScaffold.
    expect(find.text('Tab 1 Page 1', skipOffstage: false), findsOneWidget);
    // Never navigated to tab 1 page 2.
    expect(find.text('Tab 1 Page 2', skipOffstage: false), findsNothing);
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
    const Widget userMiddle = Placeholder();
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(
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
      CupertinoApp(
        home: scaffoldForNavBar(null),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevron = flying(tester,
        find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevron,
      // Only one exists from the top page. The bottom page has no back chevron.
      findsOneWidget,
    );

    // Come in from the right and fade in.
    checkOpacity(tester, backChevron, 0.0);
    expect(
        tester.getTopLeft(backChevron), const Offset(71.94993209838867, 5.0));

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, backChevron, 0.32467134296894073);
    expect(
        tester.getTopLeft(backChevron), const Offset(18.033634185791016, 5.0));
  });

  testWidgets('First appearance of back chevron fades in from the left in RTL',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder: (BuildContext context, Widget navigator) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: navigator,
          );
        },
        home: scaffoldForNavBar(null),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevron = flying(tester,
        find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevron,
      // Only one exists from the top page. The bottom page has no back chevron.
      findsOneWidget,
    );

    // Come in from the right and fade in.
    checkOpacity(tester, backChevron, 0.0);
    expect(
      tester.getTopRight(backChevron),
      const Offset(694.0500679016113, 5.0),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, backChevron, 0.32467134296894073);
    expect(
      tester.getTopRight(backChevron),
      const Offset(747.966365814209, 5.0),
    );
  });

  testWidgets('Back chevron fades out and in when both pages have it',
      (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevrons = flying(tester,
        find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevrons,
      findsNWidgets(2),
    );

    checkOpacity(tester, backChevrons.first, 0.8393326997756958);
    checkOpacity(tester, backChevrons.last, 0.0);
    // Both overlap at the same place.
    expect(tester.getTopLeft(backChevrons.first), const Offset(8.0, 5.0));
    expect(tester.getTopLeft(backChevrons.last), const Offset(8.0, 5.0));

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, backChevrons.first, 0.0);
    checkOpacity(tester, backChevrons.last, 0.6276369094848633);
    // Still in the same place.
    expect(tester.getTopLeft(backChevrons.first), const Offset(8.0, 5.0));
    expect(tester.getTopLeft(backChevrons.last), const Offset(8.0, 5.0));
  });

  testWidgets('Bottom middle just fades if top page has a custom leading',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      to: const CupertinoSliverNavigationBar(
        leading: Text('custom'),
      ),
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    // There's just 1 in flight because there's no back label on the top page.
    expect(flying(tester, find.text('Page 1')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.8609542846679688);

    // The middle widget doesn't move.
    expect(
      tester.getCenter(flying(tester, find.text('Page 1'))),
      const Offset(400.0, 22.0),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.0);
    expect(
      tester.getCenter(flying(tester, find.text('Page 1'))),
      const Offset(400.0, 22.0),
    );
  });

  testWidgets('Bottom leading fades in place', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(leading: Text('custom')),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('custom')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('custom')), 0.7655444294214249);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(16.0, 0.0),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('custom')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(16.0, 0.0),
    );
  });

  testWidgets('Bottom trailing fades in place', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(trailing: Text('custom')),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('custom')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('custom')), 0.8393326997756958);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(683.0, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('custom')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(683.0, 13.5),
    );
  });

  testWidgets('Bottom back label fades and slides to the left',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 500));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 3',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 'Page 1' appears once on Page 2 as the back label.
    expect(flying(tester, find.text('Page 1')), findsOneWidget);

    // Back label fades out faster.
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.5584745407104492);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1'))),
      const Offset(24.176071166992188, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1'))),
      const Offset(-292.97862243652344, 13.5),
    );
  });

  testWidgets('Bottom back label fades and slides to the right in RTL',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
      textDirection: TextDirection.rtl,
    );

    await tester.pump(const Duration(milliseconds: 500));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 3',
          builder: (BuildContext context) => scaffoldForNavBar(null),
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 'Page 1' appears once on Page 2 as the back label.
    expect(flying(tester, find.text('Page 1')), findsOneWidget);

    // Back label fades out faster.
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.5584745407104492);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 1'))),
      const Offset(775.8239288330078, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.0);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 1'))),
      // >1000. It's now off the screen.
      const Offset(1092.9786224365234, 13.5),
    );
  });

  testWidgets('Bottom large title moves to top back label',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    // There's 2, one from the bottom large title fading out and one from the
    // bottom back label fading in.
    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.8393326997756958);
    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(17.905914306640625, 51.58156871795654),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(17.905914306640625, 51.58156871795654),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.0);
    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.6276369094848633);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(43.278289794921875, 19.23011875152588),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(43.278289794921875, 19.23011875152588),
    );
  });

  testWidgets('Long title turns into the word back mid transition',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'A title too long to fit',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(
        flying(tester, find.text('A title too long to fit')), findsOneWidget);
    // Automatically changed to the word 'Back' in the back label.
    expect(flying(tester, find.text('Back')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('A title too long to fit')),
        0.8393326997756958);
    checkOpacity(tester, flying(tester, find.text('Back')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('A title too long to fit'))),
      const Offset(17.905914306640625, 51.58156871795654),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Back'))),
      const Offset(17.905914306640625, 51.58156871795654),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('A title too long to fit')), 0.0);
    checkOpacity(tester, flying(tester, find.text('Back')), 0.6276369094848633);
    expect(
      tester.getTopLeft(flying(tester, find.text('A title too long to fit'))),
      const Offset(43.278289794921875, 19.23011875152588),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Back'))),
      const Offset(43.278289794921875, 19.23011875152588),
    );
  });

  testWidgets('Bottom large title and top back label transitions their font',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'Page 1',
    );

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // The transition's stack is ordered. The bottom large title is inserted first.
    final RenderParagraph bottomLargeTitle =
        tester.renderObject(flying(tester, find.text('Page 1')).first);
    expect(bottomLargeTitle.text.style.color, const Color(0xFF00070F));
    expect(bottomLargeTitle.text.style.fontWeight, FontWeight.w700);
    expect(bottomLargeTitle.text.style.fontFamily, '.SF Pro Display');
    expect(bottomLargeTitle.text.style.letterSpacing, 0.21141128540039061);

    // The top back label is styled exactly the same way.
    final RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style.color, const Color(0xFF00070F));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w700);
    expect(topBackLabel.text.style.fontFamily, '.SF Pro Display');
    expect(topBackLabel.text.style.letterSpacing, 0.21141128540039061);

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomLargeTitle.text.style.color, const Color(0xFF0073F0));
    expect(bottomLargeTitle.text.style.fontWeight, FontWeight.w400);
    expect(bottomLargeTitle.text.style.fontFamily, '.SF UI Text');
    expect(bottomLargeTitle.text.style.letterSpacing, -0.2135093951225281);

    expect(topBackLabel.text.style.color, const Color(0xFF0073F0));
    expect(topBackLabel.text.style.fontWeight, FontWeight.w400);
    expect(topBackLabel.text.style.fontFamily, '.SF UI Text');
    expect(topBackLabel.text.style.letterSpacing, -0.2135093951225281);
  });

  testWidgets('Top middle fades in and slides in from the right',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 2')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(725.1760711669922, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.6972532719373703);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(408.02137756347656, 13.5),
    );
  });

  testWidgets('Top middle fades in and slides in from the left in RTL',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      toTitle: 'Page 2',
      textDirection: TextDirection.rtl,
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 2')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.0);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(74.82392883300781, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.6972532719373703);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(391.97862243652344, 13.5),
    );
  });

  testWidgets('Top large title fades in and slides in from the right',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      to: const CupertinoSliverNavigationBar(),
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 2')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(768.3521423339844, 54.0),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.6753286570310593);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(134.04275512695312, 54.0),
    );
  });

  testWidgets('Top large title fades in and slides in from the left in RTL',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      to: const CupertinoSliverNavigationBar(),
      toTitle: 'Page 2',
      textDirection: TextDirection.rtl,
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 2')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.0);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(31.647857666015625, 54.0),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.6753286570310593);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(665.9572448730469, 54.0),
    );
  });

  testWidgets('Components are not unnecessarily rebuilt during transitions',
          (WidgetTester tester) async {
    int bottomBuildTimes = 0;
    int topBuildTimes = 0;
    await startTransitionBetween(
      tester,
      from: CupertinoNavigationBar(
        middle: Builder(builder: (BuildContext context) {
          bottomBuildTimes++;
          return const Text('Page 1');
        }),
      ),
      to: CupertinoSliverNavigationBar(
        largeTitle: Builder(builder: (BuildContext context) {
          topBuildTimes++;
          return const Text('Page 2');
        }),
      ),
    );

    expect(bottomBuildTimes, 1);
    // RenderSliverPersistentHeader.layoutChild causes 2 builds.
    expect(topBuildTimes, 2);

    await tester.pump();

    // The shuttle builder builds the component widgets one more time.
    expect(bottomBuildTimes, 2);
    expect(topBuildTimes, 3);

    // Subsequent animation needs to use reprojection of children.
    await tester.pump();
    expect(bottomBuildTimes, 2);
    expect(topBuildTimes, 3);

    await tester.pump(const Duration(milliseconds: 100));
    expect(bottomBuildTimes, 2);
    expect(topBuildTimes, 3);

    // Finish animations.
    await tester.pump(const Duration(milliseconds: 400));

    expect(bottomBuildTimes, 2);
    expect(topBuildTimes, 3);
  });

  testWidgets('Back swipe gesture transitions',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    // Go to the next page.
    await tester.pump(const Duration(milliseconds: 500));

    // Start the gesture at the edge of the screen.
    final TestGesture gesture =  await tester.startGesture(const Offset(5.0, 200.0));
    // Trigger the swipe.
    await gesture.moveBy(const Offset(100.0, 0.0));

    // Back gestures should trigger and draw the hero transition in the very same
    // frame (since the "from" route has already moved to reveal the "to" route).
    await tester.pump();

    // Page 2, which is the middle of the top route, start to fly back to the right.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(352.5802058875561, 13.5),
    );

    // Page 1 is in transition in 2 places. Once as the top back label and once
    // as the bottom middle.
    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    // Past the halfway point now.
    await gesture.moveBy(const Offset(500.0, 0.0));
    await gesture.up();

    await tester.pump();

    // Transition continues.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(654.2055835723877, 13.5),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(720.8727767467499, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Cleans up properly
    expect(() => flying(tester, find.text('Page 1')), throwsAssertionError);
    expect(() => flying(tester, find.text('Page 2')), throwsAssertionError);
    // Just the bottom route's middle now.
    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('Back swipe gesture cancels properly with transition',
      (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    // Go to the next page.
    await tester.pump(const Duration(milliseconds: 500));

    // Start the gesture at the edge of the screen.
    final TestGesture gesture =  await tester.startGesture(const Offset(5.0, 200.0));
    // Trigger the swipe.
    await gesture.moveBy(const Offset(100.0, 0.0));

    // Back gestures should trigger and draw the hero transition in the very same
    // frame (since the "from" route has already moved to reveal the "to" route).
    await tester.pump();

    // Page 2, which is the middle of the top route, start to fly back to the right.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(352.5802058875561, 13.5),
    );

    await gesture.up();
    await tester.pump();

    // Transition continues from the point we let off.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(352.5802058875561, 13.5),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(350.00985169410706, 13.5),
    );

    // Finish the snap back animation.
    await tester.pump(const Duration(milliseconds: 500));

    // Cleans up properly
    expect(() => flying(tester, find.text('Page 1')), throwsAssertionError);
    expect(() => flying(tester, find.text('Page 2')), throwsAssertionError);
    // Back to page 2.
    expect(find.text('Page 2'), findsOneWidget);
  });
}
