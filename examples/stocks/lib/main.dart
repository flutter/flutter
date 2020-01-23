// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

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
import 'stock_symbol_viewer.dart';
import 'stock_types.dart';

class StocksApp extends StatefulWidget {
  @override
  StocksAppState createState() => StocksAppState();
}

class StocksAppState extends State<StocksApp> {
  StockData stocks;

  StockConfiguration _configuration = StockConfiguration(
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
    stocks = StockData();
  }

  void configurationUpdater(StockConfiguration value) {
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

  Route<dynamic> _getRoute(RouteSettings settings) {
    if (settings.name == '/stock') {
      final String symbol = settings.arguments as String;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => StockSymbolPage(symbol: symbol, stocks: stocks),
      );
    }
    // The other paths we support are in the routes table.
    return null;
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
    return MaterialApp(
      title: 'Stocks',
      theme: theme,
      localizationsDelegates: StockStrings.localizationsDelegates,
      supportedLocales: StockStrings.supportedLocales,
      debugShowMaterialGrid: _configuration.debugShowGrid,
      showPerformanceOverlay: _configuration.showPerformanceOverlay,
      showSemanticsDebugger: _configuration.showSemanticsDebugger,
      routes: <String, WidgetBuilder>{
         '/':         (BuildContext context) => StockHome(stocks, _configuration, configurationUpdater),
         '/settings': (BuildContext context) => StockSettings(_configuration, configurationUpdater),
      },
      onGenerateRoute: _getRoute,
    );
  }
}

void main() {
  runApp(StocksApp());
}
