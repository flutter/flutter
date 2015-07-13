// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/drawer_item.dart';
import 'package:sky/widgets/switch.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/theme.dart';

import 'fitness_types.dart';

typedef void SettingsUpdater({
  BackupMode backup
});

class SettingsFragment extends Component {

  SettingsFragment(this.navigator, this.backup, this.updater);

  final Navigator navigator;
  final BackupMode backup;
  final SettingsUpdater updater;

  bool showModeDialog = false;

  void _handleBackupChanged(bool value) {
    if (updater != null)
      updater(backup: value ? BackupMode.enabled : BackupMode.disabled);
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/arrow_back",
        onPressed: navigator.pop),
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane() {
    return new Material(
      type: MaterialType.canvas,
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 20.0),
        child: new Block([
          new DrawerItem(
            onPressed: () { _handleBackupChanged(!(backup == BackupMode.enabled)); },
            children: [
              new Flexible(child: new Text('Back up data to the cloud')),
              new Switch(value: backup == BackupMode.enabled, onChanged: _handleBackupChanged)
            ]
          ),
          new DrawerItem(
            children: [
              new Block([
                new Text('Height'),
                new Text("6'2\"", style: Theme.of(this).text.caption),
              ])
            ]
          ),
        ])
      )
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildSettingsPane()
    );
  }
}
