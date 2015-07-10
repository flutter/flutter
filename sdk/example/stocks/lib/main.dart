// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';

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
        builder: (navigator, route) => new StockHome(navigator, _stocks, optimismSetting, modeUpdater)
      ),
      new Route(
        name: '/settings',
        builder: (navigator, route) => new StockSettings(navigator, optimismSetting, backupSetting, settingsUpdater)
      ),
    ]);
  }

  void onBack() {
    if (_navigationState.hasPrevious()) {
      setState(() {
        _navigationState.pop();
      });
    } else {
      super.onBack();
    }
  }

  StockMode optimismSetting = StockMode.optimistic;
  BackupMode backupSetting = BackupMode.disabled;
  void modeUpdater(StockMode optimism) {
    setState(() {
      optimismSetting = optimism;
    });
  }
  void settingsUpdater({ StockMode optimism, BackupMode backup }) {
    setState(() {
      if (optimism != null)
        optimismSetting = optimism;
      if (backup != null)
        backupSetting = backup;
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
    if (optimismSetting == StockMode.optimistic) {
      theme = new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: colors.Purple
      );
    } else {
      theme = new ThemeData(
        brightness: ThemeBrightness.dark,
        accentColor: colors.RedAccent[200]
      );
    }

    return new Theme(
      data: theme,
        child: new DefaultTextStyle(
          style: typography.error, // if you see this, you've forgotten to correctly configure the text style!
          child: new TaskDescription(
            label: 'Stocks',
            child: new Navigator(_navigationState)
          )
        )
     );
   }
}

void main() {
  runApp(new StocksApp());
}
