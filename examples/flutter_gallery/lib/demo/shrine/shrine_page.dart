// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'shrine_theme.dart';
import 'shrine_types.dart';

enum ShrineAction {
  sortByPrice,
  sortByProduct,
  emptyCart
}

class ShrinePage extends StatefulWidget {
  ShrinePage({
    Key key,
    @required this.scaffoldKey,
    @required this.body,
    this.floatingActionButton,
    this.products,
    this.shoppingCart
  }) : assert(body != null),
       assert(scaffoldKey != null),
       super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget body;
  final Widget floatingActionButton;
  final List<Product> products;
  final Map<Product, Order> shoppingCart;

  @override
  ShrinePageState createState() => new ShrinePageState();
}

/// Defines the Scaffold, AppBar, etc that the demo pages have in common.
class ShrinePageState extends State<ShrinePage> {
  double _appBarElevation = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    final double elevation = notification.metrics.extentBefore <= 0.0 ? 0.0 : 1.0;
    if (elevation != _appBarElevation) {
      setState(() {
        _appBarElevation = elevation;
      });
    }
    return false;
  }

  void _showShoppingCart() {
    showModalBottomSheet<Null>(context: context, builder: (BuildContext context) {
      if (widget.shoppingCart.isEmpty) {
        return const Padding(
          padding: const EdgeInsets.all(24.0),
          child: const Text('The shopping cart is empty')
        );
      }
      return new ListView(
        padding: kMaterialListPadding,
        children: widget.shoppingCart.values.map((Order order) {
          return new ListTile(
            title: new Text(order.product.name),
            leading: new Text('${order.quantity}'),
            subtitle: new Text(order.product.vendor.name)
          );
        }).toList(),
      );
    });
  }

  void _sortByPrice() {
    widget.products.sort((Product a, Product b) => a.price.compareTo(b.price));
  }

  void _sortByProduct() {
    widget.products.sort((Product a, Product b) => a.name.compareTo(b.name));
  }

  void _emptyCart() {
    widget.shoppingCart.clear();
    widget.scaffoldKey.currentState.showSnackBar(const SnackBar(content: const Text('Shopping cart is empty')));
  }

  @override
  Widget build(BuildContext context) {
    final ShrineTheme theme = ShrineTheme.of(context);
    return new Scaffold(
      key: widget.scaffoldKey,
      appBar: new AppBar(
        elevation: _appBarElevation,
        backgroundColor: theme.appBarBackgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        brightness: Brightness.light,
        flexibleSpace: new Container(
          decoration: new BoxDecoration(
            border: new Border(
              bottom: new BorderSide(color: theme.dividerColor)
            )
          )
        ),
        title: new Center(
          child: new Text('SHRINE', style: ShrineTheme.of(context).appBarTitleStyle)
        ),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Shopping cart',
            onPressed: _showShoppingCart
          ),
          new PopupMenuButton<ShrineAction>(
            itemBuilder: (BuildContext context) => <PopupMenuItem<ShrineAction>>[
              const PopupMenuItem<ShrineAction>(
                value: ShrineAction.sortByPrice,
                child: const Text('Sort by price')
              ),
              const PopupMenuItem<ShrineAction>(
                value: ShrineAction.sortByProduct,
                child: const Text('Sort by product')
              ),
              const PopupMenuItem<ShrineAction>(
                value: ShrineAction.emptyCart,
                child: const Text('Empty shopping cart')
              )
            ],
            onSelected: (ShrineAction action) {
              switch (action) {
                case ShrineAction.sortByPrice:
                  setState(_sortByPrice);
                  break;
                case ShrineAction.sortByProduct:
                  setState(_sortByProduct);
                  break;
                case ShrineAction.emptyCart:
                  setState(_emptyCart);
                  break;
              }
            }
          )
        ]
      ),
      floatingActionButton: widget.floatingActionButton,
      body: new NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.body
      )
    );
  }
}
