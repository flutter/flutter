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
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) => false;
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
              child: new Image.asset(vendor.avatarAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8.0),
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

class FeatureImage extends StatelessWidget {
  FeatureImage({ Key key, this.product }) : super(key: key);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: new OverflowBox(
        alignment: FractionalOffset.topRight,
        child: new Image.asset(product.imageAsset, fit: BoxFit.cover),
      ),
    );
  }
}

/// Layout the main left and right elements of a FeatureItem.
class FeatureLayout extends MultiChildLayoutDelegate {
  FeatureLayout();

  static final String price = 'price';
  static final String image = 'image';
  static final String title = 'title';
  static final String description = 'description';
  static final String vendor = 'vendor';

  @override
  void performLayout(Size size) {
    final Size priceSize = layoutChild(price, new BoxConstraints.loose(size));
    positionChild(price, new Offset(size.width - priceSize.width, 0.0));

    final double halfWidth = size.width / 2.0;
    final double halfHeight = size.height / 2.0;
    final double halfUnit = unitSize / 2.0;
    const double margin = 16.0;

    final Size imageSize = layoutChild(image, new BoxConstraints.loose(size));
    final double imageX = imageSize.width < halfWidth - halfUnit
      ? halfWidth / 2.0 - imageSize.width / 2.0 - halfUnit
      : halfWidth - imageSize.width;
    positionChild(image, new Offset(imageX, halfHeight - imageSize.height / 2.0));

    final double maxTitleWidth = halfWidth + unitSize - margin;
    final BoxConstraints titleBoxConstraints = new BoxConstraints(maxWidth: maxTitleWidth);
    final Size titleSize = layoutChild(title, titleBoxConstraints);
    final double titleX = halfWidth - unitSize;
    final double titleY = halfHeight - titleSize.height;
    positionChild(title, new Offset(titleX, titleY));

    final Size descriptionSize = layoutChild(description, titleBoxConstraints);
    final double descriptionY = titleY + titleSize.height + margin;
    positionChild(description, new Offset(titleX, descriptionY));

    final Size vendorSize = layoutChild(vendor, titleBoxConstraints);
    final double vendorY = descriptionY + descriptionSize.height + margin;
    positionChild(vendor, new Offset(titleX, vendorY));
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
    final Size screenSize = MediaQuery.of(context).size;
    final ShrineTheme theme = ShrineTheme.of(context);
    return new AspectRatio(

      aspectRatio: screenSize.width > screenSize.height
        ? screenSize.width / (0.85 * screenSize.height - kToolbarHeight)
        : (0.75 * screenSize.height - kToolbarHeight) / screenSize.width,
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: theme.cardBackgroundColor,
          border: new Border(bottom: new BorderSide(color: theme.dividerColor)),
        ),
        child: new CustomMultiChildLayout(
          delegate: new FeatureLayout(),
          children: <Widget>[
            new LayoutId(
              id: FeatureLayout.price,
              child: new FeaturePriceItem(product: product),
            ),
            new LayoutId(
              id: FeatureLayout.image,
              child: new Image.asset(product.imageAsset, fit: BoxFit.cover),
            ),
            new LayoutId(
              id: FeatureLayout.title,
              child: new Text(product.featureTitle, style: theme.featureTitleStyle),
            ),
            new LayoutId(
              id: FeatureLayout.description,
              child: new Text(product.featureDescription, style: theme.featureStyle),
            ),
            new LayoutId(
              id: FeatureLayout.vendor,
              child: new VendorItem(vendor: product.vendor),
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
                    child: new Image.asset(product.imageAsset, fit: BoxFit.contain),
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
            sliver: new SliverGrid(
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
