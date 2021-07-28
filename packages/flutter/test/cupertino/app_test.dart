// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Heroes work', (WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(
      home: ListView(children: <Widget>[
        const Hero(tag: 'a', child: Text('foo')),
        Builder(builder: (BuildContext context) {
          return CupertinoButton(
            child: const Text('next'),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute<void>(builder: (BuildContext context) {
                  return const Hero(tag: 'a', child: Text('foo'));
                }),
              );
            },
          );
        }),
      ]),
    ));

    await tester.tap(find.text('next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // During the hero transition, the hero widget is lifted off of both
    // page routes and exists as its own overlay on top of both routes.
    expect(find.widgetWithText(CupertinoPageRoute, 'foo'), findsNothing);
    expect(find.widgetWithText(Navigator, 'foo'), findsOneWidget);
  });

  testWidgets('Has default cupertino localizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                Text(CupertinoLocalizations.of(context).selectAllButtonLabel),
                Text(CupertinoLocalizations.of(context).datePickerMediumDate(
                  DateTime(2018, 10, 4),
                )),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Thu Oct 4 '), findsOneWidget);
  });

  testWidgets('Can use dynamic color', (WidgetTester tester) async {
    const CupertinoDynamicColor dynamicColor = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF000000),
      darkColor: Color(0xFF000001),
    );
    await tester.pumpWidget(const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      color: dynamicColor,
      home: Placeholder(),
    ));

    expect(tester.widget<Title>(find.byType(Title)).color.value, 0xFF000000);

    await tester.pumpWidget(const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.dark),
      color: dynamicColor,
      home: Placeholder(),
    ));

    expect(tester.widget<Title>(find.byType(Title)).color.value, 0xFF000001);
  });

  testWidgets('Can customize initial routes', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigatorKey,
        onGenerateInitialRoutes: (String initialRoute) {
          expect(initialRoute, '/abc');
          return <Route<void>>[
            PageRouteBuilder<void>(
              pageBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return const Text('non-regular page one');
              },
            ),
            PageRouteBuilder<void>(
              pageBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return const Text('non-regular page two');
              },
            ),
          ];
        },
        initialRoute: '/abc',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Text('regular page one'),
          '/abc': (BuildContext context) => const Text('regular page two'),
        },
      ),
    );
    expect(find.text('non-regular page two'), findsOneWidget);
    expect(find.text('non-regular page one'), findsNothing);
    expect(find.text('regular page one'), findsNothing);
    expect(find.text('regular page two'), findsNothing);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('non-regular page two'), findsNothing);
    expect(find.text('non-regular page one'), findsOneWidget);
    expect(find.text('regular page one'), findsNothing);
    expect(find.text('regular page two'), findsNothing);
  });

  testWidgets('CupertinoApp.navigatorKey can be updated', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key1 = GlobalKey<NavigatorState>();
    await tester.pumpWidget(CupertinoApp(
      navigatorKey: key1,
      home: const Placeholder(),
    ));
    expect(key1.currentState, isA<NavigatorState>());
    final GlobalKey<NavigatorState> key2 = GlobalKey<NavigatorState>();
    await tester.pumpWidget(CupertinoApp(
      navigatorKey: key2,
      home: const Placeholder(),
    ));
    expect(key2.currentState, isA<NavigatorState>());
    expect(key1.currentState, isNull);
  });

  testWidgets('CupertinoApp.router works', (WidgetTester tester) async {
    final PlatformRouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      },
      onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
        delegate.routeInformation = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    await tester.pumpWidget(CupertinoApp.router(
      routeInformationProvider: provider,
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Simulate android back button intent.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('CupertinoApp has correct default ScrollBehavior', (WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const Placeholder();
          },
        ),
      ),
    );
    expect(ScrollConfiguration.of(capturedContext).runtimeType, CupertinoScrollBehavior);
  });

  testWidgets('A ScrollBehavior can be set for CupertinoApp', (WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      CupertinoApp(
        scrollBehavior: const MockScrollBehavior(),
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const Placeholder();
          },
        ),
      ),
    );
    final ScrollBehavior scrollBehavior = ScrollConfiguration.of(capturedContext);
    expect(scrollBehavior.runtimeType, MockScrollBehavior);
    expect(scrollBehavior.getScrollPhysics(capturedContext).runtimeType, NeverScrollableScrollPhysics);
  });

  testWidgets('When `useInheritedMediaQuery` is true an existing MediaQuery is used if one is available', (WidgetTester tester) async {
    late BuildContext capturedContext;
    final UniqueKey uniqueKey = UniqueKey();
    await tester.pumpWidget(
      MediaQuery(
        key: uniqueKey,
        data: const MediaQueryData(),
        child: CupertinoApp(
          useInheritedMediaQuery: true,
          builder: (BuildContext context, Widget? child) {
            capturedContext = context;
            return const Placeholder();
          },
          color: const Color(0xFF123456),
        ),
      ),
    );
    expect(capturedContext.dependOnInheritedWidgetOfExactType<MediaQuery>()?.key, uniqueKey);
  });
}

class MockScrollBehavior extends ScrollBehavior {
  const MockScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const NeverScrollableScrollPhysics();
}

typedef SimpleRouterDelegateBuilder = Widget Function(BuildContext, RouteInformation);
typedef SimpleNavigatorRouterDelegatePopPage<T> = bool Function(Route<T> route, T result, SimpleNavigatorRouterDelegate delegate);

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

class SimpleNavigatorRouterDelegate extends RouterDelegate<RouteInformation> with PopNavigatorRouterDelegateMixin<RouteInformation>, ChangeNotifier {
  SimpleNavigatorRouterDelegate({
    required this.builder,
    this.onPopPage,
  });

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RouteInformation get routeInformation => _routeInformation;
  late RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleNavigatorRouterDelegatePopPage<void>? onPopPage;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<void> route, void data) {
    return onPopPage!(route, data, this);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        // We need at least two pages for the pop to propagate through.
        // Otherwise, the navigator will bubble the pop to the system navigator.
        const CupertinoPage<void>(
          child:  Text('base'),
        ),
        CupertinoPage<void>(
          key: ValueKey<String?>(routeInformation.location),
          child: builder(context, routeInformation),
        ),
      ],
    );
  }
}
