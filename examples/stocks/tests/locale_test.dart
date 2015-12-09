
import 'package:test/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

void main() {
  stock_data.StockDataFetcher.actuallyFetchData = false;

  test("Test changing locale", () {
    testWidgets((WidgetTester tester) {
      stocks.main();
      tester.pump(const Duration(seconds: 1)); // Unclear why duration is required.

      Element<Text> tab = tester.findText('MARKET');
      expect(tab, isNotNull);
      tester.setLocale("es", "US");
      tester.pump();
      expect(tab.widget.data, equals("MERCADO"));
    });
  });
}
