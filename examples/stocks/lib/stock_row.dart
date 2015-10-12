// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

enum StockRowPartKind { arrow, symbol, price }

class StockRowPartGlobalKey extends GlobalKey {
  const StockRowPartGlobalKey(this.stock, this.part) : super.constructor();
  final Stock stock;
  final StockRowPartKind part;
  bool operator ==(dynamic other) {
    if (other is! StockRowPartGlobalKey)
      return false;
    final StockRowPartGlobalKey typedOther = other;
    return stock == typedOther.stock &&
           part == typedOther.part;
  }
  int get hashCode => 37 * (37 * (373) + identityHashCode(stock)) + identityHashCode(part);
  String toString() => '[StockRowPartGlobalKey ${stock.symbol}:${part.toString().split(".")[1]})]';
}

typedef void StockRowActionCallback(Stock stock, GlobalKey row, GlobalKey arrowKey, GlobalKey symbolKey, GlobalKey priceKey);

class StockRow extends StatelessComponent {
  StockRow({
    Stock stock,
    this.onPressed,
    this.onLongPressed
  }) : this.stock = stock,
       arrowKey = new StockRowPartGlobalKey(stock, StockRowPartKind.arrow),
       symbolKey = new StockRowPartGlobalKey(stock, StockRowPartKind.symbol),
       priceKey = new StockRowPartGlobalKey(stock, StockRowPartKind.price),
       super(key: new GlobalObjectKey(stock));

  final Stock stock;
  final StockRowActionCallback onPressed;
  final StockRowActionCallback onLongPressed;
  final GlobalKey arrowKey;
  final GlobalKey symbolKey;
  final GlobalKey priceKey;

  static const double kHeight = 79.0;

  GestureTapCallback _getTapHandler(StockRowActionCallback callback) {
    if (callback == null)
      return null;
    return () => callback(stock, key, arrowKey, symbolKey, priceKey);
  }

  GestureLongPressCallback _getLongPressHandler(StockRowActionCallback callback) {
    if (callback == null)
      return null;
    return () => callback(stock, key, arrowKey, symbolKey, priceKey);
  }

  Widget build(BuildContext context) {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";

    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0) changeInPrice = "+" + changeInPrice;

    return new InkWell(
      onTap: _getTapHandler(onPressed),
      onLongPress: _getLongPressHandler(onLongPressed),
      child: new Container(
        padding: const EdgeDims.TRBL(16.0, 16.0, 20.0, 16.0),
        decoration: new BoxDecoration(
          border: new Border(
            bottom: new BorderSide(color: Theme.of(context).dividerColor)
          )
        ),
        child: new Row(<Widget>[
          new Container(
            key: arrowKey,
            child: new StockArrow(percentChange: stock.percentChange),
            margin: const EdgeDims.only(right: 5.0)
          ),
          new Flexible(
            child: new Row(<Widget>[
                new Flexible(
                  flex: 2,
                  child: new Text(
                    stock.symbol,
                    key: symbolKey
                  )
                ),
                new Flexible(
                  child: new Text(
                    lastSale,
                    style: const TextStyle(textAlign: TextAlign.right),
                    key: priceKey
                  )
                ),
                new Flexible(
                  child: new Text(
                    changeInPrice,
                    style: Theme.of(context).text.caption.copyWith(textAlign: TextAlign.right)
                  )
                ),
              ],
              alignItems: FlexAlignItems.baseline,
              textBaseline: DefaultTextStyle.of(context).textBaseline
            )
          )
        ])
      )
    );
  }
}
