// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

import 'stock_data.dart';
import 'stock_home.dart';
import 'stock_settings.dart';
import 'stock_types.dart';

class StocksApp extends App {

  NavigationState _navigationState;
  StocksApp() {
    _navigationState = new NavigationState([
      new Route(
        name: '/', 
        builder: (navigator, route) => new StockHome(navigator, _stocks, stockMode, modeUpdater)
      ),
      new Route(
        name: '/settings',
        builder: (navigator, route) => new StockSettings(navigator, stockMode, settingsUpdater)
      ),
    ]);
  }

  void onBack() {
    setState(() {
      _navigationState.pop();
    });
    // TODO(jackson): Need a way to invoke default back behavior here
  }

  StockMode stockMode = StockMode.optimistic;
  void modeUpdater(StockMode value) {
    setState(() {
      stockMode = value;
    });
  }
  void settingsUpdater({StockMode mode}) {
    setState(() {
      if (mode != null)
        stockMode = mode;
    });
  }

  final List<Stock> _stocks = [];
  void didMount() {
    super.didMount();
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks);
      });
    });
  }

  Widget build() {

    ThemeData theme;
    if (stockMode == StockMode.optimistic) {
      theme = new ThemeData.light(
        primary: colors.Purple,
        accent: colors.RedAccent,
        darkToolbar: true
      );
    } else {
      theme = new ThemeData.dark(
        primary: colors.Red,
        accent: colors.PurpleAccent
      );
    }

    return new Theme(
      data: theme,
        child: new Navigator(_navigationState)
     );
   }
}

void main() {
  runApp(new StocksApp());
}
