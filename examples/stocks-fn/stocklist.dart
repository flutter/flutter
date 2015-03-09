part of stocksapp;

class Stocklist extends FixedHeightScrollable {

  List<Stock> stocks;

  Stocklist({
    Object key,
    this.stocks
  }) : super(key: key, minOffset: 0.0);

  List<Node> buildItems(int start, int count) {
    var items = [];
    for (var i = 0; i < count; i++) {
      items.add(new StockRow(stock: stocks[start + i]));
    }

    return items;
  }
}
