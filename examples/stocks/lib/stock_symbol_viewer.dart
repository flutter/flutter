// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockSymbolViewer extends StatelessComponent {
  StockSymbolViewer({ this.stock, this.showToolBar: true });

  final Stock stock;
  final bool showToolBar;

  Widget build(BuildContext context) {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";
    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0)
      changeInPrice = "+" + changeInPrice;

    TextStyle headings = Theme.of(context).text.body2;
    Widget body = new Block(<Widget>[
      new Container(
        margin: new EdgeDims.all(20.0),
        child: new Card(
          child: new Container(
            padding: new EdgeDims.all(20.0),
            child: new Column(<Widget>[
                new Row(<Widget>[
                  new Text(
                    '${stock.symbol}',
                    style: Theme.of(context).text.display2
                  ),
                  new Hero(
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
            ])
          )
        )
      )
    ]);

    if (!showToolBar)
      return body;

    return new Scaffold(
      toolBar: new ToolBar(
        left: new IconButton(
          icon: 'navigation/arrow_back',
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
        center: new Text(stock.name)
      ),
      body: body
    );
  }

}
