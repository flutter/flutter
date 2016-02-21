// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree, debugDumpLayerTree, debugDumpSemanticsTree;

import 'stock_data.dart';
import 'stock_list.dart';
import 'stock_menu.dart';
import 'stock_strings.dart';
import 'stock_symbol_viewer.dart';
import 'stock_types.dart';

typedef void ModeUpdater(StockMode mode);

enum StockHomeTab { market, portfolio }

class StockHome extends StatefulComponent {
  const StockHome(this.stocks, this.symbols, this.configuration, this.updater);

  final Map<String, Stock> stocks;
  final List<String> symbols;
  final StockConfiguration configuration;
  final ValueChanged<StockConfiguration> updater;

  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  InputValue _searchQuery = InputValue.empty;

  void _handleSearchBegin() {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(
      onRemove: () {
        setState(() {
          _isSearching = false;
          _searchQuery = InputValue.empty;
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

  void _handleSearchQueryChanged(InputValue query) {
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
    if (config.updater != null)
      config.updater(config.configuration.copyWith(stockMode: value));
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
      child: new Block(children: <Widget>[
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
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: new Text('USE IT')
                  ),
                  new FlatButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: new Text('OH WELL')
                  ),
                ]
              )
            );
          },
          child: new Text('Account Balance')
        ),
        new DrawerItem(
          icon: 'device/dvr',
          onPressed: () {
            try {
              debugDumpApp();
              debugDumpRenderTree();
              debugDumpLayerTree();
              debugDumpSemanticsTree();
            } catch (e, stack) {
              debugPrint('Exception while dumping app:\n$e\n$stack');
            }
          },
          child: new Text('Dump App to Console')
        ),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleStockModeChange(StockMode.optimistic),
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Optimistic')),
              new Radio<StockMode>(value: StockMode.optimistic, groupValue: config.configuration.stockMode, onChanged: _handleStockModeChange)
            ]
          )
        ),
        new DrawerItem(
          icon: 'action/thumb_down',
          onPressed: () => _handleStockModeChange(StockMode.pessimistic),
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Pessimistic')),
              new Radio<StockMode>(value: StockMode.pessimistic, groupValue: config.configuration.stockMode, onChanged: _handleStockModeChange)
            ]
          )
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
          onPressed: _handleSearchBegin,
          tooltip: 'Search'
        ),
        new IconButton(
          icon: "navigation/more_vert",
          onPressed: _handleMenuShow,
          tooltip: 'Show menu'
        )
      ],
      tabBar: new TabBar<StockHomeTab>(
        labels: <StockHomeTab, TabLabel>{
          StockHomeTab.market: new TabLabel(text: StockStrings.of(context).market()),
          StockHomeTab.portfolio: new TabLabel(text: StockStrings.of(context).portfolio())
        }
      )
    );
  }

  Iterable<Stock> _getStockList(Iterable<String> symbols) {
    return symbols.map((String symbol) => config.stocks[symbol])
        .where((Stock stock) => stock != null);
  }

  Iterable<Stock> _filterBySearchQuery(Iterable<Stock> stocks) {
    if (_searchQuery.text.isEmpty)
      return stocks;
    RegExp regexp = new RegExp(_searchQuery.text, caseSensitive: false);
    return stocks.where((Stock stock) => stock.symbol.contains(regexp));
  }

  void _buyStock(Stock stock, Key arrowKey) {
    setState(() {
      stock.percentChange = 100.0 * (1.0 / stock.lastSale);
      stock.lastSale += 1.0;
    });
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text("Purchased ${stock.symbol} for ${stock.lastSale}"),
      action: new SnackBarAction(
        label: "BUY MORE",
        onPressed: () {
          _buyStock(stock, arrowKey);
        }
      )
    ));
  }

  Widget _buildStockList(BuildContext context, Iterable<Stock> stocks, StockHomeTab tab) {
    return new StockList(
      keySalt: tab,
      stocks: stocks.toList(),
      onAction: _buyStock,
      onOpen: (Stock stock, Key arrowKey) {
        Set<Key> mostValuableKeys = new HashSet<Key>();
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

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Widget buildSearchBar() {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back',
        color: Theme.of(context).accentColor,
        onPressed: _handleSearchEnd,
        tooltip: 'Back'
      ),
      center: new Input(
        value: _searchQuery,
        autofocus: true,
        hintText: 'Search stocks',
        onChanged: _handleSearchQueryChanged
      ),
      backgroundColor: Theme.of(context).canvasColor
    );
  }

  void _handleCreateCompany() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => new _CreateCompanySheet()
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
    return new TabBarSelection<StockHomeTab>(
      values: <StockHomeTab>[StockHomeTab.market, StockHomeTab.portfolio],
      child: new Scaffold(
        key: _scaffoldKey,
        toolBar: _isSearching ? buildSearchBar() : buildToolBar(),
        floatingActionButton: buildFloatingActionButton(),
        drawer: _buildDrawer(context),
        body: new TabBarView(
          children: <Widget>[
            _buildStockTab(context, StockHomeTab.market, config.symbols),
            _buildStockTab(context, StockHomeTab.portfolio, portfolioSymbols),
          ]
        )
      )
    );
  }
}

class _CreateCompanySheet extends StatefulComponent {
  _CreateCompanySheetState createState() => new _CreateCompanySheetState();
}

class _CreateCompanySheetState extends State<_CreateCompanySheet> {
  InputValue _companyName = InputValue.empty;

  void _handleCompanyNameChanged(InputValue value) {
    setState(() {
      _companyName = value;
    });
  }

  Widget build(BuildContext context) {
    // TODO(ianh): Fill this out.
    return new Column(
      children: <Widget>[
        new Input(
          autofocus: true,
          hintText: 'Company Name',
          value: _companyName,
          onChanged: _handleCompanyNameChanged
        ),
      ]
    );
  }
}
