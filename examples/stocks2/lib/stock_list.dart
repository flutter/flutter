// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/widgets/fixed_height_scrollable.dart';
import 'package:sky/framework/widgets/basic.dart';

import 'stock_data.dart';
import 'stock_row.dart';

class Stocklist extends FixedHeightScrollable {

  Stocklist({
    Object key,
    this.stocks,
    this.query
  }) : super(itemHeight: StockRow.kHeight, key: key);

  String query;
  List<Stock> stocks;

  void syncFields(Stocklist source) {
    query = source.query;
    stocks = source.stocks;
    super.syncFields(source);
  }

  List<UINode> buildItems(int start, int count) {
    var filteredStocks = stocks.where((stock) {
      return query == null ||
             stock.symbol.contains(new RegExp(query, caseSensitive: false));
    });
    itemCount = filteredStocks.length;
    return filteredStocks
      .skip(start)
      .take(count)
      .map((stock) => new StockRow(stock: stock))
      .toList(growable: false);
  }
}
