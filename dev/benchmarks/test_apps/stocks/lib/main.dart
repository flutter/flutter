// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show
  debugPaintSizeEnabled,
  debugPaintBaselinesEnabled,
  debugPaintLayerBordersEnabled,
  debugPaintPointersEnabled,
  debugRepaintRainbowEnabled;

import 'i18n/stock_strings.dart';

import 'stock_data.dart';
import 'stock_home.dart';
import 'stock_settings.dart';
import 'stock_state.dart';
import 'stock_symbol_viewer.dart';

void main() => runApp(
  StockStateScope(
    stocks: StockData(),
    child: const StocksApp()
  ),
);

const String _kSettingsPageLocation = '/settings';
const String _kStockPageLocation = '/stock';
const String _kHomePageLocation = '/';

class StocksApp extends StatefulWidget {
  const StocksApp({Key key}) : super(key: key);

  @override
  StocksAppState createState() => StocksAppState();
}

class StocksAppState extends State<StocksApp> {
  final StockRouteInformationParser _routeInformationParser = StockRouteInformationParser();
  StockRouterDelegate _routerDelegate;
  RouterState _routerState;
  
  @override
  void initState() {
    super.initState();
    _routerState = RouterState();
    _routerDelegate = StockRouterDelegate(_routerState);
  }

  ThemeData geThemeFromConfiguration(StockConfiguration configuration) {
    switch (configuration.stockMode) {
      case StockMode.optimistic:
        return ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.purple,
        );
      case StockMode.pessimistic:
        return ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.redAccent,
        );
    }
    assert(configuration.stockMode != null);
    return null;
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _routerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockConfiguration configuration = StockStateScope.configurationOf(context);
    assert(() {
      debugPaintSizeEnabled = configuration.debugShowSizes;
      debugPaintBaselinesEnabled = configuration.debugShowBaselines;
      debugPaintLayerBordersEnabled = configuration.debugShowLayers;
      debugPaintPointersEnabled = configuration.debugShowPointers;
      debugRepaintRainbowEnabled = configuration.debugShowRainbow;
      return true;
    }());
    return MaterialApp.router(
      title: 'Stocks',
      theme: geThemeFromConfiguration(configuration),
      localizationsDelegates: StockStrings.localizationsDelegates,
      supportedLocales: StockStrings.supportedLocales,
      debugShowMaterialGrid: configuration.debugShowGrid,
      showPerformanceOverlay: configuration.showPerformanceOverlay,
      showSemanticsDebugger: configuration.showSemanticsDebugger,
      routeInformationParser: _routeInformationParser,
      routerDelegate: _routerDelegate,
    );
  }
}

class StockRouteInformationParser extends RouteInformationParser<StockRoutePath> {
  @override
  Future<StockRoutePath> parseRouteInformation(RouteInformation routeInformation) {
    final Uri url = Uri.parse(routeInformation.location);
    if (url.path == _kSettingsPageLocation) {
      return SynchronousFuture<StockRoutePath>(const StockSettingsPath());
    }

    if (url.path == _kStockPageLocation) {
      final String symbol = url.queryParameters['symbol'];
      if (symbol != null && symbol.isNotEmpty)
        return SynchronousFuture<StockRoutePath>(StockSymbolPath(symbol));
    }

    return SynchronousFuture<StockRoutePath>(const StockHomePath());
  }

  @override
  RouteInformation restoreRouteInformation(StockRoutePath configuration) {
    if (configuration is StockSettingsPath)
      return const RouteInformation(location: _kSettingsPageLocation);
    if (configuration is StockHomePath)
      return const RouteInformation(location: _kHomePageLocation);
    if (configuration is StockSymbolPath)
      return RouteInformation(location: '$_kStockPageLocation?symbol=${configuration.symbol}');
    assert(false);
    return null;
  }
}

class StockRouterDelegate extends RouterDelegate<StockRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<StockRoutePath>{
  StockRouterDelegate(
    this.routerState
  ) : navigatorKey = GlobalObjectKey<NavigatorState>(routerState) {
    routerState.addListener(notifyListeners);
  }

  final RouterState routerState;

  @override
  final GlobalObjectKey<NavigatorState> navigatorKey;

  @override
  StockRoutePath get currentConfiguration => routerState.routePath;

  @override
  Future<void> setNewRoutePath(StockRoutePath configuration) {
    assert(configuration != null);
    routerState.routePath = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    // _handlePopPage should not be called on the home page because the
    // PopNavigatorRouterDelegateMixin will bubble up the pop to the
    // SystemNavigator if there is only one route in the navigator.
    assert(route.willHandlePopInternally ||
           routerState.routePath is StockSettingsPath ||
           routerState.routePath is StockSymbolPath);

    final bool success = route.didPop(result);
    if (success)
      routerState.routePath = const StockHomePath();
    return success;
  }

  List<Page<void>> _buildPages(BuildContext context) {
    final List<Page<void>> pages = <Page<void>>[
      StockHomePage()
    ];

    if (routerState.routePath is StockSettingsPath) {
      pages.add(StockSettingsPage());
    }

    if (routerState.routePath is StockSymbolPath) {
      final StockSymbolPath routePath = routerState.routePath as StockSymbolPath;
      pages.add(StockPage(routePath.symbol));
    }
    return pages;
  }

  @override
  void dispose() {
    routerState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(routerState.debugInitialized);
    return RouterStateScope(
      routerState: routerState,
      child: Navigator(
        key: navigatorKey,
        pages: _buildPages(context),
        onPopPage: _handlePopPage,
      ), 
    );
  }
}

