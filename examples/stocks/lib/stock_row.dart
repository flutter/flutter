// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stock_data.dart';
import 'stock_arrow.dart';

enum StockRowPartKind { arrow }

class StockRowPartKey extends Key {
  const StockRowPartKey(this.keySalt, this.stock, this.part) : super.constructor();

  final Object keySalt;
  final Stock stock;
  final StockRowPartKind part;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final StockRowPartKey typedOther = other;
    return keySalt == typedOther.keySalt
        && stock == typedOther.stock
        && part == typedOther.part;
  }

  @override
  int get hashCode => hashValues(keySalt, stock, part);

  @override
  String toString() => '[$runtimeType ${keySalt.toString().split(".")[1]}:${stock.symbol}:${part.toString().split(".")[1]}]';
}

typedef void StockRowActionCallback(Stock stock, Key arrowKey);

class StockRow extends StatelessWidget {
  StockRow({
    Stock stock,
    Object keySalt,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPressed
  }) : this.stock = stock,
       _arrowKey = new StockRowPartKey(keySalt, stock, StockRowPartKind.arrow),
       super(key: new ObjectKey(stock));

  final Stock stock;
  final StockRowActionCallback onPressed;
  final StockRowActionCallback onDoubleTap;
  final StockRowActionCallback onLongPressed;

  final Key _arrowKey;

  static const double kHeight = 79.0;

  GestureTapCallback _getHandler(StockRowActionCallback callback) {
    return callback == null ? null : () => callback(stock, _arrowKey);
  }

  @override
  Widget build(BuildContext context) {
    final String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";
    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0)
      changeInPrice = "+" + changeInPrice;
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
                tag: StockRowPartKind.arrow,
                key: _arrowKey,
                child: new StockArrow(percentChange: stock.percentChange)
              )
            ),
            new Flexible(
              child: new Row(
                children: <Widget>[
                  new Flexible(
                    flex: 2,
                    child: new Text(
                      stock.symbol
                    )
                  ),
                  new Flexible(
                    child: new Text(
                      lastSale,
                      textAlign: TextAlign.right
                    )
                  ),
                  new Flexible(
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
