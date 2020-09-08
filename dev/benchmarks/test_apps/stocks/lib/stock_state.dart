// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'stock_data.dart';

@immutable
abstract class StockRoutePath { const StockRoutePath(); }
class StockHomePath extends StockRoutePath { const StockHomePath(); }
class StockSettingsPath extends StockRoutePath { const StockSettingsPath(); }
class StockSymbolPath extends StockRoutePath {
  const StockSymbolPath(this.symbol);
  final String symbol;
}

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

class RouterState extends ChangeNotifier {
  RouterState();

  bool get debugInitialized {
    bool answer;
    assert((){
      answer = routePath != null;
      return true;
    }());
    return answer;
  }

  StockRoutePath get routePath => _routePath;
  StockRoutePath _routePath;
  set routePath(StockRoutePath value) {
    if (value != _routePath) {
      _routePath = value;
      notifyListeners();
    }
  }
}

class RouterStateScope extends InheritedNotifier<RouterState> {
  const RouterStateScope({
    Key key,
    RouterState routerState,
    Widget child,
  }) : super(key: key, notifier: routerState, child: child);

  static RouterState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouterStateScope>().notifier;
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

class StockStateScope extends StatefulWidget {
  const StockStateScope({
    Key key,
    this.stocks,
    this.child,
  }) : super(key: key);

  final StockData stocks;
  final Widget child;

  static StockState of(BuildContext context) {
    return context.findAncestorStateOfType<StockState>();
  }

  static StockData stockDataOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<StockStateScope>().stocks;
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
  StockConfiguration _configuration = const StockConfiguration(
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

  void updateConfiguration(StockConfiguration configuration) {
    if (_configuration != configuration) {
      _configuration = configuration;
      setState(() {/* Rebuilds to trigger a inherited widget update. */});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StockConfigurationScope(
      configuration: _configuration,
      child: widget.child,
    );
  }
}
