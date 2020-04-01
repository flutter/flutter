// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

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
import 'stock_types.dart';

class StocksApp extends StatefulWidget {
  const StocksApp({Key key}) : super(key: key);

  @override
  StocksAppState createState() => StocksAppState();
}

class StocksAppState extends State<StocksApp> {

  final StockState _state = StockState(StockData());
  final StockRouteNameParser _routeNameParser = StockRouteNameParser();
  StockRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();
    _routerDelegate = StockRouterDelegate(_state);

  }

  ThemeData _getThemeFromConfiguration(StockConfiguration configuration) {
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
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    final StockConfiguration configuration = StockConfigurationProvider.of(context);
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
      theme: _getThemeFromConfiguration(configuration),
      localizationsDelegates: StockStrings.localizationsDelegates,
      supportedLocales: StockStrings.supportedLocales,
      debugShowMaterialGrid: configuration.debugShowGrid,
      showPerformanceOverlay: configuration.showPerformanceOverlay,
      showSemanticsDebugger: configuration.showSemanticsDebugger,
      routeNameParser: _routeNameParser,
      routerDelegate: _routerDelegate,
    );
  }
}

class StockRouteNameParser extends RouteNameParser<StockRoutePath> {
  @override
  Future<StockRoutePath> parse(String routeName) {
    final List<String> segments = routeName.split('?');
    final String path = segments[0];
    final String query = segments.length > 1 ? segments[1] : '';
    final Uri syntheticUrl = Uri(path: path, query: query);
    if (syntheticUrl.path == '/settings') {
      return SynchronousFuture<StockRoutePath>(const StockSettingsPath());
    } else {
      if (syntheticUrl.path == '/stock') {
        final String symbol = syntheticUrl.queryParameters['symbol'];
        if (symbol != null && symbol.isNotEmpty)
          return SynchronousFuture<StockRoutePath>(StockSymbolPath(symbol));
      }
      return SynchronousFuture<StockRoutePath>(const StockHomePath());
    }
  }

  @override
  String restore(StockRoutePath configuration) {
    if (configuration is StockSettingsPath)
      return '/settings';
    if (configuration is StockHomePath)
      return '/';
    if (configuration is StockSymbolPath)
      return '/stock?symbol=${configuration.symbol}';
    return null;
  }
}

class StockRouterDelegate extends RouterDelegate<StockRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<StockRoutePath>{
  StockRouterDelegate(
    this.stockState
  ) : navigatorKey = GlobalObjectKey<NavigatorState>(stockState) {
    stockState.addListener(notifyListeners);
  }
  StockState stockState;

  final HeroController _heroController = MaterialApp.createMaterialHeroController();

  @override
  final GlobalObjectKey<NavigatorState> navigatorKey;

  @override
  StockRoutePath get currentConfiguration => stockState.routePath;

  @override
  Future<void> setNewRoutePath(StockRoutePath configuration) {
    assert(configuration != null);
    stockState.routePath = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    final bool success = route.didPop(result);
    if (success) {
      final Page<void> page = route.settings as Page<void>;
      if (page is StockSettingsPage || page is StockPage)
        stockState.routePath = const StockHomePath();
    }
    return success;
  }

  List<Page<void>> _buildPages(BuildContext context) {
    final StockConfiguration configuration = StockConfigurationProvider.of(context);
    final List<Page<void>> pages = <Page<void>>[
      StockHomePage(configuration)
    ];

    if (stockState.routePath is StockSettingsPath) {
      pages.add(StockSettingsPage(configuration));
    }

    if (stockState.routePath is StockSymbolPath) {
      final StockSymbolPath routePath = stockState.routePath as StockSymbolPath;
      pages.add(StockPage(routePath.symbol));
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    assert(stockState.debugInitialized);
    return StockStateProvider(
      state: stockState,
      child: Navigator(
        key: navigatorKey,
        pages: _buildPages(context),
        // Enables the material style hero animation.
        observers: <NavigatorObserver>[_heroController],
        transitionDelegate: const DefaultTransitionDelegate<void>(),
        onPopPage: _handlePopPage,
      ),
    );
  }
}

void main() {
  runApp(
    StockConfigurationProvider(
      configuration: StockConfiguration(
        stockMode: StockMode.optimistic,
        backupMode: BackupMode.enabled,
        debugShowGrid: false,
        debugShowSizes: false,
        debugShowBaselines: false,
        debugShowLayers: false,
        debugShowPointers: false,
        debugShowRainbow: false,
        showPerformanceOverlay: false,
        showSemanticsDebugger: false,
      ),
      child: const StocksApp(),
    )
  );
}
