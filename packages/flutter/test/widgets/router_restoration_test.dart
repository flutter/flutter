// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('Router state restoration without RouteInformationProvider', (WidgetTester tester) async {
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

  testWidgets('Router state restoration with RouteInformationProvider', (WidgetTester tester) async {
    final UniqueKey router = UniqueKey();
    _TestRouterDelegate delegate() => tester.widget<Router<Object?>>(find.byKey(router)).routerDelegate as _TestRouterDelegate;
    _TestRouteInformationProvider provider() => tester.widget<Router<Object?>>(find.byKey(router)).routeInformationProvider! as _TestRouteInformationProvider;

    await tester.pumpWidget(_TestWidget(routerKey: router, withInformationProvider: true));
    expect(find.text('Current config: /home'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/home']);
    expect(delegate().restoredRoutePaths, isEmpty);

    provider().value = RouteInformation(uri: Uri(path: '/foo'));
    await tester.pumpAndSettle();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/home', '/foo']);
    expect(delegate().restoredRoutePaths, isEmpty);

    await tester.restartAndRestore();
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, isEmpty);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    final TestRestorationData restorationData = await tester.getRestorationData();

    provider().value = RouteInformation(uri: Uri.parse('/bar'));
    await tester.pumpAndSettle();
    expect(find.text('Current config: /bar'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/bar']);
    expect(delegate().restoredRoutePaths, <String>['/foo']);

    await tester.restoreFrom(restorationData);
    expect(find.text('Current config: /foo'), findsOneWidget);
    expect(delegate().newRoutePaths, <String>['/bar']);
    expect(delegate().restoredRoutePaths, <String>['/foo', '/foo']);
  });

  testWidgets('Router state restoration with serializable state works', (WidgetTester tester) async {
    final UniqueKey router = UniqueKey();
    _TestRouteInformationProvider provider() => tester.widget<Router<Object?>>(find.byKey(router)).routeInformationProvider! as _TestRouteInformationProvider;
    final _TestRouterDelegateWithState delegate = _TestRouterDelegateWithState();
    addTearDown(() {
      delegate.dispose();
    });

    await tester.pumpWidget(
      _TestWidget(
        routerKey: router,
        delegate: delegate,
        parser: _TestRouteInformationParserWithState(),
        withInformationProvider: true,
      ),
    );
    expect(delegate.currentConfiguration!.uri.toString(), '/home');
    expect(delegate.currentConfiguration!.state, null);

    provider().value = RouteInformation(uri: Uri(path: '/foo'), state: 'state');
    await tester.pumpAndSettle();
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, 'state');

    await tester.restartAndRestore();
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, 'state');

    final TestRestorationData restorationData = await tester.getRestorationData();

    provider().value = RouteInformation(uri: Uri.parse('/bar'), state: 'state2');
    await tester.pumpAndSettle();
    expect(delegate.currentConfiguration!.uri.toString(), '/bar');
    expect(delegate.currentConfiguration!.state, 'state2');

    await tester.restoreFrom(restorationData);
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, 'state');
  });

  testWidgets('Router state restoration with complex state and custom codec works', (WidgetTester tester) async {
    final UniqueKey router = UniqueKey();
    _TestRouteInformationProvider provider() => tester.widget<Router<Object?>>(find.byKey(router)).routeInformationProvider! as _TestRouteInformationProvider;
    final _TestRouterDelegateWithState delegate = _TestRouterDelegateWithState();
    addTearDown(() {
      delegate.dispose();
    });

    await tester.pumpWidget(
      _TestWidget(
        routerKey: router,
        delegate: delegate,
        parser: _TestRouteInformationParserWithState(),
        withInformationProvider: true,
        codec: const _TestRouteInformationCodec(),
      ),
    );
    expect(delegate.currentConfiguration!.uri.toString(), '/home');
    expect(delegate.currentConfiguration!.state, null);

    provider().value = RouteInformation(uri: Uri(path: '/foo'), state: const _TestComplexObject(1, 2));
    await tester.pumpAndSettle();
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, const _TestComplexObject(1, 2));

    await tester.restartAndRestore();
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, const _TestComplexObject(1, 2));

    final TestRestorationData restorationData = await tester.getRestorationData();

    provider().value = RouteInformation(uri: Uri.parse('/bar'), state: const _TestComplexObject(3, 4));
    await tester.pumpAndSettle();
    expect(delegate.currentConfiguration!.uri.toString(), '/bar');
    expect(delegate.currentConfiguration!.state, const _TestComplexObject(3, 4));

    await tester.restoreFrom(restorationData);
    expect(delegate.currentConfiguration!.uri.toString(), '/foo');
    expect(delegate.currentConfiguration!.state, const _TestComplexObject(1, 2));
  });
}

class _TestRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture<String>(routeInformation.uri.toString());
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}

class _TestRouterDelegate extends RouterDelegate<String> with ChangeNotifier {
  _TestRouterDelegate() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final List<String> newRoutePaths = <String>[];
  final List<String> restoredRoutePaths = <String>[];

  @override
  String? get currentConfiguration => _currentConfiguration;
  String? _currentConfiguration;
  set currentConfiguration(String? value) {
    if (value == _currentConfiguration) {
      return;
    }
    _currentConfiguration = value;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(String configuration) {
    _currentConfiguration = configuration;
    newRoutePaths.add(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<void> setRestoredRoutePath(String configuration) {
    _currentConfiguration = configuration;
    restoredRoutePaths.add(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(BuildContext context) {
    return Text('Current config: $currentConfiguration', textDirection: TextDirection.ltr);
  }

  @override
  Future<bool> popRoute() async => throw UnimplementedError();
}

class _TestRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  _TestRouteInformationProvider() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  RouteInformation get value => _value;
  RouteInformation _value = RouteInformation(uri: Uri.parse('/home'));
  set value(RouteInformation value) {
    if (value == _value) {
      return;
    }
    _value = value;
    notifyListeners();
  }
}

class _TestWidget extends StatefulWidget {
  const _TestWidget({
    this.withInformationProvider = false,
    this.routerKey,
    this.parser,
    this.delegate,
    this.codec,
  });

  final bool withInformationProvider;
  final Key? routerKey;
  final RouteInformationParser<Object?>? parser;
  final RouterDelegate<Object?>? delegate;
  final Codec<RouteInformation?, Object?>? codec;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  late final RouterDelegate<Object?> _delegate = widget.delegate ?? (_internalDelegate = _TestRouterDelegate());
  _TestRouterDelegate? _internalDelegate;
  final _TestRouteInformationProvider _routeInformationProvider = _TestRouteInformationProvider();

  @override
  void dispose() {
    _internalDelegate?.dispose();
    _routeInformationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RootRestorationScope(
      restorationId: 'root',
      child: Router<Object?>(
        key: widget.routerKey,
        restorationScopeId: 'router',
        routerDelegate: _delegate,
        routeInformationCodec: widget.codec,
        routeInformationParser: widget.parser ?? _TestRouteInformationParser(),
        routeInformationProvider: widget.withInformationProvider ? _routeInformationProvider : null,
      ),
    );
  }
}

class _TestRouteInformationParserWithState extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture<RouteInformation>(routeInformation);
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class _TestRouterDelegateWithState extends RouterDelegate<RouteInformation> with ChangeNotifier {
  _TestRouterDelegateWithState() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  RouteInformation? get currentConfiguration => _currentConfiguration;
  RouteInformation? _currentConfiguration;
  set currentConfiguration(RouteInformation? value) {
    if (value == _currentConfiguration) {
      return;
    }
    _currentConfiguration = value;
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _currentConfiguration = configuration;
    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(BuildContext context) {
    return Text('uri: ${currentConfiguration?.uri}, state: ${currentConfiguration?.state}', textDirection: TextDirection.ltr);
  }

  @override
  Future<bool> popRoute() async => throw UnimplementedError();
}

@immutable
class _TestComplexObject {
  const _TestComplexObject(this.a, this.b);
  final int a;
  final int b;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _TestComplexObject
        && a == other.a
        && b == other.b;
  }

  @override
  int get hashCode => Object.hash(a, b);
}

class _TestRouteInformationCodec extends Codec<RouteInformation?, Object?> {
  const _TestRouteInformationCodec();
  @override
  Converter<Object?, RouteInformation?> get decoder => const _TestRouteInformationDecoder();

  @override
  Converter<RouteInformation?, Object?> get encoder => const _TestRouteInformationEncoder();

}

class _TestRouteInformationDecoder extends Converter<Object?, RouteInformation?> {
  const _TestRouteInformationDecoder();
  @override
  RouteInformation? convert(Object? input) {
    if (input == null) {
      return null;
    }
    final List<Object?> castedData = input as List<Object?>;
    final String? uri = castedData.first as String?;
    if (uri == null) {
      return null;
    }
    final Object? state;
    if (castedData.length == 2) {
      final List<Object?> encodedState = castedData.last! as List<Object?>;
      state = _TestComplexObject(encodedState[0]! as int, encodedState[1]! as int);
    } else {
      state = null;
    }
    return RouteInformation(uri: Uri.parse(uri), state: state);
  }
}

class _TestRouteInformationEncoder extends Converter<RouteInformation?, Object?> {
  const _TestRouteInformationEncoder();
  @override
  Object? convert(RouteInformation? input) {
    if (input == null) {
      return null;
    }
    final _TestComplexObject? complexState = input.state as _TestComplexObject?;
    return <Object?>[
      input.uri.toString(),
      if (complexState != null)
        <int>[complexState.a, complexState.b],
    ];
  }
}
