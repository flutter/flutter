// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

typedef void SettingsUpdater({
  BackupMode backup
});

class SettingsFragment extends Component {

  SettingsFragment(this.navigator, this.backup, this.updater);

  final Navigator navigator;
  final BackupMode backup;
  final SettingsUpdater updater;

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
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.symmetric(vertical: 20.0),
          child: new Block([
            new DrawerItem(
              onPressed: () { _handleBackupChanged(!(backup == BackupMode.enabled)); },
              children: [
                new Flexible(child: new Text('Back up data to the cloud')),
                new Switch(value: backup == BackupMode.enabled, onChanged: _handleBackupChanged)
              ]
            )
          ])
        )
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
