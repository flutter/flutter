// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StateMarker extends StatefulWidget {
  const StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  StateMarkerState createState() => StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null)
      return widget.child;
    return Container();
  }
}

void main() {
  testWidgets('Can nest apps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialApp(
          home: Text('Home sweet home'),
        ),
      ),
    );

    expect(find.text('Home sweet home'), findsOneWidget);
  });

  testWidgets('Focus handling', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
          child: TextField(focusNode: focusNode, autofocus: true),
        ),
      ),
    ));

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('Can place app inside FocusScope', (WidgetTester tester) async {
    final FocusScopeNode focusScopeNode = FocusScopeNode();

    await tester.pumpWidget(FocusScope(
      autofocus: true,
      node: focusScopeNode,
      child: const MaterialApp(
        home: Text('Home'),
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Can show grid without losing sync', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StateMarker(),
      ),
    );

    final StateMarkerState state1 = tester.state(find.byType(StateMarker));
    state1.marker = 'original';

    await tester.pumpWidget(
      const MaterialApp(
        debugShowMaterialGrid: true,
        home: StateMarker(),
      ),
    );

    final StateMarkerState state2 = tester.state(find.byType(StateMarker));
    expect(state1, equals(state2));
    expect(state2.marker, equals('original'));
  });

  testWidgets('Do not rebuild page during a route transition', (WidgetTester tester) async {
    int buildCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Material(
              child: RaisedButton(
                child: const Text('X'),
                onPressed: () { Navigator.of(context).pushNamed('/next'); },
              ),
            );
          }
        ),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return Builder(
              builder: (BuildContext context) {
                ++buildCounter;
                return const Text('Y');
              },
            );
          },
        },
      ),
    );

    expect(buildCounter, 0);
    await tester.tap(find.text('X'));
    expect(buildCounter, 0);
    await tester.pump();
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(buildCounter, 1);
    expect(find.text('Y'), findsOneWidget);
  });

  testWidgets('Do rebuild the home page if it changes', (WidgetTester tester) async {
    int buildCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            ++buildCounter;
            return const Text('A');
          }
        ),
      ),
    );
    expect(buildCounter, 1);
    expect(find.text('A'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            ++buildCounter;
            return const Text('B');
          }
        ),
      ),
    );
    expect(buildCounter, 2);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Do not rebuild the home page if it does not actually change', (WidgetTester tester) async {
    int buildCounter = 0;
    final Widget home = Builder(
      builder: (BuildContext context) {
        ++buildCounter;
        return const Placeholder();
      }
    );
    await tester.pumpWidget(
      MaterialApp(
        home: home,
      ),
    );
    expect(buildCounter, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: home,
      ),
    );
    expect(buildCounter, 1);
  });

  testWidgets('Do rebuild pages that come from the routes table if the MaterialApp changes', (WidgetTester tester) async {
    int buildCounter = 0;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        ++buildCounter;
        return const Placeholder();
      },
    };
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );
    expect(buildCounter, 1);
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );
    expect(buildCounter, 2);
  });

  testWidgets('Cannot pop the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Home')));

    expect(find.text('Home'), findsOneWidget);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    final bool result = await navigator.maybePop();

    expect(result, isFalse);

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Default initialRoute', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
    }));

    expect(find.text('route "/"'), findsOneWidget);
  });

  testWidgets('One-step initial route', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Text('route "/"'),
          '/a': (BuildContext context) => const Text('route "/a"'),
          '/a/b': (BuildContext context) => const Text('route "/a/b"'),
          '/b': (BuildContext context) => const Text('route "/b"'),
        },
      )
    );

    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/a/b"'), findsNothing);
    expect(find.text('route "/b"'), findsNothing);
  });

  testWidgets('Return value from pop is correct', (WidgetTester tester) async {
    Future<Object> result;
    await tester.pumpWidget(
        MaterialApp(
          home: Builder(
              builder: (BuildContext context) {
                return Material(
                  child: RaisedButton(
                      child: const Text('X'),
                      onPressed: () async {
                        result = Navigator.of(context).pushNamed('/a');
                      }
                  ),
                );
              }
          ),
          routes: <String, WidgetBuilder>{
            '/a': (BuildContext context) {
              return Material(
                child: RaisedButton(
                  child: const Text('Y'),
                  onPressed: () {
                    Navigator.of(context).pop('all done');
                  },
                ),
              );
            }
          },
        )
    );
    await tester.tap(find.text('X'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Y'), findsOneWidget);
    await tester.tap(find.text('Y'));
    await tester.pump();

    expect(await result, equals('all done'));
  });

    testWidgets('Two-step initial route', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/a/b': (BuildContext context) => const Text('route "/a/b"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a/b',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/a/b"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);
  });

  testWidgets('Initial route with missing step', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/a/b': (BuildContext context) => const Text('route "/a/b"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a/b/c',
        routes: routes,
      )
    );
    final dynamic exception = tester.takeException();
    expect(exception is String, isTrue);
    expect(exception.startsWith('Could not navigate to initial route.'), isTrue);
    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsNothing);
    expect(find.text('route "/a/b"'), findsNothing);
    expect(find.text('route "/b"'), findsNothing);
  });

  testWidgets('Make sure initialRoute is only used the first time', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);

    // changing initialRoute has no effect
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/b',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);

    // removing it has no effect
    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('route "/"'), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);
  });

  testWidgets('onGenerateRoute / onUnknownRoute', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (RouteSettings settings) {
          log.add('onGenerateRoute ${settings.name}');
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          log.add('onUnknownRoute ${settings.name}');
          return null;
        },
      )
    );
    expect(tester.takeException(), isFlutterError);
    expect(log, <String>['onGenerateRoute /', 'onUnknownRoute /']);
  });

  testWidgets('Can get text scale from media query', (WidgetTester tester) async {
    double textScaleFactor;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder:(BuildContext context) {
        textScaleFactor = MediaQuery.of(context).textScaleFactor;
        return Container();
      }),
    ));
    expect(textScaleFactor, isNotNull);
    expect(textScaleFactor, equals(1.0));
  });

  testWidgets('MaterialApp.navigatorKey', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      home: const Placeholder(),
    ));
    expect(key.currentState, isInstanceOf<NavigatorState>());
    await tester.pumpWidget(const MaterialApp(
      color: Color(0xFF112233),
      home: Placeholder(),
    ));
    expect(key.currentState, isNull);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      home: const Placeholder(),
    ));
    expect(key.currentState, isInstanceOf<NavigatorState>());
  });

  testWidgets('Has default material and cupertino localizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                Text(MaterialLocalizations.of(context).selectAllButtonLabel),
                Text(CupertinoLocalizations.of(context).selectAllButtonLabel),
              ],
            );
          },
        ),
      ),
    );

    // Default US "select all" text.
    expect(find.text('SELECT ALL'), findsOneWidget);
    // Default Cupertino US "select all" text.
    expect(find.text('Select All'), findsOneWidget);
  });
}
