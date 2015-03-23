// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/components/action_bar.dart';
import 'package:sky/framework/components/drawer.dart';
import 'package:sky/framework/components/drawer_header.dart';
import 'package:sky/framework/components/floating_action_button.dart';
import 'package:sky/framework/components/icon.dart';
import 'package:sky/framework/components/input.dart';
import 'package:sky/framework/components/menu_divider.dart';
import 'package:sky/framework/components/menu_item.dart';
import 'package:sky/framework/components/popup_menu.dart';
import 'package:sky/framework/components/scaffold.dart';
import 'package:sky/framework/debug/tracing.dart';
import 'package:sky/framework/fn.dart';
import 'package:sky/framework/theme/typography.dart' as typography;
import 'stock_data.dart';
import 'stock_list.dart';
import 'stock_menu.dart';

class StocksApp extends App {

  DrawerController _drawerController = new DrawerController();
  PopupMenuController _menuController;

  static Style _iconStyle = new Style('''
    padding: 8px;'''
  );

  static Style _titleStyle = new Style('''
    padding-left: 24px;
    flex: 1;
    ${typography.white.title};'''
  );

  List<Stock> _sortedStocks = [];
  bool _isSearching = false;
  bool _isShowingMenu = false;
  String _searchQuery;

  StocksApp() : super() {
    fetchStockOracle().then((oracle) {
      setState(() {
        _sortedStocks = oracle.stocks;
        trace('StocksApp::sortStocks', () {
          _sortedStocks.sort((a, b) => a.symbol.compareTo(b.symbol));
        });
      });
    });
  }

  void _handleSearchClick(_) {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  void _handleMenuClick(_) {
    setState(() {
      _menuController = new PopupMenuController();
      _menuController.open();
    });
  }

  void _handleSearchQueryChanged(query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Node build() {
    var drawer = new Drawer(
      controller: _drawerController,
      level: 3,
      children: [
        new DrawerHeader(
          children: [new Text('Stocks')]
        ),
        new MenuItem(
          key: 'Inbox',
          icon: 'content/inbox',
          children: [new Text('Inbox')]
        ),
        new MenuDivider(
        ),
        new MenuItem(
          key: 'Drafts',
          icon: 'content/drafts',
          children: [new Text('Drafts')]
        ),
        new MenuItem(
          key: 'Settings',
          icon: 'action/settings',
          children: [new Text('Settings')]
        ),
        new MenuItem(
          key: 'Help & Feedback',
          icon: 'action/help',
          children: [new Text('Help & Feedback')]
        )
      ]
    );

    Node title;
    if (_isSearching) {
      title = new Input(focused: true, placeholder: 'Search stocks',
          onChanged: _handleSearchQueryChanged);
    } else {
      title = new Text('Stocks');
    }

    var actionBar = new ActionBar(
      children: [
        new EventTarget(
          new Icon(key: 'menu', style: _iconStyle,
              size: 24,
              type: 'navigation/menu_white'),
          onGestureTap: _drawerController.toggle
        ),
        new Container(
          style: _titleStyle,
          children: [title]
        ),
        new EventTarget(
          new Icon(key: 'search', style: _iconStyle,
              size: 24,
              type: 'action/search_white'),
          onGestureTap: _handleSearchClick
        ),
        new EventTarget(
          new Icon(key: 'more_white', style: _iconStyle,
              size: 24,
              type: 'navigation/more_vert_white'),
          onGestureTap: _handleMenuClick
        )
      ]
    );

    List<Node> overlays = [];

    if (_menuController != null) {
      overlays.add(new EventTarget(
        new StockMenu(controller: _menuController),
        onGestureTap: (_) {
          // TODO(abarth): We should close the menu when you tap away from the
          // menu rather than when you tap on the menu.
          setState(() {
            _menuController.close();
            _menuController = null;
          });
        }
      ));
    }

    return new Scaffold(
      actionBar: actionBar,
      content: new Stocklist(stocks: _sortedStocks, query: _searchQuery),
      fab: new FloatingActionButton(
        content: new Icon(type: 'content/add_white', size: 24), level: 3),
      drawer: drawer,
      overlays: overlays
    );
  }
}
