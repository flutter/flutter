// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome')

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnTapPage extends StatelessWidget {
  const OnTapPage({Key key, this.id, this.onTap}) : super(key: key);

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
            child: Text(id, style: Theme.of(context).textTheme.headline3),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Push and Pop should send platform messages', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => OnTapPage(
          id: '/',
          onTap: () {
            Navigator.pushNamed(context, '/A');
          }),
      '/A': (BuildContext context) => OnTapPage(
          id: 'A',
          onTap: () {
            Navigator.pop(context);
          }),
    };

    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.navigation.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(MaterialApp(
      routes: routes,
    ));

    expect(log, hasLength(1));
    expect(
        log.last,
        isMethodCall(
          'routePushed',
          arguments: <String, dynamic>{
            'previousRouteName': null,
            'routeName': '/',
          },
        ));

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(log, hasLength(2));
    expect(
        log.last,
        isMethodCall(
          'routePushed',
          arguments: <String, dynamic>{
            'previousRouteName': '/',
            'routeName': '/A',
          },
        ));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(log, hasLength(3));
    expect(
        log.last,
        isMethodCall(
          'routePopped',
          arguments: <String, dynamic>{
            'previousRouteName': '/',
            'routeName': '/A',
          },
        ));
  });

  testWidgets('Replace should send platform messages', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => OnTapPage(
          id: '/',
          onTap: () {
            Navigator.pushNamed(context, '/A');
          }),
      '/A': (BuildContext context) => OnTapPage(
          id: 'A',
          onTap: () {
            Navigator.pushReplacementNamed(context, '/B');
          }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () {}),
    };

    final List<MethodCall> log = <MethodCall>[];

    SystemChannels.navigation.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(MaterialApp(
      routes: routes,
    ));

    expect(log, hasLength(1));
    expect(
        log.last,
        isMethodCall(
          'routePushed',
          arguments: <String, dynamic>{
            'previousRouteName': null,
            'routeName': '/',
          },
        ));

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(log, hasLength(2));
    expect(
        log.last,
        isMethodCall(
          'routePushed',
          arguments: <String, dynamic>{
            'previousRouteName': '/',
            'routeName': '/A',
          },
        ));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(log, hasLength(3));
    expect(
        log.last,
        isMethodCall(
          'routeReplaced',
          arguments: <String, dynamic>{
            'previousRouteName': '/A',
            'routeName': '/B',
          },
        ));
  });

  testWidgets('Nameless routes should send platform messages', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.navigation.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(MaterialApp(
      initialRoute: '/home',
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) {
          return OnTapPage(
            id: 'Home',
            onTap: () {
              // Create a route with no name.
              final Route<void> route = MaterialPageRoute<void>(
                builder: (BuildContext context) => const Text('Nameless Route'),
              );
              Navigator.push<void>(context, route);
            },
          );
        },
      },
    ));

    expect(log, hasLength(1));
    expect(
      log.last,
      isMethodCall('routePushed', arguments: <String, dynamic>{
        'previousRouteName': null,
        'routeName': '/home',
      }),
    );

    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(log, hasLength(2));
    expect(
      log.last,
      isMethodCall('routePushed', arguments: <String, dynamic>{
        'previousRouteName': '/home',
        'routeName': null,
      }),
    );
  });
}
