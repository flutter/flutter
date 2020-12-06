// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('Simple router basic functionality - synchronized', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation information) {
            return Text(information.location);
          }
        ),
      )
    ));
    expect(find.text('initial'), findsOneWidget);

    provider.value = const RouteInformation(
      location: 'update',
    );
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
  });

  testWidgets('Simple router basic functionality - asynchronized', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleAsyncRouteInformationParser parser = SimpleAsyncRouteInformationParser();
    final SimpleAsyncRouterDelegate delegate = SimpleAsyncRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        if (information == null)
          return const Text('waiting');
        return Text(information.location);
      }
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(buildBoilerPlate(
        Router<RouteInformation>(
          routeInformationProvider: provider,
          routeInformationParser: parser,
          routerDelegate: delegate,
        )
      ));
      // Future has not yet completed.
      expect(find.text('waiting'), findsOneWidget);

      await parser.parsingFuture;
      await delegate.setNewRouteFuture;
      await tester.pump();
      expect(find.text('initial'), findsOneWidget);

      provider.value = const RouteInformation(
        location: 'update',
      );
      await tester.pump();
      // Future has not yet completed.
      expect(find.text('initial'), findsOneWidget);

      await parser.parsingFuture;
      await delegate.setNewRouteFuture;
      await tester.pump();
      expect(find.text('update'), findsOneWidget);
    });
  });

  testWidgets('Simple router can handle pop route', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation information) {
            return Text(information.location);
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped',
            );
            return SynchronousFuture<bool>(true);
          }
        ),
        backButtonDispatcher: dispatcher,
      )
    ));
    expect(find.text('initial'), findsOneWidget);

    bool result = false;
    // SynchronousFuture should complete immediately.
    dispatcher.invokeCallback(SynchronousFuture<bool>(false))
      .then((bool data) {
        result = data;
      });
    expect(result, isTrue);

    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('PopNavigatorRouterDelegateMixin works', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location);
      },
      onPopPage: (Route<void> route, void result) {
        provider.value = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      }
    );
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
        backButtonDispatcher: dispatcher,
      )
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pushes a nameless route.
    showDialog<void>(
      useRootNavigator: false,
      context: delegate.navigatorKey.currentContext,
      builder: (BuildContext context) => const Text('dialog')
    );
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    // Pops the nameless route and makes sure the initial page is shown.
    bool result = false;
    result = await dispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);

    await tester.pumpAndSettle();
    expect(find.text('initial'), findsOneWidget);
    expect(find.text('dialog'), findsNothing);

    // Pops one more time.
    result = false;
    result = await dispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('Nested routers back button dispatcher works', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation information) {
            final BackButtonDispatcher innerDispatcher = ChildBackButtonDispatcher(outerDispatcher);
            innerDispatcher.takePriority();
            // Creates the sub-router.
            return Router<RouteInformation>(
              backButtonDispatcher: innerDispatcher,
              routerDelegate: SimpleRouterDelegate(
                builder: (BuildContext context, RouteInformation innerInformation) {
                  return Text(information.location);
                },
                onPopRoute: () {
                  provider.value = const RouteInformation(
                    location: 'popped inner',
                  );
                  return SynchronousFuture<bool>(true);
                },
              ),
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outter',
            );
            return SynchronousFuture<bool>(true);
          }
        ),
      )
    ));
    expect(find.text('initial'), findsOneWidget);

    // The outer dispatcher should trigger the pop on the inner router.
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner'), findsOneWidget);
  });

  testWidgets('Nested router back button dispatcher works for multiple children', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final BackButtonDispatcher innerDispatcher1 = ChildBackButtonDispatcher(outerDispatcher);
    final BackButtonDispatcher innerDispatcher2 = ChildBackButtonDispatcher(outerDispatcher);
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information.location),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher1,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation innerInformation) {
                      return Container();
                    },
                    onPopRoute: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner1',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                  ),
                ),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher2,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation innerInformation) {
                      return Container();
                    },
                    onPopRoute: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner2',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                  ),
                ),
              ],
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outter',
            );
            return SynchronousFuture<bool>(true);
          }
        ),
      )
    ));
    expect(find.text('initial'), findsOneWidget);

    // If none of the children have taken the priority, the root router handles
    // the pop.
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped outter'), findsOneWidget);

    innerDispatcher1.takePriority();
    result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner1'), findsOneWidget);

    // The last child dispatcher that took priority handles the pop.
    innerDispatcher2.takePriority();
    result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner2'), findsOneWidget);
  });

  testWidgets('router does report URL change correctly', (WidgetTester tester) async {
    RouteInformation reportedRouteInformation;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information) {
        // Makes sure we only report once after manually cleaning up.
        expect(reportedRouteInformation, isNull);
        reportedRouteInformation = information;
      }
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      reportConfiguration: true,
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location);
      }
    );
    delegate.onPopRoute = () {
      delegate.routeInformation = const RouteInformation(
        location: 'popped',
      );
      return SynchronousFuture<bool>(true);
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    provider.value = const RouteInformation(
      location: 'initial',
    );

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      )
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(reportedRouteInformation, isNull);
    delegate.routeInformation = const RouteInformation(
      location: 'update',
    );
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    expect(reportedRouteInformation.location, 'update');

    // The router should not report if only state changes.
    reportedRouteInformation = null;
    delegate.routeInformation = const RouteInformation(
      location: 'update',
      state: 'another state',
    );
    await tester.pump();
    expect(find.text('update'), findsOneWidget);
    expect(reportedRouteInformation, isNull);

    reportedRouteInformation = null;
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
    expect(reportedRouteInformation.location, 'popped');
  });

  testWidgets('router can be forced to recognize or ignore navigating events', (WidgetTester tester) async {
    RouteInformation reportedRouteInformation;
    bool isNavigating = false;
    RouteInformation nextRouteInformation;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information) {
        // Makes sure we only report once after manually cleaning up.
        expect(reportedRouteInformation, isNull);
        reportedRouteInformation = information;
      }
    );
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(reportConfiguration: true);
    delegate.builder = (BuildContext context, RouteInformation information) {
      return ElevatedButton(
        child: Text(information.location),
        onPressed: () {
          if (isNavigating) {
            Router.navigate(context, () {
              if (delegate.routeInformation != nextRouteInformation)
                delegate.routeInformation = nextRouteInformation;
            });
          } else {
            Router.neglect(context, () {
              if (delegate.routeInformation != nextRouteInformation)
                delegate.routeInformation = nextRouteInformation;
            });
          }
        },
      );
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      )
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(reportedRouteInformation, isNull);

    nextRouteInformation = const RouteInformation(
      location: 'update',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    expect(reportedRouteInformation, isNull);

    isNavigating = true;
    // This should not trigger any real navigating event because the
    // nextRouteInformation does not change. However, the router should still
    // report a route information because isNavigating = true.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(reportedRouteInformation.location, 'update');
  });

  testWidgets('router does not report when route information is up to date with route information provider', (WidgetTester tester) async {
    RouteInformation reportedRouteInformation;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information) {
        reportedRouteInformation = information;
      }
    );
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(reportConfiguration: true);
    delegate.builder = (BuildContext context, RouteInformation routeInformation) {
      return Text(routeInformation.location);
    };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      )
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(reportedRouteInformation, isNull);
    // This will cause the router to rebuild.
    provider.value = const RouteInformation(
      location: 'update',
    );
    // This will schedule the route reporting.
    delegate.notifyListeners();
    await tester.pump();

    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    // The router should not report because the route name is already up to
    // date.
    expect(reportedRouteInformation, isNull);
  });

  testWidgets('PlatformRouteInformationProvider works', (WidgetTester tester) async {
    final RouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        final List<Widget> children = <Widget>[];
        if (information.location != null)
          children.add(Text(information.location));
        if (information.state != null)
          children.add(Text(information.state.toString()));
        return Column(
          children: children,
        );
      }
    );

    await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pushes through the `pushRouteInformation` in the navigation method channel.
    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
    };
    final ByteData routerMessage = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation)
    );
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', routerMessage, (_) { });
    await tester.pump();
    expect(find.text('testRouteName'), findsOneWidget);
    expect(find.text('state'), findsOneWidget);

    // Pushes through the `pushRoute` in the navigation method channel.
    const String testRouteName = 'newTestRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRouteName));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pump();
    expect(find.text('newTestRouteName'), findsOneWidget);
  });

  testWidgets('RootBackButtonDispatcher works', (WidgetTester tester) async {
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final RouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      reportConfiguration: true,
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location);
      }
    );
    delegate.onPopRoute = () {
      delegate.routeInformation = const RouteInformation(
        location: 'popped',
      );
      return SynchronousFuture<bool>(true);
    };

    await tester.pumpWidget(MaterialApp.router(
      backButtonDispatcher: outerDispatcher,
      routeInformationProvider: provider,
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pop route through the message channel.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
  });
}

Widget buildBoilerPlate(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

typedef SimpleRouterDelegateBuilder = Widget Function(BuildContext, RouteInformation);
typedef SimpleRouterDelegatePopRoute = Future<bool> Function();
typedef SimpleNavigatorRouterDelegatePopPage<T> = bool Function(Route<T> route, T result);
typedef RouterReportRouterInformation = void Function(RouteInformation);

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
    this.builder,
    this.onPopRoute,
    this.reportConfiguration = false,
  });

  RouteInformation get routeInformation => _routeInformation;
  RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleRouterDelegatePopRoute onPopRoute;
  final bool reportConfiguration;

  @override
  RouteInformation get currentConfiguration {
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
      return onPopRoute();
    return SynchronousFuture<bool>(true);
  }

  @override
  Widget build(BuildContext context) => builder(context, routeInformation);
}

class SimpleNavigatorRouterDelegate extends RouterDelegate<RouteInformation> with PopNavigatorRouterDelegateMixin<RouteInformation>, ChangeNotifier {
  SimpleNavigatorRouterDelegate({
    @required this.builder,
    this.onPopPage,
  });

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RouteInformation get routeInformation => _routeInformation;
  RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleNavigatorRouterDelegatePopPage<void> onPopPage;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<void> route, void data) {
    return onPopPage(route, data);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        // We need at least two pages for the pop to propagate through.
        // Otherwise, the navigator will bubble the pop to the system navigator.
        const MaterialPage<void>(
          child: Text('base'),
        ),
        MaterialPage<void>(
          key: ValueKey<String>(routeInformation?.location),
          child: builder(context, routeInformation),
        )
      ],
    );
  }
}

class SimpleRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  SimpleRouteInformationProvider({
    this.onRouterReport
  });

  RouterReportRouterInformation onRouterReport;

  @override
  RouteInformation get value => _value;
  RouteInformation _value;
  set value(RouteInformation newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  void routerReportsNewRouteInformation(RouteInformation routeInformation) {
    if (onRouterReport != null)
      onRouterReport(routeInformation);
  }
}

class SimpleAsyncRouteInformationParser extends RouteInformationParser<RouteInformation> {
  SimpleAsyncRouteInformationParser();

  Future<RouteInformation> parsingFuture;

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return parsingFuture = Future<RouteInformation>.value(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class SimpleAsyncRouterDelegate extends RouterDelegate<RouteInformation> with ChangeNotifier{
  SimpleAsyncRouterDelegate({
    @required this.builder,
  });

  RouteInformation get routeInformation => _routeInformation;
  RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  Future<void> setNewRouteFuture;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return setNewRouteFuture = Future<void>.value();
  }

  @override
  Future<bool> popRoute() {
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) => builder(context, routeInformation);
}
