// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/components/action_bar.dart';
import 'package:sky/framework/components/drawer.dart';
import 'package:sky/framework/components/drawer_header.dart';
import 'package:sky/framework/components/floating_action_button.dart';
import 'package:sky/framework/components/icon.dart';
import 'package:sky/framework/components/icon_button.dart';
import 'package:sky/framework/components/input.dart';
import 'package:sky/framework/components/menu_divider.dart';
import 'package:sky/framework/components/menu_item.dart';
import 'package:sky/framework/components/popup_menu.dart';
import 'package:sky/framework/components/scaffold.dart';
import 'package:sky/framework/debug/tracing.dart';
import 'package:sky/framework/fn.dart';
import 'package:sky/framework/theme/typography.dart' as typography;
import 'package:sky/framework/theme/colors.dart';
import 'stock_data.dart';
import 'stock_list.dart';
import 'stock_menu.dart';

class StocksApp extends App {
  DrawerController _drawerController = new DrawerController();
  PopupMenuController _menuController;

  static final Style _actionBarStyle = new Style('''
    background-color: ${Purple[500]};''');

  static final Style _searchBarStyle = new Style('''
    background-color: ${Grey[50]};''');

  static final Style _titleStyle = new Style('''
    ${typography.white.title};''');

  StockDataFetcher _stockDataFetcher;
  List<Stock> _stocks = [];
  bool _isSearching = false;
  bool _isShowingMenu = false;
  String _searchQuery;

  StocksApp() : super() {
    _stockDataFetcher = new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks);
      });
    });
  }

  void _handleSearchBegin(_) {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd(_) {
    setState(() {
      _isSearching = false;
      _searchQuery = null;
    });
  }

  void _handleSearchQueryChanged(query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _handleMenuClick(_) {
    setState(() {
      _menuController = new PopupMenuController();
      _menuController.open();
    });
  }

  Drawer buildDrawer() {
    return new Drawer(
      controller: _drawerController,
      level: 3,
      children: [
        new DrawerHeader(children: [new Text('Stocks')]),
        new MenuItem(
          key: 'Inbox',
          icon: 'content/inbox',
          children: [new Text('Inbox')]),
        new MenuDivider(),
        new MenuItem(
          key: 'Drafts',
          icon: 'content/drafts',
          children: [new Text('Drafts')]),
        new MenuItem(
          key: 'Settings',
          icon: 'action/settings',
          children: [new Text('Settings')]),
        new MenuItem(
          key: 'Help & Feedback',
          icon: 'action/help',
          children: [new Text('Help & Feedback')])
      ]
    );
  }

  Node buildActionBar() {
    return new StyleNode(
      new ActionBar(
        left: new IconButton(
          icon: 'navigation/menu_white',
          onGestureTap: _drawerController.toggle),
        center: new Container(
          style: _titleStyle,
          children: [new Text('Stocks')]),
        right: [
          new IconButton(
            icon: 'action/search_white',
            onGestureTap: _handleSearchBegin),
          new IconButton(
            icon: 'navigation/more_vert_white',
            onGestureTap: _handleMenuClick)
        ]),
      _actionBarStyle);
  }

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Node buildSearchBar() {
    return new StyleNode(
      new ActionBar(
        left: new IconButton(
          icon: 'navigation/arrow_back_grey600',
          onGestureTap: _handleSearchEnd),
        center: new Input(
          focused: true,
          placeholder: 'Search stocks',
          onChanged: _handleSearchQueryChanged)),
      _searchBarStyle);
  }

  Node build() {
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
      header: _isSearching ? buildSearchBar() : buildActionBar(),
      content: new Stocklist(stocks: _stocks, query: _searchQuery),
      fab: new FloatingActionButton(
        content: new Icon(type: 'content/add_white', size: 24), level: 3),
      drawer: buildDrawer(),
      overlays: overlays
    );
  }
}
