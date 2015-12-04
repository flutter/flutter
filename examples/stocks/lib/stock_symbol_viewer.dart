// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockSymbolView extends StatelessComponent {
  StockSymbolView({ this.stock });

  final Stock stock;

  Widget build(BuildContext context) {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";
    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0)
      changeInPrice = "+" + changeInPrice;

    TextStyle headings = Theme.of(context).text.body2;
    return new Container(
      padding: new EdgeDims.all(20.0),
      child: new Column(<Widget>[
          new Row(<Widget>[
              new Text(
                '${stock.symbol}',
                style: Theme.of(context).text.display2
              ),
              new Hero(
                key: new ObjectKey(stock),
                tag: StockRowPartKind.arrow,
                turns: 2,
                child: new StockArrow(percentChange: stock.percentChange)
              ),
            ],
            justifyContent: FlexJustifyContent.spaceBetween
          ),
          new Text('Last Sale', style: headings),
          new Text('$lastSale ($changeInPrice)'),
          new Container(
            height: 8.0
          ),
          new Text('Market Cap', style: headings),
          new Text('${stock.marketCap}'),
        ],
        justifyContent: FlexJustifyContent.collapse
      )
    );
  }
}

class StockSymbolPage extends StatelessComponent {
  StockSymbolPage({ this.stock });

  final Stock stock;

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text(stock.name)
      ),
      body: new Block(<Widget>[
        new Container(
          margin: new EdgeDims.all(20.0),
          child: new Card(child: new StockSymbolView(stock: stock))
        )
      ])
    );
  }
}

class StockSymbolBottomSheet extends StatelessComponent {
  StockSymbolBottomSheet({ this.stock });

  final Stock stock;

  Widget build(BuildContext context) {
    return new Container(
      padding: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(
        border: new Border(top: new BorderSide(color: Colors.black26, width: 1.0))
      ),
      child: new StockSymbolView(stock: stock)
   );
  }
}
