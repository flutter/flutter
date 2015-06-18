// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/widget.dart';

import 'stock_home.dart';
import 'stock_settings.dart';

class StocksApp extends App {

  NavigationState _navState = new NavigationState([
    new Route(name: '/', builder: (navigator) => new StockHome(navigator)),
    new Route(name: '/settings', builder: (navigator) => new StockSettings(navigator)),
  ]);

  void onBack() {
    if (_navState.hasPrevious()) {
      setState(() {
        _navState.pop();
      });
      return;
    }
    print ("Should exit app here");
    // TODO(jackson): Need a way to invoke default back behavior here
  }

  Widget build() {
    return new Navigator(_navState);
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
