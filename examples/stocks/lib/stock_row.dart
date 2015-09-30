// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockRow extends StatelessComponent {
  StockRow({
    Stock stock,
    this.onPressed,
    this.onLongPressed
  }) : this.stock = stock, super(key: new Key(stock.symbol));

  final Stock stock;
  final GestureTapListener onPressed;
  final GestureLongPressListener onLongPressed;

  static const double kHeight = 79.0;

  Widget build(BuildContext context) {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";

    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0) changeInPrice = "+" + changeInPrice;

    List<Widget> children = [
      new Flexible(
        child: new Text(stock.symbol),
        flex: 2
      ),
      new Flexible(
        child: new Text(
          lastSale,
          style: const TextStyle(textAlign: TextAlign.right)
        )
      ),
      new Flexible(
        child: new Text(
          changeInPrice,
          style: Theme.of(context).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];

    return new GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPressed,
      child: new InkWell(
        child: new Container(
          padding: const EdgeDims(16.0, 16.0, 20.0, 16.0),
          decoration: new BoxDecoration(
            border: new Border(
              bottom: new BorderSide(color: Theme.of(context).dividerColor)
            )
          ),
          child: new Row([
            new Container(
              child: new StockArrow(percentChange: stock.percentChange),
              margin: const EdgeDims.only(right: 5.0)
            ),
            new Flexible(
              child: new Row(
                children,
                alignItems: FlexAlignItems.baseline,
                textBaseline: DefaultTextStyle.of(context).textBaseline
              )
            )
          ])
        )
      )
    );
  }
}
