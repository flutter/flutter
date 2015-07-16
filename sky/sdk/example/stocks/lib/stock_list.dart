// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/scrollable_list.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/basic.dart';

import 'stock_data.dart';
import 'stock_row.dart';

class Stocklist extends Component {
  Stocklist({ String key, this.stocks }) : super(key: key);

  final List<Stock> stocks;

  Widget build() {
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableList<Stock>(
        items: stocks,
        itemHeight: StockRow.kHeight,
        itemBuilder: (stock) => new StockRow(stock: stock)
      )
    );
  }
}
