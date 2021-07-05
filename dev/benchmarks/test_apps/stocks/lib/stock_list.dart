// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stock_data.dart';
import 'stock_row.dart';

class StockList extends StatelessWidget {
  const StockList({
    Key? key,
    required this.stocks,
    required this.onOpen,
    required this.onShow,
    required this.onAction,
  }) : super(key: key);

  final List<Stock> stocks;
  final StockRowActionCallback onOpen;
  final StockRowActionCallback onShow;
  final StockRowActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey<String>('stock-list'),
      itemExtent: StockRow.kHeight,
      itemCount: stocks.length,
      itemBuilder: (BuildContext context, int index) {
        return StockRow(
          stock: stocks[index],
          onPressed: onOpen,
          onDoubleTap: onShow,
          onLongPressed: onAction,
        );
      },
    );
  }
}
