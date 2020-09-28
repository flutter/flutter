// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'stock_data.dart';

enum StockMode { optimistic, pessimistic }
enum BackupMode { enabled, disabled }

class StockConfiguration {
 const StockConfiguration({
    @required this.stockMode,
    @required this.backupMode,
    @required this.debugShowGrid,
    @required this.debugShowSizes,
    @required this.debugShowBaselines,
    @required this.debugShowLayers,
    @required this.debugShowPointers,
    @required this.debugShowRainbow,
    @required this.showPerformanceOverlay,
    @required this.showSemanticsDebugger,
  }) : assert(stockMode != null),
       assert(backupMode != null),
       assert(debugShowGrid != null),
       assert(debugShowSizes != null),
       assert(debugShowBaselines != null),
       assert(debugShowLayers != null),
       assert(debugShowPointers != null),
       assert(debugShowRainbow != null),
       assert(showPerformanceOverlay != null),
       assert(showSemanticsDebugger != null);

  final StockMode stockMode;
  final BackupMode backupMode;
  final bool debugShowGrid;
  final bool debugShowSizes;
  final bool debugShowBaselines;
  final bool debugShowLayers;
  final bool debugShowPointers;
  final bool debugShowRainbow;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;

  StockConfiguration copyWith({
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
    return StockConfiguration(
      stockMode: stockMode ?? this.stockMode,
      backupMode: backupMode ?? this.backupMode,
      debugShowGrid: debugShowGrid ?? this.debugShowGrid,
      debugShowSizes: debugShowSizes ?? this.debugShowSizes,
      debugShowBaselines: debugShowBaselines ?? this.debugShowBaselines,
      debugShowLayers: debugShowLayers ?? this.debugShowLayers,
      debugShowPointers: debugShowPointers ?? this.debugShowPointers,
      debugShowRainbow: debugShowRainbow ?? this.debugShowRainbow,
      showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
      showSemanticsDebugger: showSemanticsDebugger ?? this.showSemanticsDebugger,
    );
  }
}

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
    _configuration = const StockConfiguration(
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
