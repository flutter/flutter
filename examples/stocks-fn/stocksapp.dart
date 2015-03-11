library stocksapp;

import '../../framework/fn.dart';
import '../../framework/components/drawer.dart';
import '../../framework/components/drawer_header.dart';
import '../../framework/components/fixed_height_scrollable.dart';
import '../../framework/components/floating_action_button.dart';
import '../../framework/components/icon.dart';
import '../../framework/components/input.dart';
import '../../framework/components/material.dart';
import '../../framework/components/menu_divider.dart';
import '../../framework/components/menu_item.dart';
import '../../framework/components/toolbar.dart';
import '../data/stocks.dart';
import 'dart:math';

part 'stockarrow.dart';
part 'stocklist.dart';
part 'stockrow.dart';

class StocksApp extends App {

  DrawerAnimation _drawerAnimation = new DrawerAnimation();

  static Style _style = new Style('''
    display: flex;
    flex-direction: column;
    height: -webkit-fill-available;
    font-family: 'Roboto Regular', 'Helvetica';
    font-size: 16px;'''
  );

  static Style _iconStyle = new Style('''
    padding: 8px;
    margin: 0 4px;'''
  );

  static Style _titleStyle = new Style('''
    flex: 1;
    margin: 0 4px;'''
  );

  List<Stock> _sortedStocks;
  bool _isSearching = false;
  String _searchQuery;

  StocksApp() : super() {
    _sortedStocks = oracle.stocks;
    _sortedStocks.sort((a, b) => a.symbol.compareTo(b.symbol));
  }

  void _handleSearchClick(_) {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  void _handleSearchQueryChanged(query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Node build() {
    var drawer = new Drawer(
      animation: _drawerAnimation,
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
      title = new Text('I am a stocks app');
    }

    var toolbar = new Toolbar(
      children: [
        new Icon(key: 'menu', style: _iconStyle,
            size: 24,
            type: 'navigation/menu_white')
          ..events.listen('click', _drawerAnimation.toggle),
        new Container(
          style: _titleStyle,
          children: [title]
        ),
        new Icon(key: 'search', style: _iconStyle,
            size: 24,
            type: 'action/search_white')
          ..events.listen('click', _handleSearchClick),
        new Icon(key: 'more_white', style: _iconStyle,
            size: 24,
            type: 'navigation/more_vert_white')
      ]
    );

    var list = new Stocklist(stocks: _sortedStocks, query: _searchQuery);

    var fab = new FloatingActionButton(content: new Icon(
      type: 'content/add_white', size: 24));

    return new Container(
      key: 'StocksApp',
      children: [
        new Container(
          key: 'Content',
          style: _style,
          children: [toolbar, list]
        ),
        fab,
        drawer,
      ]
    );
  }
}
