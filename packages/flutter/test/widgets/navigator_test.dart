// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class FirstWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  return new GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/second');
      },
      child: new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFFFFFF00)
        ),
        child: const Text('X')
      )
    );
  }
}

class SecondWidget extends StatefulWidget {
  @override
  SecondWidgetState createState() => new SecondWidgetState();
}

class SecondWidgetState extends State<SecondWidget> {
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () => Navigator.pop(context),
      child: new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFFFF00FF)
        ),
        child: const Text('Y')
      )
    );
  }
}

typedef void ExceptionCallback(dynamic exception);

class ThirdWidget extends StatelessWidget {
  ThirdWidget({ this.targetKey, this.onException });

  final Key targetKey;
  final ExceptionCallback onException;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
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
  OnTapPage({ Key key, this.id, this.onTap }) : super(key: key);

  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Page $id')),
      body: new GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: new Container(
          child: new Center(
            child: new Text(id, style: Theme.of(context).textTheme.display2),
          ),
        ),
      ),
    );
  }
}

typedef void OnPushed(Route<dynamic> route, Route<dynamic> previousRoute);
typedef void OnPopped(Route<dynamic> route, Route<dynamic> previousRoute);

class TestObserver extends NavigatorObserver {
  OnPushed onPushed;
  OnPopped onPopped;

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
}

void main() {
  testWidgets('Can navigator navigate to and from a stateful widget', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => new FirstWidget(), // X
      '/second': (BuildContext context) => new SecondWidget(), // Y
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));
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
    final Key targetKey = const Key('foo');
    dynamic exception;
    final Widget widget = new ThirdWidget(
      targetKey: targetKey,
      onException: (dynamic e) {
        exception = e;
      }
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.byKey(targetKey));
    expect(exception, const isInstanceOf<FlutterError>());
    expect('$exception', startsWith('Navigator operation requested with a context'));
  });

  testWidgets('Gestures between push and build are ignored', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        return new Row(
          children: <Widget>[
            new GestureDetector(
              onTap: () {
                log.add('left');
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('left')
            ),
            new GestureDetector(
              onTap: () { log.add('right'); },
              child: const Text('right')
            ),
          ]
        );
      },
      '/second': (BuildContext context) => new Container(),
    };
    await tester.pumpWidget(new MaterialApp(routes: routes));
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
       '/': (BuildContext context) => new OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => new OnTapPage(id: 'A', onTap: () { Navigator.popAndPushNamed(context, '/B'); }),
      '/B': (BuildContext context) => new OnTapPage(id: 'B', onTap: () { Navigator.pop(context); }),
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));
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
       '/': (BuildContext context) => new OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => new OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = new TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(new MaterialApp(
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

  testWidgets("Add and remove an observer should work", (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) => new OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => new OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer1 = new TestObserver();
    final TestObserver observer2 = new TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1],
    ));
    expect(isPushed, isFalse);
    expect(isPopped, isFalse);

    await tester.pumpWidget(new MaterialApp(
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

    await tester.pumpWidget(new MaterialApp(
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
       '/': (BuildContext context) => new OnTapPage(id: '/', onTap: () { Navigator.pushReplacementNamed(context, '/A'); }),
      '/A': (BuildContext context) => new OnTapPage(id: 'A', onTap: () { Navigator.pushReplacementNamed(context, '/B'); }),
      '/B': (BuildContext context) => new OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));
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
       '/': (BuildContext context) => new OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => new OnTapPage(id: 'A', onTap: () { value = Navigator.pushReplacementNamed(context, '/B', result: 'B'); }),
      '/B': (BuildContext context) => new OnTapPage(id: 'B', onTap: () { Navigator.pop(context, 'B'); }),
    };

    await tester.pumpWidget(new MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return new PageRouteBuilder<String>(
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
}
