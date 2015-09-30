// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void StockActionListener(Stock stock);

class StockList extends StatelessComponent {
  StockList({ Key key, this.stocks, this.onAction, this.onOpen }) : super(key: key);

  final List<Stock> stocks;
  final StockActionListener onAction;
  final StockActionListener onOpen;

  Widget build(BuildContext context) {
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableList<Stock>(
        items: stocks,
        itemExtent: StockRow.kHeight,
        itemBuilder: (BuildContext context, Stock stock) {
          return new StockRow(
            stock: stock,
            onPressed: () { onAction(stock); },
            onLongPressed: () { onOpen(stock); }
          );
        }
      )
    );
  }
}
