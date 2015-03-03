part of stocksapp;

class Stocklist extends FixedHeightScrollable {

  List<Stock> stocks;

  Stocklist({
    Object key,
    this.stocks
  }) : super(key: key, itemHeight: 80.0, height: 800.0, minOffset: 0.0);

  List<Node> renderItems(int start, int count) {
    var items = [];
    for (var i = 0; i < count; i++) {
      items.add(new StockRow(stock: stocks[start + i]));
    }

    return items;
  }
}
