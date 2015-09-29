// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

typedef void ModeUpdater(StockMode mode);

const Duration _kSnackbarSlideDuration = const Duration(milliseconds: 200);

class StockHome extends StatefulComponent {
  StockHome(this.navigator, this.stocks, this.stockMode, this.modeUpdater);

  final NavigatorState navigator;
  final List<Stock> stocks;
  final StockMode stockMode;
  final ModeUpdater modeUpdater;

  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {

  bool _isSearching = false;
  String _searchQuery;

  AnimationStatus _snackBarStatus = AnimationStatus.dismissed;
  bool _isSnackBarShowing = false;

  void _handleSearchBegin() {
    config.navigator.pushState(this, (_) {
      setState(() {
        _isSearching = false;
        _searchQuery = null;
      });
    });
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    assert(config.navigator.currentRoute is RouteState);
    assert((config.navigator.currentRoute as RouteState).owner == this); // TODO(ianh): remove cast once analyzer is cleverer
    config.navigator.pop();
    setState(() {
      _isSearching = false;
      _searchQuery = null;
    });
  }

  void _handleSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  bool _drawerShowing = false;
  AnimationStatus _drawerStatus = AnimationStatus.dismissed;

  void _handleOpenDrawer() {
    setState(() {
      _drawerShowing = true;
      _drawerStatus = AnimationStatus.forward;
    });
  }

  void _handleDrawerDismissed() {
    setState(() {
      _drawerStatus = AnimationStatus.dismissed;
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
    showStockMenu(config.navigator,
      autorefresh: _autorefresh,
      onAutorefreshChanged: _handleAutorefreshChanged
    );
  }

  Drawer buildDrawer() {
    if (_drawerStatus == AnimationStatus.dismissed)
      return null;
    assert(_drawerShowing); // TODO(mpcomplete): this is always true
    return new Drawer(
      level: 3,
      showing: _drawerShowing,
      onDismissed: _handleDrawerDismissed,
      navigator: config.navigator,
      children: [
        new DrawerHeader(child: new Text('Stocks')),
        new DrawerItem(
          icon: 'action/assessment',
          selected: true,
          child: new Text('Stock List')
        ),
        new DrawerItem(
          icon: 'action/account_balance',
          child: new Text('Account Balance')
        ),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleStockModeChange(StockMode.optimistic),
          child: new Row([
            new Flexible(child: new Text('Optimistic')),
            new Radio(value: StockMode.optimistic, groupValue: config.stockMode, onChanged: _handleStockModeChange)
          ])
        ),
        new DrawerItem(
          icon: 'action/thumb_down',
          onPressed: () => _handleStockModeChange(StockMode.pessimistic),
          child: new Row([
            new Flexible(child: new Text('Pessimistic')),
            new Radio(value: StockMode.pessimistic, groupValue: config.stockMode, onChanged: _handleStockModeChange)
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
     ]
    );
  }

  void _handleShowSettings() {
    config.navigator.pop();
    config.navigator.pushNamed('/settings');
  }

  Widget buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: "navigation/menu",
          onPressed: _handleOpenDrawer
        ),
        center: new Text('Stocks'),
        right: [
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
  List<String> portfolioSymbols = ["AAPL","FIZZ", "FIVE", "FLAT", "ZINC", "ZNGA"];

  Iterable<Stock> _filterByPortfolio(Iterable<Stock> stocks) {
    return stocks.where((stock) => portfolioSymbols.contains(stock.symbol));
  }

  Iterable<Stock> _filterBySearchQuery(Iterable<Stock> stocks) {
    if (_searchQuery == null)
      return stocks;
    RegExp regexp = new RegExp(_searchQuery, caseSensitive: false);
    return stocks.where((stock) => stock.symbol.contains(regexp));
  }

  Widget buildMarketStockList(BuildContext context) {
    return new Stocklist(stocks: _filterBySearchQuery(config.stocks).toList());
  }

  Widget buildPortfolioStocklist(BuildContext context) {
    return new Stocklist(stocks: _filterBySearchQuery(_filterByPortfolio(config.stocks)).toList());
  }

  Widget buildTabNavigator() {
    List<TabNavigatorView> views = <TabNavigatorView>[
      new TabNavigatorView(
        label: const TabLabel(text: 'MARKET'),
        builder: buildMarketStockList
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'PORTFOLIO'),
        builder: buildPortfolioStocklist
      )
    ];
    return new TabNavigator(
      views: views,
      selectedIndex: selectedTabIndex,
      onChanged: (tabIndex) {
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
        color: Theme.of(context).accentColor,
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
    setState(() {
      _isSnackBarShowing = false;
    });
  }

  GlobalKey snackBarKey = new GlobalKey(label: 'snackbar');
  Widget buildSnackBar() {
    if (_snackBarStatus == AnimationStatus.dismissed)
      return null;
    return new SnackBar(
      showing: _isSnackBarShowing,
      content: new Text("Stock purchased!"),
      actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)],
      onDismissed: () { setState(() { _snackBarStatus = AnimationStatus.dismissed; }); }
    );
  }

  void _handleStockPurchased() {
    setState(() {
      _isSnackBarShowing = true;
      _snackBarStatus = AnimationStatus.forward;
    });
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      child: new Icon(type: 'content/add', size: 24),
      backgroundColor: Colors.redAccent[200],
      onPressed: _handleStockPurchased
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolbar: _isSearching ? buildSearchBar() : buildToolBar(),
      body: buildTabNavigator(),
      snackBar: buildSnackBar(),
      floatingActionButton: buildFloatingActionButton(),
      drawer: buildDrawer()
    );
  }
}
