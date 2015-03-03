library stocksapp;

import '../fn/lib/fn.dart';
import '../fn/widgets/widgets.dart';
import 'dart:collection';
import 'dart:math';
import 'dart:sky' as sky;

part 'companylist.dart';
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

  StocksApp() : super();

  Node render() {
    var drawer = new Drawer(
      onPositionChanged: _drawerAnimation.onPositionChanged,
      handleMaskFling: _drawerAnimation.handleFlingStart,
      handleMaskTap: _drawerAnimation.handleMaskTap,
      handlePointerCancel: _drawerAnimation.handlePointerCancel,
      handlePointerDown: _drawerAnimation.handlePointerDown,
      handlePointerMove: _drawerAnimation.handlePointerMove,
      handlePointerUp: _drawerAnimation.handlePointerUp,
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

    var toolbar = new Toolbar(
      children: [
        new Icon(key: 'menu', style: _iconStyle,
            onClick: _drawerAnimation.toggle,
            size: 24,
            type: 'navigation/menu_white'),
        new Container(
          style: _titleStyle,
          children: [new Text('I am a stocks app')]
        ),
        new Icon(key: 'search', style: _iconStyle,
            size: 24,
            type: 'action/search_white'),
        new Icon(key: 'more_white', style: _iconStyle,
            size: 24,
            type: 'navigation/more_vert_white')
      ]
    );

    return new Container(
      key: 'StocksApp',
      style: _style,
      children: [drawer, toolbar, new Stocklist(stocks: oracle.stocks)]
    );
  }
}
