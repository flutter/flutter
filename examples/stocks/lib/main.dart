// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/animation.dart';
import 'package:sky/gestures.dart';
import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/src/fn3.dart';

import 'stock_data.dart';

part 'stock_arrow.dart';
part 'stock_home.dart';
part 'stock_list.dart';
part 'stock_menu.dart';
part 'stock_row.dart';
part 'stock_settings.dart';
part 'stock_types.dart';

class StocksApp extends StatefulComponent {
  StocksAppState createState() => new StocksAppState();
}

class StocksAppState extends State<StocksApp> {

  final List<Stock> _stocks = [];

  void initState(BuildContext context) {
    super.initState(context);
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks);
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

  Widget build(BuildContext context) {
    return new App(
      title: 'Stocks',
      theme: theme,
      routes: <String, RouteBuilder>{
         '/':         (navigator, route) => new StockHome(navigator, _stocks, _optimismSetting, modeUpdater),
         '/settings': (navigator, route) => new StockSettings(navigator, _optimismSetting, _backupSetting, settingsUpdater)
      }
    );
  }
}

void main() {
  runApp(new StocksApp());
}
