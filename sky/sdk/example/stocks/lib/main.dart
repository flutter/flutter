// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library stocks;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/mojo/net/fetch.dart';
import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/editing/input.dart';
import 'package:sky/widgets/drawer.dart';
import 'package:sky/widgets/drawer_divider.dart';
import 'package:sky/widgets/drawer_header.dart';
import 'package:sky/widgets/drawer_item.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/focus.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/modal_overlay.dart';
import 'package:sky/widgets/popup_menu.dart';
import 'package:sky/widgets/radio.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tabs.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/scrollable_list.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/checkbox.dart';
import 'package:sky/widgets/popup_menu_item.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/dialog.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/scrollable_viewport.dart';
import 'package:sky/widgets/switch.dart';

//TODO(jimsimon): Is this needed?
export 'package:sky/widgets/popup_menu.dart' show PopupMenuStatus;

part 'stock_arrow.dart';
part 'stock_data.dart';
part 'stock_home.dart';
part 'stock_list.dart';
part 'stock_menu.dart';
part 'stock_row.dart';
part 'stock_settings.dart';
part 'stock_types.dart';

class StocksApp extends App {

  NavigationState _navigationState;

  void initState() {
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
    super.initState();
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
