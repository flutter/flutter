part of stocksapp;

class StockRow extends Component {

  Stock stock;

  static Style _style = new Style('''
    transform: translateX(0);
    display: flex;
    align-items: center;
    border-bottom: 1px solid #F4F4F4;
    padding-top: 16px;
    padding-left: 16px;
    padding-right: 16px;
    padding-bottom: 20px;'''
  );

  static Style _tickerStyle = new Style('''
    flex: 1;'''
  );

  static Style _lastSaleStyle = new Style('''
    text-align: right;
    padding-right: 16px;'''
  );

  static Style _changeStyle = new Style('''
    ${typography.black.caption};
    text-align: right;'''
  );

  StockRow({Stock stock}) : super(key: stock.symbol) {
    this.stock = stock;
  }

  Node build() {
    String lastSale = "\$${stock.lastSale.toStringAsFixed(2)}";

    String changeInPrice = "${stock.percentChange.toStringAsFixed(2)}%";
    if (stock.percentChange > 0)
      changeInPrice = "+" + changeInPrice;

    List<Node> children = [
      new StockArrow(
        percentChange: stock.percentChange
      ),
      new Container(
        key: 'Ticker',
        style: _tickerStyle,
        children: [new Text(stock.symbol)]
      ),
      new Container(
        key: 'LastSale',
        style: _lastSaleStyle,
        children: [new Text(lastSale)]
      ),
      new Container(
        key: 'Change',
        style: _changeStyle,
        children: [new Text(changeInPrice)]
      )
    ];

    return new Material(
      style: _style,
      children: children
    );
  }
}
