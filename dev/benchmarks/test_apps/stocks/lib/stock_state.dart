// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'stock_data.dart';
import 'stock_type.dart';

class _StockConfigurationScope extends InheritedWidget {
  const _StockConfigurationScope({
    Key key,
    this.configuration,
    Widget child,
  }) : super(key: key, child: child);

  final StockConfiguration configuration;

  @override
  bool updateShouldNotify(covariant _StockConfigurationScope oldWidget) {
    return configuration != oldWidget.configuration;
  }
}

class _StockDataScope extends InheritedWidget {
  const _StockDataScope({
    Key key,
    this.data,
    Widget child,
  }) : super(key: key, child: child);

  final StockData data;

  @override
  bool updateShouldNotify(covariant _StockDataScope oldWidget) {
    return data != oldWidget.data;
  }
}

class StockStateScope extends StatefulWidget {
  const StockStateScope({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  static StockState of(BuildContext context) {
    return context.findAncestorStateOfType<StockState>();
  }

  static StockData stockDataOf(BuildContext context) {
    return context
      .dependOnInheritedWidgetOfExactType<_StockDataScope>()
      .data;
  }

  static StockConfiguration configurationOf(BuildContext context) {
    return context
      .dependOnInheritedWidgetOfExactType<_StockConfigurationScope>()
      .configuration;
  }

  @override
  StockState createState() => StockState();
}

class StockState extends State<StockStateScope> {
  StockConfiguration _configuration;
  StockData _data;

  @override
  void initState() {
    super.initState();
    _data = StockData();
    _configuration = StockConfiguration(
      stockMode: StockMode.optimistic,
      backupMode: BackupMode.enabled,
      debugShowGrid: false,
      debugShowSizes: false,
      debugShowBaselines: false,
      debugShowLayers: false,
      debugShowPointers: false,
      debugShowRainbow: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
    );
  }

  void updateConfiguration({
    StockMode stockMode,
    BackupMode backupMode,
    bool debugShowGrid,
    bool debugShowSizes,
    bool debugShowBaselines,
    bool debugShowLayers,
    bool debugShowPointers,
    bool debugShowRainbow,
    bool showPerformanceOverlay,
    bool showSemanticsDebugger,
  }) {
    _configuration = _configuration.copyWith(
      stockMode: stockMode,
      backupMode: backupMode,
      debugShowGrid: debugShowGrid,
      debugShowSizes: debugShowSizes,
      debugShowBaselines: debugShowBaselines,
      debugShowLayers: debugShowLayers,
      debugShowPointers: debugShowPointers,
      debugShowRainbow: debugShowRainbow,
      showPerformanceOverlay: showPerformanceOverlay,
      showSemanticsDebugger: showSemanticsDebugger,
    );
    setState(() {/* Rebuilds to trigger a inherited widget update. */});
  }

  @override
  Widget build(BuildContext context) {
    return _StockConfigurationScope(
      configuration: _configuration,
      child: _StockDataScope(
        data: _data,
        child: widget.child,
      ),
    );
  }
}
