// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering/box.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/widget.dart';

import 'stock_home.dart';
import 'stock_settings.dart';

class StocksApp extends App {

  StocksApp({ RenderView renderViewOverride }) : super(renderViewOverride: renderViewOverride);

  Widget build() {
    return new Navigator(
      routes: [
        new Route(
          name: '/', 
          builder: (navigator) => new StockHome(navigator)
        ),
        new Route(
          name: '/settings', 
          builder: (navigator) => new StockSettings(navigator)
        ),
      ]
    );
  }
}

void main() {
  print("starting stocks app!");
  App app = new StocksApp();
  WidgetAppView.appView.onFrame = () {
    // uncomment this for debugging:
    // WidgetAppView.appView.debugDumpRenderTree();
  };
}
