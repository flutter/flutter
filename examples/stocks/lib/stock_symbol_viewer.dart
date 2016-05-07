// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'stock_data.dart';
import 'stock_arrow.dart';
import 'stock_row.dart';

class StockSymbolView extends StatelessWidget {
  StockSymbolView({ this.stock });

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";
    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0)
      changeInPrice = "+" + changeInPrice;

    TextStyle headings = Theme.of(context).textTheme.body2;
    return new Container(
      padding: new EdgeInsets.all(20.0),
      child: new Column(
        children: <Widget>[
          new Row(
            children: <Widget>[
              new Text(
                '${stock.symbol}',
                style: Theme.of(context).textTheme.display2
              ),
              new Hero(
                key: new ObjectKey(stock),
                tag: StockRowPartKind.arrow,
                turns: 2,
                child: new StockArrow(percentChange: stock.percentChange)
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween
          ),
          new Text('Last Sale', style: headings),
          new Text('$lastSale ($changeInPrice)'),
          new Container(
            height: 8.0
          ),
          new Text('Market Cap', style: headings),
          new Text('${stock.marketCap}'),
          new Container(
            height: 8.0
          ),
          new RichText(
            text: new TextSpan(
              style: DefaultTextStyle.of(context).style.merge(new TextStyle(fontSize: 8.0)),
              text: 'Prices may be delayed by ',
              children: <TextSpan>[
                new TextSpan(text: 'several', style: new TextStyle(fontStyle: FontStyle.italic)),
                new TextSpan(text: ' years.'),
              ]
            )
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.collapse
      )
    );
  }
}

class StockSymbolPage extends StatelessWidget {
  StockSymbolPage({ this.stock });

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(stock.name)
      ),
      body: new Block(
        children: <Widget>[
          new Container(
            margin: new EdgeInsets.all(20.0),
            child: new Card(child: new StockSymbolView(stock: stock))
          )
        ]
      )
    );
  }
}

class StockSymbolBottomSheet extends StatelessWidget {
  StockSymbolBottomSheet({ this.stock });

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: new EdgeInsets.all(10.0),
      decoration: new BoxDecoration(
        border: new Border(top: new BorderSide(color: Colors.black26))
      ),
      child: new StockSymbolView(stock: stock)
   );
  }
}
