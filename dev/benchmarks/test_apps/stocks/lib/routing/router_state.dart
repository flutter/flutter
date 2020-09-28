// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

@immutable
abstract class StockRoutePath { const StockRoutePath(); }
class StockHomePath extends StockRoutePath { const StockHomePath(); }
class StockSettingsPath extends StockRoutePath { const StockSettingsPath(); }
class StockSymbolPath extends StockRoutePath {
  const StockSymbolPath(this.symbol);
  final String symbol;
}

class RouterState extends ChangeNotifier {
  RouterState();

  StockRoutePath get routePath => _routePath;
  StockRoutePath _routePath;
  set routePath(StockRoutePath value) {
    if (value != _routePath) {
      _routePath = value;
      notifyListeners();
    }
  }

  Map<String, dynamic> get browserState => _browserState;
  Map<String, dynamic> _browserState;
  set browserState(Map<String, dynamic> value) {
    if (value != _browserState) {
      _browserState = value;
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
