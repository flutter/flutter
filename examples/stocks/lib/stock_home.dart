// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void ModeUpdater(StockMode mode);

enum StockHomeTab { market, portfolio }

class StockHome extends StatefulComponent {
  StockHome(this.stocks, this.symbols, this.stockMode, this.modeUpdater);

  final Map<String, Stock> stocks;
  final List<String> symbols;
  final StockMode stockMode;
  final ModeUpdater modeUpdater;

  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  String _searchQuery;
  TabBarSelection _tabBarSelection;

  void initState() {
    super.initState();
    _tabBarSelection = PageStorage.of(context)?.readState(context);
    if (_tabBarSelection == null) {
      _tabBarSelection = new TabBarSelection();
      PageStorage.of(context)?.writeState(context, _tabBarSelection);
    }
  }

  void _handleSearchBegin() {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(
      onRemove: () {
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
    Navigator.pop(context);
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

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
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
                      Navigator.pop(context, false);
                    }
                  ),
                  new FlatButton(
                    child: new Text('OH WELL'),
                    onPressed: () {
                      Navigator.pop(context, false);
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
          onPressed: () { debugDumpApp(); debugDumpRenderTree(); debugDumpLayerTree(); },
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
    Navigator.popAndPushNamed(context, '/settings');
  }

  Widget buildToolBar() {
    return new ToolBar(
      elevation: 0,
      center: new Text(StockStrings.of(context).title()),
      right: <Widget>[
        new IconButton(
          icon: "action/search",
          onPressed: _handleSearchBegin
        ),
        new IconButton(
          icon: "navigation/more_vert",
          onPressed: _handleMenuShow
        )
      ],
      tabBar: new TabBar(
        selection: _tabBarSelection,
        labels: <TabLabel>[
          new TabLabel(text: StockStrings.of(context).market()),
          new TabLabel(text: StockStrings.of(context).portfolio())
        ]
      )
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

  void _buyStock(Stock stock, Key arrowKey) {
    setState(() {
      stock.percentChange = 100.0 * (1.0 / stock.lastSale);
      stock.lastSale += 1.0;
    });
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text("Purchased ${stock.symbol} for ${stock.lastSale}"),
      actions: <SnackBarAction>[
        new SnackBarAction(label: "BUY MORE", onPressed: () { _buyStock(stock, arrowKey); })
      ]
    ));
  }

  Widget _buildStockList(BuildContext context, Iterable<Stock> stocks, StockHomeTab tab) {
    return new StockList(
      keySalt: tab,
      stocks: stocks.toList(),
      onAction: _buyStock,
      onOpen: (Stock stock, Key arrowKey) {
        Set<Key> mostValuableKeys = new Set<Key>();
        mostValuableKeys.add(arrowKey);
        Navigator.pushNamed(context, '/stock/${stock.symbol}', mostValuableKeys: mostValuableKeys);
      },
      onShow: (Stock stock, Key arrowKey) {
        _scaffoldKey.currentState.showBottomSheet((BuildContext context) => new StockSymbolBottomSheet(stock: stock));
      }
    );
  }

  Widget _buildStockTab(BuildContext context, StockHomeTab tab, List<String> stockSymbols) {
    return new Container(
      key: new ValueKey<StockHomeTab>(tab),
      child: _buildStockList(context, _filterBySearchQuery(_getStockList(stockSymbols)).toList(), tab)
    );
  }

  static const List<String> portfolioSymbols = const <String>["AAPL","FIZZ", "FIVE", "FLAT", "ZINC", "ZNGA"];

  static GlobalKey searchFieldKey = new GlobalKey();
  static GlobalKey companyNameKey = new GlobalKey();

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Widget buildSearchBar() {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back',
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

  void _handleCreateCompany() {
    showModalBottomSheet(
      // TODO(ianh): Fill this out.
      context: context,
      builder: (BuildContext context) {
        return new Column([
          new Input(
            key: companyNameKey,
            placeholder: 'Company Name'
          ),
        ]);
      }
    );
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      child: new Icon(icon: 'content/add'),
      backgroundColor: Colors.redAccent[200],
      onPressed: _handleCreateCompany
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      toolBar: _isSearching ? buildSearchBar() : buildToolBar(),
      floatingActionButton: buildFloatingActionButton(),
      drawer: _buildDrawer(context),
      body: new TabBarView<StockHomeTab>(
        selection: _tabBarSelection,
        items: <StockHomeTab>[StockHomeTab.market, StockHomeTab.portfolio],
        itemBuilder: (BuildContext context, StockHomeTab tab, _) {
          switch (tab) {
            case StockHomeTab.market:
              return _buildStockTab(context, tab, config.symbols);
            case StockHomeTab.portfolio:
              return _buildStockTab(context, tab, portfolioSymbols);
            default:
              assert(false);
          }
        }
      )
    );
  }
}
