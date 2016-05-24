// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree, debugDumpLayerTree, debugDumpSemanticsTree;
import 'package:flutter/scheduler.dart' show timeDilation;
import 'stock_data.dart';
import 'stock_list.dart';
import 'stock_strings.dart';
import 'stock_symbol_viewer.dart';
import 'stock_types.dart';

typedef void ModeUpdater(StockMode mode);

enum _StockMenuItem { autorefresh, refresh, speedUp, speedDown }
enum StockHomeTab { market, portfolio }

class _NotImplementedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Dialog(
      title: new Text('Not Implemented'),
      content: new Text('This feature has not yet been implemented.'),
      actions: <Widget>[
        new FlatButton(
          child: new Row(
            children: <Widget>[
              new Icon(
                icon: Icons.dvr,
                size: 18.0
              ),
              new Container(
                width: 8.0
              ),
              new Text('DUMP APP TO CONSOLE'),
            ]
          ),
          onPressed: () { debugDumpApp(); }
        ),
        new FlatButton(
          child: new Text('OH WELL'),
          onPressed: () {
            Navigator.pop(context, false);
          }
        )
      ]
    );
  }
}

class StockHome extends StatefulWidget {
  const StockHome(this.stocks, this.symbols, this.configuration, this.updater);

  final Map<String, Stock> stocks;
  final List<String> symbols;
  final StockConfiguration configuration;
  final ValueChanged<StockConfiguration> updater;

  @override
  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  InputValue _searchQuery = InputValue.empty;
  bool _autorefresh = false;

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

  void _handleStockModeChange(StockMode value) {
    if (config.updater != null)
      config.updater(config.configuration.copyWith(stockMode: value));
  }

  void _handleStockMenu(BuildContext context, _StockMenuItem value) {
    switch(value) {
      case _StockMenuItem.autorefresh:
        setState(() {
          _autorefresh = !_autorefresh;
        });
        break;
      case _StockMenuItem.refresh:
        showDialog(
          context: context,
          child: new _NotImplementedDialog()
        );
        break;
      case _StockMenuItem.speedUp:
        timeDilation /= 5.0;
        break;
      case _StockMenuItem.speedDown:
        timeDilation *= 5.0;
        break;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
      child: new Block(children: <Widget>[
        new DrawerHeader(content: new Center(child: new Text('Stocks'))),
        new DrawerItem(
          icon: Icons.assessment,
          selected: true,
          child: new Text('Stock List')
        ),
        new DrawerItem(
          icon: Icons.account_balance,
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
          icon: Icons.dvr,
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
        new Divider(),
        new DrawerItem(
          icon: Icons.thumb_up,
          onPressed: () => _handleStockModeChange(StockMode.optimistic),
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Optimistic')),
              new Radio<StockMode>(value: StockMode.optimistic, groupValue: config.configuration.stockMode, onChanged: _handleStockModeChange)
            ]
          )
        ),
        new DrawerItem(
          icon: Icons.thumb_down,
          onPressed: () => _handleStockModeChange(StockMode.pessimistic),
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Pessimistic')),
              new Radio<StockMode>(value: StockMode.pessimistic, groupValue: config.configuration.stockMode, onChanged: _handleStockModeChange)
            ]
          )
        ),
        new Divider(),
        new DrawerItem(
          icon: Icons.settings,
          onPressed: _handleShowSettings,
          child: new Text('Settings')),
        new DrawerItem(
          icon: Icons.help,
          child: new Text('Help & Feedback'))
      ])
    );
  }

  void _handleShowSettings() {
    Navigator.popAndPushNamed(context, '/settings');
  }

  Widget buildAppBar() {
    return new AppBar(
      elevation: 0,
      title: new Text(StockStrings.of(context).title()),
      actions: <Widget>[
        new IconButton(
          icon: Icons.search,
          onPressed: _handleSearchBegin,
          tooltip: 'Search'
        ),
        new PopupMenuButton<_StockMenuItem>(
          onSelected: (_StockMenuItem value) { _handleStockMenu(context, value); },
          itemBuilder: (BuildContext context) => <PopupMenuItem<_StockMenuItem>>[
            new CheckedPopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.autorefresh,
              checked: _autorefresh,
              child: new Text('Autorefresh')
            ),
            new PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.refresh,
              child: new Text('Refresh')
            ),
            new PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedUp,
              child: new Text('Increase animation speed')
            ),
            new PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedDown,
              child: new Text('Decrease animation speed')
            )
          ]
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
    return new AppBar(
      leading: new IconButton(
        icon: Icons.arrow_back,
        color: Theme.of(context).accentColor,
        onPressed: _handleSearchEnd,
        tooltip: 'Back'
      ),
      title: new Input(
        value: _searchQuery,
        autofocus: true,
        hintText: 'Search stocks',
        onChanged: _handleSearchQueryChanged
      ),
      backgroundColor: Theme.of(context).canvasColor
    );
  }

  void _handleCreateCompany() {
    showModalBottomSheet/*<Null>*/(
      context: context,
      builder: (BuildContext context) => new _CreateCompanySheet()
    );
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      tooltip: 'Create company',
      child: new Icon(icon: Icons.add),
      backgroundColor: Colors.redAccent[200],
      onPressed: _handleCreateCompany
    );
  }

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<StockHomeTab>(
      values: <StockHomeTab>[StockHomeTab.market, StockHomeTab.portfolio],
      child: new Scaffold(
        key: _scaffoldKey,
        appBar: _isSearching ? buildSearchBar() : buildAppBar(),
        floatingActionButton: buildFloatingActionButton(),
        drawer: _buildDrawer(context),
        body: new TabBarView<StockHomeTab>(
          children: <Widget>[
            _buildStockTab(context, StockHomeTab.market, config.symbols),
            _buildStockTab(context, StockHomeTab.portfolio, portfolioSymbols),
          ]
        )
      )
    );
  }
}

class _CreateCompanySheet extends StatefulWidget {
  @override
  _CreateCompanySheetState createState() => new _CreateCompanySheetState();
}

class _CreateCompanySheetState extends State<_CreateCompanySheet> {
  InputValue _companyName = InputValue.empty;

  void _handleCompanyNameChanged(InputValue value) {
    setState(() {
      _companyName = value;
    });
  }

  @override
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
