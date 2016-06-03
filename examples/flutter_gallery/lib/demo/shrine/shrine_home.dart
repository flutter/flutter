// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection' show HashSet;

import 'package:flutter/material.dart';

import 'shrine_data.dart';
import 'shrine_order.dart';
import 'shrine_page.dart';
import 'shrine_theme.dart';
import 'shrine_types.dart';

const double unitSize = kToolBarHeight;

Map<Product, Order> shoppingCart = <Product, Order>{};

/// Displays the Vendor's name and avatar.
class VendorItem extends StatelessWidget {
  VendorItem({ Key key, this.vendor }) : super(key: key) {
    assert(vendor != null);
  }

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      height: 24.0,
      child: new Row(
        children: <Widget>[
          new SizedBox(
            width: 24.0,
            child: new ClipRRect(
              xRadius: 12.0,
              yRadius: 12.0,
              child: new AssetImage(
                fit: ImageFit.cover,
                name: vendor.avatarAsset
              )
            )
          ),
          new SizedBox(width: 8.0),
          new Flexible(
            child: new Text(vendor.name, style: ShrineTheme.of(context).vendorItemStyle)
          )
        ]
      )
    );
  }
}

/// Displays the product's price. If the product is in the shopping cart the background
/// is highlighted.
class PriceItem extends StatelessWidget {
  PriceItem({ Key key, this.product }) : super(key: key) {
    assert(product != null);
  }

  final Product product;

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (shoppingCart[product] != null)
      decoration = new BoxDecoration(backgroundColor: const Color(0xFFFFE0E0));

    return new Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: decoration,
      child: new Text(product.priceString, style: ShrineTheme.of(context).priceStyle)
    );
  }
}

/// Layout the main left and right elements of a FeatureItem.
class FeatureLayout extends MultiChildLayoutDelegate {
  FeatureLayout();

  static final String left = 'left';
  static final String right = 'right';

  // Horizontally: the feature product image appears on the left and
  // occupies 50% of the available width; the feature product's
  // description apepars on the right and occupies 50% of the available
  // width + unitSize. The left and right widgets overlap and the right
  // widget is stacked on top.
  @override
  void performLayout(Size size) {
    final double halfWidth = size.width / 2.0;
    layoutChild(left, new BoxConstraints.tightFor(width: halfWidth, height: size.height));
    positionChild(left, Offset.zero);
    layoutChild(right, new BoxConstraints.expand(width: halfWidth + unitSize, height: size.height));
    positionChild(right, new Offset(halfWidth - unitSize, 0.0));
  }

  @override
  bool shouldRelayout(FeatureLayout oldDelegate) => false;
}

/// A card that highlights the "featured" catalog item.
class FeatureItem extends StatelessWidget {
  FeatureItem({ Key key, this.product }) : super(key: key) {
    assert(product.featureTitle != null);
    assert(product.featureDescription != null);
  }

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ShrineTheme theme = ShrineTheme.of(context);
    return new AspectRatio(
      aspectRatio: 3.0 / 3.5,
      child: new Material(
        type: MaterialType.card,
        elevation: 1,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new SizedBox(
              height: unitSize,
              child: new Align(
                alignment: FractionalOffset.topRight,
                child: new PriceItem(product: product)
              )
            ),
            new Flexible(
              child: new CustomMultiChildLayout(
                delegate: new FeatureLayout(),
                children: <Widget>[
                  new LayoutId(
                    id: FeatureLayout.left,
                    child: new ClipRect(
                      child: new OverflowBox(
                        minWidth: 340.0,
                        maxWidth: 340.0,
                        minHeight: 340.0,
                        maxHeight: 340.0,
                        alignment: FractionalOffset.topRight,
                        child: new NetworkImage(
                          fit: ImageFit.cover,
                          src: product.imageUrl
                        )
                      )
                    )
                  ),
                  new LayoutId(
                    id: FeatureLayout.right,
                    child: new Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Padding(
                            padding: const EdgeInsets.only(top: 18.0),
                            child: new Text(product.featureTitle, style: theme.featureTitleStyle)
                          ),
                          new Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: new Text(product.featureDescription, style: theme.featureStyle)
                          ),
                          new VendorItem(vendor: product.vendor)
                        ]
                      )
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}

/// A card that displays a product's image, price, and vendor.
class ProductItem extends StatelessWidget {
  ProductItem({ Key key, this.product, this.onPressed }) : super(key: key) {
    assert(product != null);
  }

  final Product product;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Column(
          children: <Widget>[
            new Align(
              alignment: FractionalOffset.centerRight,
              child: new PriceItem(product: product)
            ),
            new SizedBox(
              width: 144.0,
              height: 144.0,
              child: new Stack(
                children: <Widget>[
                  new Hero(
                    tag: productHeroTag,
                    key: new ObjectKey(product),
                    child: new NetworkImage(
                      fit: ImageFit.contain,
                      src: product.imageUrl
                    )
                  ),
                  new Material(
                    color: Theme.of(context).canvasColor.withAlpha(0x00),
                    child: new InkWell(onTap: onPressed)
                  ),
                ]
              )
            ),
            new VendorItem(vendor: product.vendor)
          ]
        )
      )
    );
  }
}

/// The Shrine app's home page. Displays the featured item above all of the
/// product items arranged in two columns.
class ShrineHome extends StatefulWidget {
  @override
  _ShrineHomeState createState() => new _ShrineHomeState();
}

class _ShrineHomeState extends State<ShrineHome> {
  final List<Product> _products = allProducts();

  void handleCompletedOrder(Order completedOrder) {
    assert(completedOrder.product != null);
    if (completedOrder.inCart && completedOrder.quantity > 0)
      shoppingCart[completedOrder.product] = completedOrder;
    else
      shoppingCart[completedOrder.product] = null;
  }

  void showOrderPage(Product product) {
    final Order order = shoppingCart[product] ?? new Order(product: product);
    final Completer<Order> completer = new Completer<Order>();
    final Key productKey = new ObjectKey(product);
    final Set<Key> mostValuableKeys = new HashSet<Key>();
    mostValuableKeys.add(productKey);
    Navigator.push(context, new ShrineOrderRoute(
      order: order,
      settings: new RouteSettings(mostValuableKeys: mostValuableKeys),
      completer: completer,
      builder: (BuildContext context) {
        return new OrderPage(
          order: order,
          products: _products
        );
      }
    ));
    completer.future.then(handleCompletedOrder);
  }

  @override
  Widget build(BuildContext context) {
    final Product featured = _products.firstWhere((Product product) => product.featureDescription != null);
    return new ShrinePage(
      body: new ScrollableViewport(
        child: new Column(
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.only(bottom: 8.0),
              child: new FeatureItem(product: featured)
            ),
            new FixedColumnCountGrid(
              columnCount: 2,
              rowSpacing: 8.0,
              columnSpacing: 8.0,
              padding: const EdgeInsets.all(8.0),
              tileAspectRatio: 160.0 / 216.0, // width/height
              children: _products.map((Product product) {
                return new ProductItem(
                  product: product,
                  onPressed: () { showOrderPage(product); }
                );
              }).toList()
            )
          ]
        )
      )
    );
  }
}
