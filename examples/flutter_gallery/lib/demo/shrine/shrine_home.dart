// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'shrine_data.dart';
import 'shrine_order.dart';
import 'shrine_page.dart';
import 'shrine_theme.dart';
import 'shrine_types.dart';

const double unitSize = kToolbarHeight;

final List<Product> _products = new List<Product>.from(allProducts());
final Map<Product, Order> _shoppingCart = <Product, Order>{};

const int _childrenPerBlock = 8;
const int _rowsPerBlock = 5;

int _minIndexInRow(int rowIndex) {
  final int blockIndex = rowIndex ~/ _rowsPerBlock;
  return const <int>[0, 2, 4, 6, 7][rowIndex % _rowsPerBlock] + blockIndex * _childrenPerBlock;
}

int _maxIndexInRow(int rowIndex) {
  final int blockIndex = rowIndex ~/ _rowsPerBlock;
  return const <int>[1, 3, 5, 6, 7][rowIndex % _rowsPerBlock] + blockIndex * _childrenPerBlock;
}

int _rowAtIndex(int index) {
  final int blockCount = index ~/ _childrenPerBlock;
  return const <int>[0, 0, 1, 1, 2, 2, 3, 4][index - blockCount * _childrenPerBlock] + blockCount * _rowsPerBlock;
}

int _columnAtIndex(int index) {
  return const <int>[0, 1, 0, 1, 0, 1, 0, 0][index % _childrenPerBlock];
}

int _columnSpanAtIndex(int index) {
  return const <int>[1, 1, 1, 1, 1, 1, 2, 2][index % _childrenPerBlock];
}

// The Shrine home page arranges the product cards into two columns. The card
// on every 4th and 5th row spans two columns.
class ShrineGridLayout extends SliverGridLayout {
  const ShrineGridLayout({
    @required this.rowStride,
    @required this.columnStride,
    @required this.tileHeight,
    @required this.tileWidth,
  });

  final double rowStride;
  final double columnStride;
  final double tileHeight;
  final double tileWidth;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    return _minIndexInRow(scrollOffset ~/ rowStride);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    return _maxIndexInRow(scrollOffset ~/ rowStride);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final int row = _rowAtIndex(index);
    final int column = _columnAtIndex(index);
    final int columnSpan = _columnSpanAtIndex(index);
    return new SliverGridGeometry(
      scrollOffset: row * rowStride,
      crossAxisOffset: column * columnStride,
      mainAxisExtent: tileHeight,
      crossAxisExtent: tileWidth + (columnSpan - 1) * columnStride,
    );
  }

  @override
  double estimateMaxScrollOffset(int childCount) {
    if (childCount == null)
      return null;
    if (childCount == 0)
      return 0.0;
    final int rowCount = _rowAtIndex(childCount - 1) + 1;
    final double rowSpacing = rowStride - tileHeight;
    return rowStride * rowCount - rowSpacing;
  }
}

class ShrineGridDelegate extends SliverGridDelegate {
  static const double _kSpacing = 8.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double tileWidth = (constraints.crossAxisExtent - _kSpacing) / 2.0;
    final double tileHeight = 40.0 + 144.0 + 40.0;
    return new ShrineGridLayout(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      rowStride: tileHeight + _kSpacing,
      columnStride: tileWidth + _kSpacing,
    );
  }

  @override
  bool shouldRelayout(@checked SliverGridDelegate oldDelegate) => false;
}

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
              borderRadius: new BorderRadius.circular(12.0),
              child: new Image.asset(vendor.avatarAsset, fit: ImageFit.cover),
            ),
          ),
          new SizedBox(width: 8.0),
          new Expanded(
            child: new Text(vendor.name, style: ShrineTheme.of(context).vendorItemStyle),
          ),
        ],
      ),
    );
  }
}

/// Displays the product's price. If the product is in the shopping cart the background
/// is highlighted.
abstract class PriceItem extends StatelessWidget {
  PriceItem({ Key key, this.product }) : super(key: key) {
    assert(product != null);
  }

  final Product product;

  Widget buildItem(BuildContext context, TextStyle style, EdgeInsets padding) {
    BoxDecoration decoration;
    if (_shoppingCart[product] != null)
      decoration = new BoxDecoration(backgroundColor: ShrineTheme.of(context).priceHighlightColor);

    return new Container(
      padding: padding,
      decoration: decoration,
      child: new Text(product.priceString, style: style),
    );
  }
}

class ProductPriceItem extends PriceItem {
  ProductPriceItem({ Key key, Product product }) : super(key: key, product: product);

  @override
  Widget build(BuildContext context) {
    return buildItem(
      context,
      ShrineTheme.of(context).priceStyle,
      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}

class FeaturePriceItem extends PriceItem {
  FeaturePriceItem({ Key key, Product product }) : super(key: key, product: product);

  @override
  Widget build(BuildContext context) {
    return buildItem(
      context,
      ShrineTheme.of(context).featurePriceStyle,
      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: theme.cardBackgroundColor,
          border: new Border(bottom: new BorderSide(color: theme.dividerColor)),
        ),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new SizedBox(
              height: unitSize,
              child: new Align(
                alignment: FractionalOffset.topRight,
                child: new FeaturePriceItem(product: product),
              ),
            ),
            new Expanded(
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
                        child: new Image.asset(product.imageAsset, fit: ImageFit.cover),
                      ),
                    ),
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
                            child: new Text(product.featureTitle, style: theme.featureTitleStyle),
                          ),
                          new Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: new Text(product.featureDescription, style: theme.featureStyle),
                          ),
                          new VendorItem(vendor: product.vendor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      child: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              new Align(
                alignment: FractionalOffset.centerRight,
                child: new ProductPriceItem(product: product),
              ),
              new Container(
                width: 144.0,
                height: 144.0,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: new Hero(
                    tag: product.tag,
                    child: new Image.asset(product.imageAsset, fit: ImageFit.contain),
                  ),
                ),
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: new VendorItem(vendor: product.vendor),
              ),
            ],
          ),
          new Material(
            type: MaterialType.transparency,
            child: new InkWell(onTap: onPressed),
          ),
        ],
      ),
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
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>(debugLabel: 'Shrine Home');
  static final ShrineGridDelegate gridDelegate = new ShrineGridDelegate();

  Future<Null> showOrderPage(Product product) async {
    final Order order = _shoppingCart[product] ?? new Order(product: product);
    final Order completedOrder = await Navigator.push(context, new ShrineOrderRoute(
      order: order,
      builder: (BuildContext context) {
        return new OrderPage(
          order: order,
          products: _products,
          shoppingCart: _shoppingCart,
        );
      }
    ));
    assert(completedOrder.product != null);
    if (completedOrder.quantity == 0)
      _shoppingCart.remove(completedOrder.product);
  }

  @override
  Widget build(BuildContext context) {
    final Product featured = _products.firstWhere((Product product) => product.featureDescription != null);
    return new ShrinePage(
      scaffoldKey: scaffoldKey,
      products: _products,
      shoppingCart: _shoppingCart,
      body: new CustomScrollView(
        slivers: <Widget>[
          new SliverToBoxAdapter(
            child: new FeatureItem(product: featured),
          ),
          new SliverPadding(
            padding: const EdgeInsets.all(16.0),
            child: new SliverGrid(
              gridDelegate: gridDelegate,
              delegate: new SliverChildListDelegate(
                _products.map((Product product) {
                  return new ProductItem(
                    product: product,
                    onPressed: () { showOrderPage(product); },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
