part of stocksapp;

class Stocklist extends FixedHeightScrollable {
  String query;
  List<Stock> stocks;

  Stocklist({
    Object key,
    this.stocks,
    this.query
  }) : super(key: key, scrollCurve: new BoundedScrollCurve(minOffset: 0.0));

  List<Node> buildItems(int start, int count) {
    return stocks
      .skip(start)
      .where((stock) => query == null || stock.symbol.contains(
          new RegExp(query, caseSensitive: false)))
      .take(count)
      .map((stock) => new StockRow(stock: stock))
      .toList(growable: false);
  }
}
