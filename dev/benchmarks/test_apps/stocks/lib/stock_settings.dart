// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:stocks/stock_state.dart';

class StockSettings extends StatefulWidget {
  const StockSettings();

  @override
  StockSettingsState createState() => StockSettingsState();
}

class StockSettingsState extends State<StockSettings> {
  void _handleOptimismChanged(bool value) {
    value ??= false;
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(stockMode: value ? StockMode.optimistic : StockMode.pessimistic));
  }

  void _handleBackupChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(backupMode: value ? BackupMode.enabled : BackupMode.disabled));
  }

  void _handleShowGridChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowGrid: value));
  }

  void _handleShowSizesChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowSizes: value));
  }

  void _handleShowBaselinesChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowBaselines: value));
  }

  void _handleShowLayersChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowLayers: value));
  }

  void _handleShowPointersChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowPointers: value));
  }

  void _handleShowRainbowChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(debugShowRainbow: value));
  }


  void _handleShowPerformanceOverlayChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(showPerformanceOverlay: value));
  }

  void _handleShowSemanticsDebuggerChanged(bool value) {
    final StockState state = StockStateScope.of(context);
    state.updateConfiguration(StockStateScope.configurationOf(context).copyWith(showSemanticsDebugger: value));
  }

  void _confirmOptimismChange() {
    final StockConfiguration configuration = StockStateScope.configurationOf(context);
    switch (configuration.stockMode) {
      case StockMode.optimistic:
        _handleOptimismChanged(false);
        break;
      case StockMode.pessimistic:
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Change mode?'),
              content: const Text('Optimistic mode means everything is awesome. Are you sure you can handle that?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('NO THANKS'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                TextButton(
                  child: const Text('AGREE'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        ).then<void>(_handleOptimismChanged);
        break;
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Settings'),
    );
  }

  Widget buildSettingsPane(BuildContext context) {
    final StockConfiguration configuration = StockStateScope.configurationOf(context);
    final List<Widget> rows = <Widget>[
      ListTile(
        leading: const Icon(Icons.thumb_up),
        title: const Text('Everything is awesome'),
        onTap: _confirmOptimismChange,
        trailing: Checkbox(
          value: configuration.stockMode == StockMode.optimistic,
          onChanged: (bool value) => _confirmOptimismChange(),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.backup),
        title: const Text('Back up stock list to the cloud'),
        onTap: () { _handleBackupChanged(!(configuration.backupMode == BackupMode.enabled)); },
        trailing: Switch(
          value: configuration.backupMode == BackupMode.enabled,
          onChanged: _handleBackupChanged,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.picture_in_picture),
        title: const Text('Show rendering performance overlay'),
        onTap: () { _handleShowPerformanceOverlayChanged(!configuration.showPerformanceOverlay); },
        trailing: Switch(
          value: configuration.showPerformanceOverlay,
          onChanged: _handleShowPerformanceOverlayChanged,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.accessibility),
        title: const Text('Show semantics overlay'),
        onTap: () { _handleShowSemanticsDebuggerChanged(!configuration.showSemanticsDebugger); },
        trailing: Switch(
          value: configuration.showSemanticsDebugger,
          onChanged: _handleShowSemanticsDebuggerChanged,
        ),
      ),
    ];
    assert(() {
      // material grid and size construction lines are only available in checked mode
      rows.addAll(<Widget>[
        ListTile(
          leading: const Icon(Icons.border_clear),
          title: const Text('Show material grid (for debugging)'),
          onTap: () { _handleShowGridChanged(!configuration.debugShowGrid); },
          trailing: Switch(
            value: configuration.debugShowGrid,
            onChanged: _handleShowGridChanged,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.border_all),
          title: const Text('Show construction lines (for debugging)'),
          onTap: () { _handleShowSizesChanged(!configuration.debugShowSizes); },
          trailing: Switch(
            value: configuration.debugShowSizes,
            onChanged: _handleShowSizesChanged,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.format_color_text),
          title: const Text('Show baselines (for debugging)'),
          onTap: () { _handleShowBaselinesChanged(!configuration.debugShowBaselines); },
          trailing: Switch(
            value: configuration.debugShowBaselines,
            onChanged: _handleShowBaselinesChanged,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.filter_none),
          title: const Text('Show layer boundaries (for debugging)'),
          onTap: () { _handleShowLayersChanged(!configuration.debugShowLayers); },
          trailing: Switch(
            value: configuration.debugShowLayers,
            onChanged: _handleShowLayersChanged,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.mouse),
          title: const Text('Show pointer hit-testing (for debugging)'),
          onTap: () { _handleShowPointersChanged(!configuration.debugShowPointers); },
          trailing: Switch(
            value: configuration.debugShowPointers,
            onChanged: _handleShowPointersChanged,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gradient),
          title: const Text('Show repaint rainbow (for debugging)'),
          onTap: () { _handleShowRainbowChanged(!configuration.debugShowRainbow); },
          trailing: Switch(
            value: configuration.debugShowRainbow,
            onChanged: _handleShowRainbowChanged,
          ),
        ),
      ]);
      return true;
    }());
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildSettingsPane(context),
    );
  }
}

class StockSettingsPage extends MaterialPage<void> {
  StockSettingsPage() : super(
                          key: const ValueKey<String>('settings'),
                          builder: (BuildContext context) => const StockSettings(),
                        );
}
