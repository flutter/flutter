// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

void main() {
  stock_data.StockData.actuallyFetchData = false;

  testWidgets('Changing locale', (WidgetTester tester) async {
    stocks.main();
    await tester.idle(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump();
    // The initial test app's locale is "_", so we're seeing the fallback translation here.
    expect(find.text('MARKET'), findsOneWidget);
    await tester.binding.setLocale('es', 'US');
    await tester.idle();

    // The Localizations widget has been built with the new locale. The
    // new locale's strings are loaded asynchronously, so we're still
    // displaying the previous locale's strings.
    await tester.pump();
    expect(find.text('MARKET'), findsOneWidget);

    // The localized strings have finished loading and dependent
    // widgets have been updated.
    await tester.pump();
    expect(find.text('MERCADO'), findsOneWidget);
  });
}
