// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockSettings extends StatefulComponent {
  const StockSettings(this.configuration, this.updater);

  final StockConfiguration configuration;
  final ValueChanged<StockConfiguration> updater;

  StockSettingsState createState() => new StockSettingsState();
}

class StockSettingsState extends State<StockSettings> {
  void _handleOptimismChanged(bool value) {
    value ??= false;
    sendUpdates(config.configuration.copyWith(stockMode: value ? StockMode.optimistic : StockMode.pessimistic));
  }

  void _handleBackupChanged(bool value) {
    sendUpdates(config.configuration.copyWith(backupMode: value ? BackupMode.enabled : BackupMode.disabled));
  }

  void _handleShowGridChanged(bool value) {
    sendUpdates(config.configuration.copyWith(showGrid: value));
  }

  void _confirmOptimismChange() {
    switch (config.configuration.stockMode) {
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

  void sendUpdates(StockConfiguration value) {
    if (config.updater != null)
      config.updater(value);
  }

  Widget buildToolBar(BuildContext context) {
    return new ToolBar(
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane(BuildContext context) {
    List<Widget> rows = <Widget>[
      new DrawerItem(
        icon: 'action/thumb_up',
        onPressed: () => _confirmOptimismChange(),
        child: new Row(<Widget>[
          new Flexible(child: new Text('Everything is awesome')),
          new Checkbox(
            value: config.configuration.stockMode == StockMode.optimistic,
            onChanged: (bool value) => _confirmOptimismChange()
          ),
        ])
      ),
      new DrawerItem(
        icon: 'action/backup',
        onPressed: () { _handleBackupChanged(!(config.configuration.backupMode == BackupMode.enabled)); },
        child: new Row(<Widget>[
          new Flexible(child: new Text('Back up stock list to the cloud')),
          new Switch(
            value: config.configuration.backupMode == BackupMode.enabled,
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
          onPressed: () { _handleShowGridChanged(!config.configuration.showGrid); },
          child: new Row(<Widget>[
            new Flexible(child: new Text('Show material grid (for debugging)')),
            new Switch(
              value: config.configuration.showGrid,
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
