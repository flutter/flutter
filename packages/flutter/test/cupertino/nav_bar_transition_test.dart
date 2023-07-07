// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> startTransitionBetween(
  WidgetTester tester, {
  Widget? from,
  Widget? to,
  String? fromTitle,
  String? toTitle,
  TextDirection textDirection = TextDirection.ltr,
  CupertinoThemeData? theme,
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: theme,
      builder: (BuildContext context, Widget? navigator) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
          child: Directionality(
            textDirection: textDirection,
            child: navigator!,
          )
        );
      },
      home: const Placeholder(),
    ),
  );

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(CupertinoPageRoute<void>(
        title: fromTitle,
        builder: (BuildContext context) => scaffoldForNavBar(from)!,
      ));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));

  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(CupertinoPageRoute<void>(
        title: toTitle,
        builder: (BuildContext context) => scaffoldForNavBar(to)!,
      ));

  await tester.pump();
}

CupertinoPageScaffold? scaffoldForNavBar(Widget? navBar) {
  if (navBar is CupertinoNavigationBar || navBar == null) {
    return CupertinoPageScaffold(
      navigationBar: navBar as CupertinoNavigationBar? ?? const CupertinoNavigationBar(),
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
  final ContainerRenderObjectMixin<RenderBox, StackParentData> theater = tester.renderObject(find.byType(Overlay));
  final Finder lastOverlayFinder = find.byElementPredicate((Element element) {
    return element is RenderObjectElement && element.renderObject == theater.lastChild;
  });

  assert(
    find.descendant(
      of: lastOverlayFinder,
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget.runtimeType.toString() == '_NavigationBarTransition',
      ),
    ).evaluate().length == 1,
    'The last overlay in the navigator was not a flying hero',
  );

  return find.descendant(
    of: lastOverlayFinder,
    matching: finder,
  );
}

void checkBackgroundBoxHeight(WidgetTester tester, double height) {
  final Widget transitionBackgroundBox =
      tester.widget<Stack>(flying(tester, find.byType(Stack))).children[0];
  expect(
    tester.widget<SizedBox>(
      find.descendant(
        of: find.byWidget(transitionBackgroundBox),
        matching: find.byType(SizedBox),
      ),
    ).height,
    height,
  );
}

void checkOpacity(WidgetTester tester, Finder finder, double opacity) {
  expect(
    tester.firstRenderObject<RenderAnimatedOpacity>(
      find.ancestor(
        of: finder,
        matching: find.byType(FadeTransition),
      ),
    ).opacity.value,
    moreOrLessEquals(opacity),
  );
}

void main() {
  testWidgets('Bottom middle moves between middle and back label', (WidgetTester tester) async {
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
      const Offset(342.33420100808144, 13.5),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(342.33420100808144, 13.5),
    );
  });

  testWidgets('Bottom middle moves between middle and back label RTL', (WidgetTester tester) async {
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
      const Offset(357.66579899191856, 13.5),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(357.66579899191856, 13.5),
    );
  });

  testWidgets('Bottom middle never changes size during the animation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080.0 / 2.75, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(const Size(800.0, 600.0));
    });

    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
    );

    final Size size = tester.getSize(find.text('Page 1'));

    for (int i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 1));
      expect(flying(tester, find.text('Page 1')), findsNWidgets(2));
      expect(tester.getSize(flying(tester, find.text('Page 1')).first), size);
      expect(tester.getSize(flying(tester, find.text('Page 1')).last), size);
    }
  });

  testWidgets('Bottom middle and top back label transitions their font', (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // The transition's stack is ordered. The bottom middle is inserted first.
    final RenderParagraph bottomMiddle =
        tester.renderObject(flying(tester, find.text('Page 1')).first);
    expect(bottomMiddle.text.style!.color, const Color(0xff000306));
    expect(bottomMiddle.text.style!.fontWeight, FontWeight.w600);
    expect(bottomMiddle.text.style!.fontFamily, '.SF Pro Text');
    expect(bottomMiddle.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.9404401779174805);

    // The top back label is styled exactly the same way. But the opacity tweens
    // are flipped.
    final RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style!.color, const Color(0xff000306));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w600);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Text');
    expect(topBackLabel.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.0);

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomMiddle.text.style!.color, const Color(0xff005ec5));
    expect(bottomMiddle.text.style!.fontWeight, FontWeight.w400);
    expect(bottomMiddle.text.style!.fontFamily, '.SF Pro Text');
    expect(bottomMiddle.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.0);

    expect(topBackLabel.text.style!.color, const Color(0xff005ec5));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w400);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Text');
    expect(topBackLabel.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.5292819738388062);
  });

  testWidgets('Font transitions respect themes', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      theme: const CupertinoThemeData(brightness: Brightness.dark),
    );

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    // The transition's stack is ordered. The bottom middle is inserted first.
    final RenderParagraph bottomMiddle =
        tester.renderObject(flying(tester, find.text('Page 1')).first);
    expect(bottomMiddle.text.style!.color, const Color(0xfff8fbff));
    expect(bottomMiddle.text.style!.fontWeight, FontWeight.w600);
    expect(bottomMiddle.text.style!.fontFamily, '.SF Pro Text');
    expect(bottomMiddle.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.9404401779174805);

    // The top back label is styled exactly the same way. But the opacity tweens
    // are flipped.
    final RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style!.color, const Color(0xfff8fbff));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w600);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Text');
    expect(topBackLabel.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.0);

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomMiddle.text.style!.color, const Color(0xff409fff));
    expect(bottomMiddle.text.style!.fontWeight, FontWeight.w400);
    expect(bottomMiddle.text.style!.fontFamily, '.SF Pro Text');
    expect(bottomMiddle.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.0);

    expect(topBackLabel.text.style!.color, const Color(0xff409fff));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w400);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Text');
    expect(topBackLabel.text.style!.letterSpacing, -0.41);

    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.5292819738388062);
  });

  testWidgets('Fullscreen dialogs do not create heroes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 2',
          fullscreenDialog: true,
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
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

  testWidgets('Popping mid-transition is symmetrical', (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // Be mid-transition.
    await tester.pump(const Duration(milliseconds: 50));

    void checkColorAndPositionAt50ms() {
      // The transition's stack is ordered. The bottom middle is inserted first.
      final RenderParagraph bottomMiddle =
          tester.renderObject(flying(tester, find.text('Page 1')).first);
      expect(bottomMiddle.text.style!.color, const Color(0xff000306));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).first),
        const Offset(342.33420100808144, 13.5),
      );

      // The top back label is styled exactly the same way. But the opacity tweens
      // are flipped.
      final RenderParagraph topBackLabel =
          tester.renderObject(flying(tester, find.text('Page 1')).last);
      expect(topBackLabel.text.style!.color, const Color(0xff000306));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).last),
        const Offset(342.33420100808144, 13.5),
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

  testWidgets('Popping mid-transition is symmetrical RTL', (WidgetTester tester) async {
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
      expect(bottomMiddle.text.style!.color, const Color(0xff000306));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).first),
        const Offset(357.66579899191856, 13.5),
      );

      // The top back label is styled exactly the same way. But the opacity tweens
      // are flipped.
      final RenderParagraph topBackLabel =
          tester.renderObject(flying(tester, find.text('Page 1')).last);
      expect(topBackLabel.text.style!.color, const Color(0xff000306));
      expect(
        tester.getTopLeft(flying(tester, find.text('Page 1')).last),
        const Offset(357.66579899191856, 13.5),
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

  testWidgets('There should be no global keys in the hero flight', (WidgetTester tester) async {
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

  testWidgets('DartPerformanceMode is latency mid-animation', (WidgetTester tester) async {
    DartPerformanceMode? mode;

    // before the animation starts, no requests are active.
    mode = SchedulerBinding.instance.debugGetRequestedPerformanceMode();
    expect(mode, isNull);

    await startTransitionBetween(tester, fromTitle: 'Page 1');

    // mid-transition, latency mode is expected.
    await tester.pump(const Duration(milliseconds: 50));
    mode = SchedulerBinding.instance.debugGetRequestedPerformanceMode();
    expect(mode, equals(DartPerformanceMode.latency));

    // end of transition, go back to no requests active.
    await tester.pump(const Duration(milliseconds: 500));
    mode = SchedulerBinding.instance.debugGetRequestedPerformanceMode();
    expect(mode, isNull);
  });

  testWidgets('Multiple nav bars tags do not conflict if in different navigators', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.search),
                label: 'Tab 1',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: 'Tab 2',
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
                          },
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

  testWidgets('Transition box grows to large title size', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      to: const CupertinoSliverNavigationBar(),
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 45.3376561999321);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 51.012951374053955);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 63.06760931015015);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 75.89544230699539);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 84.33018499612808);
  });

  testWidgets('Large transition box shrinks to standard nav bar size', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 94.6623438000679);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 88.98704862594604);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 76.93239068984985);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 64.10455769300461);

    await tester.pump(const Duration(milliseconds: 50));
    checkBackgroundBoxHeight(tester, 55.66981500387192);
  });

  testWidgets('Hero flight removed at the end of page transition', (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    await tester.pump(const Duration(milliseconds: 50));

    // There's 2 of them. One from the top route's back label and one from the
    // bottom route's middle widget.
    expect(flying(tester, find.text('Page 1')), findsNWidgets(2));

    // End the transition.
    await tester.pump(const Duration(milliseconds: 500));

    expect(() => flying(tester, find.text('Page 1')), throwsAssertionError);
  });

  testWidgets('Exact widget is reused to build inside the transition', (WidgetTester tester) async {
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

  testWidgets('Middle is not shown if alwaysShowMiddle is false and the nav bar is expanded', (WidgetTester tester) async {
    const Widget userMiddle = Placeholder();
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(
        middle: userMiddle,
        alwaysShowMiddle: false,
      ),
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.byWidget(userMiddle)), findsNothing);
  });

  testWidgets('Middle is shown if alwaysShowMiddle is false but the nav bar is collapsed', (WidgetTester tester) async {
    const Widget userMiddle = Placeholder();
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CustomScrollView(
            controller: scrollController,
            slivers: const <Widget>[
              CupertinoSliverNavigationBar(
                largeTitle: Text('Page 1'),
                middle: userMiddle,
                alwaysShowMiddle: false,
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 1200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(600.0);
    await tester.pumpAndSettle();

    // Middle widget is visible when nav bar is collapsed.
    final RenderAnimatedOpacity userMiddleOpacity = tester
        .element(find.byWidget(userMiddle))
        .findAncestorRenderObjectOfType<RenderAnimatedOpacity>()!;
    expect(userMiddleOpacity.opacity.value, 1.0);

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 2',
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.byWidget(userMiddle)), findsOneWidget);
  });

  testWidgets('First appearance of back chevron fades in from the right', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: scaffoldForNavBar(null),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevron = flying(tester, find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevron,
      // Only one exists from the top page. The bottom page has no back chevron.
      findsOneWidget,
    );
    // Come in from the right and fade in.
    checkOpacity(tester, backChevron, 0.0);
    expect(tester.getTopLeft(backChevron), const Offset(88.04496401548386, 7.0));

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, backChevron, 0.09497911669313908);
    expect(tester.getTopLeft(backChevron), const Offset(31.055883467197418, 7.0));
  });

  testWidgets('First appearance of back chevron fades in from the left in RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder: (BuildContext context, Widget? navigator) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: navigator!,
          );
        },
        home: scaffoldForNavBar(null),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(CupertinoPageRoute<void>(
          title: 'Page 1',
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevron = flying(tester, find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevron,
      // Only one exists from the top page. The bottom page has no back chevron.
      findsOneWidget,
    );

    // Come in from the right and fade in.
    checkOpacity(tester, backChevron, 0.0);
    expect(
      tester.getTopRight(backChevron),
      const Offset(685.9550359845161, 7.0),
    );

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, backChevron, 0.09497911669313908);
    expect(
      tester.getTopRight(backChevron),
      const Offset(742.9441165328026, 7.0),
    );
  });

  testWidgets('Back chevron fades out and in when both pages have it', (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1');

    await tester.pump(const Duration(milliseconds: 50));

    final Finder backChevrons = flying(tester, find.text(String.fromCharCode(CupertinoIcons.back.codePoint)));

    expect(
      backChevrons,
      findsNWidgets(2),
    );

    checkOpacity(tester, backChevrons.first, 0.9280824661254883);
    checkOpacity(tester, backChevrons.last, 0.0);
    // Both overlap at the same place.
    expect(tester.getTopLeft(backChevrons.first), const Offset(14.0, 7.0));
    expect(tester.getTopLeft(backChevrons.last), const Offset(14.0, 7.0));

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, backChevrons.first, 0.0);
    checkOpacity(tester, backChevrons.last, 0.4604858811944723);
    // Still in the same place.
    expect(tester.getTopLeft(backChevrons.first), const Offset(14.0, 7.0));
    expect(tester.getTopLeft(backChevrons.last), const Offset(14.0, 7.0));
  });

  testWidgets('Bottom middle just fades if top page has a custom leading', (WidgetTester tester) async {
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

    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.9404401779174805);

    // The middle widget doesn't move.
    expect(
      tester.getCenter(flying(tester, find.text('Page 1'))),
      const Offset(400.0, 22.0),
    );

    await tester.pump(const Duration(milliseconds: 200));
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

    checkOpacity(tester, flying(tester, find.text('custom')), 0.8948725312948227);
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

    checkOpacity(tester, flying(tester, find.text('custom')), 0.9280824661254883);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(684.0, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));
    checkOpacity(tester, flying(tester, find.text('custom')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('custom'))),
      const Offset(684.0, 13.5),
    );
  });

  testWidgets('Bottom back label fades and slides to the left', (WidgetTester tester) async {
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
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 'Page 1' appears once on Page 2 as the back label.
    expect(flying(tester, find.text('Page 1')), findsOneWidget);

    // Back label fades out faster.
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.7952219992876053);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1'))),
      const Offset(41.71033692359924, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1'))),
      const Offset(-258.2321922779083, 13.5),
    );
  });

  testWidgets('Bottom back label fades and slides to the right in RTL', (WidgetTester tester) async {
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
          builder: (BuildContext context) => scaffoldForNavBar(null)!,
        ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 'Page 1' appears once on Page 2 as the back label.
    expect(flying(tester, find.text('Page 1')), findsOneWidget);

    // Back label fades out faster.
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.7952219992876053);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 1'))),
      const Offset(758.2896630764008, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, flying(tester, find.text('Page 1')), 0.0);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 1'))),
      // >1000. It's now off the screen.
      const Offset(1058.2321922779083, 13.5),
    );
  });

  testWidgets('Bottom large title moves to top back label', (WidgetTester tester) async {
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

    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.9280824661254883);
    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(16.926069676876068, 52.73951627314091),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(16.926069676876068, 52.73951627314091),
    );

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, flying(tester, find.text('Page 1')).first, 0.0);
    checkOpacity(tester, flying(tester, find.text('Page 1')).last, 0.4604858811944723);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).first),
      const Offset(43.92089730501175, 22.49655644595623),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 1')).last),
      const Offset(43.92089730501175, 22.49655644595623),
    );
  });

  testWidgets('Long title turns into the word back mid transition', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      from: const CupertinoSliverNavigationBar(),
      fromTitle: 'A title too long to fit',
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('A title too long to fit')), findsOneWidget);
    // Automatically changed to the word 'Back' in the back label.
    expect(flying(tester, find.text('Back')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('A title too long to fit')), 0.9280824661254883);
    checkOpacity(tester, flying(tester, find.text('Back')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('A title too long to fit'))),
      const Offset(16.926069676876068, 52.73951627314091),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Back'))),
      const Offset(16.926069676876068, 52.73951627314091),
    );

    await tester.pump(const Duration(milliseconds: 200));
    checkOpacity(tester, flying(tester, find.text('A title too long to fit')), 0.0);
    checkOpacity(tester, flying(tester, find.text('Back')), 0.4604858811944723);
    expect(
      tester.getTopLeft(flying(tester, find.text('A title too long to fit'))),
      const Offset(43.92089730501175, 22.49655644595623),
    );
    expect(
      tester.getTopLeft(flying(tester, find.text('Back'))),
      const Offset(43.92089730501175, 22.49655644595623),
    );
  });

  testWidgets('Bottom large title and top back label transitions their font', (WidgetTester tester) async {
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
    expect(bottomLargeTitle.text.style!.color, const Color(0xff000306));
    expect(bottomLargeTitle.text.style!.fontWeight, FontWeight.w700);
    expect(bottomLargeTitle.text.style!.fontFamily, '.SF Pro Display');
    expect(bottomLargeTitle.text.style!.letterSpacing, moreOrLessEquals(0.38890619069337845));

    // The top back label is styled exactly the same way.
    final RenderParagraph topBackLabel =
        tester.renderObject(flying(tester, find.text('Page 1')).last);
    expect(topBackLabel.text.style!.color, const Color(0xff000306));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w700);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Display');
    expect(topBackLabel.text.style!.letterSpacing, moreOrLessEquals(0.38890619069337845));

    // Move animation further a bit.
    await tester.pump(const Duration(milliseconds: 200));
    expect(bottomLargeTitle.text.style!.color, const Color(0xff005ec5));
    expect(bottomLargeTitle.text.style!.fontWeight, FontWeight.w500);
    expect(bottomLargeTitle.text.style!.fontFamily, '.SF Pro Text');
    expect(bottomLargeTitle.text.style!.letterSpacing, moreOrLessEquals(-0.2259759941697121));

    expect(topBackLabel.text.style!.color, const Color(0xff005ec5));
    expect(topBackLabel.text.style!.fontWeight, FontWeight.w500);
    expect(topBackLabel.text.style!.fontFamily, '.SF Pro Text');
    expect(topBackLabel.text.style!.letterSpacing, moreOrLessEquals(-0.2259759941697121));
  });

  testWidgets('Top middle fades in and slides in from the right', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      toTitle: 'Page 2',
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(flying(tester, find.text('Page 2')), findsOneWidget);

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.0);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(739.7103369235992, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.29867843724787235);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(504.65044379234314, 13.5),
    );
  });

  testWidgets('Top middle never changes size during the animation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080.0 / 2.75, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(const Size(800.0, 600.0));
    });

    await startTransitionBetween(
      tester,
      toTitle: 'Page 2',
    );

    Size? previousSize;

    for (int i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 1));
      expect(flying(tester, find.text('Page 2')), findsOneWidget);
      final Size size = tester.getSize(flying(tester, find.text('Page 2')));
      if (previousSize != null) {
        expect(size, previousSize);
      }
      previousSize = size;
    }
  });

  testWidgets('Top middle fades in and slides in from the left in RTL', (WidgetTester tester) async {
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
      const Offset(60.28966307640076, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.29867843724787235);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(295.34955620765686, 13.5),
    );
  });

  testWidgets('Top large title fades in and slides in from the right', (WidgetTester tester) async {
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
      const Offset(795.4206738471985, 54.0),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.2601277381181717);
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(325.3008875846863, 54.0),
    );
  });

  testWidgets('Top large title fades in and slides in from the left in RTL', (WidgetTester tester) async {
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
      const Offset(4.579326152801514, 54.0),
    );

    await tester.pump(const Duration(milliseconds: 150));

    checkOpacity(tester, flying(tester, find.text('Page 2')), 0.2601277381181717);
    expect(
      tester.getTopRight(flying(tester, find.text('Page 2'))),
      const Offset(474.6991124153137, 54.0),
    );
  });

  testWidgets('Components are not unnecessarily rebuilt during transitions', (WidgetTester tester) async {
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

  testWidgets('Back swipe gesture transitions', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    // Go to the next page.
    await tester.pump(const Duration(milliseconds: 600));

    // Start the gesture at the edge of the screen.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 200.0));
    // Trigger the swipe.
    await gesture.moveBy(const Offset(100.0, 0.0));

    // Back gestures should trigger and draw the hero transition in the very same
    // frame (since the "from" route has already moved to reveal the "to" route).
    await tester.pump();

    // Page 2, which is the middle of the top route, start to fly back to the right.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(353.5802058875561, 13.5),
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
      const Offset(655.2055835723877, 13.5),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(749.6335566043854, 13.5),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Cleans up properly
    expect(() => flying(tester, find.text('Page 1')), throwsAssertionError);
    expect(() => flying(tester, find.text('Page 2')), throwsAssertionError);
    // Just the bottom route's middle now.
    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('textScaleFactor is set to 1.0 on transition', (WidgetTester tester) async {
    await startTransitionBetween(tester, fromTitle: 'Page 1', textScale: 99);

    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.firstWidget<RichText>(flying(tester, find.byType(RichText))).textScaleFactor, 1);
  });

  testWidgets('Back swipe gesture cancels properly with transition', (WidgetTester tester) async {
    await startTransitionBetween(
      tester,
      fromTitle: 'Page 1',
      toTitle: 'Page 2',
    );

    // Go to the next page.
    await tester.pump(const Duration(milliseconds: 600));

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
      const Offset(353.5802058875561, 13.5),
    );

    await gesture.up();
    await tester.pump();

    // Transition continues from the point we let off.
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(353.5802058875561, 13.5),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getTopLeft(flying(tester, find.text('Page 2'))),
      const Offset(350.0011436641216, 13.5),
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
