// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Router state restoration without RouteInformationProvider', (final WidgetTester tester) async {
    final UniqueKey router = UniqueKey();
    _TestRouterDelegate delegate() => tester.widget<Router<Object?>>(find.byKey(router)).routerDelegate as _TestRouterDelegate;

    await tester.pumpWidget(_TestWidget(routerKey: router));
    expect(find.text('Current config: null'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, isEmpty);

    delegate().currentConfiguration = '/foo';
    await tester.pumpAndSettle();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, isEmpty);

    await tester.restartAndRestore();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    final TestRestorationData restorationData = await tester.getRestorationData();

    delegate().currentConfiguration = '/bar';
    await tester.pumpAndSettle();
    expect(find.text('Current config: /bar'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    await tester.restoreFrom(restorationData);
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, <String>['/foo', '/foo']);
  });

  testWidgets('Router state restoration with RouteInformationProvider', (final WidgetTester tester) async {
    final UniqueKey router = UniqueKey();
    _TestRouterDelegate delegate() => tester.widget<Router<Object?>>(find.byKey(router)).routerDelegate as _TestRouterDelegate;
    _TestRouteInformationProvider provider() => tester.widget<Router<Object?>>(find.byKey(router)).routeInformationProvider! as _TestRouteInformationProvider;

    await tester.pumpWidget(_TestWidget(routerKey: router, withInformationProvider: true));
    expect(find.text('Current config: /home'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/home']);
    expect(delegate().restoredRoutePaths, isEmpty);

    provider().value = const RouteInformation(location: '/foo');
    await tester.pumpAndSettle();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/home', '/foo']);
    expect(delegate().restoredRoutePaths, isEmpty);

    await tester.restartAndRestore();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    final TestRestorationData restorationData = await tester.getRestorationData();

    provider().value = const RouteInformation(location: '/bar');
    await tester.pumpAndSettle();
    expect(find.text('Current config: /bar'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/bar']);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    await tester.restoreFrom(restorationData);
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/bar']);
    expect(delegate().restoredRoutePaths, <String>['/foo', '/foo']);
  });
}

class _TestRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(final RouteInformation routeInformation) {
    return SynchronousFuture<String>(routeInformation.location!);
  }

  @override
  RouteInformation? restoreRouteInformation(final String configuration) {
    return RouteInformation(location: configuration);
  }
}

class _TestRouterDelegate extends RouterDelegate<String> with ChangeNotifier {
  final List<String> newRoutePaths = <String>[];
  final List<String> restoredRoutePaths = <String>[];

  @override
  String? get currentConfiguration => _currentConfiguration;
  String? _currentConfiguration;
  set currentConfiguration(final String? value) {
    if (value == _currentConfiguration) {
      return;
    }
    _currentConfiguration = value;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(final String configuration) {
    _currentConfiguration = configuration;
    newRoutePaths.add(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<void> setRestoredRoutePath(final String configuration) {
    _currentConfiguration = configuration;
    restoredRoutePaths.add(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(final BuildContext context) {
    return Text('Current config: $currentConfiguration', textDirection: TextDirection.ltr);
  }

  @override
  Future<bool> popRoute() async => throw UnimplementedError();
}

class _TestRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  @override
  RouteInformation get value => _value;
  RouteInformation _value = const RouteInformation(location: '/home');
  set value(final RouteInformation value) {
    if (value == _value) {
      return;
    }
    _value = value;
    notifyListeners();
  }
}

class _TestWidget extends StatelessWidget {
  const _TestWidget({this.withInformationProvider = false, this.routerKey});

  final bool withInformationProvider;
  final Key? routerKey;

  @override
  Widget build(final BuildContext context) {
    return RootRestorationScope(
      restorationId: 'root',
      child: Router<String>(
        key: routerKey,
        restorationScopeId: 'router',
        routerDelegate: _TestRouterDelegate(),
        routeInformationParser: _TestRouteInformationParser(),
        routeInformationProvider: withInformationProvider ? _TestRouteInformationProvider() : null,
      ),
    );
  }
}
