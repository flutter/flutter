// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree, debugDumpLayerTree, debugDumpSemanticsTree, DebugSemanticsDumpOrder;
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
    return new AlertDialog(
      title: const Text('Not Implemented'),
      content: const Text('This feature has not yet been implemented.'),
      actions: <Widget>[
        new FlatButton(
          onPressed: debugDumpApp,
          child: new Row(
            children: <Widget>[
              const Icon(
                Icons.dvr,
                size: 18.0,
              ),
              new Container(
                width: 8.0,
              ),
              const Text('DUMP APP TO CONSOLE'),
            ],
          ),
        ),
        new FlatButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('OH WELL'),
        ),
      ],
    );
  }
}

class StockHome extends StatefulWidget {
  const StockHome(this.stocks, this.configuration, this.updater);

  final StockData stocks;
  final StockConfiguration configuration;
  final ValueChanged<StockConfiguration> updater;

  @override
  StockHomeState createState() => new StockHomeState();
}

class StockHomeState extends State<StockHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = new TextEditingController();
  bool _isSearching = false;
  bool _autorefresh = false;

  void _handleSearchBegin() {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(
      onRemove: () {
        setState(() {
          _isSearching = false;
          _searchQuery.clear();
        });
      },
    ));
    setState(() {
      _isSearching = true;
    });
  }

  void _handleStockModeChange(StockMode value) {
    if (widget.updater != null)
      widget.updater(widget.configuration.copyWith(stockMode: value));
  }

  void _handleStockMenu(BuildContext context, _StockMenuItem value) {
    switch (value) {
      case _StockMenuItem.autorefresh:
        setState(() {
          _autorefresh = !_autorefresh;
        });
        break;
      case _StockMenuItem.refresh:
        showDialog<Null>(
          context: context,
          builder: (BuildContext context) => new _NotImplementedDialog(),
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
      child: new ListView(
        children: <Widget>[
          const DrawerHeader(child: const Center(child: const Text('Stocks'))),
          const ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Stock List'),
            selected: true,
          ),
          const ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Account Balance'),
            enabled: false,
          ),
          new ListTile(
            leading: const Icon(Icons.dvr),
            title: const Text('Dump App to Console'),
            onTap: () {
              try {
                debugDumpApp();
                debugDumpRenderTree();
                debugDumpLayerTree();
                debugDumpSemanticsTree(DebugSemanticsDumpOrder.geometricOrder);
              } catch (e, stack) {
                debugPrint('Exception while dumping app:\n$e\n$stack');
              }
            },
          ),
          const Divider(),
          new ListTile(
            leading: const Icon(Icons.thumb_up),
            title: const Text('Optimistic'),
            trailing: new Radio<StockMode>(
              value: StockMode.optimistic,
              groupValue: widget.configuration.stockMode,
              onChanged: _handleStockModeChange,
            ),
            onTap: () {
              _handleStockModeChange(StockMode.optimistic);
            },
          ),
          new ListTile(
            leading: const Icon(Icons.thumb_down),
            title: const Text('Pessimistic'),
            trailing: new Radio<StockMode>(
              value: StockMode.pessimistic,
              groupValue: widget.configuration.stockMode,
              onChanged: _handleStockModeChange,
            ),
            onTap: () {
              _handleStockModeChange(StockMode.pessimistic);
            },
          ),
          const Divider(),
          new ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: _handleShowSettings,
          ),
          new ListTile(
            leading: const Icon(Icons.help),
            title: const Text('About'),
            onTap: _handleShowAbout,
          ),
        ],
      ),
    );
  }

  void _handleShowSettings() {
    Navigator.popAndPushNamed(context, '/settings');
  }

  void _handleShowAbout() {
    showAboutDialog(context: context);
  }

  Widget buildAppBar() {
    return new AppBar(
      elevation: 0.0,
      title: new Text(StockStrings.of(context).title()),
      actions: <Widget>[
        new IconButton(
          icon: const Icon(Icons.search),
          onPressed: _handleSearchBegin,
          tooltip: 'Search',
        ),
        new PopupMenuButton<_StockMenuItem>(
          onSelected: (_StockMenuItem value) { _handleStockMenu(context, value); },
          itemBuilder: (BuildContext context) => <PopupMenuItem<_StockMenuItem>>[
            new CheckedPopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.autorefresh,
              checked: _autorefresh,
              child: const Text('Autorefresh'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.refresh,
              child: const Text('Refresh'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedUp,
              child: const Text('Increase animation speed'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedDown,
              child: const Text('Decrease animation speed'),
            ),
          ],
        ),
      ],
      bottom: new TabBar(
        tabs: <Widget>[
          new Tab(text: StockStrings.of(context).market()),
          new Tab(text: StockStrings.of(context).portfolio()),
        ],
      ),
    );
  }

  static Iterable<Stock> _getStockList(StockData stocks, Iterable<String> symbols) {
    return symbols.map<Stock>((String symbol) => stocks[symbol])
        .where((Stock stock) => stock != null);
  }

  Iterable<Stock> _filterBySearchQuery(Iterable<Stock> stocks) {
    if (_searchQuery.text.isEmpty)
      return stocks;
    final RegExp regexp = new RegExp(_searchQuery.text, caseSensitive: false);
    return stocks.where((Stock stock) => stock.symbol.contains(regexp));
  }

  void _buyStock(Stock stock) {
    setState(() {
      stock.percentChange = 100.0 * (1.0 / stock.lastSale);
      stock.lastSale += 1.0;
    });
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text('Purchased ${stock.symbol} for ${stock.lastSale}'),
      action: new SnackBarAction(
        label: 'BUY MORE',
        onPressed: () {
          _buyStock(stock);
        },
      ),
    ));
  }

  Widget _buildStockList(BuildContext context, Iterable<Stock> stocks, StockHomeTab tab) {
    return new StockList(
      stocks: stocks.toList(),
      onAction: _buyStock,
      onOpen: (Stock stock) {
        Navigator.pushNamed(context, '/stock:${stock.symbol}');
      },
      onShow: (Stock stock) {
        _scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) => new StockSymbolBottomSheet(stock: stock));
      },
    );
  }

  Widget _buildStockTab(BuildContext context, StockHomeTab tab, List<String> stockSymbols) {
    return new AnimatedBuilder(
      key: new ValueKey<StockHomeTab>(tab),
      animation: new Listenable.merge(<Listenable>[_searchQuery, widget.stocks]),
      builder: (BuildContext context, Widget child) {
        return _buildStockList(context, _filterBySearchQuery(_getStockList(widget.stocks, stockSymbols)).toList(), tab);
      },
    );
  }

  static const List<String> portfolioSymbols = const <String>['AAPL','FIZZ', 'FIVE', 'FLAT', 'ZINC', 'ZNGA'];

  Widget buildSearchBar() {
    return new AppBar(
      leading: new BackButton(
        color: Theme.of(context).accentColor,
      ),
      title: new TextField(
        controller: _searchQuery,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search stocks',
        ),
      ),
      backgroundColor: Theme.of(context).canvasColor,
    );
  }

  void _handleCreateCompany() {
    showModalBottomSheet<Null>(
      context: context,
      builder: (BuildContext context) => new _CreateCompanySheet(),
    );
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      tooltip: 'Create company',
      child: const Icon(Icons.add),
      backgroundColor: Colors.redAccent,
      onPressed: _handleCreateCompany,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: 2,
      child: new Scaffold(
        key: _scaffoldKey,
        appBar: _isSearching ? buildSearchBar() : buildAppBar(),
        floatingActionButton: buildFloatingActionButton(),
        drawer: _buildDrawer(context),
        body: new TabBarView(
          children: <Widget>[
            _buildStockTab(context, StockHomeTab.market, widget.stocks.allSymbols),
            _buildStockTab(context, StockHomeTab.portfolio, portfolioSymbols),
          ],
        ),
      ),
    );
  }
}

class _CreateCompanySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(
      children: const <Widget>[
        const TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Company Name',
          ),
        ),
        const Text('(This demo is not yet complete.)'),
        // For example, we could add a button that actually updates the list
        // and then contacts the server, etc.
      ],
    );
  }
}
