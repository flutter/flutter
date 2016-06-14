// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'shrine_theme.dart';

enum ShrineAction {
  sortByPrice,
  sortByProduct,
  emptyCart
}

class ShrinePage extends StatefulWidget {
  ShrinePage({ Key key, this.scaffoldKey, this.body, this.floatingActionButton }) : super(key: key);

  final Key scaffoldKey;
  final Widget body;
  final Widget floatingActionButton;

  @override
  ShrinePageState createState() => new ShrinePageState();
}

/// Defines the Scaffold, AppBar, etc that the demo pages have in common.
class ShrinePageState extends State<ShrinePage> {
  int _appBarElevation = 0;

  bool _handleScrollNotification(ScrollNotification notification) {
    int elevation = notification.scrollable.scrollOffset <= 0.0 ? 0 : 1;
    if (elevation != _appBarElevation) {
      setState(() {
        _appBarElevation = elevation;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: config.scaffoldKey,
      appBar: new AppBar(
        elevation: _appBarElevation,
        backgroundColor: Theme.of(context).cardColor,
        flexibleSpace: new Container(
          decoration: new BoxDecoration(
            border: new Border(
              bottom: new BorderSide(color: const Color(0xFFD9D9D9))
            )
          )
        ),
        title: new Center(
          child: new Text('SHRINE', style: ShrineTheme.of(context).appBarTitleStyle)
        ),
        actions: <Widget>[
          new IconButton(
            icon: Icons.shopping_cart,
            tooltip: 'Shopping cart',
            onPressed: () {
              // TODO(hansmuller): implement the action.
            }
          ),
          new PopupMenuButton<ShrineAction>(
            itemBuilder: (BuildContext context) => <PopupMenuItem<ShrineAction>>[
              new PopupMenuItem<ShrineAction>(
                value: ShrineAction.sortByPrice,
                child: new Text('Sort by price')
              ),
              new PopupMenuItem<ShrineAction>(
                value: ShrineAction.sortByProduct,
                child: new Text('Sort by product')
              ),
              new PopupMenuItem<ShrineAction>(
                value: ShrineAction.emptyCart,
                child: new Text('Empty shopping cart')
              )
            ],
            onSelected: (ShrineAction action) {
              switch (action) {
                case ShrineAction.sortByPrice:
                  // TODO(hansmuller): implement the action.
                  break;
                case ShrineAction.sortByProduct:
                  // TODO(hansmuller): implement the action.
                  break;
                case ShrineAction.emptyCart:
                  // TODO(hansmuller): implement the action.
                  break;
              }
            }
          )
        ]
      ),
      floatingActionButton: config.floatingActionButton,
      body: new NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: config.body
      )
    );
  }
}
