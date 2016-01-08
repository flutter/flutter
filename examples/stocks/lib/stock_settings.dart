// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void SettingsUpdater({
  StockMode optimism,
  BackupMode backup,
  bool showGrid
});

class StockSettings extends StatefulComponent {
  const StockSettings(this.optimism, this.backup, this.showGrid, this.updater);

  final StockMode optimism;
  final BackupMode backup;
  final SettingsUpdater updater;
  final bool showGrid;

  StockSettingsState createState() => new StockSettingsState();
}

class StockSettingsState extends State<StockSettings> {
  void _handleOptimismChanged(bool value) {
    value ??= false;
    sendUpdates(value ? StockMode.optimistic : StockMode.pessimistic, config.backup, config.showGrid);
  }

  void _handleBackupChanged(bool value) {
    sendUpdates(config.optimism, value ? BackupMode.enabled : BackupMode.disabled, config.showGrid);
  }

  void _handleShowGridChanged(bool value) {
    sendUpdates(config.optimism, config.backup, value);
  }

  void _confirmOptimismChange() {
    switch (config.optimism) {
      case StockMode.optimistic:
        _handleOptimismChanged(false);
        break;
      case StockMode.pessimistic:
        showDialog(
          context: context,
          child: new Dialog(
            title: new Text("Change mode?"),
            content: new Text("Optimistic mode means everything is awesome. Are you sure you can handle that?"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('NO THANKS'),
                onPressed: () {
                  Navigator.pop(context, false);
                }
              ),
              new FlatButton(
                child: new Text('AGREE'),
                onPressed: () {
                  Navigator.pop(context, true);
                }
              ),
            ]
          )
        ).then(_handleOptimismChanged);
        break;
    }
  }

  void sendUpdates(StockMode optimism, BackupMode backup, bool showGrid) {
    if (config.updater != null)
      config.updater(
        optimism: optimism,
        backup: backup,
        showGrid: showGrid
      );
  }

  Widget buildToolBar(BuildContext context) {
    return new ToolBar(
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane(BuildContext context) {
    // TODO(ianh): Once we have the gesture API hooked up, fix https://github.com/domokit/mojo/issues/281
    // (whereby tapping the widgets below causes both the widget and the menu item to fire their callbacks)
    List<Widget> rows = <Widget>[
      new DrawerItem(
        icon: 'action/thumb_up',
        onPressed: () => _confirmOptimismChange(),
        child: new Row(<Widget>[
          new Flexible(child: new Text('Everything is awesome')),
          new Checkbox(
            value: config.optimism == StockMode.optimistic,
            onChanged: (bool value) => _confirmOptimismChange()
          ),
        ])
      ),
      new DrawerItem(
        icon: 'action/backup',
        onPressed: () { _handleBackupChanged(!(config.backup == BackupMode.enabled)); },
        child: new Row(<Widget>[
          new Flexible(child: new Text('Back up stock list to the cloud')),
          new Switch(
            value: config.backup == BackupMode.enabled,
            onChanged: _handleBackupChanged
          ),
        ])
      ),
    ];
    assert(() {
      // material grid is only available in checked mode
      rows.add(
        new DrawerItem(
          icon: 'editor/border_clear',
          onPressed: () { _handleShowGridChanged(!config.showGrid); },
          child: new Row(<Widget>[
            new Flexible(child: new Text('Show material grid (for debugging)')),
            new Switch(
              value: config.showGrid,
              onChanged: _handleShowGridChanged
            ),
          ])
        )
      );
      return true;
    });
    return new Block(
      rows,
      padding: const EdgeDims.symmetric(vertical: 20.0)
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(context),
      body: buildSettingsPane(context)
    );
  }
}
