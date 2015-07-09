// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/editing/input.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/animated_container.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/drawer.dart';
import 'package:sky/widgets/drawer_header.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/menu_divider.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/modal_overlay.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/popup_menu.dart';
import 'package:sky/widgets/radio.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tabs.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

import 'stock_data.dart';
import 'stock_list.dart';
import 'stock_menu.dart';
import 'stock_types.dart';

typedef void ModeUpdater(StockMode mode);

const Duration _kSnackbarSlideDuration = const Duration(milliseconds: 200);

class StockHome extends AnimatedComponent {

  StockHome(this.navigator, this.stocks, this.stockMode, this.modeUpdater) {
    // if (debug)
    //   new Timer(new Duration(seconds: 1), dumpState);
    _drawerController = new DrawerController(_handleDrawerStatusChanged);
  }

  Navigator navigator;
  List<Stock> stocks;
  StockMode stockMode;
  ModeUpdater modeUpdater;

  void syncFields(StockHome source) {
    navigator = source.navigator;
    stocks = source.stocks;
    stockMode = source.stockMode;
    modeUpdater = source.modeUpdater;
  }

  bool _isSearching = false;
  String _searchQuery;

  AnimatedContainer _snackbarTransform;

  void _handleSearchBegin() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
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

  DrawerController _drawerController;
  bool _drawerShowing = false;

  void _handleDrawerStatusChanged(bool showing) {
    if (!showing && navigator.currentRoute.name == "/drawer") {
      navigator.pop();
    }
    setState(() {
      _drawerShowing = showing;
    });
  }

  PopupMenuController _menuController;

  void _handleMenuShow() {
    setState(() {
      _menuController = new PopupMenuController();
      _menuController.open();
    });
  }

  void _handleMenuHide() {
    setState(() {
      _menuController.close().then((_) {
        setState(() {
          _menuController = null;
        });
      });
    });
  }

  bool _autorefresh = false;
  void _handleAutorefreshChanged(bool value) {
    setState(() {
      _autorefresh = value;
    });
  }

  void _handleStockModeChange(StockMode value) {
    setState(() {
      stockMode = value;
    });
    if (modeUpdater != null)
      modeUpdater(value);
  }

  Drawer buildDrawer() {
    return new Drawer(
      controller: _drawerController,
      level: 3,
      children: [
        new DrawerHeader(children: [new Text('Stocks')]),
        new MenuItem(
          icon: 'action/assessment',
          selected: true,
          children: [new Text('Stock List')]),
        new MenuItem(
          icon: 'action/account_balance',
          children: [new Text('Account Balance')]),
        new MenuDivider(),
        new MenuItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleStockModeChange(StockMode.optimistic),
          children: [
            new Flexible(child: new Text('Optimistic')),
            new Radio(value: StockMode.optimistic, groupValue: stockMode, onChanged: _handleStockModeChange)
          ]),
        new MenuItem(
          icon: 'action/thumb_down',
          onPressed: () => _handleStockModeChange(StockMode.pessimistic),
          children: [
            new Flexible(child: new Text('Pessimistic')),
            new Radio(value: StockMode.pessimistic, groupValue: stockMode, onChanged: _handleStockModeChange)
          ]),
        new MenuDivider(),
        new MenuItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          children: [new Text('Settings')]),
        new MenuItem(
          icon: 'action/help',
          children: [new Text('Help & Feedback')])
     ]
    );
  }

  void _handleShowSettings() {
    assert(navigator.currentRoute.name == '/drawer');
    navigator.pop();
    assert(navigator.currentRoute.name == '/');
    navigator.pushNamed('/settings');
  }

  void _handleOpenDrawer() {
    _drawerController.open();
    navigator.pushState("/drawer", (_) {
      _drawerController.close();
    });
  }

  Widget buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: 'navigation/menu_white',
          onPressed: _handleOpenDrawer),
        center: new Text('Stocks'),
        right: [
          new IconButton(
            icon: 'action/search_white',
            onPressed: _handleSearchBegin),
          new IconButton(
            icon: 'navigation/more_vert_white',
            onPressed: _handleMenuShow)
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

  Widget buildMarketStockList() {
    return new Stocklist(stocks: _filterBySearchQuery(stocks).toList());
  }

  Widget buildPortfolioStocklist() {
    return new Stocklist(stocks: _filterBySearchQuery(_filterByPortfolio(stocks)).toList());
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

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Widget buildSearchBar() {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back_grey600',
        onPressed: _handleSearchEnd),
      center: new Input(
        focused: true,
        placeholder: 'Search stocks',
        onChanged: _handleSearchQueryChanged),
      backgroundColor: Theme.of(this).canvasColor
    );
  }

  void _handleUndo() {
    setState(() {
      _snackbarTransform = null;
    });
  }

  Widget buildSnackBar() {
    if (_snackbarTransform == null)
      return null;
    return _snackbarTransform.build(
      new SnackBar(
        content: new Text("Stock purchased!"),
        actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)]
      ));
  }

  void _handleStockPurchased() {
    setState(() {
      _snackbarTransform = new AnimatedContainer()
        ..position = new AnimatedType<Point>(const Point(0.0, 45.0), end: Point.origin);
      var performance = _snackbarTransform.createPerformance(
          _snackbarTransform.position, duration: _kSnackbarSlideDuration);
      watchPerformance(performance);
      performance.play();
    });
  }

  Widget buildFloatingActionButton() {
    var widget = new FloatingActionButton(
      child: new Icon(type: 'content/add_white', size: 24),
      onPressed: _handleStockPurchased
    );
    if (_snackbarTransform != null)
      widget = _snackbarTransform.build(widget);
    return widget;
  }

  void addMenuToOverlays(List<Widget> overlays) {
    if (_menuController == null)
      return;
    overlays.add(new ModalOverlay(
      children: [new StockMenu(
        controller: _menuController,
        autorefresh: _autorefresh,
        onAutorefreshChanged: _handleAutorefreshChanged
      )],
      onDismiss: _handleMenuHide));
  }

  Widget build() {
    List<Widget> overlays = [
      new Scaffold(
        toolbar: _isSearching ? buildSearchBar() : buildToolBar(),
        body: buildTabNavigator(),
        snackBar: buildSnackBar(),
        floatingActionButton: buildFloatingActionButton(),
        drawer: _drawerShowing ? buildDrawer() : null
      ),
    ];
    addMenuToOverlays(overlays);
    return new Stack(overlays);
  }
}
