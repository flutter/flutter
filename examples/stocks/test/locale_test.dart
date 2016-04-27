// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;
import 'package:test/test.dart';

void main() {
  stock_data.StockDataFetcher.actuallyFetchData = false;

  test("Test changing locale", () {
    testWidgets((WidgetTester tester) {
      stocks.main();
      tester.flushMicrotasks(); // see https://github.com/flutter/flutter/issues/1865
      tester.pump();

      expect(tester, hasWidget(find.text('MARKET')));
      tester.setLocale("es", "US");
      tester.pump();
      expect(tester, hasWidget(find.text('MERCADO')));
    });
  });
}
