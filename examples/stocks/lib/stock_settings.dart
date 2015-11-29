// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockSettings extends StatefulComponent {
  const StockSettings(this.settings);

  final GlobalSettings settings;

  _StockSettingsState createState() => new _StockSettingsState();
}

class _StockSettingsState extends State<StockSettings> {
  void _handleOptimismChanged(bool value) {
    value ??= false;
    config.settings.optimism = value ? OptimismMode.optimistic : OptimismMode.pessimistic;
  }

  void _handleBackupChanged(bool value) {
    value ??= false;
    config.settings.backup = value ? BackupMode.enabled : BackupMode.disabled;
  }

  void _confirmOptimismChange() {
    switch (config.optimism) {
      case OptimismMode.optimistic:
        _handleOptimismChanged(false);
        break;
      case OptimismMode.pessimistic:
        showDialog(
          context: context,
          child: new Dialog(
            title: new Text("Change mode?"),
            content: new Text("Optimistic mode means everything is awesome. Are you sure you can handle that?"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('NO THANKS'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                }
              ),
              new FlatButton(
                child: new Text('AGREE'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                }
              ),
            ]
          )
        ).then(_handleOptimismChanged);
        break;
    }
  }

  Widget buildToolBar(BuildContext context) {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back',
        onPressed: () => Navigator.of(context).pop()
      ),
      center: new Text('Settings')
    );
  }

  Widget buildSettingsPane(BuildContext context) {
    // TODO(ianh): Once we have the gesture API hooked up, fix https://github.com/domokit/mojo/issues/281
    // (whereby tapping the widgets below causes both the widget and the menu item to fire their callbacks)
    return new Block(<Widget>[
        new DrawerItem(
          icon: 'action/thumb_up',
          onPressed: () => _confirmOptimismChange(),
          child: new Row(<Widget>[
            new Flexible(child: new Text('Everything is awesome')),
            new Checkbox(
              value: config.optimism == OptimismMode.optimistic,
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
      ],
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
