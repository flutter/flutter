// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/checkbox.dart';
import 'package:sky/widgets/switch.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/dialog.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';

import 'stock_types.dart';

typedef void SettingsUpdater({
  StockMode optimism,
  BackupMode backup
});

class StockSettings extends Component {

  StockSettings(this.navigator, this.optimism, this.backup, this.updater) : super(stateful: true);

  Navigator navigator;
  StockMode optimism;
  BackupMode backup;
  SettingsUpdater updater;

  bool showModeDialog = false;

  void syncFields(StockSettings source) {
    navigator = source.navigator;
    optimism = source.optimism;
    backup = source.backup;
    updater = source.updater;
  }

  void _handleOptimismChanged(bool value) {
    setState(() {
      optimism = value ? StockMode.optimistic : StockMode.pessimistic;
    });
    sendUpdates();
  }

  void _handleBackupChanged(bool value) {
    setState(() {
      backup = value ? BackupMode.enabled : BackupMode.disabled;
    });
    sendUpdates();
  }

  void _confirmOptimismChange() {
    switch (optimism) {
      case StockMode.optimistic:
        _handleOptimismChanged(false);
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
        optimism: optimism,
        backup: backup
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
    // TODO(ianh): Once we have the gesture API hooked up, fix https://github.com/domokit/mojo/issues/281
    // (whereby tapping the widgets below causes both the widget and the menu item to fire their callbacks)
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 20.0),
        child: new Block([
          new MenuItem(
            icon: 'action/thumb_up',
            onPressed: () => _confirmOptimismChange(),
            children: [
              new Flexible(child: new Text('Everything is awesome')),
              new Checkbox(value: optimism == StockMode.optimistic, onChanged: _handleOptimismChanged)
            ]
          ),
          new MenuItem(
            icon: 'action/backup',
            onPressed: () { _handleBackupChanged(!(backup == BackupMode.enabled)); },
            children: [
              new Flexible(child: new Text('Back up stock list to the cloud')),
              new Switch(value: backup == BackupMode.enabled, onChanged: _handleBackupChanged)
            ]
          ),
        ])
      )
    );
  }

  Widget build() {
    List<Widget> layers = [
      new Scaffold(
        toolbar: buildToolBar(),
        body: buildSettingsPane()
      )
    ];
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
              _handleOptimismChanged(true);
              navigator.pop();
            }
          ),
        ]
      ));
    }
    return new Stack(layers);
  }
}
