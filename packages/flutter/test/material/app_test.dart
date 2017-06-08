// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class StateMarker extends StatefulWidget {
  const StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  StateMarkerState createState() => new StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null)
      return widget.child;
    return new Container();
  }
}

void main() {
  testWidgets('Can nest apps', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new MaterialApp(
          home: const Text('Home sweet home'),
        ),
      ),
    );

    expect(find.text('Home sweet home'), findsOneWidget);
  });

  testWidgets('Focus handling', (WidgetTester tester) async {
    final FocusNode focusNode = new FocusNode();
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new TextField(focusNode: focusNode, autofocus: true),
        ),
      ),
    ));

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('Can place app inside FocusScope', (WidgetTester tester) async {
    final FocusScopeNode focusScopeNode = new FocusScopeNode();

    await tester.pumpWidget(new FocusScope(
      autofocus: true,
      node: focusScopeNode,
      child: new MaterialApp(
        home: const Text('Home'),
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Can show grid without losing sync', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const StateMarker(),
      ),
    );

    final StateMarkerState state1 = tester.state(find.byType(StateMarker));
    state1.marker = 'original';

    await tester.pumpWidget(
      new MaterialApp(
        debugShowMaterialGrid: true,
        home: const StateMarker(),
      ),
    );

    final StateMarkerState state2 = tester.state(find.byType(StateMarker));
    expect(state1, equals(state2));
    expect(state2.marker, equals('original'));
  });

  testWidgets('Do not rebuild page on the second frame of the route transition', (WidgetTester tester) async {
    int buildCounter = 0;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            return new Material(
              child: new RaisedButton(
                child: const Text('X'),
                onPressed: () { Navigator.of(context).pushNamed('/next'); },
              ),
            );
          }
        ),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Builder(
              builder: (BuildContext context) {
                ++buildCounter;
                return new Container();
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
    expect(buildCounter, 2);
  });

  testWidgets('Cannot pop the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: const Text('Home')));

    expect(find.text('Home'), findsOneWidget);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    final bool result = await navigator.maybePop();

    expect(result, isFalse);

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Default initialRoute', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
    }));

    expect(find.text('route "/"'), findsOneWidget);
  });

  testWidgets('Custom initialRoute only', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        initialRoute: '/a',
        routes: <String, WidgetBuilder>{
          '/a': (BuildContext context) => const Text('route "/a"'),
        },
      )
    );

    expect(find.text('route "/a"'), findsOneWidget);
  });

  testWidgets('Custom initialRoute along with Navigator.defaultRouteName', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      new MaterialApp(
        initialRoute: '/a',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsNothing);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);
  });

  testWidgets('Make sure initialRoute is only used the first time', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      new MaterialApp(
        initialRoute: '/a',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsNothing);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);

    await tester.pumpWidget(
      new MaterialApp(
        initialRoute: '/b',
        routes: routes,
      )
    );
    expect(find.text('route "/"'), findsNothing);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);

    await tester.pumpWidget(new MaterialApp(routes: routes));
    expect(find.text('route "/"'), findsNothing);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"'), findsNothing);
  });
}
