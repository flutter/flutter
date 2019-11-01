// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

final List<String> results = <String>[];

Set<TestRoute> routes = HashSet<TestRoute>();

class TestRoute extends Route<String> with LocalHistoryRoute<String> {
  TestRoute(this.name);
  final String name;

  @override
  List<OverlayEntry> get overlayEntries => _entries;

  final List<OverlayEntry> _entries = <OverlayEntry>[];

  void log(String s) {
    results.add('$name: $s');
  }

  @override
  void install(OverlayEntry insertionPoint) {
    log('install');
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) => Container(),
      opaque: true,
    );
    _entries.add(entry);
    navigator.overlay?.insert(entry, above: insertionPoint);
    routes.add(this);
    super.install(insertionPoint);
  }

  @override
  TickerFuture didPush() {
    log('didPush');
    return super.didPush();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    expect(oldRoute, isInstanceOf<TestRoute>());
    final TestRoute castRoute = oldRoute;
    log('didReplace ${castRoute.name}');
    super.didReplace(castRoute);
  }

  @override
  bool didPop(String result) {
    log('didPop $result');
    bool returnValue;
    if (returnValue = super.didPop(result))
      navigator.finalizeRoute(this);
    return returnValue;
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    expect(nextRoute, isInstanceOf<TestRoute>());
    final TestRoute castRoute = nextRoute;
    log('didPopNext ${castRoute.name}');
    super.didPopNext(castRoute);
  }

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    expect(nextRoute, anyOf(isNull, isInstanceOf<TestRoute>()));
    final TestRoute castRoute = nextRoute;
    log('didChangeNext ${castRoute?.name}');
    super.didChangeNext(castRoute);
  }

  @override
  void dispose() {
    log('dispose');
    for (OverlayEntry entry in _entries)
      entry.remove();
    _entries.clear();
    routes.remove(this);
    super.dispose();
  }

}

Future<void> runNavigatorTest(
  WidgetTester tester,
  NavigatorState host,
  VoidCallback test,
  List<String> expectations,
) async {
  expect(host, isNotNull);
  test();
  expect(results, equals(expectations));
  results.clear();
  await tester.pump();
}

void main() {
  testWidgets('Route settings', (WidgetTester tester) async {
    const RouteSettings settings = RouteSettings(name: 'A');
    expect(settings, hasOneLineDescription);
    final RouteSettings settings2 = settings.copyWith(name: 'B');
    expect(settings2.name, 'B');
    expect(settings2.isInitialRoute, false);
    final RouteSettings settings3 = settings2.copyWith(isInitialRoute: true);
    expect(settings3.name, 'B');
    expect(settings3.isInitialRoute, true);
  });

  testWidgets('Route settings arguments', (WidgetTester tester) async {
    const RouteSettings settings = RouteSettings(name: 'A');
    expect(settings.arguments, isNull);

    final Object arguments = Object();
    final RouteSettings settings2 = RouteSettings(name: 'A', arguments: arguments);
    expect(settings2.arguments, same(arguments));

    final RouteSettings settings3 = settings2.copyWith();
    expect(settings3.arguments, equals(arguments));

    final Object arguments2 = Object();
    final RouteSettings settings4 = settings2.copyWith(arguments: arguments2);
    expect(settings4.arguments, same(arguments2));
    expect(settings4.arguments, isNot(same(arguments)));
  });

  testWidgets('Route management - push, replace, pop', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (_) => TestRoute('initial'),
        ),
      ),
    );
    final NavigatorState host = navigatorKey.currentState;
    await runNavigatorTest(
      tester,
      host,
      () { },
      <String>[
        'initial: install',
        'initial: didPush',
        'initial: didChangeNext null',
      ],
    );
    TestRoute second;
    await runNavigatorTest(
      tester,
      host,
      () { host.push(second = TestRoute('second')); },
      <String>[
        'second: install',
        'second: didPush',
        'second: didChangeNext null',
        'initial: didChangeNext second',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.push(TestRoute('third')); },
      <String>[
        'third: install',
        'third: didPush',
        'third: didChangeNext null',
        'second: didChangeNext third',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.replace(oldRoute: second, newRoute: TestRoute('two')); },
      <String>[
        'two: install',
        'two: didReplace second',
        'two: didChangeNext third',
        'initial: didChangeNext two',
        'second: dispose',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.pop('hello'); },
      <String>[
        'third: didPop hello',
        'third: dispose',
        'two: didPopNext third',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.pop('good bye'); },
      <String>[
        'two: didPop good bye',
        'two: dispose',
        'initial: didPopNext two',
      ],
    );
    await tester.pumpWidget(Container());
    expect(results, equals(<String>['initial: dispose']));
    expect(routes.isEmpty, isTrue);
    results.clear();
  });

  testWidgets('Route management - push, remove, pop', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (_) => TestRoute('first'),
        ),
      ),
    );
    final NavigatorState host = navigatorKey.currentState;
    await runNavigatorTest(
      tester,
      host,
      () { },
      <String>[
        'first: install',
        'first: didPush',
        'first: didChangeNext null',
      ],
    );
    TestRoute second;
    await runNavigatorTest(
      tester,
      host,
      () { host.push(second = TestRoute('second')); },
      <String>[
        'second: install',
        'second: didPush',
        'second: didChangeNext null',
        'first: didChangeNext second',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.push(TestRoute('third')); },
      <String>[
        'third: install',
        'third: didPush',
        'third: didChangeNext null',
        'second: didChangeNext third',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.removeRouteBelow(second); },
      <String>[
        'first: dispose',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.pop('good bye'); },
      <String>[
        'third: didPop good bye',
        'third: dispose',
        'second: didPopNext third',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.push(TestRoute('three')); },
      <String>[
        'three: install',
        'three: didPush',
        'three: didChangeNext null',
        'second: didChangeNext three',
      ],
    );
    TestRoute four;
    await runNavigatorTest(
      tester,
      host,
      () { host.push(four = TestRoute('four')); },
      <String>[
        'four: install',
        'four: didPush',
        'four: didChangeNext null',
        'three: didChangeNext four',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.removeRouteBelow(four); },
      <String>[
        'second: didChangeNext four',
        'three: dispose',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.pop('the end'); },
      <String>[
        'four: didPop the end',
        'four: dispose',
        'second: didPopNext four',
      ],
    );
    await tester.pumpWidget(Container());
    expect(results, equals(<String>['second: dispose']));
    expect(routes.isEmpty, isTrue);
    results.clear();
  });

  testWidgets('Route management - push, replace, popUntil', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (_) => TestRoute('A'),
        ),
      ),
    );
    final NavigatorState host = navigatorKey.currentState;
    await runNavigatorTest(
      tester,
      host,
      () { },
      <String>[
        'A: install',
        'A: didPush',
        'A: didChangeNext null',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.push(TestRoute('B')); },
      <String>[
        'B: install',
        'B: didPush',
        'B: didChangeNext null',
        'A: didChangeNext B',
      ],
    );
    TestRoute routeC;
    await runNavigatorTest(
      tester,
      host,
      () { host.push(routeC = TestRoute('C')); },
      <String>[
        'C: install',
        'C: didPush',
        'C: didChangeNext null',
        'B: didChangeNext C',
      ],
    );
    expect(routeC.isActive, isTrue);
    TestRoute routeB;
    await runNavigatorTest(
      tester,
      host,
      () { host.replaceRouteBelow(anchorRoute: routeC, newRoute: routeB = TestRoute('b')); },
      <String>[
        'b: install',
        'b: didReplace B',
        'b: didChangeNext C',
        'A: didChangeNext b',
        'B: dispose',
      ],
    );
    await runNavigatorTest(
      tester,
      host,
      () { host.popUntil((Route<dynamic> route) => route == routeB); },
      <String>[
        'C: didPop null',
        'C: dispose',
        'b: didPopNext C',
      ],
    );
    await tester.pumpWidget(Container());
    expect(results, equals(<String>['A: dispose', 'b: dispose']));
    expect(routes.isEmpty, isTrue);
    results.clear();
  });

  testWidgets('Route localHistory - popUntil', (WidgetTester tester) async {
    final TestRoute routeA = TestRoute('A');
    routeA.addLocalHistoryEntry(LocalHistoryEntry(
      onRemove: () { routeA.log('onRemove 0'); }
    ));
    routeA.addLocalHistoryEntry(LocalHistoryEntry(
      onRemove: () { routeA.log('onRemove 1'); }
    ));
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (_) => routeA,
        ),
      ),
    );
    final NavigatorState host = navigatorKey.currentState;
    await runNavigatorTest(
      tester,
      host,
      () { host.popUntil((Route<dynamic> route) => !route.willHandlePopInternally); },
      <String>[
        'A: install',
        'A: didPush',
        'A: didChangeNext null',
        'A: didPop null',
        'A: onRemove 1',
        'A: didPop null',
        'A: onRemove 0',
      ],
    );

    await runNavigatorTest(
      tester,
      host,
      () { host.popUntil((Route<dynamic> route) => !route.willHandlePopInternally); },
      <String>[
      ],
    );
  });

  group('PageRouteObserver', () {
    test('calls correct listeners', () {
      final RouteObserver<PageRoute<dynamic>> observer = RouteObserver<PageRoute<dynamic>>();
      final RouteAware pageRouteAware1 = MockRouteAware();
      final MockPageRoute route1 = MockPageRoute();
      observer.subscribe(pageRouteAware1, route1);
      verify(pageRouteAware1.didPush()).called(1);

      final RouteAware pageRouteAware2 = MockRouteAware();
      final MockPageRoute route2 = MockPageRoute();
      observer.didPush(route2, route1);
      verify(pageRouteAware1.didPushNext()).called(1);

      observer.subscribe(pageRouteAware2, route2);
      verify(pageRouteAware2.didPush()).called(1);

      observer.didPop(route2, route1);
      verify(pageRouteAware2.didPop()).called(1);
      verify(pageRouteAware1.didPopNext()).called(1);
    });

    test('does not call listeners for non-PageRoute', () {
      final RouteObserver<PageRoute<dynamic>> observer = RouteObserver<PageRoute<dynamic>>();
      final RouteAware pageRouteAware = MockRouteAware();
      final MockPageRoute pageRoute = MockPageRoute();
      final MockRoute route = MockRoute();
      observer.subscribe(pageRouteAware, pageRoute);
      verify(pageRouteAware.didPush());

      observer.didPush(route, pageRoute);
      observer.didPop(route, pageRoute);
      verifyNoMoreInteractions(pageRouteAware);
    });

    test('does not call listeners when already subscribed', () {
      final RouteObserver<PageRoute<dynamic>> observer = RouteObserver<PageRoute<dynamic>>();
      final RouteAware pageRouteAware = MockRouteAware();
      final MockPageRoute pageRoute = MockPageRoute();
      observer.subscribe(pageRouteAware, pageRoute);
      observer.subscribe(pageRouteAware, pageRoute);
      verify(pageRouteAware.didPush()).called(1);
    });

    test('does not call listeners when unsubscribed', () {
      final RouteObserver<PageRoute<dynamic>> observer = RouteObserver<PageRoute<dynamic>>();
      final RouteAware pageRouteAware = MockRouteAware();
      final MockPageRoute pageRoute = MockPageRoute();
      final MockPageRoute nextPageRoute = MockPageRoute();
      observer.subscribe(pageRouteAware, pageRoute);
      observer.subscribe(pageRouteAware, nextPageRoute);
      verify(pageRouteAware.didPush()).called(2);

      observer.unsubscribe(pageRouteAware);

      observer.didPush(nextPageRoute, pageRoute);
      observer.didPop(nextPageRoute, pageRoute);
      verifyNoMoreInteractions(pageRouteAware);
    });
  });

  testWidgets('Can autofocus a TextField nested in a Focus in a route.', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    final FocusNode focusNode = FocusNode(debugLabel: 'Test Node');
    await tester.pumpWidget(
      Material(
        child: MaterialApp(
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (BuildContext context, Animation<double> input, Animation<double> out) {
                return Focus(
                  child: TextField(
                    autofocus: true,
                    focusNode: focusNode,
                    controller: controller,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  group('TrasitionRoute', () {
    testWidgets('secondary animation is kDismissed when next route finishes pop', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Text('home'),
        )
      );

      // Push page one, its secondary animation is kAlwaysDismissedAnimation.
      ProxyAnimation secondaryAnimationProxyPageOne;
      ProxyAnimation animationPageOne;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageOne = secondaryAnimation;
            animationPageOne = animation;
            return const Text('Page One');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageOne = secondaryAnimationProxyPageOne.parent;
      expect(animationPageOne.value, 1.0);
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);

      // Push page two, the secondary animation of page one is the primary
      // animation of page two.
      ProxyAnimation secondaryAnimationProxyPageTwo;
      ProxyAnimation animationPageTwo;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageTwo = secondaryAnimation;
            animationPageTwo = animation;
            return const Text('Page Two');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageTwo = secondaryAnimationProxyPageTwo.parent;
      expect(animationPageTwo.value, 1.0);
      expect(secondaryAnimationPageTwo.parent, kAlwaysDismissedAnimation);
      expect(secondaryAnimationPageOne.parent, animationPageTwo.parent);

      // Pop page two, the secondary animation of page one becomes
      // kAlwaysDismissedAnimation.
      navigator.currentState.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(secondaryAnimationPageOne.parent, animationPageTwo.parent);
      await tester.pumpAndSettle();
      expect(animationPageTwo.value, 0.0);
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);
    });

    testWidgets('secondary animation is kDismissed when next route is removed', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Text('home'),
          )
      );

      // Push page one, its secondary animation is kAlwaysDismissedAnimation.
      ProxyAnimation secondaryAnimationProxyPageOne;
      ProxyAnimation animationPageOne;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageOne = secondaryAnimation;
            animationPageOne = animation;
            return const Text('Page One');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageOne = secondaryAnimationProxyPageOne.parent;
      expect(animationPageOne.value, 1.0);
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);

      // Push page two, the secondary animation of page one is the primary
      // animation of page two.
      ProxyAnimation secondaryAnimationProxyPageTwo;
      ProxyAnimation animationPageTwo;
      Route<void> secondRoute;
      navigator.currentState.push(
        secondRoute = PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageTwo = secondaryAnimation;
            animationPageTwo = animation;
            return const Text('Page Two');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageTwo = secondaryAnimationProxyPageTwo.parent;
      expect(animationPageTwo.value, 1.0);
      expect(secondaryAnimationPageTwo.parent, kAlwaysDismissedAnimation);
      expect(secondaryAnimationPageOne.parent, animationPageTwo.parent);

      // Remove the second route, the secondary animation of page one is
      // kAlwaysDismissedAnimation again.
      navigator.currentState.removeRoute(secondRoute);
      await tester.pump();
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);
    });

    testWidgets('secondary animation is kDismissed after train hopping finishes and pop', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Text('home'),
          )
      );

      // Push page one, its secondary animation is kAlwaysDismissedAnimation.
      ProxyAnimation secondaryAnimationProxyPageOne;
      ProxyAnimation animationPageOne;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageOne = secondaryAnimation;
            animationPageOne = animation;
            return const Text('Page One');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageOne = secondaryAnimationProxyPageOne.parent;
      expect(animationPageOne.value, 1.0);
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);

      // Push page two, the secondary animation of page one is the primary
      // animation of page two.
      ProxyAnimation animationPageTwo;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            animationPageTwo = animation;
            return const Text('Page Two');
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(secondaryAnimationPageOne.parent, animationPageTwo.parent);

      // Replace with a different route while push is ongoing to trigger
      // TrainHopping.
      ProxyAnimation animationPageThree;
      navigator.currentState.pushReplacement(
        TestPageRouteBuilder(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            animationPageThree = animation;
            return const Text('Page Three');
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(secondaryAnimationPageOne.parent, isA<TrainHoppingAnimation>());
      final TrainHoppingAnimation trainHopper = secondaryAnimationPageOne.parent;
      expect(trainHopper.currentTrain, animationPageTwo.parent);
      await tester.pump(const Duration(milliseconds: 100));
      expect(secondaryAnimationPageOne.parent, isNot(isA<TrainHoppingAnimation>()));
      expect(secondaryAnimationPageOne.parent, animationPageThree.parent);
      expect(trainHopper.currentTrain, isNull); // Has been disposed.
      await tester.pumpAndSettle();
      expect(secondaryAnimationPageOne.parent, animationPageThree.parent);

      // Pop page three.
      navigator.currentState.pop();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);
    });

    testWidgets('secondary animation is kDismissed when train hopping is interrupted', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Text('home'),
          )
      );

      // Push page one, its secondary animation is kAlwaysDismissedAnimation.
      ProxyAnimation secondaryAnimationProxyPageOne;
      ProxyAnimation animationPageOne;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationProxyPageOne = secondaryAnimation;
            animationPageOne = animation;
            return const Text('Page One');
          },
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      final ProxyAnimation secondaryAnimationPageOne = secondaryAnimationProxyPageOne.parent;
      expect(animationPageOne.value, 1.0);
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);

      // Push page two, the secondary animation of page one is the primary
      // animation of page two.
      ProxyAnimation animationPageTwo;
      navigator.currentState.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            animationPageTwo = animation;
            return const Text('Page Two');
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(secondaryAnimationPageOne.parent, animationPageTwo.parent);

      // Replace with a different route while push is ongoing to trigger
      // TrainHopping.
      navigator.currentState.pushReplacement(
        TestPageRouteBuilder(
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            return const Text('Page Three');
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(secondaryAnimationPageOne.parent, isA<TrainHoppingAnimation>());
      final TrainHoppingAnimation trainHopper = secondaryAnimationPageOne.parent;
      expect(trainHopper.currentTrain, animationPageTwo.parent);

      // Pop page three while replacement push is ongoing.
      navigator.currentState.pop();
      await tester.pump();
      expect(secondaryAnimationPageOne.parent, isA<TrainHoppingAnimation>());
      final TrainHoppingAnimation trainHopper2 = secondaryAnimationPageOne.parent;
      expect(trainHopper2.currentTrain, animationPageTwo.parent);
      expect(trainHopper.currentTrain, isNull); // Has been disposed.
      await tester.pumpAndSettle();
      expect(secondaryAnimationPageOne.parent, kAlwaysDismissedAnimation);
      expect(trainHopper2.currentTrain, isNull); // Has been disposed.
    });

    testWidgets('showGeneralDialog uses root navigator by default', (WidgetTester tester) async {
      final DialogObserver rootObserver = DialogObserver();
      final DialogObserver nestedObserver = DialogObserver();

      await tester.pumpWidget(MaterialApp(
        navigatorObservers: <NavigatorObserver>[rootObserver],
        home: Navigator(
          observers: <NavigatorObserver>[nestedObserver],
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return RaisedButton(
                  onPressed: () {
                    showGeneralDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      transitionDuration: Duration.zero,
                      pageBuilder: (BuildContext innerContext, _, __) {
                        return const SizedBox();
                      },
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            );
          },
        ),
      ));

      // Open the dialog.
      await tester.tap(find.byType(RaisedButton));

      expect(rootObserver.dialogCount, 1);
      expect(nestedObserver.dialogCount, 0);
    });

    testWidgets('showGeneralDialog uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
      final DialogObserver rootObserver = DialogObserver();
      final DialogObserver nestedObserver = DialogObserver();

      await tester.pumpWidget(MaterialApp(
        navigatorObservers: <NavigatorObserver>[rootObserver],
        home: Navigator(
          observers: <NavigatorObserver>[nestedObserver],
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return RaisedButton(
                  onPressed: () {
                    showGeneralDialog<void>(
                      useRootNavigator: false,
                      context: context,
                      barrierDismissible: false,
                      transitionDuration: Duration.zero,
                      pageBuilder: (BuildContext innerContext, _, __) {
                        return const SizedBox();
                      },
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            );
          },
        ),
      ));

      // Open the dialog.
      await tester.tap(find.byType(RaisedButton));

      expect(rootObserver.dialogCount, 0);
      expect(nestedObserver.dialogCount, 1);
    });
  });
}

class MockPageRoute extends Mock implements PageRoute<dynamic> { }

class MockRoute extends Mock implements Route<dynamic> { }

class MockRouteAware extends Mock implements RouteAware { }

class TestPageRouteBuilder extends PageRouteBuilder<void> {
  TestPageRouteBuilder({RoutePageBuilder pageBuilder}) : super(pageBuilder: pageBuilder);

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(parent: super.createAnimation(), curve: Curves.easeOutExpo);
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
