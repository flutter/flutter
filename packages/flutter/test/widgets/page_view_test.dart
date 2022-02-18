// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';
import 'semantics_tester.dart';
import 'states.dart';

void main() {
  testWidgets('PageView resize from zero-size viewport should not lose state', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/88956
    final PageController controller = PageController(
      initialPage: 1,
    );

    Widget build(Size size) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PageView(
              controller: controller,
              onPageChanged: (int page) { },
              children: kStates.map<Widget>((String state) => Text(state)).toList(),
            ),
          ),
        ),
      );
    }

    // The pageView have a zero viewport, so nothing display.
    await tester.pumpWidget(build(Size.zero));
    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alabama', skipOffstage: false), findsOneWidget);

    // Resize from zero viewport to non-zero, the controller's initialPage 1 will display.
    await tester.pumpWidget(build(const Size(200.0, 200.0)));
    expect(find.text('Alaska'), findsOneWidget);

    // Jump to page 'Iowa'.
    controller.jumpToPage(kStates.indexOf('Iowa'));
    await tester.pump();
    expect(find.text('Iowa'), findsOneWidget);

    // Resize to zero viewport again, nothing display.
    await tester.pumpWidget(build(Size.zero));
    expect(find.text('Iowa'), findsNothing);

    // Resize from zero to non-zero, the pageView should not lose state, so the page 'Iowa' show again.
    await tester.pumpWidget(build(const Size(200.0, 200.0)));
    expect(find.text('Iowa'), findsOneWidget);
  });

  testWidgets('Change the page through the controller when zero-size viewport', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/88956
    final PageController controller = PageController(
      initialPage: 1,
    );

    Widget build(Size size) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PageView(
              controller: controller,
              onPageChanged: (int page) { },
              children: kStates.map<Widget>((String state) => Text(state)).toList(),
            ),
          ),
        ),
      );
    }

    // The pageView have a zero viewport, so nothing display.
    await tester.pumpWidget(build(Size.zero));
    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alabama', skipOffstage: false), findsOneWidget);

    // Change the page through the page controller when zero viewport
    controller.animateToPage(kStates.indexOf('Iowa'), duration: kTabScrollDuration, curve: Curves.ease);
    expect(controller.page, kStates.indexOf('Iowa'));

    controller.jumpToPage(kStates.indexOf('Illinois'));
    expect(controller.page, kStates.indexOf('Illinois'));

    // Resize from zero viewport to non-zero, the latest state should not lost.
    await tester.pumpWidget(build(const Size(200.0, 200.0)));
    expect(controller.page, kStates.indexOf('Illinois'));
    expect(find.text('Illinois'), findsOneWidget);
  });

  testWidgets('PageController cannot return page while unattached',
      (WidgetTester tester) async {
    final PageController controller = PageController();
    expect(() => controller.page, throwsAssertionError);
  });

  testWidgets('PageView control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
        dragStartBehavior: DragStartBehavior.down,
        children: kStates.map<Widget>((String state) {
          return GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onTap: () {
              log.add(state);
            },
            child: Container(
              height: 200.0,
              color: const Color(0xFF0000FF),
              child: Text(state),
            ),
          );
        }).toList(),
      ),
    ));

    await tester.tap(find.text('Alabama'));
    expect(log, equals(<String>['Alabama']));
    log.clear();

    expect(find.text('Alaska'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-20.0, 0.0));
    await tester.pump();

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-401.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    await tester.tap(find.text('Alaska'));
    expect(log, equals(<String>['Alaska']));
    log.clear();

    await tester.fling(find.byType(PageView), const Offset(-200.0, 0.0), 1000.0);
    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsNothing);
    expect(find.text('Arizona'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(200.0, 0.0), 1000.0);
    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);
  });

  testWidgets('PageView does not squish when overscrolled', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PageView(
        children: List<Widget>.generate(10, (int i) {
          return Container(
            key: ValueKey<int>(i),
            color: const Color(0xFF0000FF),
          );
        }),
      ),
    ));

    Size sizeOf(int i) => tester.getSize(find.byKey(ValueKey<int>(i)));
    double leftOf(int i) => tester.getTopLeft(find.byKey(ValueKey<int>(i))).dx;

    expect(leftOf(0), equals(0.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    // Going into overscroll.
    await tester.drag(find.byType(PageView), const Offset(100.0, 0.0));
    await tester.pump();

    expect(leftOf(0), greaterThan(0.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));

    // Easing overscroll past overscroll limit.
    await tester.drag(find.byType(PageView), const Offset(-200.0, 0.0));
    await tester.pump();

    expect(leftOf(0), lessThan(0.0));
    expect(sizeOf(0), equals(const Size(800.0, 600.0)));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('PageController control test', (WidgetTester tester) async {
    final PageController controller = PageController(initialPage: 4);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 600.0,
          height: 400.0,
          child: PageView(
            controller: controller,
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('California'), findsOneWidget);

    controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle();

    expect(find.text('Colorado'), findsOneWidget);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300.0,
          height: 400.0,
          child: PageView(
            controller: controller,
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Colorado'), findsOneWidget);

    controller.previousPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle();

    expect(find.text('California'), findsOneWidget);
  });

  testWidgets('PageController page stability', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 600.0,
          height: 400.0,
          child: PageView(
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Alabama'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-1250.0, 0.0));
    await tester.pumpAndSettle();

    expect(find.text('Arizona'), findsOneWidget);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 250.0,
          height: 100.0,
          child: PageView(
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Arizona'), findsOneWidget);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 450.0,
          height: 400.0,
          child: PageView(
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Arizona'), findsOneWidget);
  });

  testWidgets('PageController nextPage and previousPage return Futures that resolve', (WidgetTester tester) async {
    final PageController controller = PageController();
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: controller,
          children: kStates.map<Widget>((String state) => Text(state)).toList(),
        ),
    ));

    bool nextPageCompleted = false;
    controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.ease)
        .then((_) => nextPageCompleted = true);

    expect(nextPageCompleted, false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(nextPageCompleted, false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(nextPageCompleted, true);


    bool previousPageCompleted = false;
    controller.previousPage(duration: const Duration(milliseconds: 150), curve: Curves.ease)
        .then((_) => previousPageCompleted = true);

    expect(previousPageCompleted, false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(previousPageCompleted, false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(previousPageCompleted, true);
  });

  testWidgets('PageView in zero-size container', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 0.0,
          height: 0.0,
          child: PageView(
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Alabama', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200.0,
          height: 200.0,
          child: PageView(
            children: kStates.map<Widget>((String state) => Text(state)).toList(),
          ),
        ),
      ),
    ));

    expect(find.text('Alabama'), findsOneWidget);
  });

  testWidgets('Page changes at halfway point', (WidgetTester tester) async {
    final List<int> log = <int>[];
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
        onPageChanged: log.add,
        children: kStates.map<Widget>((String state) => Text(state)).toList(),
      ),
    ));

    expect(log, isEmpty);

    final TestGesture gesture =
        await tester.startGesture(const Offset(100.0, 100.0));
    // The page view is 800.0 wide, so this move is just short of halfway.
    await gesture.moveBy(const Offset(-380.0, 0.0));

    expect(log, isEmpty);

    // We've crossed the halfway mark.
    await gesture.moveBy(const Offset(-40.0, 0.0));

    expect(log, equals(const <int>[1]));
    log.clear();

    // Moving a bit more should not generate redundant notifications.
    await gesture.moveBy(const Offset(-40.0, 0.0));

    expect(log, isEmpty);

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    await gesture.moveBy(const Offset(-40.0, 0.0));
    await tester.pump();

    expect(log, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(log, isEmpty);

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
  });

  testWidgets('Bouncing scroll physics ballistics does not overshoot', (WidgetTester tester) async {
    final List<int> log = <int>[];
    final PageController controller = PageController(viewportFraction: 0.9);

    Widget build(PageController controller, { Size? size }) {
      final Widget pageView = Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: controller,
          onPageChanged: log.add,
          physics: const BouncingScrollPhysics(),
          children: kStates.map<Widget>((String state) => Text(state)).toList(),
        ),
      );

      if (size != null) {
        return OverflowBox(
          minWidth: size.width,
          minHeight: size.height,
          maxWidth: size.width,
          maxHeight: size.height,
          child: pageView,
        );
      } else {
        return pageView;
      }
    }

    await tester.pumpWidget(build(controller));
    expect(log, isEmpty);

    // Fling right to move to a non-existent page at the beginning of the
    // PageView, and confirm that the PageView settles back on the first page.
    await tester.fling(find.byType(PageView), const Offset(100.0, 0.0), 800.0);
    await tester.pumpAndSettle();
    expect(log, isEmpty);

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);

    // Try again with a Cupertino "Plus" device size.
    await tester.pumpWidget(build(controller, size: const Size(414.0, 736.0)));
    expect(log, isEmpty);

    await tester.fling(find.byType(PageView), const Offset(100.0, 0.0), 800.0);
    await tester.pumpAndSettle();
    expect(log, isEmpty);

    expect(find.text('Alabama'), findsOneWidget);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsNothing);
  });

  testWidgets('PageView viewportFraction', (WidgetTester tester) async {
    PageController controller = PageController(viewportFraction: 7/8);

    Widget build(PageController controller) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          controller: controller,
          itemCount: kStates.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              height: 200.0,
              color: index.isEven
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
              child: Text(kStates[index]),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Alaska')), const Offset(750.0, 0.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Georgia')), const Offset(-650.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(750.0, 0.0));

    controller = PageController(viewportFraction: 39/40);

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Georgia')), const Offset(-770.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(10.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(790.0, 0.0));
  });

  testWidgets('Page snapping disable and reenable', (WidgetTester tester) async {
    final List<int> log = <int>[];

    Widget build({ required bool pageSnapping }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          pageSnapping: pageSnapping,
          onPageChanged: log.add,
          children:
              kStates.map<Widget>((String state) => Text(state)).toList(),
        ),
      );
    }

    await tester.pumpWidget(build(pageSnapping: true));
    expect(log, isEmpty);

    // Drag more than halfway to the next page, to confirm the default behavior.
    TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    // The page view is 800.0 wide, so this move is just beyond halfway.
    await gesture.moveBy(const Offset(-420.0, 0.0));

    expect(log, equals(const <int>[1]));
    log.clear();

    // Release the gesture, confirm that the page settles on the next.
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);

    // Disable page snapping, and try moving halfway. Confirm it doesn't snap.
    await tester.pumpWidget(build(pageSnapping: false));
    gesture = await tester.startGesture(const Offset(100.0, 100.0));
    // Move just beyond halfway, again.
    await gesture.moveBy(const Offset(-420.0, 0.0));

    // Page notifications still get sent.
    expect(log, equals(const <int>[2]));
    log.clear();

    // Release the gesture, confirm that both pages are visible.
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Alabama'), findsNothing);
    expect(find.text('Alaska'), findsOneWidget);
    expect(find.text('Arizona'), findsOneWidget);
    expect(find.text('Arkansas'), findsNothing);

    // Now re-enable snapping, confirm that we've settled on a page.
    await tester.pumpWidget(build(pageSnapping: true));
    await tester.pumpAndSettle();

    expect(log, isEmpty);

    expect(find.text('Alaska'), findsNothing);
    expect(find.text('Arizona'), findsOneWidget);
    expect(find.text('Arkansas'), findsNothing);
  });

  testWidgets('PageView small viewportFraction', (WidgetTester tester) async {
    final PageController controller = PageController(viewportFraction: 1/8);

    Widget build(PageController controller) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          controller: controller,
          itemCount: kStates.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              height: 200.0,
              color: index.isEven
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
              child: Text(kStates[index]),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(350.0, 0.0));
    expect(tester.getTopLeft(find.text('Alaska')), const Offset(450.0, 0.0));
    expect(tester.getTopLeft(find.text('Arizona')), const Offset(550.0, 0.0));
    expect(tester.getTopLeft(find.text('Arkansas')), const Offset(650.0, 0.0));
    expect(tester.getTopLeft(find.text('California')), const Offset(750.0, 0.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Connecticut')), const Offset(-50.0, 0.0));
    expect(tester.getTopLeft(find.text('Delaware')), const Offset(50.0, 0.0));
    expect(tester.getTopLeft(find.text('Florida')), const Offset(150.0, 0.0));
    expect(tester.getTopLeft(find.text('Georgia')), const Offset(250.0, 0.0));
    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(350.0, 0.0));
    expect(tester.getTopLeft(find.text('Idaho')), const Offset(450.0, 0.0));
    expect(tester.getTopLeft(find.text('Illinois')), const Offset(550.0, 0.0));
    expect(tester.getTopLeft(find.text('Indiana')), const Offset(650.0, 0.0));
    expect(tester.getTopLeft(find.text('Iowa')), const Offset(750.0, 0.0));
  });

  testWidgets('PageView large viewportFraction', (WidgetTester tester) async {
    final PageController controller = PageController(viewportFraction: 5/4);

    Widget build(PageController controller) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          controller: controller,
          itemCount: kStates.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              height: 200.0,
              color: index.isEven
                ? const Color(0xFF0000FF)
                : const Color(0xFF00FF00),
              child: Text(kStates[index]),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(build(controller));

    expect(tester.getTopLeft(find.text('Alabama')), const Offset(-100.0, 0.0));
    expect(tester.getBottomRight(find.text('Alabama')), const Offset(900.0, 600.0));

    controller.jumpToPage(10);
    await tester.pump();

    expect(tester.getTopLeft(find.text('Hawaii')), const Offset(-100.0, 0.0));
  });

  testWidgets(
    'Updating PageView large viewportFraction',
    (WidgetTester tester) async {
      Widget build(PageController controller) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: controller,
            itemCount: kStates.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 200.0,
                color: index.isEven
                  ? const Color(0xFF0000FF)
                  : const Color(0xFF00FF00),
                child: Text(kStates[index]),
              );
            },
          ),
        );
      }

      final PageController oldController = PageController(viewportFraction: 5/4);
      await tester.pumpWidget(build(oldController));

      expect(tester.getTopLeft(find.text('Alabama')), const Offset(-100, 0));
      expect(tester.getBottomRight(find.text('Alabama')), const Offset(900.0, 600.0));

      final PageController newController = PageController(viewportFraction: 4);
      await tester.pumpWidget(build(newController));
      newController.jumpToPage(10);
      await tester.pump();

      expect(tester.getTopLeft(find.text('Hawaii')), const Offset(-(4 - 1) * 800 / 2, 0));
    },
  );

  testWidgets(
    'PageView large viewportFraction can scroll to the last page and snap',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/45096.
      final PageController controller = PageController(viewportFraction: 5/4);

      Widget build(PageController controller) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: controller,
            itemCount: 3,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 200.0,
                color: index.isEven
                  ? const Color(0xFF0000FF)
                  : const Color(0xFF00FF00),
                  child: Text(index.toString()),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build(controller));

      expect(tester.getCenter(find.text('0')), const Offset(400, 300));

      controller.jumpToPage(2);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.getCenter(find.text('2')), const Offset(400, 300));
    },
  );

  testWidgets(
    'All visible pages are able to receive touch events',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/23873.
      final PageController controller = PageController(viewportFraction: 1/4);
      late int tappedIndex;

      Widget build() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: controller,
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () => tappedIndex = index,
                child: SizedBox.expand(child: Text('$index')),
              );
            },
          ),
        );
      }

      Iterable<int> visiblePages = const <int> [0, 1, 2];
      await tester.pumpWidget(build());

      // The first 3 items should be visible and tappable.
      for (final int index in visiblePages) {
        expect(find.text(index.toString()), findsOneWidget);
        // The center of page 2's x-coordinate is 800, so we have to manually
        // offset it a bit to make sure the tap lands within the screen.
        final Offset center = tester.getCenter(find.text('$index')) - const Offset(3, 0);
        await tester.tapAt(center);
        expect(tappedIndex, index);
      }

      controller.jumpToPage(19);
      await tester.pump();
      // The last 3 items should be visible and tappable.
      visiblePages = const <int> [17, 18, 19];
      for (final int index in visiblePages) {
        expect(find.text('$index'), findsOneWidget);
        await tester.tap(find.text('$index'));
        expect(tappedIndex, index);
      }
    },
  );

  testWidgets('the current item remains centered on constraint change', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/50505.
    final PageController controller = PageController(
      initialPage: kStates.length - 1,
      viewportFraction: 0.5,
    );

    Widget build(Size size) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PageView(
              controller: controller,
              children: kStates.map<Widget>((String state) => Text(state)).toList(),
              onPageChanged: (int page) { },
            ),
          ),
        ),
      );
    }

    // Verifies that the last item is centered on screen.
    void verifyCentered() {
      expect(
        tester.getCenter(find.text(kStates.last)),
        offsetMoreOrLessEquals(const Offset(400, 300)),
      );
    }

    await tester.pumpWidget(build(const Size(300, 300)));
    await tester.pumpAndSettle();

    verifyCentered();

    await tester.pumpWidget(build(const Size(200, 300)));
    await tester.pumpAndSettle();

    verifyCentered();
  });

  testWidgets('PageView does not report page changed on overscroll', (WidgetTester tester) async {
    final PageController controller = PageController(
      initialPage: kStates.length - 1,
    );
    int changeIndex = 0;
    Widget build() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: controller,
          children: kStates.map<Widget>((String state) => Text(state)).toList(),
          onPageChanged: (int page) {
            changeIndex = page;
          },
        ),
      );
    }

    await tester.pumpWidget(build());
    controller.jumpToPage(kStates.length * 2); // try to move beyond max range
    // change index should be zero, shouldn't fire onPageChanged
    expect(changeIndex, 0);
    await tester.pump();
    expect(changeIndex, 0);
  });

  testWidgets('PageView can restore page', (WidgetTester tester) async {
    final PageController controller = PageController();
    expect(
      () => controller.page,
      throwsA(isAssertionError.having(
        (AssertionError error) => error.message,
        'message',
        equals('PageController.page cannot be accessed before a PageView is built with it.'),
      )),
    );
    final PageStorageBucket bucket = PageStorageBucket();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageStorage(
        bucket: bucket,
        child: PageView(
          key: const PageStorageKey<String>('PageView'),
          controller: controller,
          children: const <Widget>[
            Placeholder(),
            Placeholder(),
            Placeholder(),
          ],
        ),
      ),
    ));
    expect(controller.page, 0);
    controller.jumpToPage(2);
    expect(await tester.pumpAndSettle(const Duration(minutes: 1)), 2);
    expect(controller.page, 2);
    await tester.pumpWidget(
      PageStorage(
        bucket: bucket,
        child: Container(),
      ),
    );
    expect(
      () => controller.page,
      throwsA(isAssertionError.having(
        (AssertionError error) => error.message,
        'message',
        equals('PageController.page cannot be accessed before a PageView is built with it.'),
      )),
    );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageStorage(
        bucket: bucket,
        child: PageView(
          key: const PageStorageKey<String>('PageView'),
          controller: controller,
          children: const <Widget>[
            Placeholder(),
            Placeholder(),
            Placeholder(),
          ],
        ),
      ),
    ));
    expect(controller.page, 2);

    final PageController controller2 = PageController(keepPage: false);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageStorage(
        bucket: bucket,
        child: PageView(
          key: const PageStorageKey<String>('Check it again against your list and see consistency!'),
          controller: controller2,
          children: const <Widget>[
            Placeholder(),
            Placeholder(),
            Placeholder(),
          ],
        ),
      ),
    ));
    expect(controller2.page, 0);
  });

  testWidgets('PageView exposes semantics of children', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final PageController controller = PageController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
          controller: controller,
          children: List<Widget>.generate(3, (int i) {
            return Semantics(
              container: true,
              child: Text('Page #$i'),
            );
          }),
        ),
    ));
    expect(controller.page, 0);

    expect(semantics, includesNodeWith(label: 'Page #0'));
    expect(semantics, isNot(includesNodeWith(label: 'Page #1')));
    expect(semantics, isNot(includesNodeWith(label: 'Page #2')));

    controller.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(semantics, isNot(includesNodeWith(label: 'Page #0')));
    expect(semantics, includesNodeWith(label: 'Page #1'));
    expect(semantics, isNot(includesNodeWith(label: 'Page #2')));

    controller.jumpToPage(2);
    await tester.pumpAndSettle();

    expect(semantics, isNot(includesNodeWith(label: 'Page #0')));
    expect(semantics, isNot(includesNodeWith(label: 'Page #1')));
    expect(semantics, includesNodeWith(label: 'Page #2'));

    semantics.dispose();
  });

  testWidgets('PageMetrics', (WidgetTester tester) async {
    final PageMetrics page = PageMetrics(
      minScrollExtent: 100.0,
      maxScrollExtent: 200.0,
      pixels: 150.0,
      viewportDimension: 25.0,
      axisDirection: AxisDirection.right,
      viewportFraction: 1.0,
    );
    expect(page.page, 6);
    final PageMetrics page2 = page.copyWith(
      pixels: page.pixels - 100.0,
    );
    expect(page2.page, 4.0);
  });

  testWidgets('Page controller can handle rounding issue', (WidgetTester tester) async {
    final PageController pageController = PageController();

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
        controller: pageController,
        children: List<Widget>.generate(3, (int i) {
          return Semantics(
            container: true,
            child: Text('Page #$i'),
          );
        }),
      ),
    ));
    // Simulate precision error.
    pageController.position.jumpTo(799.99999999999);
    expect(pageController.page, 1);
  });

  testWidgets('PageView can participate in a11y scrolling', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final PageController controller = PageController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
          controller: controller,
          allowImplicitScrolling: true,
          children: List<Widget>.generate(4, (int i) {
            return Semantics(
              container: true,
              child: Text('Page #$i'),
            );
          }),
        ),
    ));
    expect(controller.page, 0);

    expect(semantics, includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling]));
    expect(semantics, includesNodeWith(label: 'Page #0'));
    expect(semantics, includesNodeWith(label: 'Page #1', flags: <SemanticsFlag>[SemanticsFlag.isHidden]));
    expect(semantics, isNot(includesNodeWith(label: 'Page #2', flags: <SemanticsFlag>[SemanticsFlag.isHidden])));
    expect(semantics, isNot(includesNodeWith(label: 'Page #3', flags: <SemanticsFlag>[SemanticsFlag.isHidden])));

    controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle();
    expect(semantics, includesNodeWith(label: 'Page #0', flags: <SemanticsFlag>[SemanticsFlag.isHidden]));
    expect(semantics, includesNodeWith(label: 'Page #1'));
    expect(semantics, includesNodeWith(label: 'Page #2', flags: <SemanticsFlag>[SemanticsFlag.isHidden]));
    expect(semantics, isNot(includesNodeWith(label: 'Page #3', flags: <SemanticsFlag>[SemanticsFlag.isHidden])));

    controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.ease);
    await tester.pumpAndSettle();
    expect(semantics, isNot(includesNodeWith(label: 'Page #0', flags: <SemanticsFlag>[SemanticsFlag.isHidden])));
    expect(semantics, includesNodeWith(label: 'Page #1', flags: <SemanticsFlag>[SemanticsFlag.isHidden]));
    expect(semantics, includesNodeWith(label: 'Page #2'));
    expect(semantics, includesNodeWith(label: 'Page #3', flags: <SemanticsFlag>[SemanticsFlag.isHidden]));

    semantics.dispose();
  });

  testWidgets('PageView respects clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          children: <Widget>[Container(height: 2000.0)],
        ),
      ),
    );

    // 1st, check that the render object has received the default clip behavior.
    final RenderViewport renderObject = tester.allRenderObjects.whereType<RenderViewport>().first;
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    // 2nd, check that the painting context has received the default clip behavior.
    final TestClipPaintingContext context = TestClipPaintingContext();
    renderObject.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.hardEdge));

    // 3rd, pump a new widget to check that the render object can update its clip behavior.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          clipBehavior: Clip.antiAlias,
          children: <Widget>[Container(height: 2000.0)],
        ),
      ),
    );
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));

    // 4th, check that a non-default clip behavior can be sent to the painting context.
    renderObject.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PageView.padEnds tests', (WidgetTester tester) async {
    Finder viewportFinder() => find.byType(SliverFillViewport, skipOffstage: false);

    // PageView() defaults to true.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(),
    ));

    expect(tester.widget<SliverFillViewport>(viewportFinder()).padEnds, true);

    // PageView(padEnds: false) is propagated properly.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView(
        padEnds: false,
      ),
    ));

    expect(tester.widget<SliverFillViewport>(viewportFinder()).padEnds, false);
  });

  testWidgets('PageView - precision error inside RenderSliverFixedExtentBoxAdaptor', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/95101

    final PageController controller = PageController(initialPage: 152);
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 392.72727272727275,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: PageView.builder(
              controller: controller,
              itemCount: 366,
              itemBuilder: (BuildContext context, int index) {
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    controller.jumpToPage(365);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
