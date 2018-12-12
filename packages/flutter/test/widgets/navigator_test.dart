// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'semantics_tester.dart';

class FirstWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/second');
      },
      child: Container(
        color: const Color(0xFFFFFF00),
        child: const Text('X'),
      ),
    );
  }
}

class SecondWidget extends StatefulWidget {
  @override
  SecondWidgetState createState() => SecondWidgetState();
}

class SecondWidgetState extends State<SecondWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: const Color(0xFFFF00FF),
        child: const Text('Y'),
      ),
    );
  }
}

typedef ExceptionCallback = void Function(dynamic exception);

class ThirdWidget extends StatelessWidget {
  const ThirdWidget({ this.targetKey, this.onException });

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
      behavior: HitTestBehavior.opaque
    );
  }
}

class OnTapPage extends StatelessWidget {
  const OnTapPage({ Key key, this.id, this.onTap }) : super(key: key);

  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page $id')),
      body: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          child: Center(
            child: Text(id, style: Theme.of(context).textTheme.display2),
          ),
        ),
      ),
    );
  }
}

typedef OnObservation = void Function(Route<dynamic> route, Route<dynamic> previousRoute);

class TestObserver extends NavigatorObserver {
  OnObservation onPushed;
  OnObservation onPopped;
  OnObservation onRemoved;
  OnObservation onReplaced;
  OnObservation onStartUserGesture;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (onPushed != null) {
      onPushed(route, previousRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (onPopped != null) {
      onPopped(route, previousRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (onRemoved != null)
      onRemoved(route, previousRoute);
  }

  @override
  void didReplace({ Route<dynamic> oldRoute, Route<dynamic> newRoute }) {
    if (onReplaced != null)
      onReplaced(newRoute, oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (onStartUserGesture != null)
      onStartUserGesture(route, previousRoute);
  }
}

void main() {
  testWidgets('Can navigator navigate to and from a stateful widget', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => FirstWidget(), // X
      '/second': (BuildContext context) => SecondWidget(), // Y
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
      }
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.byKey(targetKey));
    expect(exception, isInstanceOf<FlutterError>());
    expect('$exception', startsWith('Navigator operation requested with a context'));
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
                  if (settings.isInitialRoute) {
                    return MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return RaisedButton(
                          child: const Text('Next'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return RaisedButton(
                                    child: const Text('Inner page'),
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext context) {
                                            return const Text('Dialog');
                                          }
                                        ),
                                      );
                                    },
                                  );
                                }
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
              child: const Text('left')
            ),
            GestureDetector(
              onTap: () { log.add('right'); },
              child: const Text('right')
            ),
          ]
        );
      },
      '/second': (BuildContext context) => Container(),
    };
    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(log, isEmpty);
    await tester.tap(find.text('left'));
    expect(log, equals(<String>['left']));
    await tester.tap(find.text('right'));
    expect(log, equals(<String>['left']));
  });

  // This test doesn't work because the testing framework uses a fake version of
  // the pointer event dispatch loop.
  //
  // TODO(abarth): Test more of the real code and enable this test.
  // See https://github.com/flutter/flutter/issues/4771.
  //
  // testWidgets('Pending gestures are rejected', (WidgetTester tester) async {
  //   List<String> log = <String>[];
  //   final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  //     '/': (BuildContext context) {
  //       return new Row(
  //         children: <Widget>[
  //           new GestureDetector(
  //             onTap: () {
  //               log.add('left');
  //               Navigator.pushNamed(context, '/second');
  //             },
  //             child: new Text('left')
  //           ),
  //           new GestureDetector(
  //             onTap: () { log.add('right'); },
  //             child: new Text('right')
  //           ),
  //         ]
  //       );
  //     },
  //     '/second': (BuildContext context) => new Container(),
  //   };
  //   await tester.pumpWidget(new MaterialApp(routes: routes));
  //   TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('right')), pointer: 23);
  //   expect(log, isEmpty);
  //   await tester.tap(find.text('left'));
  //   expect(log, equals(<String>['left']));
  //   await gesture.up();
  //   expect(log, equals(<String>['left']));
  // });

  testWidgets('popAndPushNamed', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
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

  testWidgets('Push and pop should trigger the observers',
      (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
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
    observer.onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
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
    observer.onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
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
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer1 = TestObserver();
    final TestObserver observer2 = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
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

  testWidgets('replaceNamed', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushReplacementNamed(context, '/A'); }),
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

  testWidgets('replaceNamed returned value', (WidgetTester tester) async {
    Future<String> value;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { value = Navigator.pushReplacementNamed(context, '/B', result: 'B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop(context, 'B'); }),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return routes[settings.name](context);
          },
        );
      }
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

    final String replaceNamedValue = await value; // replaceNamed result was 'B'
    expect(replaceNamedValue, 'B');
  });

  testWidgets('removeRoute', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pushNamed(context, '/B'); }),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    Route<String> removedRoute;
    Route<String> previousRoute;

    final TestObserver observer = TestObserver()
      ..onRemoved = (Route<dynamic> route, Route<dynamic> previous) {
        removedRoute = route;
        previousRoute = previous;
      };

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[observer],
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name](context);
          },
        );
        return routes[settings.name];
      }
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
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, true);
    expect(routes['/B'].isActive, true);
    expect(routes['/'].isFirst, true);
    expect(routes['/B'].isCurrent, true);

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/B']); // stack becomes /, /A
    await tester.pump();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /B
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, true);
    expect(routes['/B'].isActive, false);
    expect(routes['/'].isFirst, true);
    expect(routes['/A'].isCurrent, true);

    expect(removedRoute, routes['/B']);
    expect(previousRoute, routes['/A']);

    navigator.removeRoute(routes['/A']); // stack becomes just /
    await tester.pump();
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /A
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, false);
    expect(routes['/B'].isActive, false);
    expect(routes['/'].isFirst, true);
    expect(routes['/'].isCurrent, true);
    expect(removedRoute, routes['/A']);
    expect(previousRoute, routes['/']);
  });

  testWidgets('remove a route whose value is awaited', (WidgetTester tester) async {
    Future<String> pageValue;
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
      '/':  (BuildContext context) => OnTapPage(id: '/', onTap: () { pageValue = Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context, 'A'); }),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name](context);
          },
        );
        return routes[settings.name];
      }
    ));

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pumpAndSettle();
    pageValue.then((String value) { assert(false); });

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/A']); // stack becomes /, pageValue will not complete
  });

  testWidgets('replacing route can be observed', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('pushed ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('popped ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('removed ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onReplaced = (Route<dynamic> newRoute, Route<dynamic> oldRoute) {
        log.add('replaced ${oldRoute.settings.name} with ${newRoute.settings.name}');
      };
    Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: <NavigatorObserver>[observer],
      home: FlatButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              return FlatButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      return FlatButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState.replace(
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

  testWidgets('didStartUserGesture observable',
      (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };

    Route<dynamic> observedRoute;
    Route<dynamic> observedPreviousRoute;
    final TestObserver observer = TestObserver()
      ..onStartUserGesture = (Route<dynamic> route, Route<dynamic> previousRoute) {
        observedRoute = route;
        observedPreviousRoute = previousRoute;
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
    Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: FlatButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              log.add('building B');
              return FlatButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      log.add('building C');
                      log.add('found ${ModalRoute.of(context).settings.name}');
                      return FlatButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState.replace(
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
    key.currentState.pop<void>();
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C', 'building D', 'building C', 'found C']);
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
}
