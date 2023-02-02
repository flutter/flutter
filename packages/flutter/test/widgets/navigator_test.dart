// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'observer_tester.dart';
import 'semantics_tester.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({ super.key });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/second');
      },
      child: const ColoredBox(
        color: Color(0xFFFFFF00),
        child: Text('X'),
      ),
    );
  }
}

class SecondWidget extends StatefulWidget {
  const SecondWidget({ super.key });
  @override
  SecondWidgetState createState() => SecondWidgetState();
}

class SecondWidgetState extends State<SecondWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const ColoredBox(
        color: Color(0xFFFF00FF),
        child: Text('Y'),
      ),
    );
  }
}

typedef ExceptionCallback = void Function(dynamic exception);

class ThirdWidget extends StatelessWidget {
  const ThirdWidget({ super.key, required this.targetKey, required this.onException });

  final Key targetKey;
  final ExceptionCallback onException;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: targetKey,
      onTap: () {
        try {
          Navigator.of(context);
        } catch (e) {
          onException(e);
        }
      },
      behavior: HitTestBehavior.opaque,
    );
  }
}

class OnTapPage extends StatelessWidget {
  const OnTapPage({ super.key, required this.id, this.onTap });

  final String id;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page $id')),
      body: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(id, style: Theme.of(context).textTheme.displaySmall),
        ),
      ),
    );
  }
}

class SlideInOutPageRoute<T> extends PageRouteBuilder<T> {
  SlideInOutPageRoute({required WidgetBuilder bodyBuilder, super.settings}) : super(
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => bodyBuilder(context),
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0),
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
  );

  @override
  AnimationController? get controller => super.controller;
}

void main() {
  testWidgets('Can navigator navigate to and from a stateful widget', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(), // X
      '/second': (BuildContext context) => const SecondWidget(), // Y
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), findsNothing);

    await tester.tap(find.text('X'));
    await tester.pump();
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), isOffstage);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('X'), findsNothing);
    expect(find.text('X', skipOffstage: false), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.tap(find.text('Y'));
    expect(find.text('X'), findsNothing);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump();
    await tester.pump();
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), findsNothing);
  });

  testWidgets('Navigator.of fails gracefully when not found in context', (WidgetTester tester) async {
    const Key targetKey = Key('foo');
    dynamic exception;
    final Widget widget = ThirdWidget(
      targetKey: targetKey,
      onException: (dynamic e) {
        exception = e;
      },
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.byKey(targetKey));
    expect(exception, isFlutterError);
    expect('$exception', startsWith('Navigator operation requested with a context'));
  });

  testWidgets('Navigator can push Route created through page class as Pageless route', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(
          body: Text('home'),
        )
      )
    );
    const MaterialPage<void> page = MaterialPage<void>(child: Text('page'));
    nav.currentState!.push<void>(page.createRoute(nav.currentContext!));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Navigator can set clip behavior', (WidgetTester tester) async {
    const MaterialPage<void> page = MaterialPage<void>(child: Text('page'));
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.binding.window),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            pages: const <Page<void>>[page],
            onPopPage: (_, __) => false,
          ),
        ),
      ),
    );
    // Default to hard edge.
    expect(tester.widget<Overlay>(find.byType(Overlay)).clipBehavior, Clip.hardEdge);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.binding.window),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            pages: const <Page<void>>[page],
            clipBehavior: Clip.none,
            onPopPage: (_, __) => false,
          ),
        ),
      ),
    );
    expect(tester.widget<Overlay>(find.byType(Overlay)).clipBehavior, Clip.none);
  });

  testWidgets('Zero transition page-based route correctly notifies observers when it is popped', (WidgetTester tester) async {
    final List<Page<void>> pages = <Page<void>>[
      const ZeroTransitionPage(name: 'Page 1'),
      const ZeroTransitionPage(name: 'Page 2'),
    ];
    final List<NavigatorObservation> observations = <NavigatorObservation>[];

    final TestObserver observer = TestObserver()
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'pop',
          ),
        );
      };
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      TestDependencies(
        child: Navigator(
          key: navigator,
          pages: pages,
          observers: <NavigatorObserver>[observer],
          onPopPage: (Route<dynamic> route, dynamic result) {
            pages.removeLast();
            return route.didPop(result);
          },
        ),
      ),
    );

    navigator.currentState!.pop();
    await tester.pump();

    expect(observations.length, 1);
    expect(observations[0].current, 'Page 2');
    expect(observations[0].previous, 'Page 1');
  });

  testWidgets('Navigator.of rootNavigator finds root Navigator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 300.0,
              child: Text('Root page'),
            ),
            SizedBox(
              height: 300.0,
              child: Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  if (settings.name == '/') {
                    return MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return ElevatedButton(
                          child: const Text('Next'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return ElevatedButton(
                                    child: const Text('Inner page'),
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext context) {
                                            return const Text('Dialog');
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Both elements are on screen.
    expect(tester.getTopLeft(find.text('Root page')).dy, 0.0);
    expect(tester.getTopLeft(find.text('Inner page')).dy, greaterThan(300.0));

    await tester.tap(find.text('Inner page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog is pushed to the whole page and is at the top of the screen, not
    // inside the inner page.
    expect(tester.getTopLeft(find.text('Dialog')).dy, 0.0);
  });

  testWidgets('Gestures between push and build are ignored', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        return Row(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                log.add('left');
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('left'),
            ),
            GestureDetector(
              onTap: () { log.add('right'); },
              child: const Text('right'),
            ),
          ],
        );
      },
      '/second': (BuildContext context) => Container(),
    };
    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(log, isEmpty);
    await tester.tap(find.text('left'));
    expect(log, equals(<String>['left']));
    await tester.tap(find.text('right'), warnIfMissed: false);
    expect(log, equals(<String>['left']));
  });

  testWidgets('pushnamed can handle Object as type', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('/'),
      '/second': (BuildContext context) => const Text('/second'),
    };
    await tester.pumpWidget(MaterialApp(navigatorKey: nav, routes: routes));
    expect(find.text('/'), findsOneWidget);
    Error? error;
    try {
      nav.currentState!.pushNamed<Object>('/second');
    } on Error catch(e) {
      error = e;
    }
    expect(error, isNull);
    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('/second'), findsOneWidget);
  });

  testWidgets('Pending gestures are rejected', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        return Row(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                log.add('left');
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('left'),
            ),
            GestureDetector(
              onTap: () { log.add('right'); },
              child: const Text('right'),
            ),
          ],
        );
      },
      '/second': (BuildContext context) => Container(),
    };
    await tester.pumpWidget(MaterialApp(routes: routes));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('right')), pointer: 23);
    expect(log, isEmpty);
    await tester.tap(find.text('left'), pointer: 1);
    expect(log, equals(<String>['left']));
    await gesture.up();
    expect(log, equals(<String>['left']));
  });

  testWidgets('popAndPushNamed', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.popAndPushNamed(context, '/B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop(context); }),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsNothing);

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('popAndPushNamed with explicit void type parameter', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed<void>(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.popAndPushNamed<void, void>(context, '/B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop<void>(context); }),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsNothing);

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Push and pop should trigger the observers', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPushed = true;
    };

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPopped = true;
    };

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isFalse);
    expect(isPopped, isTrue);
  });

  testWidgets('Add and remove an observer should work', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer1 = TestObserver();
    final TestObserver observer2 = TestObserver()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        isPushed = true;
      }
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1],
    ));
    expect(isPushed, isFalse);
    expect(isPopped, isFalse);

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1, observer2],
    ));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1],
    ));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(isPushed, isFalse);
    expect(isPopped, isFalse);
  });

  testWidgets('initial route trigger observer in the right order', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => const Text('/'),
      '/A': (BuildContext context) => const Text('A'),
      '/A/B': (BuildContext context) => const Text('B'),
    };
    final List<NavigatorObservation> observations = <NavigatorObservation>[];
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        // Pushes the initial route.
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'push',
          ),
        );
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      initialRoute: '/A/B',
      navigatorObservers: <NavigatorObserver>[observer],
    ));

    expect(observations.length, 3);
    expect(observations[0].operation, 'push');
    expect(observations[0].current, '/');
    expect(observations[0].previous, isNull);

    expect(observations[1].operation, 'push');
    expect(observations[1].current, '/A');
    expect(observations[1].previous, '/');

    expect(observations[2].operation, 'push');
    expect(observations[2].current, '/A/B');
    expect(observations[2].previous, '/A');
  });

  testWidgets('Route didAdd and dispose in same frame work', (WidgetTester tester) async {
    // Regression Test for https://github.com/flutter/flutter/issues/61346.
    Widget buildNavigator() {
      return Navigator(
        pages: const <Page<void>>[
          MaterialPage<void>(
            child: Placeholder(),
          ),
        ],
        onPopPage: (Route<dynamic> route, dynamic result) => false,
      );
    }
    final TabController controller = TabController(length: 3, vsync: tester);
    await tester.pumpWidget(
      TestDependencies(
        child: TabBarView(
          controller: controller,
          children: <Widget>[
            buildNavigator(),
            buildNavigator(),
            buildNavigator(),
          ],
        ),
      ),
    );

    // This test should finish without crashing.
    controller.index = 2;
    await tester.pumpAndSettle();
  });

  testWidgets('Page-based route pop before push finishes', (WidgetTester tester) async {
    List<Page<void>> pages = <Page<void>>[const MaterialPage<void>(child: Text('Page 1'))];
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    Widget buildNavigator() {
      return Navigator(
        key: navigator,
        pages: pages,
        onPopPage: (Route<dynamic> route, dynamic result) {
          pages.removeLast();
          return route.didPop(result);
        },
      );
    }
    await tester.pumpWidget(
      TestDependencies(
        child: buildNavigator(),
      ),
    );
    expect(find.text('Page 1'), findsOneWidget);
    pages = pages.toList();
    pages.add(const MaterialPage<void>(child: Text('Page 2')));

    await tester.pumpWidget(
      TestDependencies(
        child: buildNavigator(),
      ),
    );
    // This test should finish without crashing.
    await tester.pump();
    await tester.pump();

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('Pages update does update overlay correctly', (WidgetTester tester) async {
    // Regression Test for https://github.com/flutter/flutter/issues/64941.
    List<Page<void>> pages = const <Page<void>>[
      MaterialPage<void>(
        key:  ValueKey<int>(0),
        child: Text('page 0'),
      ),
      MaterialPage<void>(
        key: ValueKey<int>(1),
        child: Text('page 1'),
      ),
    ];
    Widget buildNavigator() {
      return Navigator(
        pages: pages,
        onPopPage: (Route<dynamic> route, dynamic result) => false,
      );
    }
    await tester.pumpWidget(
      TestDependencies(
        child: buildNavigator(),
      ),
    );

    expect(find.text('page 1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);

    // Removes the first page.
    pages = const <Page<void>>[
      MaterialPage<void>(
        key: ValueKey<int>(1),
        child: Text('page 1'),
      ),
    ];

    await tester.pumpWidget(
      TestDependencies(
        child: buildNavigator(),
      ),
    );
    // Overlay updates correctly.
    expect(find.text('page 1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('page 1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);
  });

  testWidgets('replaceNamed replaces', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushReplacementNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pushReplacementNamed(context, '/B'); }),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    await tester.tap(find.text('/')); // replaceNamed('/A')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);

    await tester.tap(find.text('A')); // replaceNamed('/B')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('pushReplacement sets secondaryAnimation after transition, with history change during transition', (WidgetTester tester) async {
    final Map<String, SlideInOutPageRoute<dynamic>> routes = <String, SlideInOutPageRoute<dynamic>>{};
    final Map<String, WidgetBuilder> builders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        },
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushNamed(context, '/B');
        },
      ),
      '/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/C');
        },
      ),
      '/C': (BuildContext context) => OnTapPage(
        id: 'C',
        onTap: () {
          Navigator.removeRoute(context, routes['/']!);
        },
      ),
    };
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        final SlideInOutPageRoute<dynamic> ret = SlideInOutPageRoute<dynamic>(bodyBuilder: builders[settings.name]!, settings: settings);
        routes[settings.name!] = ret;
        return ret;
      },
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    final double a2 = routes['/A']!.secondaryAnimation!.value;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(routes['/A']!.secondaryAnimation!.value, greaterThan(a2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(routes['/A']!.secondaryAnimation!.value, equals(1.0));
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(find.text('C'), isOnstage);
    expect(routes['/A']!.secondaryAnimation!.value, equals(routes['/C']!.animation!.value));
    final AnimationController controller = routes['/C']!.controller!;
    controller.value = 1 - controller.value;
    expect(routes['/A']!.secondaryAnimation!.value, equals(routes['/C']!.animation!.value));
  });

  testWidgets('new route removed from navigator history during pushReplacement transition', (WidgetTester tester) async {
    final Map<String, SlideInOutPageRoute<dynamic>> routes = <String, SlideInOutPageRoute<dynamic>>{};
    final Map<String, WidgetBuilder> builders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        },
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/B');
        },
      ),
      '/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.removeRoute(context, routes['/B']!);
        },
      ),
    };
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        final SlideInOutPageRoute<dynamic> ret = SlideInOutPageRoute<dynamic>(bodyBuilder: builders[settings.name]!, settings: settings);
        routes[settings.name!] = ret;
        return ret;
      },
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('/'), isOnstage);
    expect(find.text('B'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(routes['/']!.secondaryAnimation!.value, equals(0.0));
    expect(routes['/']!.animation!.value, equals(1.0));
  });

  testWidgets('pushReplacement triggers secondaryAnimation', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/A');
        },
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/B');
        },
      ),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return SlideInOutPageRoute<dynamic>(bodyBuilder: routes[settings.name]!);
      },
    ));
    await tester.pumpAndSettle();
    final Offset rootOffsetOriginal = tester.getTopLeft(find.text('/'));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), isOnstage);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), findsNothing);
    final Offset rootOffset = tester.getTopLeft(find.text('/'));
    expect(rootOffset.dx, lessThan(rootOffsetOriginal.dx));

    Offset aOffsetOriginal = tester.getTopLeft(find.text('A'));
    await tester.pumpAndSettle();
    Offset aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    aOffsetOriginal = aOffset;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));
  });

  testWidgets('pushReplacement correctly reports didReplace to the observer', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/56892.
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => const OnTapPage(
        id: '/',
      ),
      '/A': (BuildContext context) => const OnTapPage(
        id: 'A',
      ),
      '/A/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          Navigator.of(context).pushReplacementNamed('/C');
        },
      ),
      '/C': (BuildContext context) => const OnTapPage(id: 'C',
      ),
    };
    final List<NavigatorObservation> observations = <NavigatorObservation>[];
    final TestObserver observer = TestObserver()
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didPop',
          ),
        );
      }
      ..onReplaced = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didReplace',
          ),
        );
      };
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
        navigatorObservers: <NavigatorObserver>[observer],
        initialRoute: '/A/B',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('B'), isOnstage);

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(observations.length, 3);
    expect(observations[0].current, '/A/B');
    expect(observations[0].previous, '/A');
    expect(observations[0].operation, 'didPop');
    expect(observations[1].current, '/A');
    expect(observations[1].previous, '/');
    expect(observations[1].operation, 'didPop');

    expect(observations[2].current, '/C');
    expect(observations[2].previous, '/');
    expect(observations[2].operation, 'didReplace');

    await tester.pumpAndSettle();
    expect(find.text('C'), isOnstage);
  });

  testWidgets('Able to pop all routes', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => const OnTapPage(
        id: '/',
      ),
      '/A': (BuildContext context) => const OnTapPage(
        id: 'A',
      ),
      '/A/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          // Pops all routes with bad predicate.
          Navigator.of(context).popUntil((Route<dynamic> route) => false);
        },
      ),
    };
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
        initialRoute: '/A/B',
      ),
    );
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pushAndRemoveUntil triggers secondaryAnimation', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        },
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, '/B', (Route<dynamic> route) => false);
        },
      ),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return SlideInOutPageRoute<dynamic>(bodyBuilder: routes[settings.name]!);
      },
    ));
    await tester.pumpAndSettle();
    final Offset rootOffsetOriginal = tester.getTopLeft(find.text('/'));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), isOnstage);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), findsNothing);
    final Offset rootOffset = tester.getTopLeft(find.text('/'));
    expect(rootOffset.dx, lessThan(rootOffsetOriginal.dx));

    Offset aOffsetOriginal = tester.getTopLeft(find.text('A'));
    await tester.pumpAndSettle();
    Offset aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    aOffsetOriginal = aOffset;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), isOnstage);
  });

  testWidgets('pushAndRemoveUntil does not remove routes below the first route that pass the predicate', (WidgetTester tester) async {
    // Regression https://github.com/flutter/flutter/issues/56688
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('home'),
      '/A': (BuildContext context) => const Text('page A'),
      '/A/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/D', ModalRoute.withName('/A'));
        },
      ),
      '/D': (BuildContext context) => const Text('page D'),
    };

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        routes: routes,
        initialRoute: '/A/B',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('page D'), isOnstage);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('page A'), isOnstage);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), isOnstage);
  });

  testWidgets('replaceNamed returned value', (WidgetTester tester) async {
    late Future<String?> value;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { value = Navigator.pushReplacementNamed(context, '/B', result: 'B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop(context, 'B'); }),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return routes[settings.name]!(context);
          },
        );
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsNothing);

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A')); // replaceNamed('/B'), stack becomes /, /B
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.text('B')); // pop, stack becomes /
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    final String? replaceNamedValue = await value; // replaceNamed result was 'B'
    expect(replaceNamedValue, 'B');
  });

  testWidgets('removeRoute', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pushNamed(context, '/B'); }),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    late Route<String> removedRoute;
    late Route<String> previousRoute;

    final TestObserver observer = TestObserver()
      ..onRemoved = (Route<dynamic>? route, Route<dynamic>? previous) {
        removedRoute = route! as Route<String>;
        previousRoute = previous! as Route<String>;
      };

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[observer],
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name!] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name!]!(context);
          },
        );
        return routes[settings.name];
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A')); // pushNamed('/B'), stack becomes /, /A, /B
    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    // Verify that the navigator's stack is ordered as expected.
    expect(routes['/']!.isActive, true);
    expect(routes['/A']!.isActive, true);
    expect(routes['/B']!.isActive, true);
    expect(routes['/']!.isFirst, true);
    expect(routes['/B']!.isCurrent, true);

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/B']!); // stack becomes /, /A
    await tester.pump();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /B
    expect(routes['/']!.isActive, true);
    expect(routes['/A']!.isActive, true);
    expect(routes['/B']!.isActive, false);
    expect(routes['/']!.isFirst, true);
    expect(routes['/A']!.isCurrent, true);

    expect(removedRoute, routes['/B']);
    expect(previousRoute, routes['/A']);

    navigator.removeRoute(routes['/A']!); // stack becomes just /
    await tester.pump();
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /A
    expect(routes['/']!.isActive, true);
    expect(routes['/A']!.isActive, false);
    expect(routes['/B']!.isActive, false);
    expect(routes['/']!.isFirst, true);
    expect(routes['/']!.isCurrent, true);
    expect(removedRoute, routes['/A']);
    expect(previousRoute, routes['/']);
  });

  testWidgets('remove a route whose value is awaited', (WidgetTester tester) async {
    late Future<String?> pageValue;
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
      '/':  (BuildContext context) => OnTapPage(id: '/', onTap: () { pageValue = Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context, 'A'); }),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name!] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name!]!(context);
          },
        );
        return routes[settings.name];
      },
    ));

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pumpAndSettle();
    pageValue.then((String? value) { assert(false); });

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/A']!); // stack becomes /, pageValue will not complete
  });

  testWidgets('replacing route can be observed', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        log.add('pushed ${route!.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        log.add('popped ${route!.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onRemoved = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        log.add('removed ${route!.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onReplaced = (Route<dynamic>? newRoute, Route<dynamic>? oldRoute) {
        log.add('replaced ${oldRoute!.settings.name} with ${newRoute!.settings.name}');
      };
    late Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: <NavigatorObserver>[observer],
      home: TextButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState!.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              return TextButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState!.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      return TextButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState!.replace(
                            oldRoute: routeB,
                            newRoute: MaterialPageRoute<int>(
                              settings: const RouteSettings(name: 'D'),
                              builder: (BuildContext context) {
                                return const Text('D');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ));
                },
              );
            },
          ));
        },
      ),
    ));
    expect(log, <String>['pushed / (previous is <none>)']);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)']);
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)', 'pushed C (previous is B)']);
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)', 'pushed C (previous is B)', 'replaced B with D']);
  });

  testWidgets('didStartUserGesture observable', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };

    late Route<dynamic> observedRoute;
    late Route<dynamic> observedPreviousRoute;
    final TestObserver observer = TestObserver()
      ..onStartUserGesture = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observedRoute = route!;
        observedPreviousRoute = previousRoute!;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).didStartUserGesture();

    expect(observedRoute.settings.name, '/A');
    expect(observedPreviousRoute.settings.name, '/');
  });

  testWidgets('ModalRoute.of sets up a route to rebuild if its state changes', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    late Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: TextButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState!.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              log.add('building B');
              return TextButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState!.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      log.add('building C');
                      log.add('found ${ModalRoute.of(context)!.settings.name}');
                      return TextButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState!.replace(
                            oldRoute: routeB,
                            newRoute: MaterialPageRoute<int>(
                              settings: const RouteSettings(name: 'D'),
                              builder: (BuildContext context) {
                                log.add('building D');
                                return const Text('D');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ));
                },
              );
            },
          ));
        },
      ),
    ));
    expect(log, <String>[]);
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B']);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C']);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C', 'building D']);
    key.currentState!.pop<void>();
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C', 'building D']);
  });

  testWidgets("Routes don't rebuild just because their animations ended", (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    Route<dynamic>? nextRoute = PageRouteBuilder<int>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        log.add('building page 1 - ${ModalRoute.of(context)!.canPop}');
        return const Placeholder();
      },
    );
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      onGenerateRoute: (RouteSettings settings) {
        assert(nextRoute != null);
        final Route<dynamic> result = nextRoute!;
        nextRoute = null;
        return result;
      },
    ));
    expect(log, <String>['building page 1 - false']);
    key.currentState!.pushReplacement(PageRouteBuilder<int>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        log.add('building page 2 - ${ModalRoute.of(context)!.canPop}');
        return const Placeholder();
      },
    ));
    expect(log, <String>['building page 1 - false']);
    await tester.pump();
    expect(log, <String>['building page 1 - false', 'building page 2 - false']);
    await tester.pump(const Duration(milliseconds: 150));
    expect(log, <String>['building page 1 - false', 'building page 2 - false']);
    key.currentState!.pushReplacement(PageRouteBuilder<int>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        log.add('building page 3 - ${ModalRoute.of(context)!.canPop}');
        return const Placeholder();
      },
    ));
    expect(log, <String>['building page 1 - false', 'building page 2 - false']);
    await tester.pump();
    expect(log, <String>['building page 1 - false', 'building page 2 - false', 'building page 3 - false']);
    await tester.pump(const Duration(milliseconds: 200));
    expect(log, <String>['building page 1 - false', 'building page 2 - false', 'building page 3 - false']);
  });

  testWidgets('route semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => OnTapPage(id: '1', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: '2', onTap: () { Navigator.pushNamed(context, '/B/C'); }),
      '/B/C': (BuildContext context) => const OnTapPage(id: '3'),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 1',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));

    await tester.tap(find.text('1')); // pushNamed('/A')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 2',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));

    await tester.tap(find.text('2')); // pushNamed('/B/C')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.scopesRoute,
      ],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 3',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));


    semantics.dispose();
  });

  testWidgets('arguments for named routes on Navigator', (WidgetTester tester) async {
    late GlobalKey currentRouteKey;
    final List<Object?> arguments = <Object?>[];

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        arguments.add(settings.arguments);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Center(key: currentRouteKey = GlobalKey(), child: Text(settings.name!)),
        );
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(arguments.single, isNull);
    arguments.clear();

    Navigator.pushNamed(
      currentRouteKey.currentContext!,
      '/A',
      arguments: 'pushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsOneWidget);
    expect(arguments.single, 'pushNamed');
    arguments.clear();

    Navigator.popAndPushNamed(
      currentRouteKey.currentContext!,
      '/B',
      arguments: 'popAndPushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsOneWidget);
    expect(arguments.single, 'popAndPushNamed');
    arguments.clear();

    Navigator.pushNamedAndRemoveUntil(
      currentRouteKey.currentContext!,
      '/C',
      (Route<dynamic> route) => route.isFirst,
      arguments: 'pushNamedAndRemoveUntil',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsOneWidget);
    expect(arguments.single, 'pushNamedAndRemoveUntil');
    arguments.clear();

    Navigator.pushReplacementNamed(
      currentRouteKey.currentContext!,
      '/D',
      arguments: 'pushReplacementNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsNothing);
    expect(find.text('/D'), findsOneWidget);
    expect(arguments.single, 'pushReplacementNamed');
    arguments.clear();
  });

  testWidgets('arguments for named routes on NavigatorState', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final List<Object?> arguments = <Object?>[];

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        arguments.add(settings.arguments);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Center(child: Text(settings.name!)),
        );
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(arguments.single, isNull);
    arguments.clear();

    navigatorKey.currentState!.pushNamed(
      '/A',
      arguments:'pushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsOneWidget);
    expect(arguments.single, 'pushNamed');
    arguments.clear();

    navigatorKey.currentState!.popAndPushNamed(
      '/B',
      arguments: 'popAndPushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsOneWidget);
    expect(arguments.single, 'popAndPushNamed');
    arguments.clear();

    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      '/C',
      (Route<dynamic> route) => route.isFirst,
      arguments: 'pushNamedAndRemoveUntil',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsOneWidget);
    expect(arguments.single, 'pushNamedAndRemoveUntil');
    arguments.clear();

    navigatorKey.currentState!.pushReplacementNamed(
      '/D',
      arguments: 'pushReplacementNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsNothing);
    expect(find.text('/D'), findsOneWidget);
    expect(arguments.single, 'pushReplacementNamed');
    arguments.clear();
  });

  testWidgets('Initial route can have gaps', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> keyNav = GlobalKey<NavigatorState>();
    const Key keyRoot = Key('Root');
    const Key keyA = Key('A');
    const Key keyABC = Key('ABC');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: keyNav,
        initialRoute: '/A/B/C',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: keyRoot),
          '/A': (BuildContext context) => Container(key: keyA),
          // The route /A/B is intentionally left out.
          '/A/B/C': (BuildContext context) => Container(key: keyABC),
        },
      ),
    );

    // The initial route /A/B/C should've been pushed successfully.
    expect(find.byKey(keyRoot, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyA, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyABC), findsOneWidget);

    keyNav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(keyRoot, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyA), findsOneWidget);
    expect(find.byKey(keyABC, skipOffstage: false), findsNothing);
  });

  testWidgets('The full initial route has to be matched', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> keyNav = GlobalKey<NavigatorState>();
    const Key keyRoot = Key('Root');
    const Key keyA = Key('A');
    const Key keyAB = Key('AB');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: keyNav,
        initialRoute: '/A/B/C',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: keyRoot),
          '/A': (BuildContext context) => Container(key: keyA),
          '/A/B': (BuildContext context) => Container(key: keyAB),
          // The route /A/B/C is intentionally left out.
        },
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isA<String>());
    // ignore: avoid_dynamic_calls
    expect(exception.startsWith('Could not navigate to initial route.'), isTrue);

    // Only the root route should've been pushed.
    expect(find.byKey(keyRoot), findsOneWidget);
    expect(find.byKey(keyA), findsNothing);
    expect(find.byKey(keyAB), findsNothing);
  });

  testWidgets("Popping immediately after pushing doesn't crash", (WidgetTester tester) async {
    // Added this test to protect against regression of https://github.com/flutter/flutter/issues/45539
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () {
        Navigator.pushNamed(context, '/A');
        Navigator.of(context).pop();
      }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPushed = true;
    };

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isTrue);
  });

  group('error control test', () {
    testWidgets('onUnknownRoute null and onGenerateRoute returns null', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => null,
      ));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error, isNotNull);
      expect(error.diagnostics.last, isA<DiagnosticsProperty<NavigatorState>>());
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Navigator.onGenerateRoute returned null when requested to build\n'
          '   route "/".\n'
          '   The onGenerateRoute callback must never return null, unless an\n'
          '   onUnknownRoute callback is provided as well.\n'
          '   The Navigator was:\n'
          '     NavigatorState#00000(lifecycle state: initialized)\n',
        ),
      );
    });

    testWidgets('onUnknownRoute null and onGenerateRoute returns null', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => null,
        onUnknownRoute: (_) => null,
      ));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error, isNotNull);
      expect(error.diagnostics.last, isA<DiagnosticsProperty<NavigatorState>>());
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Navigator.onUnknownRoute returned null when requested to build\n'
          '   route "/".\n'
          '   The onUnknownRoute callback must never return null.\n'
          '   The Navigator was:\n'
          '     NavigatorState#00000(lifecycle state: initialized)\n',
        ),
      );
    });
  });

  testWidgets('OverlayEntry of topmost initial route is marked as opaque', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final Key root = UniqueKey();
    final Key intermediate = UniqueKey();
    final GlobalKey topmost = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/A/B',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: root),
          '/A': (BuildContext context) => Container(key: intermediate),
          '/A/B': (BuildContext context) => Container(key: topmost),
        },
      ),
    );

    expect(ModalRoute.of(topmost.currentContext!)!.overlayEntries.first.opaque, isTrue);

    expect(find.byKey(root), findsNothing);  // hidden by opaque Route
    expect(find.byKey(intermediate), findsNothing);  // hidden by opaque Route
    expect(find.byKey(topmost), findsOneWidget);
  });

  testWidgets('OverlayEntry of topmost route is set to opaque after Push', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          return NoAnimationPageRoute(
            pageBuilder: (_) => Container(key: ValueKey<String>(settings.name!)),
          );
        },
      ),
    );
    expect(find.byKey(const ValueKey<String>('/')), findsOneWidget);

    navigator.currentState!.pushNamed('/A');
    await tester.pump();

    final BuildContext topMostContext = tester.element(find.byKey(const ValueKey<String>('/A')));
    expect(ModalRoute.of(topMostContext)!.overlayEntries.first.opaque, isTrue);

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /A
    expect(find.byKey(const ValueKey<String>('/A')), findsOneWidget);
  });

  testWidgets('OverlayEntry of topmost route is set to opaque after Replace', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/A/B',
        onGenerateRoute: (RouteSettings settings) {
          return NoAnimationPageRoute(
            pageBuilder: (_) => Container(key: ValueKey<String>(settings.name!)),
          );
        },
      ),
    );
    expect(find.byKey(const ValueKey<String>('/')), findsNothing);
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);
    expect(find.byKey(const ValueKey<String>('/A/B')), findsOneWidget);

    final Route<dynamic> oldRoute = ModalRoute.of(
      tester.element(find.byKey(const ValueKey<String>('/A'), skipOffstage: false)),
    )!;
    final Route<void> newRoute = NoAnimationPageRoute(
      pageBuilder: (_) => Container(key: const ValueKey<String>('/C')),
    );

    navigator.currentState!.replace<void>(oldRoute: oldRoute, newRoute: newRoute);
    await tester.pump();

    expect(newRoute.overlayEntries.first.opaque, isTrue);

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /A/B
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);  // replaced
    expect(find.byKey(const ValueKey<String>('/C')), findsNothing);  // hidden by /A/B
    expect(find.byKey(const ValueKey<String>('/A/B')), findsOneWidget);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /C
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);  // replaced
    expect(find.byKey(const ValueKey<String>('/A/B')), findsNothing); // popped
    expect(find.byKey(const ValueKey<String>('/C')), findsOneWidget);
  });

  testWidgets('Pushing opaque Route does not rebuild routes below', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/45797.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final Key bottomRoute = UniqueKey();
    final Key topRoute = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        navigatorKey: navigator,
        routes: <String, WidgetBuilder>{
          '/' : (BuildContext context) => StatefulTestWidget(key: bottomRoute),
          '/a': (BuildContext context) => StatefulTestWidget(key: topRoute),
        },
      ),
    );
    expect(tester.state<StatefulTestState>(find.byKey(bottomRoute)).rebuildCount, 1);

    navigator.currentState!.pushNamed('/a');
    await tester.pumpAndSettle();

    // Bottom route is offstage and did not rebuild.
    expect(find.byKey(bottomRoute), findsNothing);
    expect(tester.state<StatefulTestState>(find.byKey(bottomRoute, skipOffstage: false)).rebuildCount, 1);

    expect(tester.state<StatefulTestState>(find.byKey(topRoute)).rebuildCount, 1);
  });

  testWidgets('initial routes below opaque route are offstage', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      TestDependencies(
        child: Navigator(
          key: testKey,
          initialRoute: '/a/b',
          onGenerateRoute: (RouteSettings s) {
            return MaterialPageRoute<void>(
              builder: (BuildContext c) {
                return Text('+${s.name}+');
              },
              settings: s,
            );
          },
        ),
      ),
    );

    expect(find.text('+/+'), findsNothing);
    expect(find.text('+/+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a+'), findsNothing);
    expect(find.text('+/a+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a/b+'), findsOneWidget);

    testKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('+/+'), findsNothing);
    expect(find.text('+/+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a+'), findsOneWidget);
    expect(find.text('+/a/b+'), findsNothing);

    testKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('+/+'), findsOneWidget);
    expect(find.text('+/a+'), findsNothing);
    expect(find.text('+/a/b+'), findsNothing);
  });

  testWidgets('Can provide custom onGenerateInitialRoutes', (WidgetTester tester) async {
    bool onGenerateInitialRoutesCalled = false;
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      TestDependencies(
        child: Navigator(
          key: testKey,
          initialRoute: 'Hello World',
          onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
            onGenerateInitialRoutesCalled = true;
            final List<Route<void>> result = <Route<void>>[];
            for (final String route in initialRoute.split(' ')) {
              result.add(MaterialPageRoute<void>(builder: (BuildContext context) {
                return Text(route);
              }));
            }
            return result;
          },
        ),
      ),
    );

    expect(onGenerateInitialRoutesCalled, true);
    expect(find.text('Hello'), findsNothing);
    expect(find.text('World'), findsOneWidget);

    testKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsNothing);
  });

  testWidgets('Navigator.of able to handle input context is a navigator context', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: testKey,
        home: const Text('home'),
      ),
    );

    final NavigatorState state = Navigator.of(testKey.currentContext!);
    expect(state, testKey.currentState);
  });

  testWidgets('Navigator.of able to handle input context is a navigator context - root navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> sub = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        home: Navigator(
          key: sub,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) => const Text('dummy'),
            );
          },
        ),
      ),
    );

    final NavigatorState state = Navigator.of(sub.currentContext!, rootNavigator: true);
    expect(state, root.currentState);
  });

  testWidgets('Navigator.maybeOf throws when there is no navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(SizedBox(key: testKey));

    expect(() async {
      Navigator.of(testKey.currentContext!);
    }, throwsFlutterError);
  });

  testWidgets('Navigator.maybeOf works when there is no navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(SizedBox(key: testKey));

    final NavigatorState? state = Navigator.maybeOf(testKey.currentContext!);
    expect(state, isNull);
  });

  testWidgets('Navigator.maybeOf able to handle input context is a navigator context', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> testKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(
          navigatorKey: testKey,
          home: const Text('home'),
        ),
    );

    final NavigatorState? state = Navigator.maybeOf(testKey.currentContext!);
    expect(state, isNotNull);
    expect(state, testKey.currentState);
  });

  testWidgets('Navigator.maybeOf able to handle input context is a navigator context - root navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> sub = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(
          navigatorKey: root,
          home: Navigator(
            key: sub,
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) => const Text('dummy'),
              );
            },
          ),
        ),
    );

    final NavigatorState? state = Navigator.maybeOf(sub.currentContext!, rootNavigator: true);
    expect(state, isNotNull);
    expect(state, root.currentState);
  });

  testWidgets('pushAndRemove until animates the push', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/25080.

    const Duration kFourTenthsOfTheTransitionDuration = Duration(milliseconds: 120);
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final Map<String, MaterialPageRoute<dynamic>> routeNameToContext = <String, MaterialPageRoute<dynamic>>{};

    await tester.pumpWidget(
      TestDependencies(
        child: Navigator(
          key: navigator,
          initialRoute: 'root',
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                routeNameToContext[settings.name!] = ModalRoute.of(context)! as MaterialPageRoute<dynamic>;
                return Text('Route: ${settings.name}');
              },
            );
          },
        ),
      ),
    );

    expect(find.text('Route: root'), findsOneWidget);

    navigator.currentState!.pushNamed('1');
    await tester.pumpAndSettle();

    expect(find.text('Route: 1'), findsOneWidget);

    navigator.currentState!.pushNamed('2');
    await tester.pumpAndSettle();

    expect(find.text('Route: 2'), findsOneWidget);

    navigator.currentState!.pushNamed('3');
    await tester.pumpAndSettle();

    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 2', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    navigator.currentState!.pushNamedAndRemoveUntil('4', (Route<dynamic> route) => route.isFirst);
    await tester.pump();

    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    final Animation<double> route4Entry = routeNameToContext['4']!.animation!;
    expect(route4Entry.value, 0.0); // Entry animation has not started.

    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 0.4);

    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 0.8);
    expect(find.text('Route: 2', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    // When we hit 1.0 all but root and current have been removed.
    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3', skipOffstage: false), findsNothing);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 1.0);
    expect(find.text('Route: 2', skipOffstage: false), findsNothing);
    expect(find.text('Route: 1', skipOffstage: false), findsNothing);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('Route: root'), findsOneWidget);
    expect(find.text('Route: 4', skipOffstage: false), findsNothing);
  });

  testWidgets('Wrapping TickerMode can turn off ticking in routes', (WidgetTester tester) async {
    int tickCount = 0;
    Widget widgetUnderTest({required bool enabled}) {
      return TickerMode(
        enabled: enabled,
        child: TestDependencies(
          child: Navigator(
            initialRoute: 'root',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return _TickingWidget(
                    onTick: () {
                      tickCount++;
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(widgetUnderTest(enabled: false));
    expect(tickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tickCount, 0);

    await tester.pumpWidget(widgetUnderTest(enabled: true));
    expect(tickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tickCount, 4);
  });

  testWidgets('Route announce correctly for first route and last route', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/57133.
    Route<void>? previousOfFirst = NotAnnounced();
    Route<void>? nextOfFirst = NotAnnounced();
    Route<void>? popNextOfFirst = NotAnnounced();
    Route<void>? firstRoute;

    Route<void>? previousOfSecond = NotAnnounced();
    Route<void>? nextOfSecond = NotAnnounced();
    Route<void>? popNextOfSecond = NotAnnounced();
    Route<void>? secondRoute;

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/second',
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/') {
            firstRoute = RouteAnnouncementSpy(
              onDidChangeNext: (Route<void>? next) => nextOfFirst = next,
              onDidChangePrevious: (Route<void>? previous) => previousOfFirst = previous,
              onDidPopNext: (Route<void>? next) => popNextOfFirst = next,
              settings: settings,
            );
            return firstRoute;
          }
          secondRoute = RouteAnnouncementSpy(
            onDidChangeNext: (Route<void>? next) => nextOfSecond = next,
            onDidChangePrevious: (Route<void>? previous) => previousOfSecond = previous,
            onDidPopNext: (Route<void>? next) => popNextOfSecond = next,
            settings: settings,
          );
          return secondRoute;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(previousOfFirst, isNull);
    expect(nextOfFirst, secondRoute);
    expect(popNextOfFirst, isA<NotAnnounced>());

    expect(previousOfSecond, firstRoute);
    expect(nextOfSecond, isNull);
    expect(popNextOfSecond, isA<NotAnnounced>());

    navigator.currentState!.pop();
    expect(popNextOfFirst, secondRoute);
  });

  testWidgets('hero controller scope works', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> top = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> sub = GlobalKey<NavigatorState>();

    final List<NavigatorObservation> observations = <NavigatorObservation>[];
    final HeroControllerSpy spy = HeroControllerSpy()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didPush',
          ),
        );
      };
    await tester.pumpWidget(
      HeroControllerScope(
        controller: spy,
        child: TestDependencies(
          child: Navigator(
            key: top,
            initialRoute: 'top1',
            onGenerateRoute: (RouteSettings s) {
              return MaterialPageRoute<void>(
                builder: (BuildContext c) {
                  return Navigator(
                    key: sub,
                    initialRoute: 'sub1',
                    onGenerateRoute: (RouteSettings s) {
                      return MaterialPageRoute<void>(
                        builder: (BuildContext c) {
                          return const Placeholder();
                        },
                        settings: s,
                      );
                    },
                  );
                },
                settings: s,
              );
            },
          ),
        ),
      ),
    );
    // It should only observe the top navigator.
    expect(observations.length, 1);
    expect(observations[0].current, 'top1');
    expect(observations[0].previous, isNull);

    sub.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name:'sub2'),
      builder: (BuildContext context) => const Text('sub2'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('sub2'), findsOneWidget);
    // It should not record sub navigator.
    expect(observations.length, 1);

    top.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name:'top2'),
      builder: (BuildContext context) => const Text('top2'),
    ));
    await tester.pumpAndSettle();
    expect(observations.length, 2);
    expect(observations[1].current, 'top2');
    expect(observations[1].previous, 'top1');
  });

  testWidgets('hero controller can correctly transfer subscription - replacing navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key1 = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> key2 = GlobalKey<NavigatorState>();

    final List<NavigatorObservation> observations = <NavigatorObservation>[];
    final HeroControllerSpy spy = HeroControllerSpy()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didPush',
          ),
        );
      };
    await tester.pumpWidget(
      HeroControllerScope(
        controller: spy,
        child: TestDependencies(
          child: Navigator(
            key: key1,
            initialRoute: 'navigator1',
            onGenerateRoute: (RouteSettings s) {
              return MaterialPageRoute<void>(
                builder: (BuildContext c) {
                  return const Placeholder();
                },
                settings: s,
              );
            },
          ),
        ),
      ),
    );
    // Transfer the subscription to another navigator
    await tester.pumpWidget(
      HeroControllerScope(
        controller: spy,
        child: TestDependencies(
          child: Navigator(
            key: key2,
            initialRoute: 'navigator2',
            onGenerateRoute: (RouteSettings s) {
              return MaterialPageRoute<void>(
                builder: (BuildContext c) {
                  return const Placeholder();
                },
                settings: s,
              );
            },
          ),
        ),
      ),
    );
    observations.clear();

    key2.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name:'new route'),
      builder: (BuildContext context) => const Text('new route'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('new route'), findsOneWidget);
    // It should record from the new navigator.
    expect(observations.length, 1);
    expect(observations[0].current, 'new route');
    expect(observations[0].previous, 'navigator2');
  });

  testWidgets('hero controller can correctly transfer subscription - swapping navigator', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key1 = GlobalKey<NavigatorState>();
    final GlobalKey<NavigatorState> key2 = GlobalKey<NavigatorState>();

    final List<NavigatorObservation> observations1 = <NavigatorObservation>[];
    final HeroControllerSpy spy1 = HeroControllerSpy()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations1.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didPush',
          ),
        );
      };
    final List<NavigatorObservation> observations2 = <NavigatorObservation>[];
    final HeroControllerSpy spy2 = HeroControllerSpy()
      ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
        observations2.add(
          NavigatorObservation(
            current: route?.settings.name,
            previous: previousRoute?.settings.name,
            operation: 'didPush',
          ),
        );
      };
    await tester.pumpWidget(
      TestDependencies(
        child: Stack(
          children: <Widget>[
            HeroControllerScope(
              controller: spy1,
              child: Navigator(
                key: key1,
                initialRoute: 'navigator1',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ),
            HeroControllerScope(
              controller: spy2,
              child: Navigator(
                key: key2,
                initialRoute: 'navigator2',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    expect(observations1.length, 1);
    expect(observations1[0].current, 'navigator1');
    expect(observations1[0].previous, isNull);
    expect(observations2.length, 1);
    expect(observations2[0].current, 'navigator2');
    expect(observations2[0].previous, isNull);

    // Swaps the spies.
    await tester.pumpWidget(
      TestDependencies(
        child: Stack(
          children: <Widget>[
            HeroControllerScope(
              controller: spy2,
              child: Navigator(
                key: key1,
                initialRoute: 'navigator1',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ),
            HeroControllerScope(
              controller: spy1,
              child: Navigator(
                key: key2,
                initialRoute: 'navigator2',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Pushes a route to navigator2.
    key2.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name:'new route2'),
      builder: (BuildContext context) => const Text('new route2'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('new route2'), findsOneWidget);
    // The spy1 should record the push in navigator2.
    expect(observations1.length, 2);
    expect(observations1[1].current, 'new route2');
    expect(observations1[1].previous, 'navigator2');
    // The spy2 should not record anything.
    expect(observations2.length, 1);

    // Pushes a route to navigator1
    key1.currentState!.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name:'new route1'),
      builder: (BuildContext context) => const Text('new route1'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('new route1'), findsOneWidget);
    // The spy1 should not record anything.
    expect(observations1.length, 2);
    // The spy2 should record the push in navigator1.
    expect(observations2.length, 2);
    expect(observations2[1].current, 'new route1');
    expect(observations2[1].previous, 'navigator1');
  });

  testWidgets('hero controller subscribes to multiple navigators does throw', (WidgetTester tester) async {
    final HeroControllerSpy spy = HeroControllerSpy();
    await tester.pumpWidget(
      HeroControllerScope(
        controller: spy,
        child: TestDependencies(
          child: Stack(
            children: <Widget>[
              Navigator(
                initialRoute: 'navigator1',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
              Navigator(
                initialRoute: 'navigator2',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('hero controller throws has correct error message', (WidgetTester tester) async {
    final HeroControllerSpy spy = HeroControllerSpy();
    await tester.pumpWidget(
      HeroControllerScope(
        controller: spy,
        child: TestDependencies(
          child: Stack(
            children: <Widget>[
              Navigator(
                initialRoute: 'navigator1',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
              Navigator(
                initialRoute: 'navigator2',
                onGenerateRoute: (RouteSettings s) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext c) {
                      return const Placeholder();
                    },
                    settings: s,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception as FlutterError;
    expect(
      error.toStringDeep(),
      equalsIgnoringHashCodes(
        'FlutterError\n'
        '   A HeroController can not be shared by multiple Navigators. The\n'
        '   Navigators that share the same HeroController are:\n'
        '   - NavigatorState#00000(tickers: tracking 1 ticker)\n'
        '   - NavigatorState#00000(tickers: tracking 1 ticker)\n'
        '   Please create a HeroControllerScope for each Navigator or use a\n'
        '   HeroControllerScope.none to prevent subtree from receiving a\n'
        '   HeroController.\n',
      ),
    );
  });

  group('Page api', () {
    Widget buildNavigator({
      required List<Page<dynamic>> pages,
      required PopPageCallback onPopPage,
      GlobalKey<NavigatorState>? key,
      TransitionDelegate<dynamic>? transitionDelegate,
      List<NavigatorObserver> observers = const <NavigatorObserver>[],
    }) {
      return MediaQuery(
        data: MediaQueryData.fromView(WidgetsBinding.instance.window),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: TestDependencies(
            child: Navigator(
              key: key,
              pages: pages,
              onPopPage: onPopPage,
              observers: observers,
              transitionDelegate: transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
            ),
          ),
        ),
      );
    }

    testWidgets('can initialize with pages list', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('third'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('initial'), findsNothing);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('third'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsOneWidget);
    });

    testWidgets('can handle duplicate page key if update before transition finishes', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/97363.
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final List<TestPage> myPages1 = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
      ];
      final List<TestPage> myPages2 = <TestPage>[
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) => false;

      await tester.pumpWidget(
        buildNavigator(pages: myPages1, onPopPage: onPopPage, key: navigator),
      );
      await tester.pump();
      expect(find.text('initial'), findsOneWidget);
      // Update multiple times without waiting for pop to finish to leave
      // multiple popping route entries in route stack with the same page key.
      await tester.pumpWidget(
        buildNavigator(pages: myPages2, onPopPage: onPopPage, key: navigator),
      );
      await tester.pump();
      await tester.pumpWidget(
        buildNavigator(pages: myPages1, onPopPage: onPopPage, key: navigator),
      );
      await tester.pump();
      await tester.pumpWidget(
        buildNavigator(pages: myPages2, onPopPage: onPopPage, key: navigator),
      );

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('throw if onPopPage callback is not provided', (WidgetTester tester) async {
      final List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(tester.binding.window),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const <LocalizationsDelegate<dynamic>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: TestDependencies(
              child: Navigator(
                pages: myPages,
              ),
            ),
          ),
        ),
      );

      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   The Navigator.onPopPage must be provided to use the\n'
          '   Navigator.pages API\n',
        ),
      );
    });

    testWidgets('throw if page list is empty', (WidgetTester tester) async {
      final List<TestPage> myPages = <TestPage>[];
      final FlutterExceptionHandler? originalOnError = FlutterError.onError;
      FlutterErrorDetails? firstError;
      FlutterError.onError = (FlutterErrorDetails? detail) {
        // We only care about the first error;
        firstError ??= detail;
      };
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(tester.binding.window),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const <LocalizationsDelegate<dynamic>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: TestDependencies(
              child: Navigator(
                pages: myPages,
              ),
            ),
          ),
        ),
      );
      FlutterError.onError = originalOnError;
      expect(
        firstError!.exception.toString(),
        'The Navigator.pages must not be empty to use the Navigator.pages API',
      );
    });

    testWidgets('can push and pop pages using page api', (WidgetTester tester) async {
      late Animation<double> secondaryAnimationOfRouteOne;
      late Animation<double> primaryAnimationOfRouteOne;
      late Animation<double> secondaryAnimationOfRouteTwo;
      late Animation<double> primaryAnimationOfRouteTwo;
      late Animation<double> secondaryAnimationOfRouteThree;
      late Animation<double> primaryAnimationOfRouteThree;
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<Page<dynamic>> myPages = <Page<dynamic>>[
        BuilderPage(
          key: const ValueKey<String>('1'),
          name:'initial',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteOne = secondaryAnimation;
            primaryAnimationOfRouteOne = animation;
            return const Text('initial');
          },
        ),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(find.text('initial'), findsOneWidget);

      myPages = <Page<dynamic>>[
        BuilderPage(
          key: const ValueKey<String>('1'),
          name:'initial',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteOne = secondaryAnimation;
            primaryAnimationOfRouteOne = animation;
            return const Text('initial');
          },
        ),
        BuilderPage(
          key: const ValueKey<String>('2'),
          name:'second',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteTwo = secondaryAnimation;
            primaryAnimationOfRouteTwo = animation;
            return const Text('second');
          },
        ),
        BuilderPage(
          key: const ValueKey<String>('3'),
          name:'third',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteThree = secondaryAnimation;
            primaryAnimationOfRouteThree = animation;
            return const Text('third');
          },
        ),
      ];

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // The third page is transitioning, and the secondary animation of first
      // page should chain with the third page. The animation of second page
      // won't start until the third page finishes transition.
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.forward);

      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.value, 0.1);
      await tester.pumpAndSettle();
      // After transition finishes, the routes' animations are correctly chained.
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);
      // Starts pops the pages using page api and verify the animations chain
      // correctly.

      myPages = <Page<dynamic>>[
        BuilderPage(
          key: const ValueKey<String>('1'),
          name:'initial',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteOne = secondaryAnimation;
            primaryAnimationOfRouteOne = animation;
            return const Text('initial');
          },
        ),
        BuilderPage(
          key: const ValueKey<String>('2'),
          name:'second',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteTwo = secondaryAnimation;
            primaryAnimationOfRouteTwo = animation;
            return const Text('second');
          },
        ),
      ];

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.value, 0.9);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
    });

    testWidgets('can modify routes history and secondary animation still works', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      late Animation<double> secondaryAnimationOfRouteOne;
      late Animation<double> primaryAnimationOfRouteOne;
      late Animation<double> secondaryAnimationOfRouteTwo;
      late Animation<double> primaryAnimationOfRouteTwo;
      late Animation<double> secondaryAnimationOfRouteThree;
      late Animation<double> primaryAnimationOfRouteThree;
      List<Page<dynamic>> myPages = <Page<void>>[
        BuilderPage(
          key: const ValueKey<String>('1'),
          name:'initial',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteOne = secondaryAnimation;
            primaryAnimationOfRouteOne = animation;
            return const Text('initial');
          },
        ),
        BuilderPage(
          key: const ValueKey<String>('2'),
          name:'second',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteTwo = secondaryAnimation;
            primaryAnimationOfRouteTwo = animation;
            return const Text('second');
          },
        ),
        BuilderPage(
          key: const ValueKey<String>('3'),
          name:'third',
          pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
            secondaryAnimationOfRouteThree = secondaryAnimation;
            primaryAnimationOfRouteThree = animation;
            return const Text('third');
          },
        ),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);

      myPages = myPages.reversed.toList();
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // Reversed routes are still chained up correctly.
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);

      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.value, 0.9);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);

      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.value, 0.9);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
    });

    testWidgets('Pop no animation page does not crash', (WidgetTester tester) async {
      // Regression Test for https://github.com/flutter/flutter/issues/86604.
      Widget buildNavigator(bool secondPage) {
        return TestDependencies(
          child: Navigator(
            pages: <Page<void>>[
              const ZeroDurationPage(
                child: Text('page1'),
              ),
              if (secondPage)
                const ZeroDurationPage(
                  child: Text('page2'),
                ),
            ],
            onPopPage: (Route<dynamic> route, dynamic result) => false,
          ),
        );
      }
      await tester.pumpWidget(buildNavigator(true));
      expect(find.text('page2'), findsOneWidget);

      await tester.pumpWidget(buildNavigator(false));
      expect(find.text('page1'), findsOneWidget);
    });

    testWidgets('can work with pageless route', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(find.text('second'), findsOneWidget);
      expect(find.text('initial'), findsNothing);
      // Pushes two pageless routes to second page route
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
        ),
      );
      await tester.pumpAndSettle();
      // Now the history should look like
      // [initial, second, second-pageless1, second-pageless2].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsOneWidget);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(find.text('third'), findsOneWidget);

      // Pushes one pageless routes to third page route
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
        ),
      );
      await tester.pumpAndSettle();
      // Now the history should look like
      // [initial, second, second-pageless1, second-pageless2, third, third-pageless1].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsOneWidget);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // Swaps the order without any adding or removing should not trigger any
      // transition. The routes should update without a pumpAndSettle
      // Now the history should look like
      // [initial, third, third-pageless1, second, second-pageless1, second-pageless2].
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsOneWidget);
      // Pops the route one by one to make sure the order is correct.
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsOneWidget);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 3);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 3);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 2);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 2);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsOneWidget);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 1);
    });

    testWidgets('complex case 1', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      // Add initial page route with one pageless route.
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      bool initialPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('initial-pageless1'),
        ),
      ).then((_) => initialPageless1Completed = true);
      await tester.pumpAndSettle();

      // Pushes second page route with two pageless routes.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pumpAndSettle();
      bool secondPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
        ),
      ).then((_) => secondPageless1Completed = true);
      await tester.pumpAndSettle();
      bool secondPageless2Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
        ),
      ).then((_) => secondPageless2Completed = true);
      await tester.pumpAndSettle();

      // Pushes third page route with one pageless route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pumpAndSettle();
      bool thirdPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
        ),
      ).then((_) => thirdPageless1Completed = true);
      await tester.pumpAndSettle();

      // Nothing has been popped.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      // Switches order and removes the initial page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // The pageless route of initial page route should be completed.
      expect(initialPageless1Completed, true);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pumpAndSettle();
      expect(secondPageless1Completed, true);
      expect(secondPageless2Completed, true);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('4'), name: 'forth'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(thirdPageless1Completed, true);
      await tester.pumpAndSettle();
      expect(find.text('forth'), findsOneWidget);
    });

    //Regression test for https://github.com/flutter/flutter/issues/115887
    testWidgets('Complex case 2', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      expect(find.text('second'), findsOneWidget);
      expect(find.text('initial'), findsNothing);
      // Push pageless route to second page route
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
        ),
      );

      await tester.pumpAndSettle();
      // Now the history should look like [initial, second, second-pageless1].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsOneWidget);
      expect(myPages.length, 2);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      await tester.pumpAndSettle();

      // Now the history should look like [second, second-pageless1].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsOneWidget);
      expect(myPages.length, 1);

      // Pop the pageless route.
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(myPages.length, 1);
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('second-pageless1'), findsNothing);
    });

    testWidgets('complex case 1 - with always remove transition delegate', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final AlwaysRemoveTransitionDelegate transitionDelegate = AlwaysRemoveTransitionDelegate();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      // Add initial page route with one pageless route.
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      bool initialPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('initial-pageless1'),
        ),
      ).then((_) => initialPageless1Completed = true);
      await tester.pumpAndSettle();

      // Pushes second page route with two pageless routes.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      bool secondPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
        ),
      ).then((_) => secondPageless1Completed = true);
      await tester.pumpAndSettle();
      bool secondPageless2Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
        ),
      ).then((_) => secondPageless2Completed = true);
      await tester.pumpAndSettle();

      // Pushes third page route with one pageless route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      bool thirdPageless1Completed = false;
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
        ),
      ).then((_) => thirdPageless1Completed = true);
      await tester.pumpAndSettle();

      // Nothing has been popped.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      // Switches order and removes the initial page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      // The pageless route of initial page route should be removed without complete.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      await tester.pumpAndSettle();
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('4'), name: 'forth'),
      ];
      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          transitionDelegate: transitionDelegate,
        ),
      );
      await tester.pump();
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);
      expect(find.text('forth'), findsOneWidget);
    });

    testWidgets('can repush a page that was previously popped before it has finished popping', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<Page<dynamic>> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // Pops the second page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // Re-push the second page again before it finishes popping.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // It should not crash the app.
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('can update pages before a route has finished popping', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<Page<dynamic>> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // Pops the second page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // Updates the pages again before second page finishes popping.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );

      // It should not crash the app.
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsOneWidget);
    });

    testWidgets('can update pages before a pageless route has finished popping', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/68162.
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<Page<dynamic>> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // Pushes a pageless route.
      showDialog<void>(
        useRootNavigator: false,
        context: navigator.currentContext!,
        builder: (BuildContext context) => const Text('dialog'),
      );
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
      // Pops the pageless route.
      navigator.currentState!.pop();
      // Before the pop finishes, updates the page list.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      await tester.pumpWidget(
        buildNavigator(pages: myPages, onPopPage: onPopPage, key: navigator),
      );
      // It should not crash the app.
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsOneWidget);
    });

    testWidgets('pages remove and add trigger observer in the right order', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'first'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];
      final List<NavigatorObservation> observations = <NavigatorObservation>[];
      final TestObserver observer = TestObserver()
        ..onPushed = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
          observations.add(
            NavigatorObservation(
              current: route?.settings.name,
              previous: previousRoute?.settings.name,
              operation: 'push',
            ),
          );
        }
        ..onRemoved = (Route<dynamic>? route, Route<dynamic>? previousRoute) {
          observations.add(
            NavigatorObservation(
              current: route?.settings.name,
              previous: previousRoute?.settings.name,
              operation: 'remove',
            ),
          );
        };
      bool onPopPage(Route<dynamic> route, dynamic result) => false;

      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          observers: <NavigatorObserver>[observer],
        ),
      );
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('4'), name:'forth'),
        const TestPage(key: ValueKey<String>('5'), name:'fifth'),
      ];

      await tester.pumpWidget(
        buildNavigator(
          pages: myPages,
          onPopPage: onPopPage,
          key: navigator,
          observers: <NavigatorObserver>[observer],
        ),
      );

      await tester.pumpAndSettle();
      expect(observations.length, 8);
      // Initial routes are pushed.
      expect(observations[0].operation, 'push');
      expect(observations[0].current, 'first');
      expect(observations[0].previous, isNull);

      expect(observations[1].operation, 'push');
      expect(observations[1].current, 'second');
      expect(observations[1].previous, 'first');

      expect(observations[2].operation, 'push');
      expect(observations[2].current, 'third');
      expect(observations[2].previous, 'second');

      // Pages are updated.
      // New routes are pushed before removing the initial routes.
      expect(observations[3].operation, 'push');
      expect(observations[3].current, 'forth');
      expect(observations[3].previous, 'third');

      expect(observations[4].operation, 'push');
      expect(observations[4].current, 'fifth');
      expect(observations[4].previous, 'forth');

      // Initial routes are removed.
      expect(observations[5].operation, 'remove');
      expect(observations[5].current, 'third');
      expect(observations[5].previous, isNull);

      expect(observations[6].operation, 'remove');
      expect(observations[6].current, 'second');
      expect(observations[6].previous, isNull);

      expect(observations[7].operation, 'remove');
      expect(observations[7].current, 'first');
      expect(observations[7].previous, isNull);
    });
  });

  testWidgets('Can reuse NavigatorObserver in rebuilt tree', (WidgetTester tester) async {
    final NavigatorObserver observer = NavigatorObserver();
    Widget build([Key? key]) {
      return TestDependencies(
        child: Navigator(
          key: key,
          observers: <NavigatorObserver>[observer],
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) {
                return Container();
              },
            );
          },
        ),
      );
    }

    // Test without reinsertion
    await tester.pumpWidget(build());
    await tester.pumpWidget(Container(child: build()));
    expect(observer.navigator, tester.state<NavigatorState>(find.byType(Navigator)));

    // Clear the tree
    await tester.pumpWidget(Container());
    expect(observer.navigator, isNull);

    // Test with reinsertion
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(build(key));
    await tester.pumpWidget(Container(child: build(key)));
    expect(observer.navigator, tester.state<NavigatorState>(find.byType(Navigator)));
  });

  testWidgets('Navigator requests focus if requestFocus is true', (WidgetTester tester) async {
    final GlobalKey navigatorKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    final Map<String, Widget> routes = <String, Widget>{
      '/': const Text('A'),
      '/second': Text('B', key: innerKey),
    };
    late final NavigatorState navigator = navigatorKey.currentState! as NavigatorState;
    final FocusScopeNode focusNode = FocusScopeNode();

    await tester.pumpWidget(Column(
      children: <Widget>[
        FocusScope(node: focusNode, child: Container()),
        Expanded(
          child: MaterialApp(
            home: Navigator(
              key: navigatorKey,
              onGenerateRoute: (RouteSettings settings) {
                return PageRouteBuilder<void>(
                  settings: settings,
                  pageBuilder: (BuildContext _, Animation<double> __,
                      Animation<double> ___) {
                    return routes[settings.name!]!;
                  },
                );
              },
            ),
          ),
        ),
      ],
    ));
    expect(navigator.widget.requestFocus, true);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);
    expect(focusNode.hasFocus, false);

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, true);

    navigator.pushNamed('/second');
    await tester.pumpAndSettle();
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(focusNode.hasFocus, false);

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, true);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);
    // Pop does not take focus.
    expect(focusNode.hasFocus, true);

    navigator.pushReplacementNamed('/second');
    await tester.pumpAndSettle();
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(focusNode.hasFocus, false);

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, true);

    ModalRoute.of(innerKey.currentContext!)!.addLocalHistoryEntry(
      LocalHistoryEntry(),
    );
    await tester.pumpAndSettle();
    // addLocalHistoryEntry does not take focus.
    expect(focusNode.hasFocus, true);
  });

  testWidgets('Navigator does not request focus if requestFocus is false', (WidgetTester tester) async {
    final GlobalKey navigatorKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    final Map<String, Widget> routes = <String, Widget>{
      '/': const Text('A'),
      '/second': Text('B', key: innerKey),
    };
    late final NavigatorState navigator =
    navigatorKey.currentState! as NavigatorState;
    final FocusScopeNode focusNode = FocusScopeNode();

    await tester.pumpWidget(Column(
      children: <Widget>[
        FocusScope(node: focusNode, child: Container()),
        Expanded(
          child: MaterialApp(
            home: Navigator(
              key: navigatorKey,
              onGenerateRoute: (RouteSettings settings) {
                return PageRouteBuilder<void>(
                  settings: settings,
                  pageBuilder: (BuildContext _, Animation<double> __,
                      Animation<double> ___) {
                    return routes[settings.name!]!;
                  },
                );
              },
              requestFocus: false,
            ),
          ),
        ),
      ],
    ));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);
    expect(focusNode.hasFocus, false);

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, true);

    navigator.pushNamed('/second');
    await tester.pumpAndSettle();
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(focusNode.hasFocus, true);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);
    expect(focusNode.hasFocus, true);

    navigator.pushReplacementNamed('/second');
    await tester.pumpAndSettle();
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(focusNode.hasFocus, true);

    ModalRoute.of(innerKey.currentContext!)!.addLocalHistoryEntry(
      LocalHistoryEntry(),
    );
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, true);
  });

  testWidgets('class implementing NavigatorObserver can be used without problems', (WidgetTester tester) async {
    final _MockNavigatorObserver observer = _MockNavigatorObserver();
    Widget build([Key? key]) {
      return TestDependencies(
        child: Navigator(
          key: key,
          observers: <NavigatorObserver>[observer],
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) {
                return Container();
              },
            );
          },
        ),
      );
    }

    await tester.pumpWidget(build());
    observer._checkInvocations(<Symbol>[#navigator, #didPush]);
    await tester.pumpWidget(Container(child: build()));
    observer._checkInvocations(<Symbol>[#navigator, #didPush, #navigator]);
    await tester.pumpWidget(Container());
    observer._checkInvocations(<Symbol>[#navigator]);
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(build(key));
    observer._checkInvocations(<Symbol>[#navigator, #didPush]);
    await tester.pumpWidget(Container(child: build(key)));
    observer._checkInvocations(<Symbol>[#navigator, #navigator]);
  });

  testWidgets("Navigator doesn't override FocusTraversalPolicy of ancestors", (WidgetTester tester) async {
    FocusTraversalPolicy? policy;
    await tester.pumpWidget(
      TestDependencies(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              return PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (BuildContext context, Animation<double> __, Animation<double> ___) {
                  policy = FocusTraversalGroup.of(context);
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      ),
    );
    expect(policy, isA<WidgetOrderTraversalPolicy>());
  });

  testWidgets('Navigator inserts ReadingOrderTraversalPolicy if no ancestor has a policy', (WidgetTester tester) async {
    FocusTraversalPolicy? policy;
    await tester.pumpWidget(
      TestDependencies(
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (BuildContext context, Animation<double> __, Animation<double> ___) {
                policy = FocusTraversalGroup.of(context);
                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
    expect(policy, isA<ReadingOrderTraversalPolicy>());
  });

  group('RouteSettings.toString', () {
    test('when name is not null, should have double quote', () {
      expect(const RouteSettings(name: '/home').toString(), 'RouteSettings("/home", null)');
    });

    test('when name is null, should not have double quote', () {
      expect(const RouteSettings().toString(), 'RouteSettings(none, null)');
    });
  });
}

typedef AnnouncementCallBack = void Function(Route<dynamic>?);

class NotAnnounced extends Route<void> { /* A place holder for not announced route*/ }

class RouteAnnouncementSpy extends Route<void> {
  RouteAnnouncementSpy({
    this.onDidChangePrevious,
    this.onDidChangeNext,
    this.onDidPopNext,
    super.settings,
  });
  final AnnouncementCallBack? onDidChangePrevious;
  final AnnouncementCallBack? onDidChangeNext;
  final AnnouncementCallBack? onDidPopNext;

  @override
  List<OverlayEntry> get overlayEntries => <OverlayEntry>[
    OverlayEntry(
      builder: (BuildContext context) => const Placeholder(),
    ),
  ];

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    onDidChangeNext?.call(nextRoute);
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    onDidChangePrevious?.call(previousRoute);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    onDidPopNext?.call(nextRoute);
  }
}

class _TickingWidget extends StatefulWidget {
  const _TickingWidget({required this.onTick});

  final VoidCallback onTick;

  @override
  State<_TickingWidget> createState() => _TickingWidgetState();
}

class _TickingWidgetState extends State<_TickingWidget> with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration _) {
      widget.onTick();
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class AlwaysRemoveTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord> locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    void handleExitingRoute(RouteTransitionRecord? location) {
      if (!locationToExitingPageRoute.containsKey(location)) {
        return;
      }

      final RouteTransitionRecord exitingPageRoute = locationToExitingPageRoute[location]!;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final bool hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        exitingPageRoute.markForRemove();
        if (hasPagelessRoute) {
          final List<RouteTransitionRecord> pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute]!;
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }
      results.add(exitingPageRoute);

      handleExitingRoute(exitingPageRoute);
    }
    handleExitingRoute(null);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute);

    }
    return results;
  }
}

class ZeroTransitionPage extends Page<void> {
  const ZeroTransitionPage({
    super.key,
    super.arguments,
    required String super.name,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return NoAnimationPageRoute(
      settings: this,
      pageBuilder: (BuildContext context) => Text(name!),
    );
  }
}

class TestPage extends Page<void> {
  const TestPage({
    super.key,
    required String super.name,
    super.arguments,
  });

  @override
  Route<void> createRoute(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => Text(name!),
      settings: this,
    );
  }
}

class NoAnimationPageRoute extends PageRouteBuilder<void> {
  NoAnimationPageRoute({
    super.settings,
    required WidgetBuilder pageBuilder
  }) : super(
         transitionDuration: Duration.zero,
         reverseTransitionDuration: Duration.zero,
         pageBuilder: (BuildContext context, __, ___) {
           return pageBuilder(context);
         }
       );
}

class StatefulTestWidget extends StatefulWidget {
  const StatefulTestWidget({super.key});

  @override
  State<StatefulTestWidget> createState() => StatefulTestState();
}

class StatefulTestState extends State<StatefulTestWidget> {
  int rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    rebuildCount += 1;
    return Container();
  }
}

class HeroControllerSpy extends HeroController {
  OnObservation? onPushed;
  @override
  void didPush(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    onPushed?.call(route, previousRoute);
  }
}

class NavigatorObservation {
  const NavigatorObservation({this.previous, this.current, required this.operation});
  final String? previous;
  final String? current;
  final String operation;

  @override
  String toString() => 'NavigatorObservation($operation, $current, $previous)';
}

class BuilderPage extends Page<void> {
  const BuilderPage({super.key, super.name, required this.pageBuilder});

  final RoutePageBuilder pageBuilder;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: pageBuilder,
    );
  }
}

class ZeroDurationPage extends Page<void> {
  const ZeroDurationPage({required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return ZeroDurationPageRoute(page: this);
  }
}

class ZeroDurationPageRoute extends PageRoute<void> {
  ZeroDurationPageRoute({required ZeroDurationPage page})
      : super(settings: page, allowSnapshotting: false);

  @override
  Duration get transitionDuration => Duration.zero;

  ZeroDurationPage get _page => settings as ZeroDurationPage;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _page.child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  @override
  bool get maintainState => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;
}

class _MockNavigatorObserver implements NavigatorObserver {
  final List<Symbol> _invocations = <Symbol>[];

  void _checkInvocations(List<Symbol> expected) {
    expect(_invocations, expected);
    _invocations.clear();
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    _invocations.add(invocation.memberName);
    return null;
  }
}

class TestDependencies extends StatelessWidget {
  const TestDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      )
    );
  }
}
