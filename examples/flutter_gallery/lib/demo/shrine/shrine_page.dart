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

/// Defines the Scaffold, AppBar, etc that the demo pages have in common.
class ShrinePage extends StatelessWidget {
  ShrinePage({ Key key, this.scaffoldKey, this.body, this.floatingActionButton }) : super(key: key);

  final Key scaffoldKey;
  final Widget body;
  final Widget floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Center(
          child: new Text('SHRINE', style: ShrineTheme.of(context).appBarTitleStyle)
        ),
        backgroundColor: Theme.of(context).canvasColor,
        actions: <Widget>[  // TODO(hansmuller): implement the actions.
          new IconButton(
            icon: Icons.shopping_cart,
            tooltip: 'Shopping cart',
            onPressed: () { /* activate the button for now */ }
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
            ]
          )
        ]
      ),
      floatingActionButton: floatingActionButton,
      body: body
    );
  }
}
