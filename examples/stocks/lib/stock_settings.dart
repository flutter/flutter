// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stock_types.dart';

class StockSettings extends StatefulWidget {
  const StockSettings(this.configuration, this.updater);

  final StockConfiguration configuration;
  final ValueChanged<StockConfiguration> updater;

  @override
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

  void _handleShowBaselinesChanged(bool value) {
    sendUpdates(config.configuration.copyWith(debugShowBaselines: value));
  }

  void _handleShowLayersChanged(bool value) {
    sendUpdates(config.configuration.copyWith(debugShowLayers: value));
  }

  void _handleShowPointersChanged(bool value) {
    sendUpdates(config.configuration.copyWith(debugShowPointers: value));
  }

  void _handleShowRainbowChanged(bool value) {
    sendUpdates(config.configuration.copyWith(debugShowRainbow: value));
  }


  void _handleShowPerformanceOverlayChanged(bool value) {
    sendUpdates(config.configuration.copyWith(showPerformanceOverlay: value));
  }

  void _handleShowSemanticsDebuggerChanged(bool value) {
    sendUpdates(config.configuration.copyWith(showSemanticsDebugger: value));
  }

  void _confirmOptimismChange() {
    switch (config.configuration.stockMode) {
      case StockMode.optimistic:
        _handleOptimismChanged(false);
        break;
      case StockMode.pessimistic:
        showDialog<bool>(
          context: context,
          child: new AlertDialog(
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
        ).then<Null>(_handleOptimismChanged);
        break;
    }
  }

  void sendUpdates(StockConfiguration value) {
    if (config.updater != null)
      config.updater(value);
  }

  Widget buildAppBar(BuildContext context) {
    return new AppBar(
      title: new Text('Settings')
    );
  }

  Widget buildSettingsPane(BuildContext context) {
    List<Widget> rows = <Widget>[
      new DrawerItem(
        icon: new Icon(Icons.thumb_up),
        onPressed: () => _confirmOptimismChange(),
        child: new Row(
          children: <Widget>[
            new Expanded(child: new Text('Everything is awesome')),
            new Checkbox(
              value: config.configuration.stockMode == StockMode.optimistic,
              onChanged: (bool value) => _confirmOptimismChange()
            ),
          ]
        )
      ),
      new DrawerItem(
        icon: new Icon(Icons.backup),
        onPressed: () { _handleBackupChanged(!(config.configuration.backupMode == BackupMode.enabled)); },
        child: new Row(
          children: <Widget>[
            new Expanded(child: new Text('Back up stock list to the cloud')),
            new Switch(
              value: config.configuration.backupMode == BackupMode.enabled,
              onChanged: _handleBackupChanged
            ),
          ]
        )
      ),
      new DrawerItem(
        icon: new Icon(Icons.picture_in_picture),
        onPressed: () { _handleShowPerformanceOverlayChanged(!config.configuration.showPerformanceOverlay); },
        child: new Row(
          children: <Widget>[
            new Expanded(child: new Text('Show rendering performance overlay')),
            new Switch(
              value: config.configuration.showPerformanceOverlay,
              onChanged: _handleShowPerformanceOverlayChanged
            ),
          ]
        )
      ),
      new DrawerItem(
        icon: new Icon(Icons.accessibility),
        onPressed: () { _handleShowSemanticsDebuggerChanged(!config.configuration.showSemanticsDebugger); },
        child: new Row(
          children: <Widget>[
            new Expanded(child: new Text('Show semantics overlay')),
            new Switch(
              value: config.configuration.showSemanticsDebugger,
              onChanged: _handleShowSemanticsDebuggerChanged
            ),
          ]
        )
      ),
    ];
    assert(() {
      // material grid and size construction lines are only available in checked mode
      rows.addAll(<Widget>[
        new DrawerItem(
          icon: new Icon(Icons.border_clear),
          onPressed: () { _handleShowGridChanged(!config.configuration.debugShowGrid); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show material grid (for debugging)')),
              new Switch(
                value: config.configuration.debugShowGrid,
                onChanged: _handleShowGridChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: new Icon(Icons.border_all),
          onPressed: () { _handleShowSizesChanged(!config.configuration.debugShowSizes); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show construction lines (for debugging)')),
              new Switch(
                value: config.configuration.debugShowSizes,
                onChanged: _handleShowSizesChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: new Icon(Icons.format_color_text),
          onPressed: () { _handleShowBaselinesChanged(!config.configuration.debugShowBaselines); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show baselines (for debugging)')),
              new Switch(
                value: config.configuration.debugShowBaselines,
                onChanged: _handleShowBaselinesChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: new Icon(Icons.filter_none),
          onPressed: () { _handleShowLayersChanged(!config.configuration.debugShowLayers); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show layer boundaries (for debugging)')),
              new Switch(
                value: config.configuration.debugShowLayers,
                onChanged: _handleShowLayersChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: new Icon(Icons.mouse),
          onPressed: () { _handleShowPointersChanged(!config.configuration.debugShowPointers); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show pointer hit-testing (for debugging)')),
              new Switch(
                value: config.configuration.debugShowPointers,
                onChanged: _handleShowPointersChanged
              ),
            ]
          )
        ),
        new DrawerItem(
          icon: new Icon(Icons.gradient),
          onPressed: () { _handleShowRainbowChanged(!config.configuration.debugShowRainbow); },
          child: new Row(
            children: <Widget>[
              new Expanded(child: new Text('Show repaint rainbow (for debugging)')),
              new Switch(
                value: config.configuration.debugShowRainbow,
                onChanged: _handleShowRainbowChanged
              ),
            ]
          )
        ),
      ]);
      return true;
    });
    return new ListView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: buildAppBar(context),
      body: buildSettingsPane(context)
    );
  }
}
