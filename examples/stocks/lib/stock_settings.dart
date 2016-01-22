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
    sendUpdates(config.configuration.copyWith(debugShowGrid: value));
  }

  void _handleShowSizesChanged(bool value) {
    sendUpdates(config.configuration.copyWith(debugShowSizes: value));
  }

  void _handleShowPerformanceOverlayChanged(bool value) {
    sendUpdates(config.configuration.copyWith(showPerformanceOverlay: value));
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
        child: new Row(
          children: <Widget>[
            new Flexible(child: new Text('Everything is awesome')),
            new Checkbox(
              value: config.configuration.stockMode == StockMode.optimistic,
              onChanged: (bool value) => _confirmOptimismChange()
            ),
          ]
        )
      ),
      new DrawerItem(
        icon: 'action/backup',
        onPressed: () { _handleBackupChanged(!(config.configuration.backupMode == BackupMode.enabled)); },
        child: new Row(
          children: <Widget>[
            new Flexible(child: new Text('Back up stock list to the cloud')),
            new Switch(
              value: config.configuration.backupMode == BackupMode.enabled,
              onChanged: _handleBackupChanged
            ),
          ]
        )
      ),
      new DrawerItem(
        icon: 'action/picture_in_picture',
        onPressed: () { _handleShowPerformanceOverlayChanged(!config.configuration.showPerformanceOverlay); },
        child: new Row(
          children: <Widget>[
            new Flexible(child: new Text('Show rendering performance overlay')),
            new Switch(
              value: config.configuration.showPerformanceOverlay,
              onChanged: _handleShowPerformanceOverlayChanged
            ),
          ]
        )
      ),
    ];
    assert(() {
      // material grid and size construction lines are only available in checked mode
      rows.addAll([
        new DrawerItem(
          icon: 'editor/border_clear',
          onPressed: () { _handleShowGridChanged(!config.configuration.debugShowGrid); },
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Show material grid (for debugging)')),
              new Switch(
                value: config.configuration.debugShowGrid,
                onChanged: _handleShowGridChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: 'editor/border_all',
          onPressed: () { _handleShowSizesChanged(!config.configuration.debugShowSizes); },
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Show construction lines (for debugging)')),
              new Switch(
                value: config.configuration.debugShowSizes,
                onChanged: _handleShowSizesChanged
              ),
            ]
          )
        )
      ]);
      return true;
    });
    return new Block(
      children: rows,
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
