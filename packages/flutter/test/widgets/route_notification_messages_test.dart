// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnTapPage extends StatelessWidget {
  const OnTapPage({Key? key, required this.id, required this.onTap}) : super(key: key);

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

Map<String, dynamic> convertRouteInformationToMap(RouteInformation routeInformation) {
  return <String, dynamic>{
    'location': routeInformation.location,
    'state': routeInformation.state,
  };
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
          'routeUpdated',
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
          'routeUpdated',
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
          'routeUpdated',
          arguments: <String, dynamic>{
            'previousRouteName': '/A',
            'routeName': '/',
          },
        ));
  });

  testWidgets('Navigator does not report route name by default', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.navigation.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Navigator(
        pages: const <Page<void>>[
          TestPage(name: '/'),
        ],
        onPopPage: (Route<void> route, void result) => false,
      )
    ));

    expect(log, hasLength(0));

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Navigator(
        pages: const <Page<void>>[
          TestPage(name: '/'),
          TestPage(name: '/abc',),
        ],
        onPopPage: (Route<void> route, void result) => false,
      )
    ));

    await tester.pumpAndSettle();
    expect(log, hasLength(0));
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
          'routeUpdated',
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
          'routeUpdated',
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
          'routeUpdated',
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
      isMethodCall('routeUpdated', arguments: <String, dynamic>{
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
      isMethodCall('routeUpdated', arguments: <String, dynamic>{
        'previousRouteName': '/home',
        'routeName': null,
      }),
    );
  });

  testWidgets('PlatformRouteInformationProvider reports URL', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.navigation.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    final PlatformRouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      reportConfiguration: true,
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      }
    );

    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: provider,
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Triggers a router rebuild and verify the route information is reported
    // to the web engine.
    delegate.routeInformation = const RouteInformation(
      location: 'update',
      state: 'state',
    );
    await tester.pump();
    expect(find.text('update'), findsOneWidget);

    expect(log, hasLength(1));
    // TODO(chunhtai): check routeInformationUpdated instead once the engine
    // side is done.
    expect(
      log.last,
      isMethodCall('routeInformationUpdated', arguments: <String, dynamic>{
        'location': 'update',
        'state': 'state',
      }),
    );
  });
}

typedef SimpleRouterDelegateBuilder = Widget Function(BuildContext, RouteInformation);
typedef SimpleRouterDelegatePopRoute = Future<bool> Function();

class SimpleRouteInformationParser extends RouteInformationParser<RouteInformation> {
  SimpleRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return SynchronousFuture<RouteInformation>(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class SimpleRouterDelegate extends RouterDelegate<RouteInformation> with ChangeNotifier {
  SimpleRouterDelegate({
    required this.builder,
    this.onPopRoute,
    this.reportConfiguration = false,
  });

  RouteInformation get routeInformation => _routeInformation;
  late RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleRouterDelegatePopRoute? onPopRoute;
  final bool reportConfiguration;

  @override
  RouteInformation? get currentConfiguration {
    if (reportConfiguration)
      return routeInformation;
    return null;
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  @override
  Future<bool> popRoute() {
    if (onPopRoute != null)
      return onPopRoute!();
    return SynchronousFuture<bool>(true);
  }

  @override
  Widget build(BuildContext context) => builder(context, routeInformation);
}

class TestPage extends Page<void> {
  const TestPage({LocalKey? key, String? name}) : super(key: key, name: name);

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => const Placeholder(),
    );
  }
}
