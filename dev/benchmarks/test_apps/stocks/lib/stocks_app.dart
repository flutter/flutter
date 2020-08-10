// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

const String _kSettingsPageLocation = '/settings';
const String _kStockPageLocation = '/stock';
const String _kHomePageLocation = '/';

class StocksApp extends StatefulWidget {
  const StocksApp({Key key}) : super(key: key);

  static StockConfiguration configurationOf(BuildContext context) {
    final _StockConfigurationScope scope = context.dependOnInheritedWidgetOfExactType<_StockConfigurationScope>();
    return scope.state._configuration;
  }

  static void updateConfigurationOf(BuildContext context, StockConfiguration configuration) {
    final _StockConfigurationScope scope = context
      .getElementForInheritedWidgetOfExactType<_StockConfigurationScope>()
      .widget as _StockConfigurationScope;
    return scope.state._configurationUpdater(configuration);
  }

  @override
  StocksAppState createState() => StocksAppState();
}

class StocksAppState extends State<StocksApp> {

  final StockState _state = StockState(StockData());
  final StockRouteInformationParser _routeInformationParser = StockRouteInformationParser();
  StockRouterDelegate _routerDelegate;

  StockConfiguration _configuration = const StockConfiguration(
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
  );

  @override
  void initState() {
    super.initState();
    _routerDelegate = StockRouterDelegate(_state);
  }

  void _configurationUpdater(StockConfiguration value) {
    setState(() {
      _configuration = value;
    });
  }

  ThemeData get theme {
    switch (_configuration.stockMode) {
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
    assert(_configuration.stockMode != null);
    return null;
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPaintSizeEnabled = _configuration.debugShowSizes;
      debugPaintBaselinesEnabled = _configuration.debugShowBaselines;
      debugPaintLayerBordersEnabled = _configuration.debugShowLayers;
      debugPaintPointersEnabled = _configuration.debugShowPointers;
      debugRepaintRainbowEnabled = _configuration.debugShowRainbow;
      return true;
    }());
    return _StockConfigurationScope(
      configuration: _configuration,
      state: this,
      child: MaterialApp.router(
        title: 'Stocks',
        theme: theme,
        localizationsDelegates: StockStrings.localizationsDelegates,
        supportedLocales: StockStrings.supportedLocales,
        debugShowMaterialGrid: _configuration.debugShowGrid,
        showPerformanceOverlay: _configuration.showPerformanceOverlay,
        showSemanticsDebugger: _configuration.showSemanticsDebugger,
        routeInformationParser: _routeInformationParser,
        routerDelegate: _routerDelegate,
      )
    );
  }
}

class _StockConfigurationScope extends InheritedWidget{
  const _StockConfigurationScope({
    Key key,
    this.state,
    this.configuration,
    Widget child,
  }) : super(key: key, child: child);

  final StockConfiguration configuration;
  final StocksAppState state;

  @override
  bool updateShouldNotify(_StockConfigurationScope oldWidget) {
    return oldWidget.configuration != configuration;
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
  }
}

class StockRouterDelegate extends RouterDelegate<StockRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<StockRoutePath>{
  StockRouterDelegate(
    this.stockState
  ) : navigatorKey = GlobalObjectKey<NavigatorState>(stockState) {
    stockState.addListener(notifyListeners);
  }

  StockState stockState;

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
    // _handlePopPage should not be called on the home page because the
    // PopNavigatorRouterDelegateMixin will bubble up the pop to the
    // SystemNavigator if there is only one route in the navigator.
    assert(route.willHandlePopInternally ||
           stockState.routePath is StockSettingsPath ||
           stockState.routePath is StockSymbolPath);

    final bool success = route.didPop(result);
    if (success)
      stockState.routePath = const StockHomePath();
    return success;
  }

  List<Page<void>> _buildPages(BuildContext context) {
    final StockConfiguration configuration = StocksApp.configurationOf(context);
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
    return StockStateScope(
      state: stockState,
      child: Navigator(
        key: navigatorKey,
        pages: _buildPages(context),
        onPopPage: _handlePopPage,
      ),
    );
  }
}
