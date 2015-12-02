// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import 'stock_data.dart';

part 'stock_arrow.dart';
part 'stock_home.dart';
part 'stock_list.dart';
part 'stock_menu.dart';
part 'stock_row.dart';
part 'stock_settings.dart';
part 'stock_symbol_viewer.dart';
part 'stock_types.dart';

class StocksApp extends StatefulComponent {
  StocksAppState createState() => new StocksAppState();
}

class StocksAppState extends State<StocksApp> {

  final Map<String, Stock> _stocks = <String, Stock>{};
  final List<String> _symbols = <String>[];

  void initState() {
    super.initState();
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks, _symbols);
      });
    });
  }

  StockMode _optimismSetting = StockMode.optimistic;
  BackupMode _backupSetting = BackupMode.disabled;
  void modeUpdater(StockMode optimism) {
    setState(() {
      _optimismSetting = optimism;
    });
  }
  void settingsUpdater({ StockMode optimism, BackupMode backup }) {
    setState(() {
      if (optimism != null)
        _optimismSetting = optimism;
      if (backup != null)
        _backupSetting = backup;
    });
  }

  ThemeData get theme {
    switch (_optimismSetting) {
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

  RouteBuilder _getRoute(String name) {
    List<String> path = name.split('/');
    if (path[0] != '')
      return null;
    if (path[1] == 'stock') {
      if (path.length != 3)
        return null;
      if (_stocks.containsKey(path[2]))
        return (RouteArguments args) => new StockSymbolPage(stock: _stocks[path[2]]);
      return null;
    }
    return null;
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Stocks',
      theme: theme,
      routes: <String, RouteBuilder>{
         '/':         (RouteArguments args) => new StockHome(_stocks, _symbols, _optimismSetting, modeUpdater),
         '/settings': (RouteArguments args) => new StockSettings(_optimismSetting, _backupSetting, settingsUpdater)
      },
      onGenerateRoute: _getRoute
    );
  }
}

void main() {
  runApp(new StocksApp());
}
