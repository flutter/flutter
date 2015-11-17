// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void ModeUpdater(StockMode mode);

class StockHome extends StatefulComponent {
  StockHome(this.stocks, this.symbols, this.stockMode, this.modeUpdater);

  final Map<String, Stock> stocks;
  final List<String> symbols;
  final StockMode stockMode;
  final ModeUpdater modeUpdater;

  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {

  final GlobalKey<PlaceholderState> _snackBarPlaceholderKey = new GlobalKey<PlaceholderState>();
  final GlobalKey<PlaceholderState> _bottomSheetPlaceholderKey = new GlobalKey<PlaceholderState>();
  bool _isSearching = false;
  String _searchQuery;

  void _handleSearchBegin() {
    Navigator.of(context).push(new StateRoute(
      onPop: () {
        setState(() {
          _isSearching = false;
          _searchQuery = null;
        });
      }
    ));
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    Navigator.of(context).pop();
  }

  void _handleSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  bool _autorefresh = false;
  void _handleAutorefreshChanged(bool value) {
    setState(() {
      _autorefresh = value;
    });
  }

  void _handleStockModeChange(StockMode value) {
    if (config.modeUpdater != null)
      config.modeUpdater(value);
  }

  void _handleMenuShow() {
    showStockMenu(
      context: context,
      autorefresh: _autorefresh,
      onAutorefreshChanged: _handleAutorefreshChanged
    );
  }

  void _showDrawer() {
    showDrawer(
      context: context,
      child: new Block(<Widget>[
        new DrawerHeader(child: new Text('Stocks')),
        new DrawerItem(
          icon: 'action/assessment',
          selected: true,
          child: new Text('Stock List')
        ),
        new DrawerItem(
          icon: 'action/account_balance',
          onPressed: () {
            showDialog(
              context: context,
              child: new Dialog(
                title: new Text('Not Implemented'),
                content: new Text('This feature has not yet been implemented.'),
                actions: <Widget>[
                  new FlatButton(
                    child: new Text('USE IT'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }
                  ),
                  new FlatButton(
                    child: new Text('OH WELL'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }
                  ),
                ]
              )
            );
          },
          child: new Text('Account Balance')
        ),
        new DrawerItem(
          icon: 'device/dvr',
          onPressed: () { debugDumpApp(); debugDumpRenderTree(); },
          child: new Text('Dump App to Console')
        ),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleStockModeChange(StockMode.optimistic),
          child: new Row(<Widget>[
            new Flexible(child: new Text('Optimistic')),
            new Radio<StockMode>(value: StockMode.optimistic, groupValue: config.stockMode, onChanged: _handleStockModeChange)
          ])
        ),
        new DrawerItem(
          icon: 'action/thumb_down',
          onPressed: () => _handleStockModeChange(StockMode.pessimistic),
          child: new Row(<Widget>[
            new Flexible(child: new Text('Pessimistic')),
            new Radio<StockMode>(value: StockMode.pessimistic, groupValue: config.stockMode, onChanged: _handleStockModeChange)
          ])
        ),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          child: new Text('Settings')),
        new DrawerItem(
          icon: 'action/help',
          child: new Text('Help & Feedback'))
      ])
    );
  }

  void _handleShowSettings() {
    Navigator.of(context)..pop()
                         ..pushNamed('/settings');
  }

  Widget buildToolBar() {
    return new ToolBar(
      elevation: 0,
      left: new IconButton(
        icon: "navigation/menu",
        onPressed: _showDrawer
      ),
      center: new Text('Stocks'),
      right: <Widget>[
        new IconButton(
          icon: "action/search",
          onPressed: _handleSearchBegin
        ),
        new IconButton(
          icon: "navigation/more_vert",
          onPressed: _handleMenuShow
        )
      ]
    );
  }

  int selectedTabIndex = 0;

  Iterable<Stock> _getStockList(Iterable<String> symbols) {
    return symbols.map((String symbol) => config.stocks[symbol])
        .where((Stock stock) => stock != null);
  }

  Iterable<Stock> _filterBySearchQuery(Iterable<Stock> stocks) {
    if (_searchQuery == null)
      return stocks;
    RegExp regexp = new RegExp(_searchQuery, caseSensitive: false);
    return stocks.where((Stock stock) => stock.symbol.contains(regexp));
  }

  Widget buildStockList(BuildContext context, Iterable<Stock> stocks) {
    return new StockList(
      stocks: stocks.toList(),
      onAction: (Stock stock, Key arrowKey) {
        setState(() {
          stock.percentChange = 100.0 * (1.0 / stock.lastSale);
          stock.lastSale += 1.0;
        });
        showModalBottomSheet(
          context: context,
          child: new StockSymbolBottomSheet(stock: stock)
        );
      },
      onOpen: (Stock stock, Key arrowKey) {
        Set<Key> mostValuableKeys = new Set<Key>();
        mostValuableKeys.add(arrowKey);
        Navigator.of(context).pushNamed('/stock/${stock.symbol}', mostValuableKeys: mostValuableKeys);
      },
      onShow: (Stock stock, Key arrowKey) {
        showBottomSheet(
          placeholderKey: _bottomSheetPlaceholderKey,
          context: context,
          child: new StockSymbolBottomSheet(stock: stock)
        );
      }
    );
  }

  static const List<String> portfolioSymbols = const <String>["AAPL","FIZZ", "FIVE", "FLAT", "ZINC", "ZNGA"];

  Widget buildTabNavigator() {
    return new TabNavigator(
      views: <TabNavigatorView>[
        new TabNavigatorView(
          label: const TabLabel(text: 'MARKET'),
          builder: (BuildContext context) => buildStockList(context, _filterBySearchQuery(_getStockList(config.symbols)).toList())
        ),
        new TabNavigatorView(
          label: const TabLabel(text: 'PORTFOLIO'),
          builder: (BuildContext context) => buildStockList(context, _filterBySearchQuery(_getStockList(portfolioSymbols)).toList())
        )
      ],
      selectedIndex: selectedTabIndex,
      onChanged: (int tabIndex) {
        setState(() { selectedTabIndex = tabIndex; } );
      }
    );
  }

  static GlobalKey searchFieldKey = new GlobalKey();

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Widget buildSearchBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/arrow_back",
        colorFilter: new ColorFilter.mode(Theme.of(context).accentColor, ui.TransferMode.srcATop),
        onPressed: _handleSearchEnd
      ),
      center: new Input(
        key: searchFieldKey,
        placeholder: 'Search stocks',
        onChanged: _handleSearchQueryChanged
      ),
      backgroundColor: Theme.of(context).canvasColor
    );
  }

  void _handleUndo() {
    Navigator.of(context).pop();
  }

  void _handleStockPurchased() {
    showSnackBar(
      context: context,
      placeholderKey: _snackBarPlaceholderKey,
      content: new Text("Stock purchased!"),
      actions: <SnackBarAction>[
        new SnackBarAction(label: "UNDO", onPressed: _handleUndo)
      ]
    );
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      child: new Icon(icon: 'content/add'),
      backgroundColor: Colors.redAccent[200],
      onPressed: _handleStockPurchased
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: _isSearching ? buildSearchBar() : buildToolBar(),
      body: buildTabNavigator(),
      snackBar: new Placeholder(key: _snackBarPlaceholderKey),
      bottomSheet: new Placeholder(key: _bottomSheetPlaceholderKey),
      floatingActionButton: buildFloatingActionButton()
    );
  }
}
