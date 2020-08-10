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

class StockState extends ChangeNotifier {
  StockState(this.stocks);

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

  final StockData stocks;
}

class StockStateScope extends InheritedNotifier<StockState> {
  const StockStateScope({
    Key key,
    StockState state,
    Widget child,
  }) : super(key: key, notifier: state, child: child);

  static StockState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StockStateScope>().notifier;
  }
}
