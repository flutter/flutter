// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// This sample demonstrates using [NavigatorPopHandler] to handle system back
/// gestures when there are nested [Navigator] widgets by delegating to the
/// current [Navigator].

void main() => runApp(const NavigatorPopHandlerApp());

class NavigatorPopHandlerApp extends StatelessWidget {
  const NavigatorPopHandlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => _HomePage(),
        '/nested_navigators': (BuildContext context) => const NestedNavigatorsPage(),
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Navigators Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Home Page'),
            const Text('A system back gesture here will exit the app.'),
            const SizedBox(height: 20.0),
            ListTile(
              title: const Text('Nested Navigator route'),
              subtitle: const Text('This route has another Navigator widget in addition to the one inside MaterialApp above.'),
              onTap: () {
                Navigator.of(context).pushNamed('/nested_navigators');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NestedNavigatorsPage extends StatefulWidget {
  const NestedNavigatorsPage({super.key});

  @override
  State<NestedNavigatorsPage> createState() => _NestedNavigatorsPageState();
}

class _NestedNavigatorsPageState extends State<NestedNavigatorsPage> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPop: () {
        _nestedNavigatorKey.currentState!.maybePop();
      },
      child: Navigator(
        key: _nestedNavigatorKey,
        initialRoute: 'nested_navigators/one',
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case 'nested_navigators/one':
              final BuildContext rootContext = context;
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => NestedNavigatorsPageOne(
                  onBack: () {
                    Navigator.of(rootContext).pop();
                  },
                ),
              );
            case 'nested_navigators/one/another_one':
              return MaterialPageRoute<void>(
                builder: (BuildContext context) => const NestedNavigatorsPageTwo(
                ),
              );
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
        },
      ),
    );
  }
}

class NestedNavigatorsPageOne extends StatelessWidget {
  const NestedNavigatorsPageOne({
    required this.onBack,
    super.key,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Nested Navigators Page One'),
            const Text('A system back here returns to the home page.'),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('nested_navigators/one/another_one');
              },
              child: const Text('Go to another route in this nested Navigator'),
            ),
            TextButton(
              // Can't use Navigator.of(context).pop() because this is the root
              // route, so it can't be popped. The Navigator above this needs to
              // be popped.
              onPressed: onBack,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class NestedNavigatorsPageTwo extends StatelessWidget {
  const NestedNavigatorsPageTwo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withBlue(180),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Nested Navigators Page Two'),
            const Text('A system back here will go back to Nested Navigators Page One'),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
