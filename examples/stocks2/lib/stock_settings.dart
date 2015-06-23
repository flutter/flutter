// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/checkbox.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';

import 'stock_types.dart';

typedef void SettingsUpdater({StockMode mode});

class StockSettings extends Component {

  StockSettings(this.navigator, this.stockMode, this.updater) : super(stateful: true);

  Navigator navigator;
  StockMode stockMode;
  SettingsUpdater updater;

  void syncFields(StockSettings source) {
    navigator = source.navigator;
    stockMode = source.stockMode;
    updater = source.updater;
  }

  void _handleStockModeChanged(bool value) {
    setState(() {
      stockMode = value ? StockMode.optimistic : StockMode.pessimistic;
    });
    sendUpdates();
  }

  void sendUpdates() {
    if (updater != null)
      updater(
        mode: stockMode
      );
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back_white',
        onPressed: navigator.pop),
      center: new Text('Settings', style: Theme.of(this).text.title)
    );
  }

  Widget buildSettingsPane() {
    return new Container(
      padding: const EdgeDims.symmetric(vertical: 20.0),
      decoration: new BoxDecoration(backgroundColor: colors.Grey[50]),
      child: new Block([
        new MenuItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleStockModeChanged(stockMode == StockMode.optimistic ? false : true),
          children: [
            new Flexible(child: new Text('Everything is awesome')),
            new Checkbox(value: stockMode == StockMode.optimistic, onChanged: _handleStockModeChanged)
          ]
        ),
      ])
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildSettingsPane()
    );
  }
}
