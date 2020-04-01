// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum StockMode { optimistic, pessimistic }
enum BackupMode { enabled, disabled }

class StockConfiguration extends ChangeNotifier {
  StockConfiguration({
    @required StockMode stockMode,
    @required BackupMode backupMode,
    @required bool debugShowGrid,
    @required bool debugShowSizes,
    @required bool debugShowBaselines,
    @required bool debugShowLayers,
    @required bool debugShowPointers,
    @required bool debugShowRainbow,
    @required bool showPerformanceOverlay,
    @required bool showSemanticsDebugger,
  }) : assert(stockMode != null),
       assert(backupMode != null),
       assert(debugShowGrid != null),
       assert(debugShowSizes != null),
       assert(debugShowBaselines != null),
       assert(debugShowLayers != null),
       assert(debugShowPointers != null),
       assert(debugShowRainbow != null),
       assert(showPerformanceOverlay != null),
       assert(showSemanticsDebugger != null),
       _stockMode = stockMode,
       _backupMode = backupMode,
       _debugShowGrid = debugShowGrid,
       _debugShowSizes = debugShowSizes,
       _debugShowBaselines = debugShowBaselines,
       _debugShowLayers = debugShowLayers,
       _debugShowPointers = debugShowPointers,
       _debugShowRainbow = debugShowRainbow,
       _showPerformanceOverlay = showPerformanceOverlay,
       _showSemanticsDebugger = showSemanticsDebugger;



  StockMode get stockMode => _stockMode;
  StockMode _stockMode;
  set stockMode(StockMode other) {
    if (_stockMode != other) {
      _stockMode = other;
      notifyListeners();
    }
  }

  BackupMode get backupMode => _backupMode;
  BackupMode _backupMode;
  set backupMode(BackupMode other) {
    if (_backupMode != other) {
      _backupMode = other;
      notifyListeners();
    }
  }

  bool get debugShowGrid => _debugShowGrid;
  bool _debugShowGrid;
  set debugShowGrid(bool other) {
    if (_debugShowGrid != other) {
      _debugShowGrid = other;
      notifyListeners();
    }
  }

  bool get debugShowSizes => _debugShowSizes;
  bool _debugShowSizes;
  set debugShowSizes(bool other) {
    if (_debugShowSizes != other) {
      _debugShowSizes = other;
      notifyListeners();
    }
  }

  bool get debugShowBaselines => _debugShowBaselines;
  bool _debugShowBaselines;
  set debugShowBaselines(bool other) {
    if (_debugShowBaselines != other) {
      _debugShowBaselines = other;
      notifyListeners();
    }
  }

  bool get debugShowLayers => _debugShowLayers;
  bool _debugShowLayers;
  set debugShowLayers(bool other) {
    if (_debugShowLayers != other) {
      _debugShowLayers = other;
      notifyListeners();
    }
  }

  bool get debugShowPointers => _debugShowPointers;
  bool _debugShowPointers;
  set debugShowPointers(bool other) {
    if (_debugShowPointers != other) {
      _debugShowPointers = other;
      notifyListeners();
    }
  }

  bool get debugShowRainbow => _debugShowRainbow;
  bool _debugShowRainbow;
  set debugShowRainbow(bool other) {
    if (_debugShowRainbow != other) {
      _debugShowRainbow = other;
      notifyListeners();
    }
  }

  bool get showPerformanceOverlay => _showPerformanceOverlay;
  bool _showPerformanceOverlay;
  set showPerformanceOverlay(bool other) {
    if (_showPerformanceOverlay != other) {
      _showPerformanceOverlay = other;
      notifyListeners();
    }
  }

  bool get showSemanticsDebugger  => _showSemanticsDebugger;
  bool _showSemanticsDebugger;
  set showSemanticsDebugger (bool other) {
    if (_showSemanticsDebugger != other) {
      _showSemanticsDebugger = other;
      notifyListeners();
    }
  }
}

class StockConfigurationProvider extends InheritedNotifier<StockConfiguration> {
  const StockConfigurationProvider({
    Key key,
    StockConfiguration configuration,
    Widget child,
  }) : super(key: key, notifier: configuration, child: child);

  static StockConfiguration of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StockConfigurationProvider>().notifier;
  }
}