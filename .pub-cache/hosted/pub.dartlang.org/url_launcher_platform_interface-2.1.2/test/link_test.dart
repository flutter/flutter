// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:url_launcher_platform_interface/link.dart';

void main() {
  testWidgets('Link with Navigator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Placeholder(key: Key('home')),
      routes: <String, WidgetBuilder>{
        '/a': (BuildContext context) => const Placeholder(key: Key('a')),
      },
    ));
    expect(find.byKey(const Key('home')), findsOneWidget);
    expect(find.byKey(const Key('a')), findsNothing);
    await tester.runAsync(() => pushRouteNameToFramework(null, '/a'));
    // start animation
    await tester.pump();
    // skip past animation (5s is arbitrary, just needs to be long enough)
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('a')), findsOneWidget);
    expect(find.byKey(const Key('home')), findsNothing);
  });

  testWidgets('Link with Navigator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(
      routeInformationParser: _RouteInformationParser(),
      routerDelegate: _RouteDelegate(),
    ));
    expect(find.byKey(const Key('/')), findsOneWidget);
    expect(find.byKey(const Key('/a')), findsNothing);
    await tester.runAsync(() => pushRouteNameToFramework(null, '/a'));
    // start animation
    await tester.pump();
    // skip past animation (5s is arbitrary, just needs to be long enough)
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('/a')), findsOneWidget);
    expect(find.byKey(const Key('/')), findsNothing);
  });
}

class _RouteInformationParser extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
      RouteInformation routeInformation) {
    return SynchronousFuture<RouteInformation>(routeInformation);
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class _RouteDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  final Queue<RouteInformation> _history = Queue<RouteInformation>();

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _history.add(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<bool> popRoute() {
    if (_history.isEmpty) {
      return SynchronousFuture<bool>(false);
    }
    _history.removeLast();
    return SynchronousFuture<bool>(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_history.isEmpty) {
      return const Placeholder(key: Key('empty'));
    }
    return Placeholder(key: Key('${_history.last.location}'));
  }
}
