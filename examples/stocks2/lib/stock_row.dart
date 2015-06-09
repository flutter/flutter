// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'package:sky/framework/components2/ink_well.dart';
import 'package:sky/framework/fn2.dart';
import 'package:sky/framework/rendering/flex.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/theme/typography.dart' as typography;
import 'stock_arrow.dart';
import 'stock_data.dart';

class StockRow extends Component {
  static const double kHeight = 70.0;

  Stock stock;

  StockRow({ Stock stock }) : super(key: stock.symbol) {
    this.stock = stock;
  }

  UINode build() {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";

    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0) changeInPrice = "+" + changeInPrice;

    List<UINode> children = [
      new Container(
          child: new StockArrow(percentChange: stock.percentChange),
          margin: const EdgeDims.only(right: 5.0)),
      new FlexExpandingChild(new Text(stock.symbol), flex: 2, key: "symbol"),
      // TODO(hansmuller): text-align: right
      new FlexExpandingChild(new Text(lastSale), key: "lastSale"),
      // TODO(hansmuller): text-align: right, ${typography.black.caption};
      new FlexExpandingChild(new Text(changeInPrice), key: "changeInPrice")
    ];

    return new Container(
      padding: const EdgeDims(16.0, 16.0, 20.0, 16.0),
      height: kHeight, // TODO(hansmuller): This shouldn't be needed
      decoration: const BoxDecoration(
          backgroundColor: const sky.Color(0xFFFFFFFF),
          border: const Border(
              bottom: const BorderSide(
                  color: const sky.Color(0xFFF4F4F4),
                  width: 1.0))),
      child: new FlexContainer(children: children));
  }
}
