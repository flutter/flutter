// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/checkbox.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/dialog.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';

import 'stock_types.dart';

typedef void SettingsUpdater({StockMode mode});

class StockSettings extends Component {

  StockSettings(this.navigator, this.stockMode, this.updater) : super(stateful: true);

  Navigator navigator;
  StockMode stockMode;
  SettingsUpdater updater;
  bool showModeDialog = false;

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

  void _confirmStockModeChange() {
    switch (stockMode) {
      case StockMode.optimistic:
        _handleStockModeChanged(false);
        break;
      case StockMode.pessimistic:
        showModeDialog = true;
        navigator.pushState("/settings/confirm", (_) {
          showModeDialog = false;
        });
        break;
    }
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
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane() {
    return new Container(
      padding: const EdgeDims.symmetric(vertical: 20.0),
      decoration: new BoxDecoration(backgroundColor: colors.Grey[50]),
      child: new Block([
        new MenuItem(
          icon: 'action/thumb_up',
          onPressed: () => _confirmStockModeChange(),
          children: [
            new Flexible(child: new Text('Everything is awesome')),
            new Checkbox(value: stockMode == StockMode.optimistic, onChanged: _handleStockModeChanged)
          ]
        ),
      ])
    );
  }

  Widget build() {
    List<Widget> layers = [new Scaffold(
        toolbar: buildToolBar(),
        body: buildSettingsPane()
    )];
    if (showModeDialog) {
      layers.add(new Dialog(
        title: new Text("Change mode?"),
        content: new Text("Optimistic mode means everything is awesome. Are you sure you can handle that?"),
        onDismiss: navigator.pop,
        actions: [
          new FlatButton(
            child: new Text('NO THANKS'),
            onPressed: navigator.pop
          ),
          new FlatButton(
            child: new Text('AGREE'),
            onPressed: () {
              _handleStockModeChanged(true);
              navigator.pop();
            }
          ),
        ]
      ));
    }
    return new Stack(layers);
  }
}
