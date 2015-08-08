// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/widgets/framework.dart';

import '../../../examples/stocks/lib/main.dart';
import '../../../examples/stocks/lib/stock_data.dart';
import '../resources/display_list.dart';

class TestStocksApp extends StocksApp {

  Completer _completer = new Completer();
  Future get isMounted => _completer.future;

  void didMount() {
    super.didMount();
    _completer.complete();
  }
}

main() async {
  StockDataFetcher.actuallyFetchData = false;

  TestRenderView testRenderView = new TestRenderView();
  TestStocksApp app = new TestStocksApp();
  runApp(app, renderViewOverride: testRenderView);
  await testRenderView.checkFrame();
  await app.isMounted;
  await testRenderView.checkFrame();
  testRenderView.endTest();
}
