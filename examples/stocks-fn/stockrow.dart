part of stocksapp;

class StockRow extends Component {

  Stock stock;
  LinkedHashSet<SplashAnimation> _splashes;

  static Style _style = new Style('''
    transform: translateX(0);
    max-height: 48px;
    display: flex;
    align-items: center;
    border-bottom: 1px solid #F4F4F4;
    padding-top: 16px;
    padding-left: 16px;
    padding-right: 16px;
    padding-bottom: 20px;'''
  );

  static Style _tickerStyle = new Style('''
    flex: 1;
    font-family: 'Roboto Medium', 'Helvetica';'''
  );

  static Style _lastSaleStyle = new Style('''
    text-align: right;
    padding-right: 16px;'''
  );

  static Style _changeStyle = new Style('''
    color: #8A8A8A;
    text-align: right;'''
  );

  StockRow({Stock stock}) : super(key: stock.symbol) {
    this.stock = stock;
  }

  Node render() {
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

    if (_splashes != null) {
      children.addAll(_splashes.map((s) => new InkSplash(s.onStyleChanged)));
    }

    return new Container(
      style: _style,
      onScrollStart: _cancelSplashes,
      onWheel: _cancelSplashes,
      onPointerDown: _handlePointerDown,
      children: children
    );
  }

  sky.ClientRect _getBoundingRect() => getRoot().getBoundingClientRect();

  void _handlePointerDown(sky.Event event) {
    setState(() {
      if (_splashes == null) {
        _splashes = new LinkedHashSet<SplashAnimation>();
      }

      var splash;
      splash = new SplashAnimation(_getBoundingRect(), event.x, event.y,
                                   onDone: () { _splashDone(splash); });

      _splashes.add(splash);
    });
  }

  void _cancelSplashes(sky.Event event) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      var splashes = _splashes;
      _splashes = null;
      splashes.forEach((s) { s.cancel(); });
    });
  }

  void willUnmount() {
    _cancelSplashes(null);
  }

  void _splashDone(SplashAnimation splash) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      _splashes.remove(splash);
      if (_splashes.length == 0) {
        _splashes = null;
      }
    });
  }
}
