// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/components2/tool_bar.dart';
// import 'package:sky/framework/components2/drawer.dart';
// import 'package:sky/framework/components2/drawer_header.dart';
// import 'package:sky/framework/components2/floating_action_button.dart';
// import 'package:sky/framework/components2/icon.dart';
import 'package:sky/framework/components2/icon_button.dart';
// import 'package:sky/framework/components2/input.dart';
// import 'package:sky/framework/components2/menu_divider.dart';
// import 'package:sky/framework/components2/menu_item.dart';
// import 'package:sky/framework/components2/modal_overlay.dart';
// import 'package:sky/framework/components2/popup_menu.dart';
// import 'package:sky/framework/components2/radio.dart';
import 'package:sky/framework/components2/scaffold.dart';
import 'package:sky/framework/fn2.dart';
import 'package:sky/framework/theme/typography.dart' as typography;
import 'package:sky/framework/theme/colors.dart';
import 'stock_data.dart';
import 'package:sky/framework/rendering/box.dart';
// import 'stock_list.dart';
// import 'stock_menu.dart';

import 'dart:async';
import 'dart:sky' as sky;

enum StockMode { Optimistic, Pessimistic }

class StocksApp extends App {

  // static final Style _searchBarStyle = new Style('''
  //   background-color: ${Grey[50]};''');

  // static final Style _titleStyle = new Style('''
  //   ${typography.white.title};''');

  List<Stock> _stocks = [];

  StocksApp() : super() {
    // if (debug)
    //   new Timer(new Duration(seconds: 1), dumpState);
    new StockDataFetcher((StockData data) {
      setState(() {
        data.appendTo(_stocks);
      });
    });
    // _drawerController = new DrawerController(_handleDrawerStatusChanged);
  }

  bool _isSearching = false;
  String _searchQuery;

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

  void _handleSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // DrawerController _drawerController;
  bool _drawerShowing = false;

  void _handleDrawerStatusChanged(bool showing) {
    setState(() {
      _drawerShowing = showing;
    });
  }

  // PopupMenuController _menuController;

  void _handleMenuShow(_) {
    setState(() {
      // _menuController = new PopupMenuController();
      // _menuController.open();
    });
  }

  void _handleMenuHide(_) {
    setState(() {
      // _menuController.close().then((_) {
      //   setState(() {
      //     _menuController = null;
      //   });
      // });
    });
  }

  bool _autorefresh = false;
  void _handleAutorefreshChanged(bool value) {
    setState(() {
      _autorefresh = value;
    });
  }

  StockMode _stockMode = StockMode.Optimistic;
  void _handleStockModeChange(StockMode value) {
    setState(() {
      _stockMode = value;
    });
  }

  // static FlexBoxParentData _flex1 = new FlexBoxParentData()..flex = 1;

  // Drawer buildDrawer() {
  //   return new Drawer(
  //     controller: _drawerController,
  //     level: 3,
  //     children: [
  //       new DrawerHeader(children: [new Text('Stocks')]),
  //       new MenuItem(
  //         key: 'Stock list',
  //         icon: 'action/assessment',
  //         children: [new Text('Stock List')]),
  //       new MenuItem(
  //         key: 'Account Balance',
  //         icon: 'action/account_balance',
  //         children: [new Text('Account Balance')]),
  //       new MenuDivider(key: 'div1'),
  //       new MenuItem(
  //         key: 'Optimistic Menu Item',
  //         icon: 'action/thumb_up',
  //         onGestureTap: (event) => _handleStockModeChange(StockMode.Optimistic),
  //         children: [
  //           new ParentDataNode(new Text('Optimistic'), _flex1),
  //           new Radio(key: 'optimistic-radio', value: StockMode.Optimistic, groupValue: _stockMode, onChanged: _handleStockModeChange)
  //         ]),
  //       new MenuItem(
  //         key: 'Pessimistic Menu Item',
  //         icon: 'action/thumb_down',
  //         onGestureTap: (event) => _handleStockModeChange(StockMode.Pessimistic),
  //         children: [
  //           new ParentDataNode(new Text('Pessimistic'), _flex1),
  //           new Radio(key: 'pessimistic-radio', value: StockMode.Pessimistic, groupValue: _stockMode, onChanged: _handleStockModeChange)
  //         ]),
  //       new MenuDivider(key: 'div2'),
  //       new MenuItem(
  //         key: 'Settings',
  //         icon: 'action/settings',
  //         children: [new Text('Settings')]),
  //       new MenuItem(
  //         key: 'Help & Feedback',
  //         icon: 'action/help',
  //         children: [new Text('Help & Feedback')])
  //     ]
  //   );
  // }

  UINode buildToolBar() {
    return new ToolBar(
        left: new IconButton(
          icon: 'navigation/menu_white',
          onGestureTap: (_) => true), // _drawerController.toggle),
        center: new Text('Stocks'),
        right: [
          new IconButton(
            icon: 'action/search_white',
            onGestureTap: _handleSearchBegin),
          new IconButton(
            icon: 'navigation/more_vert_white',
            onGestureTap: _handleMenuShow)
        ],
        backgroundColor: colorFromCSSHexColorString(Purple[500])
      );
  }

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  UINode buildSearchBar() {
    // return new StyleNode(
    //   new ToolBar(
    //     left: new IconButton(
    //       icon: 'navigation/arrow_back_grey600',
    //       onGestureTap: _handleSearchEnd),
    //     center: new Input(
    //       focused: true,
    //       placeholder: 'Search stocks',
    //       onChanged: _handleSearchQueryChanged)),
    //   _searchBarStyle);
  }

  // void addMenuToOverlays(List<UINode> overlays) {
  //   if (_menuController == null)
  //     return;
  //   overlays.add(new ModalOverlay(
  //     children: [new StockMenu(
  //       controller: _menuController,
  //       autorefresh: _autorefresh,
  //       onAutorefreshChanged: _handleAutorefreshChanged
  //     )],
  //     onDismiss: _handleMenuHide));
  // }

  UINode build() {
    // List<UINode> overlays = [];
    // addMenuToOverlays(overlays);
    return new Container(
      child: new BlockContainer(children: [buildToolBar()]),
      decoration: new BoxDecoration(
        backgroundColor: 0xFFFFFFFF
      )
    );

    // return new Scaffold(
    //    toolbar: _isSearching ? buildSearchBar() : buildToolBar()
    // ,
    //   body: new Stocklist(stocks: _stocks, query: _searchQuery),
    //   floatingActionButton: new FloatingActionButton(
    //     content: new Icon(type: 'content/add_white', size: 24), level: 3),
    //   drawer: _drawerShowing ? buildDrawer() : null,
    //   overlays: overlays
    // );
  }
}

void main() {
  print("starting stocks app!");
  new StocksApp();
}
