// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/widget.dart';

import 'stock_data.dart';
import 'stock_home.dart';
import 'stock_settings.dart';

class StocksApp extends App {

  StocksApp() {
    _navigationState = new NavigationState([
      new Route(
        name: '/', 
        builder: (navigator, route) => new StockHome(navigator, route, _stocks)
      ),
      new Route(
        name: '/settings',
        builder: (navigator, route) => new StockSettings(navigator)
      ),
    ]);
  }

  void didMount() {
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks);
      });
    });
  }

  final List<Stock> _stocks = [];
  NavigationState _navigationState;

  void onBack() {
    setState(() {
      _navigationState.pop();
    });
    // TODO(jackson): Need a way to invoke default back behavior here
  }

  Widget build() {
    return new Navigator(_navigationState);
  }
}

void main() {
  print("starting stocks app!");
  runApp(new StocksApp());
  SkyBinding.instance.onFrame = () {
    // uncomment this for debugging:
    // SkyBinding.instance.debugDumpRenderTree();
  };
}
