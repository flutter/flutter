// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';

void main() {
  MockNavigatorObserver navigatorObserver;

  setUp(() {
    navigatorObserver = MockNavigatorObserver();
  });

  testWidgets('Middle auto-populates with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // There should be a Text widget with the title in the nav bar even though
    // we didn't specify anything in the nav bar constructor.
    expect(find.widgetWithText(CupertinoNavigationBar, 'An iPod'), findsOneWidget);

    // As a title, it should also be centered.
    expect(tester.getCenter(find.text('An iPod')).dx, 400.0);
  });

  testWidgets('Large title auto-populates with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(),
              ],
            ),
          );
        },
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // There should be 2 Text widget with the title in the nav bar. One in the
    // large title position and one in the middle position (though the middle
    // position Text is initially invisible while the sliver is expanded).
    expect(
      find.widgetWithText(CupertinoSliverNavigationBar, 'An iPod'),
      findsNWidgets(2),
    );

    final List<Element> titles = tester.elementList(find.text('An iPod'))
        .toList()
        ..sort((Element a, Element b) {
          final RenderParagraph aParagraph = a.renderObject;
          final RenderParagraph bParagraph = b.renderObject;
          return aParagraph.text.style.fontSize.compareTo(
            bParagraph.text.style.fontSize
          );
        });

    final Iterable<double> opacities = titles.map<double>((Element element) {
      final RenderAnimatedOpacity renderOpacity =
          element.ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
      return renderOpacity.opacity.value;
    });

    expect(opacities, <double> [
        0.0, // Initially the smaller font title is invisible.
        1.0, // The larger font title is visible.
    ]);

    // Check that the large font title is at the right spot.
    expect(
      tester.getTopLeft(find.byWidget(titles[1].widget)),
      const Offset(16.0, 54.0),
    );

    // The smaller, initially invisible title, should still be positioned in the
    // center.
    expect(tester.getCenter(find.byWidget(titles[0].widget)).dx, 400.0);
  });

  testWidgets('Leading auto-populates with back button with previous title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'A Phone',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(CupertinoNavigationBar, 'A Phone'), findsOneWidget);
    expect(tester.getCenter(find.text('A Phone')).dx, 400.0);

    // Also shows the previous page's title next to the back button.
    expect(find.widgetWithText(CupertinoButton, 'An iPod'), findsOneWidget);
    // 2 paddings + 1 ahem character at font size 34.0.
    expect(tester.getTopLeft(find.text('An iPod')).dx, 8.0 + 34.0 + 6.0);
  });

  testWidgets('Previous title is correct on first transition frame', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'A Phone',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      )
    );

    // Trigger the route push
    await tester.pump();
    // Draw the first frame.
    await tester.pump();

    // Also shows the previous page's title next to the back button.
    expect(find.widgetWithText(CupertinoButton, 'An iPod'), findsOneWidget);
  });

  testWidgets('Previous title stays up to date with changing routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      title: 'An iPod',
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: Placeholder(),
        );
      },
    );

    final CupertinoPageRoute<void> route3 = CupertinoPageRoute<void>(
      title: 'A Phone',
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: Placeholder(),
        );
      },
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(route2);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(route3);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).replace(
      oldRoute: route2,
      newRoute: CupertinoPageRoute<void>(
        title: 'An Internet communicator',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        },
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(CupertinoNavigationBar, 'A Phone'), findsOneWidget);
    expect(tester.getCenter(find.text('A Phone')).dx, 400.0);

    // After swapping the route behind the top one, the previous label changes
    // from An iPod to Back (since An Internet communicator is too long to
    // fit in the back button).
    expect(find.widgetWithText(CupertinoButton, 'Back'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Back')).dx, 8.0 + 34.0 + 6.0);
  });

  testWidgets('Back swipe dismiss interrupted by route push', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28728
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: CupertinoButton(
              onPressed: () {
                Navigator.push<void>(scaffoldKey.currentContext, CupertinoPageRoute<void>(
                  builder: (BuildContext context) {
                    return const CupertinoPageScaffold(
                      child: Center(child: Text('route')),
                    );
                  },
                ));
              },
              child: const Text('push'),
            ),
          ),
        ),
      ),
    );

    // Check the basic iOS back-swipe dismiss transition. Dragging the pushed
    // route halfway across the screen will trigger the iOS dismiss animation

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('route'), findsOneWidget);
    expect(find.text('push'), findsNothing);

    TestGesture gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pump();
    expect( // The 'route' route has been dragged to the right, halfway across the screen
      tester.getTopLeft(find.ancestor(of: find.text('route'), matching: find.byType(CupertinoPageScaffold))),
      const Offset(400, 0),
    );
    expect( // The 'push' route is sliding in from the left.
      tester.getTopLeft(find.ancestor(of: find.text('push'), matching: find.byType(CupertinoPageScaffold))).dx,
      lessThan(0),
    );
    await tester.pumpAndSettle();
    expect(find.text('push'), findsOneWidget);
    expect(
      tester.getTopLeft(find.ancestor(of: find.text('push'), matching: find.byType(CupertinoPageScaffold))),
      Offset.zero,
    );
    expect(find.text('route'), findsNothing);


    // Run the dismiss animation 60%, which exposes the route "push" button,
    // and then press the button.

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('route'), findsOneWidget);
    expect(find.text('push'), findsNothing);

    gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(400, 0)); // Drag halfway.
    await gesture.up();
    // Trigger the snapping animation.
    // Since the back swipe drag was brought to >=50% of the screen, it will
    // self snap to finish the pop transition as the gesture is lifted.
    //
    // This drag drop animation is 400ms when dropped exactly halfway
    // (800 / [pixel distance remaining], see
    // _CupertinoBackGestureController.dragEnd). It follows a curve that is very
    // steep initially.
    await tester.pump();
    expect(
      tester.getTopLeft(find.ancestor(of: find.text('route'), matching: find.byType(CupertinoPageScaffold))),
      const Offset(400, 0),
    );
    // Let the dismissing snapping animation go 60%.
    await tester.pump(const Duration(milliseconds: 240));
    expect(
      tester.getTopLeft(find.ancestor(of: find.text('route'), matching: find.byType(CupertinoPageScaffold))).dx,
      moreOrLessEquals(798, epsilon: 1),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('route'), findsOneWidget);
    expect(find.text('push'), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      false,
    );
  });

  testWidgets('Fullscreen route animates correct transform values over time', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            return CupertinoButton(
              child: const Text('Button'),
              onPressed: () {
                Navigator.push<void>(context, CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (BuildContext context) {
                    return Column(
                      children: <Widget>[
                        const Placeholder(),
                        CupertinoButton(
                          child: const Text('Close'),
                          onPressed: () {
                            Navigator.pop<void>(context);
                          },
                        ),
                      ],
                    );
                  },
                ));
              },
            );
          }
        ),
      ),
    );

    // Enter animation.
    await tester.tap(find.text('Button'));
    await tester.pump();

    // We use a higher number of intervals since the animation has to scale the
    // entire screen.

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(443.7, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(291.9, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(168.2, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(89.5, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(48.1, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(26.1, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(14.3, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(7.41, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(3.0, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(0.0, 0.1));

    // Exit animation
    await tester.tap(find.text('Close'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(156.3, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(308.1, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(431.7, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(510.4, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(551.8, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(573.8, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(585.6, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(592.6, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(596.9, 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, closeTo(600.0, 0.1));
  });

  testWidgets('Animated push/pop is not linear', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Text('1'),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          child: Text('2'),
        );
      }
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(route2);
    // The whole transition is 400ms based on CupertinoPageRoute.transitionDuration.
    // Break it up into small chunks.

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-87, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(537, epsilon: 1));

    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-166, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(301, epsilon: 1));

    await tester.pump(const Duration(milliseconds: 50));
    // Translation slows down as time goes on.
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-220, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(141, epsilon: 1));

    // Finish the rest of the animation
    await tester.pump(const Duration(milliseconds: 250));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-179, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(262, epsilon: 1));

    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-100, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(499, epsilon: 1));

    await tester.pump(const Duration(milliseconds: 50));
    // Translation slows down as time goes on.
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-47, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(659, epsilon: 1));
  });

  testWidgets('Dragged pop gesture is linear', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Text('1'),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          child: Text('2'),
        );
      }
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(route2);

    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(0));

    final TestGesture swipeGesture = await tester.startGesture(const Offset(5, 100));

    await swipeGesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-233, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(100));
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      true,
    );

    await swipeGesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-200));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(200));

    // Moving by the same distance each time produces linear movements on both
    // routes.
    await swipeGesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-166, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(300));
  });

  testWidgets('Pop gesture snapping is not linear', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Text('1'),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          child: Text('2'),
        );
      }
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(route2);

    await tester.pumpAndSettle();

    final TestGesture swipeGesture = await tester.startGesture(const Offset(5, 100));

    await swipeGesture.moveBy(const Offset(500, 0));
    await swipeGesture.up();
    await tester.pump();
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-100));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(500));
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      true,
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-19, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(744, epsilon: 1));

    await tester.pump(const Duration(milliseconds: 50));
    // Rate of change is slowing down.
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(-4, epsilon: 1));
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(787, epsilon: 1));

    await tester.pumpAndSettle();
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      false,
    );
  });

  testWidgets('Snapped drags forwards and backwards should signal didStart/StopUserGesture', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[navigatorObserver],
        navigatorKey: navigatorKey,
        home: const Text('1'),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          child: Text('2'),
        );
      }
    );

    navigatorKey.currentState.push(route2);
    await tester.pumpAndSettle();
    verify(navigatorObserver.didPush(any, any)).called(greaterThanOrEqualTo(1));

    await tester.dragFrom(const Offset(5, 100), const Offset(100, 0));
    verify(navigatorObserver.didStartUserGesture(any, any)).called(1);
    await tester.pump();
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(100));
    expect(navigatorKey.currentState.userGestureInProgress, true);

    // Didn't drag far enough to snap into dismissing this route.
    // Each 100px distance takes 100ms to snap back.
    await tester.pump(const Duration(milliseconds: 101));
    // Back to the page covering the whole screen.
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(0));
    expect(navigatorKey.currentState.userGestureInProgress, false);
    verify(navigatorObserver.didStopUserGesture()).called(1);
    verifyNever(navigatorObserver.didPop(any, any));

    await tester.dragFrom(const Offset(5, 100), const Offset(500, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(500));
    expect(navigatorKey.currentState.userGestureInProgress, true);
    verify(navigatorObserver.didPop(any, any)).called(1);

    // Did go far enough to snap out of this route.
    await tester.pump(const Duration(milliseconds: 301));
    // Back to the page covering the whole screen.
    expect(find.text('2'), findsNothing);
    // First route covers the whole screen.
    expect(tester.getTopLeft(find.text('1')).dx, moreOrLessEquals(0));
    expect(navigatorKey.currentState.userGestureInProgress, false);
  });

  /// Regression test for https://github.com/flutter/flutter/issues/29596.
  testWidgets('test edge swipe then drop back at ending point works', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[navigatorObserver],
        onGenerateRoute: (RouteSettings settings) {
          return CupertinoPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? '1' : '2';
              return Center(child: Text('Page $pageNumber'));
            },
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    final TestGesture gesture = await tester.startGesture(const Offset(5, 200));
    // The width of the page.
    await gesture.moveBy(const Offset(800, 0));
    verify(navigatorObserver.didStartUserGesture(any, any)).called(1);
    await gesture.up();
    await tester.pump();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
    verify(navigatorObserver.didPop(any, any)).called(1);
    verify(navigatorObserver.didStopUserGesture()).called(1);
  });

  testWidgets('test edge swipe then drop back at starting point works', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[navigatorObserver],
        onGenerateRoute: (RouteSettings settings) {
          return CupertinoPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? '1' : '2';
              return Center(child: Text('Page $pageNumber'));
            },
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    final TestGesture gesture = await tester.startGesture(const Offset(5, 200));
    // Move right a bit
    await gesture.moveBy(const Offset(300, 0));
    verify(navigatorObserver.didStartUserGesture(any, any)).called(1);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      true,
    );
    await tester.pump();

    // Move back to where we started.
    await gesture.moveBy(const Offset(-300, 0));
    await gesture.up();
    await tester.pump();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);
    verifyNever(navigatorObserver.didPop(any, any));
    verify(navigatorObserver.didStopUserGesture()).called(1);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress,
      false,
    );
  });

  testWidgets('ModalPopup overlay dark mode', (WidgetTester tester) async {
    StateSetter stateSetter;
    Brightness brightness = Brightness.light;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          stateSetter = setter;
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: CupertinoPageScaffold(
              child: Builder(builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () async {
                    await showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) => const SizedBox(),
                    );
                  },
                  child: const Text('tap'),
                );
              }),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color.value,
      0x33000000,
    );

    stateSetter(() { brightness = Brightness.dark; });
    await tester.pump();

    // TODO(LongCatIsLooong): The background overlay SHOULD switch to dark color.
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color.value,
      0x33000000,
    );

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: CupertinoPageScaffold(
          child: Builder(builder: (BuildContext context) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
          }),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color.value,
      0x7A000000,
    );
  });
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}
