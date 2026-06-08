// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

class _TestOverlayRoute extends OverlayRoute<void> {
  @override
  Iterable<OverlayEntry> createOverlayEntries() => [OverlayEntry(builder: _build)];

  Widget _build(BuildContext context) => const Text('Overlay');
}

void main() {
  testWidgets('Check onstage/offstage handling around transitions', (WidgetTester tester) async {
    final GlobalKey containerKey1 = GlobalKey();
    final GlobalKey containerKey2 = GlobalKey();
    final routes = <String, WidgetBuilder>{
      '/': (_) => Container(key: containerKey1, child: const Text('Home')),
      '/settings': (_) => Container(key: containerKey2, child: const Text('Settings')),
    };

    await tester.pumpWidget(TestWidgetsApp(routes: routes, pageRouteBuilder: _testPageRoute));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext!), isFalse);
    Navigator.pushNamed(containerKey1.currentContext!, '/settings');
    expect(Navigator.canPop(containerKey1.currentContext!), isTrue);

    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings', skipOffstage: false), isOffstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    Navigator.push(containerKey2.currentContext!, _TestOverlayRoute());

    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    expect(Navigator.canPop(containerKey2.currentContext!), isTrue);
    Navigator.pop(containerKey2.currentContext!);
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey2.currentContext!), isTrue);
    Navigator.pop(containerKey2.currentContext!);
    await tester.pump();
    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext!), isFalse);
  });

  testWidgets('Check back gesture disables Heroes', (WidgetTester tester) async {
    final GlobalKey containerKey1 = GlobalKey();
    final GlobalKey containerKey2 = GlobalKey();
    const kHeroTag = 'hero';
    final routes = <String, WidgetBuilder>{
      '/': (_) => SizedBox(
        key: containerKey1,
        child: const ColoredBox(
          color: Color(0xff00ffff),
          child: Hero(tag: kHeroTag, child: Text('Home')),
        ),
      ),
      '/settings': (_) => SizedBox(
        key: containerKey2,
        child: Container(
          padding: const EdgeInsets.all(100.0),
          color: const Color(0xffff00ff),
          child: const Hero(tag: kHeroTag, child: Text('Settings')),
        ),
      ),
    };

    await tester.pumpWidget(
      TestWidgetsApp(
        navigatorObservers: <NavigatorObserver>[HeroController()],
        routes: routes,
        pageRouteBuilder: _testPageRoute,
      ),
    );

    Navigator.pushNamed(containerKey1.currentContext!, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Settings'), isOnstage);

    // Settings text is heroing to its new location.
    Offset settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.dx, greaterThan(0.0));
    expect(settingsOffset.dx, lessThan(100.0));
    expect(settingsOffset.dy, greaterThan(0.0));
    expect(settingsOffset.dy, lessThan(100.0));

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
    await gesture.moveBy(const Offset(50.0, 0.0));
    await tester.pump();

    // Home is now visible.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Home page is sliding in from the left, no heroes.
    final Offset homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.dx, lessThan(0.0));
    expect(homeOffset.dy, 0.0);

    // Settings page is sliding off to the right, no heroes.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.dx, greaterThan(100.0));
    expect(settingsOffset.dy, 100.0);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets("Check back gesture doesn't start during transitions", (WidgetTester tester) async {
    final GlobalKey containerKey1 = GlobalKey();
    final GlobalKey containerKey2 = GlobalKey();
    final routes = <String, WidgetBuilder>{
      '/': (_) => SizedBox(key: containerKey1, child: const Text('Home')),
      '/settings': (_) => SizedBox(key: containerKey2, child: const Text('Settings')),
    };

    await tester.pumpWidget(TestWidgetsApp(routes: routes, pageRouteBuilder: _testPageRoute));

    Navigator.pushNamed(containerKey1.currentContext!, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // We are mid-transition, both pages are on stage.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture. (near bottom so we grab
    // the Settings page as it comes up).
    TestGesture gesture = await tester.startGesture(const Offset(5.0, 550.0));
    await gesture.moveBy(const Offset(500.0, 0.0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // The original forward navigation should have completed, instead of the
    // back gesture, since we were mid transition.
    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Try again now that we're settled.
    gesture = await tester.startGesture(const Offset(5.0, 550.0));
    await gesture.moveBy(const Offset(500.0, 0.0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Test completed future', (WidgetTester tester) async {
    final routes = <String, WidgetBuilder>{
      '/': (_) => const Center(child: Text('home')),
      '/next': (_) => const Center(child: Text('next')),
    };

    await tester.pumpWidget(TestWidgetsApp(routes: routes));

    final PageRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/page'),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => const Center(child: Text('page')),
    );

    var popCount = 0;
    route.popped.whenComplete(() {
      popCount += 1;
    });

    var completeCount = 0;
    route.completed.whenComplete(() {
      completeCount += 1;
    });

    expect(popCount, 0);
    expect(completeCount, 0);

    Navigator.push(tester.element(find.text('home')), route);

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump();

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(seconds: 1));

    expect(popCount, 0);
    expect(completeCount, 0);

    Navigator.pop(tester.element(find.text('page')));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump();

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(seconds: 1));

    expect(popCount, 1);
    expect(completeCount, 1);
  });
}

PageRoute<T> _testPageRoute<T>(RouteSettings settings, WidgetBuilder builder) {
  return _TestPageRoute<T>(settings: settings, builder: builder);
}

class _TestPageRoute<T> extends PageRoute<T> {
  _TestPageRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<Offset> primaryPosition = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(animation);
    final Animation<Offset> secondaryPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(secondaryAnimation);

    return _TestBackGestureDetector<T>(
      route: this,
      child: SlideTransition(
        position: secondaryPosition,
        child: SlideTransition(
          position: primaryPosition,
          child: _OffstageOnDismissedTransition(
            animation: animation,
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}

class _OffstageOnDismissedTransition extends StatelessWidget {
  const _OffstageOnDismissedTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        return Offstage(offstage: animation.value == 0.0, child: child);
      },
    );
  }
}

class _TestBackGestureDetector<T> extends StatefulWidget {
  const _TestBackGestureDetector({required this.route, required this.child});

  final PageRoute<T> route;
  final Widget child;

  @override
  State<_TestBackGestureDetector<T>> createState() => _TestBackGestureDetectorState<T>();
}

class _TestBackGestureDetectorState<T> extends State<_TestBackGestureDetector<T>> {
  static const double _kBackGestureWidth = 20.0;

  bool _dragging = false;
  double _progress = 1.0;

  void _handleDragStart(DragStartDetails details) {
    if (!widget.route.popGestureEnabled || details.globalPosition.dx > _kBackGestureWidth) {
      return;
    }
    _dragging = true;
    _progress = widget.route.animation!.value;
    widget.route.handleStartBackGesture(progress: _progress);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) {
      return;
    }
    final double width = context.size!.width;
    _progress = (_progress - (details.primaryDelta ?? 0.0) / width).clamp(0.0, 1.0);
    widget.route.handleUpdateBackGestureProgress(progress: _progress);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    if (_progress < 0.5) {
      widget.route.handleCommitBackGesture();
    } else {
      widget.route.handleCancelBackGesture();
    }
  }

  void _handleDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    widget.route.handleCancelBackGesture();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      child: widget.child,
    );
  }
}
