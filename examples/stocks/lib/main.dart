// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

import 'stock_data.dart';
import 'i18n/stock_messages_all.dart';

part 'stock_arrow.dart';
part 'stock_home.dart';
part 'stock_list.dart';
part 'stock_menu.dart';
part 'stock_row.dart';
part 'stock_settings.dart';
part 'stock_strings.dart';
part 'stock_symbol_viewer.dart';
part 'stock_types.dart';

class StocksApp extends StatefulComponent {
  StocksAppState createState() => new StocksAppState();
}

class StocksAppState extends State<StocksApp> {

  final Map<String, Stock> _stocks = <String, Stock>{};
  final List<String> _symbols = <String>[];

  StockConfiguration _configuration = new StockConfiguration(
    stockMode: StockMode.optimistic,
    backupMode: BackupMode.enabled,
    showGrid: false
  );

  void initState() {
    super.initState();
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks, _symbols);
      });
    });
  }

  void configurationUpdater(StockConfiguration value) {
    setState(() {
      _configuration = value;
    });
  }

  ThemeData get theme {
    switch (_configuration.stockMode) {
      case StockMode.optimistic:
        return new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: Colors.purple
        );
      case StockMode.pessimistic:
        return new ThemeData(
          brightness: ThemeBrightness.dark,
          accentColor: Colors.redAccent[200]
        );
    }
  }

  Route _getRoute(RouteSettings settings) {
    List<String> path = settings.name.split('/');
    if (path[0] != '')
      return null;
    if (path[1] == 'stock') {
      if (path.length != 3)
        return null;
      if (_stocks.containsKey(path[2])) {
        return new MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) => new StockSymbolPage(stock: _stocks[path[2]])
        );
      }
    }
    return null;
  }

  Future<LocaleQueryData> _onLocaleChanged(ui.Locale locale) async {
    String localeString = locale.toString();
    await initializeMessages(localeString);
    Intl.defaultLocale = localeString;
    return StockStrings.instance;
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Stocks',
      theme: theme,
      debugShowMaterialGrid: _configuration.showGrid,
      routes: <String, RouteBuilder>{
         '/':         (RouteArguments args) => new StockHome(_stocks, _symbols, _configuration, configurationUpdater),
         '/settings': (RouteArguments args) => new StockSettings(_configuration, configurationUpdater)
      },
      onGenerateRoute: _getRoute,
      onLocaleChanged: _onLocaleChanged
    );
  }
}

void main() {
  runApp(new StocksApp());
}
