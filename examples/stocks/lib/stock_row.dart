// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stock_arrow.dart';
import 'stock_data.dart';

typedef void StockRowActionCallback(Stock stock);

class StockRow extends StatelessWidget {
  StockRow({
    this.stock,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPressed
  }) : super(key: new ObjectKey(stock));

  final Stock stock;
  final StockRowActionCallback onPressed;
  final StockRowActionCallback onDoubleTap;
  final StockRowActionCallback onLongPressed;

  static const double kHeight = 79.0;

  GestureTapCallback _getHandler(StockRowActionCallback callback) {
    return callback == null ? null : () => callback(stock);
  }

  @override
  Widget build(BuildContext context) {
    final String lastSale = '\$${stock.lastSale.toStringAsFixed(2)}';
    String changeInPrice = '${stock.percentChange.toStringAsFixed(2)}%';
    if (stock.percentChange > 0)
      changeInPrice = '+' + changeInPrice;
    return new InkWell(
      onTap: _getHandler(onPressed),
      onDoubleTap: _getHandler(onDoubleTap),
      onLongPress: _getHandler(onLongPressed),
      child: new Container(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
        decoration: new BoxDecoration(
          border: new Border(
            bottom: new BorderSide(color: Theme.of(context).dividerColor)
          )
        ),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 5.0),
              child: new Hero(
                tag: stock,
                child: new StockArrow(percentChange: stock.percentChange)
              )
            ),
            new Expanded(
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    flex: 2,
                    child: new Text(
                      stock.symbol
                    )
                  ),
                  new Expanded(
                    child: new Text(
                      lastSale,
                      textAlign: TextAlign.right
                    )
                  ),
                  new Expanded(
                    child: new Text(
                      changeInPrice,
                      textAlign: TextAlign.right
                    )
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: DefaultTextStyle.of(context).style.textBaseline
              )
            ),
          ]
        )
      )
    );
  }
}
