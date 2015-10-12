// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockSymbolViewer extends StatefulComponent {
  StockSymbolViewer(this.navigator, this.stock);

  final NavigatorState navigator;
  final Stock stock;

  StockSymbolViewerState createState() => new StockSymbolViewerState();
}

class StockSymbolViewerState extends State<StockSymbolViewer> {

  Widget build(BuildContext context) {

    String lastSale = "\$${config.stock.lastSale.toStringAsFixed(2)}";

    String changeInPrice = "${config.stock.percentChange.toStringAsFixed(2)}%";
    if (config.stock.percentChange > 0) changeInPrice = "+" + changeInPrice;

    TextStyle headings = Theme.of(context).text.body2;

    return new Scaffold(
      toolBar: new ToolBar(
        left: new IconButton(
          icon: 'navigation/arrow_back',
          onPressed: config.navigator.pop
        ),
        center: new Text('${config.stock.name} (${config.stock.symbol})')
      ),
      body: new Material(
        child: new Block([
          new Container(
            padding: new EdgeDims.all(20.0),
            child: new Column([
                new Text('Last Sale', style: headings),
                new Text('${lastSale} (${changeInPrice})'),
                new Container(
                  height: 8.0
                ),
                new Text('Market Cap', style: headings),
                new Text('${config.stock.marketCap}'),
              ],
              alignItems: FlexAlignItems.stretch
            )
          )
        ])
      )
    );
  }

}
