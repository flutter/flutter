// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void SettingsUpdater({
  StockMode optimism,
  BackupMode backup
});

class StockSettings extends StatefulComponent {

  StockSettings(this.navigator, this.optimism, this.backup, this.updater);

  Navigator navigator;
  StockMode optimism;
  BackupMode backup;
  SettingsUpdater updater;

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
        showDialog(navigator, (navigator) {
          return new Dialog(
            title: new Text("Change mode?"),
            content: new Text("Optimistic mode means everything is awesome. Are you sure you can handle that?"),
            onDismiss: () {
              navigator.pop(false);
            },
            actions: [
              new FlatButton(
                child: new Text('NO THANKS'),
                onPressed: () {
                  navigator.pop(false);
                }
              ),
              new FlatButton(
                child: new Text('AGREE'),
                onPressed: () {
                  navigator.pop(true);
                }
              ),
            ]
          );
        }).then(_handleOptimismChanged);
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
        icon: 'navigation/arrow_back',
        onPressed: navigator.pop),
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane() {
    // TODO(ianh): Once we have the gesture API hooked up, fix https://github.com/domokit/mojo/issues/281
    // (whereby tapping the widgets below causes both the widget and the menu item to fire their callbacks)
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.symmetric(vertical: 20.0),
          child: new Block([
            new DrawerItem(
              icon: 'action/thumb_up',
              onPressed: () => _confirmOptimismChange(),
              children: [
                new Flexible(child: new Text('Everything is awesome')),
                new Checkbox(value: optimism == StockMode.optimistic, onChanged: _handleOptimismChanged)
              ]
            ),
            new DrawerItem(
              icon: 'action/backup',
              onPressed: () { _handleBackupChanged(!(backup == BackupMode.enabled)); },
              children: [
                new Flexible(child: new Text('Back up stock list to the cloud')),
                new Switch(value: backup == BackupMode.enabled, onChanged: _handleBackupChanged)
              ]
            ),
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
