// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  MockNavigatorObserver navigatorObserver;

  setUp(() {
    navigatorObserver = MockNavigatorObserver();
  });

  testWidgets(
    'Throws FlutterError with correct message when route builder returns null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
          CupertinoPageRoute<void>(
            title: 'Route 1',
            builder: (_) => null,
          ),
        );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final dynamic error = tester.takeException();
    expect(error, isFlutterError);
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   The builder for route "null" returned null.\n'
      '   Route builders must never return null.\n'
    ));
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
      ),
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
      ),
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
          final RenderParagraph aParagraph = a.renderObject as RenderParagraph;
          final RenderParagraph bParagraph = b.renderObject as RenderParagraph;
          return aParagraph.text.style.fontSize.compareTo(
            bParagraph.text.style.fontSize
          );
        });

    final Iterable<double> opacities = titles.map<double>((Element element) {
      final RenderAnimatedOpacity renderOpacity =
          element.findAncestorRenderObjectOfType<RenderAnimatedOpacity>();
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
      ),
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
      ),
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
      ),
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
      ),
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

    // Use the navigator to push a route instead of tapping the 'push' button.
    // The topmost route (the one that's animating away), ignores input while
    // the pop is underway because route.navigator.userGestureInProgress.
    Navigator.push<void>(scaffoldKey.currentContext, CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          child: Center(child: Text('route')),
        );
      },
    ));

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
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(443.7, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(291.9, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(168.2, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(89.5, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(48.1, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(26.1, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(14.3, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(7.41, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(3.0, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(0.0, epsilon: 0.1));

    // Exit animation
    await tester.tap(find.text('Close'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(156.3, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(308.1, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(431.7, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(510.4, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(551.8, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(573.8, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(585.6, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(592.6, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(596.9, epsilon: 0.1));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dy, moreOrLessEquals(600.0, epsilon: 0.1));
  });

  Future<void> testParallax(WidgetTester tester, {@required bool fromFullscreenDialog}) async {
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) => CupertinoPageRoute<void>(
          fullscreenDialog: fromFullscreenDialog,
          settings: settings,
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                const Placeholder(),
                CupertinoButton(
                  child: const Text('Button'),
                  onPressed: () {
                    Navigator.push<void>(context, CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return CupertinoButton(
                          child: const Text('Close'),
                          onPressed: () {
                            Navigator.pop<void>(context);
                          },
                        );
                      },
                    ));
                  },
                ),
              ],
            );
          }
        ),
      ),
    );

    // Enter animation.
    await tester.tap(find.text('Button'));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(0.0, epsilon: 0.1));
    await tester.pump();

    // We use a higher number of intervals since the animation has to scale the
    // entire screen.

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-70.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-137.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-192.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-227.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-246.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-255.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-260.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-264.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-266.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-267.0, epsilon: 1.0));

    // Exit animation
    await tester.tap(find.text('Button'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-198.0, epsilon: 1.0));

    await tester.pump(const Duration(milliseconds: 360));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(-0.0, epsilon: 1.0));
  }

  testWidgets('CupertinoPageRoute has parallax when non fullscreenDialog route is pushed on top', (WidgetTester tester) async {
    await testParallax(tester, fromFullscreenDialog: false);
  });

  testWidgets('FullscreenDialog CupertinoPageRoute has parallax when non fullscreenDialog route is pushed on top', (WidgetTester tester) async {
    await testParallax(tester, fromFullscreenDialog: true);
  });

  Future<void> testNoParallax(WidgetTester tester, {@required bool fromFullscreenDialog}) async{
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) => CupertinoPageRoute<void>(
          fullscreenDialog: fromFullscreenDialog,
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                const Placeholder(),
                CupertinoButton(
                  child: const Text('Button'),
                  onPressed: () {
                    Navigator.push<void>(context, CupertinoPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (BuildContext context) {
                        return CupertinoButton(
                          child: const Text('Close'),
                          onPressed: () {
                            Navigator.pop<void>(context);
                          },
                        );
                      },
                    ));
                  },
                ),
              ],
            );
          }
        ),
      ),
    );

    // Enter animation.
    await tester.tap(find.text('Button'));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, moreOrLessEquals(0.0, epsilon: 0.1));
    await tester.pump();

    // We use a higher number of intervals since the animation has to scale the
    // entire screen.

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    // Exit animation
    await tester.tap(find.text('Button'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);

    await tester.pump(const Duration(milliseconds: 360));
    expect(tester.getTopLeft(find.byType(Placeholder)).dx, 0.0);
  }

  testWidgets('CupertinoPageRoute has no parallax when fullscreenDialog route is pushed on top', (WidgetTester tester) async {
    await testNoParallax(tester, fromFullscreenDialog: false);
  });

  testWidgets('FullscreenDialog CupertinoPageRoute has no parallax when fullscreenDialog route is pushed on top', (WidgetTester tester) async {
    await testNoParallax(tester, fromFullscreenDialog: true);
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
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didPush);

    await tester.dragFrom(const Offset(5, 100), const Offset(100, 0));
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStartUserGesture);
    await tester.pump();
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(100));
    expect(navigatorKey.currentState.userGestureInProgress, true);

    // Didn't drag far enough to snap into dismissing this route.
    // Each 100px distance takes 100ms to snap back.
    await tester.pump(const Duration(milliseconds: 101));
    // Back to the page covering the whole screen.
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(0));
    expect(navigatorKey.currentState.userGestureInProgress, false);

    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStopUserGesture);
    expect(navigatorObserver.invocations.removeLast(), isNot(NavigatorInvocation.didPop));

    await tester.dragFrom(const Offset(5, 100), const Offset(500, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('2')).dx, moreOrLessEquals(500));
    expect(navigatorKey.currentState.userGestureInProgress, true);
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didPop);

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
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStartUserGesture);
    await gesture.up();
    await tester.pump();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStopUserGesture);
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didPop);
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
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStartUserGesture);
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
    expect(navigatorObserver.invocations.removeLast(), NavigatorInvocation.didStopUserGesture);
    expect(navigatorObserver.invocations.removeLast(), isNot(NavigatorInvocation.didPop));
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

  testWidgets('During back swipe the route ignores input', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/39989

    final GlobalKey homeScaffoldKey = GlobalKey();
    final GlobalKey pageScaffoldKey = GlobalKey();
    int homeTapCount = 0;
    int pageTapCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: homeScaffoldKey,
          child: GestureDetector(
            onTap: () {
              homeTapCount += 1;
            }
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(homeScaffoldKey));
    expect(homeTapCount, 1);
    expect(pageTapCount, 0);

    Navigator.push<void>(homeScaffoldKey.currentContext, CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
          key: pageScaffoldKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                pageTapCount += 1;
              }
            ),
          ),
        );
      },
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pageScaffoldKey));
    expect(homeTapCount, 1);
    expect(pageTapCount, 1);

    // Start the basic iOS back-swipe dismiss transition. Drag the pushed
    // "page" route halfway across the screen. The underlying "home" will
    // start sliding in from the left.

    final TestGesture gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(pageScaffoldKey)), const Offset(400, 0));
    expect(tester.getTopLeft(find.byKey(homeScaffoldKey)).dx, lessThan(0));

    // Tapping on the "page" route doesn't trigger the GestureDetector because
    // it's being dragged.
    await tester.tap(find.byKey(pageScaffoldKey));
    expect(homeTapCount, 1);
    expect(pageTapCount, 1);
  });

  testWidgets('showCupertinoModalPopup uses root navigator by default', (WidgetTester tester) async {
    final PopupObserver rootObserver = PopupObserver();
    final PopupObserver nestedObserver = PopupObserver();

    await tester.pumpWidget(CupertinoApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.text('tap'));

    expect(rootObserver.popupCount, 1);
    expect(nestedObserver.popupCount, 0);
  });

  testWidgets('back swipe to screen edges does not dismiss the hero animation', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final UniqueKey container = UniqueKey();
    await tester.pumpWidget(CupertinoApp(
      navigatorKey: navigator,
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) {
          return CupertinoPageScaffold(
            child: Center(
              child: Hero(
                tag: 'tag',
                transitionOnUserGestures: true,
                child: Container(key: container, height: 150.0, width: 150.0)
              ),
            )
          );
        },
        '/page2': (BuildContext context) {
          return CupertinoPageScaffold(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(100.0, 0.0, 0.0, 0.0),
                child: Hero(
                  tag: 'tag',
                  transitionOnUserGestures: true,
                  child: Container(key: container, height: 150.0, width: 150.0)
                )
              ),
            )
          );
        }
      },
    ));

    RenderBox box = tester.renderObject(find.byKey(container)) as RenderBox;
    final double initialPosition = box.localToGlobal(Offset.zero).dx;

    navigator.currentState.pushNamed('/page2');
    await tester.pumpAndSettle();
    box = tester.renderObject(find.byKey(container)) as RenderBox;
    final double finalPosition = box.localToGlobal(Offset.zero).dx;

    final TestGesture gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    box = tester.renderObject(find.byKey(container)) as RenderBox;
    final double firstPosition = box.localToGlobal(Offset.zero).dx;
    // Checks the hero is in-transit.
    expect(finalPosition, greaterThan(firstPosition));
    expect(firstPosition, greaterThan(initialPosition));

    // Goes back to final position.
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    box = tester.renderObject(find.byKey(container)) as RenderBox;
    final double secondPosition = box.localToGlobal(Offset.zero).dx;
    // There will be a small difference.
    expect(finalPosition - secondPosition, lessThan(0.001));

    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    box = tester.renderObject(find.byKey(container)) as RenderBox;
    final double thirdPosition = box.localToGlobal(Offset.zero).dx;
    // Checks the hero is still in-transit and moves further away from the first
    // position.
    expect(finalPosition, greaterThan(thirdPosition));
    expect(thirdPosition, greaterThan(initialPosition));
    expect(firstPosition, greaterThan(thirdPosition));
  });

  testWidgets('showCupertinoModalPopup uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final PopupObserver rootObserver = PopupObserver();
    final PopupObserver nestedObserver = PopupObserver();

    await tester.pumpWidget(CupertinoApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.text('tap'));

    expect(rootObserver.popupCount, 0);
    expect(nestedObserver.popupCount, 1);
  });

  testWidgets('showCupertinoDialog uses root navigator by default', (WidgetTester tester) async {
    final DialogObserver rootObserver = DialogObserver();
    final DialogObserver nestedObserver = DialogObserver();

    await tester.pumpWidget(CupertinoApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoDialog<void>(
                    context: context,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.text('tap'));

    expect(rootObserver.dialogCount, 1);
    expect(nestedObserver.dialogCount, 0);
  });

  testWidgets('showCupertinoDialog uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final DialogObserver rootObserver = DialogObserver();
    final DialogObserver nestedObserver = DialogObserver();

    await tester.pumpWidget(CupertinoApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.text('tap'));

    expect(rootObserver.dialogCount, 0);
    expect(nestedObserver.dialogCount, 1);
  });

  testWidgets('showCupertinoModalPopup does not allow for semantics dismiss by default', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(CupertinoApp(
      home: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Push the route.
    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();

    expect(semantics, isNot(includesNodeWith(
      actions: <SemanticsAction>[SemanticsAction.tap],
      label: 'Dismiss',
    )));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('showCupertinoModalPopup allows for semantics dismiss when set', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(CupertinoApp(
      home: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<dynamic>(
            pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
              return GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    semanticsDismissible: true,
                    builder: (BuildContext context) => const SizedBox(),
                  );
                },
                child: const Text('tap'),
              );
            },
          );
        },
      ),
    ));

    // Push the route.
    await tester.tap(find.text('tap'));
    await tester.pumpAndSettle();

    expect(semantics, includesNodeWith(
      actions: <SemanticsAction>[SemanticsAction.tap],
      label: 'Dismiss',
    ));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('CupertinoPage works', (WidgetTester tester) async {
    final LocalKey pageKey = UniqueKey();
    final TransitionDetector detector = TransitionDetector();
    List<Page<void>> myPages = <Page<void>>[
      CupertinoPage<void>(
        key: pageKey,
        title: 'title one',
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(key: UniqueKey()),
          child: const Text('first'),
        ),
      ),
    ];
    await tester.pumpWidget(
      buildNavigator(
        pages: myPages,
        onPopPage: (Route<dynamic> route, dynamic result) => null,
        transitionDelegate: detector,
      )
    );

    expect(detector.hasTransition, isFalse);
    expect(find.widgetWithText(CupertinoNavigationBar, 'title one'), findsOneWidget);
    expect(find.text('first'), findsOneWidget);

    myPages = <Page<void>>[
      CupertinoPage<void>(
        key: pageKey,
        title: 'title two',
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(key: UniqueKey()),
          child: const Text('second'),
        ),
      ),
    ];

    await tester.pumpWidget(
      buildNavigator(
        pages: myPages,
        onPopPage: (Route<dynamic> route, dynamic result) => null,
        transitionDelegate: detector,
      )
    );

    // There should be no transition because the page has the same key.
    expect(detector.hasTransition, isFalse);
    // The content does update.
    expect(find.text('first'), findsNothing);
    expect(find.widgetWithText(CupertinoNavigationBar, 'title one'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.widgetWithText(CupertinoNavigationBar, 'title two'), findsOneWidget);
  });

  testWidgets('CupertinoPage can toggle MaintainState', (WidgetTester tester) async {
    final LocalKey pageKeyOne = UniqueKey();
    final LocalKey pageKeyTwo = UniqueKey();
    final TransitionDetector detector = TransitionDetector();
    List<Page<void>> myPages = <Page<void>>[
      CupertinoPage<void>(key: pageKeyOne, maintainState: false, child: const Text('first')),
      CupertinoPage<void>(key: pageKeyTwo, child: const Text('second')),
    ];
    await tester.pumpWidget(
      buildNavigator(
        pages: myPages,
        onPopPage: (Route<dynamic> route, dynamic result) => null,
        transitionDelegate: detector,
      )
    );

    expect(detector.hasTransition, isFalse);
    // Page one does not maintain state.
    expect(find.text('first', skipOffstage: false), findsNothing);
    expect(find.text('second'), findsOneWidget);

    myPages = <Page<void>>[
      CupertinoPage<void>(key: pageKeyOne, maintainState: true, child: const Text('first')),
      CupertinoPage<void>(key: pageKeyTwo, child: const Text('second')),
    ];

    await tester.pumpWidget(
      buildNavigator(
        pages: myPages,
        onPopPage: (Route<dynamic> route, dynamic result) => null,
        transitionDelegate: detector,
      )
    );
    // There should be no transition because the page has the same key.
    expect(detector.hasTransition, isFalse);
    // Page one sets the maintain state to be true, its widget tree should be
    // built.
    expect(find.text('first', skipOffstage: false), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
  });
}

class MockNavigatorObserver extends NavigatorObserver {
  final List<NavigatorInvocation> invocations = <NavigatorInvocation>[];

  @override
  void didStartUserGesture(Route<Object> route, Route<Object> previousRoute) {
    invocations.add(NavigatorInvocation.didStartUserGesture);
  }

  @override
  void didPop(Route<Object> route, Route<Object> previousRoute) {
    invocations.add(NavigatorInvocation.didPop);
  }

  @override
  void didPush(Route<Object> route, Route<Object> previousRoute) {
    invocations.add(NavigatorInvocation.didPush);
  }

  @override
  void didStopUserGesture() {
    invocations.add(NavigatorInvocation.didStopUserGesture);
  }
}

enum NavigatorInvocation {
  didStartUserGesture,
  didPop,
  didPush,
  didStopUserGesture,
}

class PopupObserver extends NavigatorObserver {
  int popupCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_CupertinoModalPopupRoute')) {
      popupCount++;
    }
    super.didPush(route, previousRoute);
  }
}

class DialogObserver extends NavigatorObserver {
  int dialogCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_DialogRoute')) {
      dialogCount++;
    }
    super.didPush(route, previousRoute);
  }
}

class TransitionDetector extends DefaultTransitionDelegate<void> {
  bool hasTransition = false;
  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes
  }) {
    hasTransition = true;
    return super.resolve(
      newPageRouteHistory: newPageRouteHistory,
      locationToExitingPageRoute: locationToExitingPageRoute,
      pageRouteToPagelessRoutes: pageRouteToPagelessRoutes
    );
  }
}

Widget buildNavigator({
  List<Page<dynamic>> pages,
  PopPageCallback onPopPage,
  GlobalKey<NavigatorState> key,
  TransitionDelegate<dynamic> transitionDelegate
}) {
  return MediaQuery(
    data: MediaQueryData.fromWindow(WidgetsBinding.instance.window),
    child: Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: key,
          pages: pages,
          onPopPage: onPopPage,
          transitionDelegate: transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
        ),
      ),
    ),
  );
}
