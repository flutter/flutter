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
import 'routing/router.dart';
import 'routing/router_state.dart';
import 'stock_state.dart';

void main() => runApp(
  const StockStateScope(
    child: StocksApp()
  ),
);

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

  ThemeData _geThemeFromConfiguration(StockConfiguration configuration) {
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
      theme: _geThemeFromConfiguration(configuration),
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
