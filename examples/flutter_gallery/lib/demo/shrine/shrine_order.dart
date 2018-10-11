// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../shrine_demo.dart' show ShrinePageRoute;
import 'shrine_page.dart';
import 'shrine_theme.dart';
import 'shrine_types.dart';

// Displays the product title's, description, and order quantity dropdown.
class _ProductItem extends StatelessWidget {
  const _ProductItem({
    Key key,
    @required this.product,
    @required this.quantity,
    @required this.onChanged,
  }) : assert(product != null),
       assert(quantity != null),
       assert(onChanged != null),
       super(key: key);

  final Product product;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ShrineTheme theme = ShrineTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(product.name, style: theme.featureTitleStyle),
        const SizedBox(height: 24.0),
        Text(product.description, style: theme.featureStyle),
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 88.0),
          child: DropdownButtonHideUnderline(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFD9D9D9),
                ),
              ),
              child: DropdownButton<int>(
                items: <int>[0, 1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('Quantity $value', style: theme.quantityMenuStyle),
                    ),
                  );
                }).toList(),
                value: quantity,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Vendor name and description
class _VendorItem extends StatelessWidget {
  const _VendorItem({ Key key, @required this.vendor })
    : assert(vendor != null),
      super(key: key);

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final ShrineTheme theme = ShrineTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 24.0,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(vendor.name, style: theme.vendorTitleStyle),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(vendor.description, style: theme.vendorStyle),
      ],
    );
  }
}

// Layout the order page's heading: the product's image, the
// title/description/dropdown product item, and the vendor item.
class _HeadingLayout extends MultiChildLayoutDelegate {
  _HeadingLayout();

  static const String image = 'image';
  static const String icon = 'icon';
  static const String product = 'product';
  static const String vendor = 'vendor';

  @override
  void performLayout(Size size) {
    const double margin = 56.0;
    final bool landscape = size.width > size.height;
    final double imageWidth = (landscape ? size.width / 2.0 : size.width) - margin * 2.0;
    final BoxConstraints imageConstraints = BoxConstraints(maxHeight: 224.0, maxWidth: imageWidth);
    final Size imageSize = layoutChild(image, imageConstraints);
    const double imageY = 0.0;
    positionChild(image, const Offset(margin, imageY));

    final double productWidth = landscape ? size.width / 2.0 : size.width - margin;
    final BoxConstraints productConstraints = BoxConstraints(maxWidth: productWidth);
    final Size productSize = layoutChild(product, productConstraints);
    final double productX = landscape ? size.width / 2.0 : margin;
    final double productY = landscape ? 0.0 : imageY + imageSize.height + 16.0;
    positionChild(product, Offset(productX, productY));

    final Size iconSize = layoutChild(icon, BoxConstraints.loose(size));
    positionChild(icon, Offset(productX - iconSize.width - 16.0, productY + 8.0));

    final double vendorWidth = landscape ? size.width - margin : productWidth;
    layoutChild(vendor, BoxConstraints(maxWidth: vendorWidth));
    final double vendorX = landscape ? margin : productX;
    final double vendorY = productY + productSize.height + 16.0;
    positionChild(vendor, Offset(vendorX, vendorY));
  }

  @override
  bool shouldRelayout(_HeadingLayout oldDelegate) => true;
}

// Describes a product and vendor in detail, supports specifying
// a order quantity (0-5). Appears at the top of the OrderPage.
class _Heading extends StatelessWidget {
  const _Heading({
    Key key,
    @required this.product,
    @required this.quantity,
    this.quantityChanged,
  }) : assert(product != null),
       assert(quantity != null && quantity >= 0 && quantity <= 5),
       super(key: key);

  final Product product;
  final int quantity;
  final ValueChanged<int> quantityChanged;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return SizedBox(
      height: (screenSize.height - kToolbarHeight) * 1.35,
      child: Material(
        type: MaterialType.card,
        elevation: 0.0,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 18.0, right: 16.0, bottom: 24.0),
          child: CustomMultiChildLayout(
            delegate: _HeadingLayout(),
            children: <Widget>[
              LayoutId(
                id: _HeadingLayout.image,
                child: Hero(
                  tag: product.tag,
                  child: Image.asset(
                    product.imageAsset,
                    package: product.imageAssetPackage,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              LayoutId(
                id: _HeadingLayout.icon,
                child: const Icon(
                  Icons.info_outline,
                  size: 24.0,
                  color: Color(0xFFFFE0E0),
                ),
              ),
              LayoutId(
                id: _HeadingLayout.product,
                child: _ProductItem(
                  product: product,
                  quantity: quantity,
                  onChanged: quantityChanged,
                ),
              ),
              LayoutId(
                id: _HeadingLayout.vendor,
                child: _VendorItem(vendor: product.vendor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  OrderPage({
    Key key,
    @required this.order,
    @required this.products,
    @required this.shoppingCart,
  }) : assert(order != null),
       assert(products != null && products.isNotEmpty),
       assert(shoppingCart != null),
       super(key: key);

  final Order order;
  final List<Product> products;
  final Map<Product, Order> shoppingCart;

  @override
  _OrderPageState createState() => _OrderPageState();
}

// Displays a product's heading above photos of all of the other products
// arranged in two columns. Enables the user to specify a quantity and add an
// order to the shopping cart.
class _OrderPageState extends State<OrderPage> {
  GlobalKey<ScaffoldState> scaffoldKey;

  @override
  void initState() {
    super.initState();
    scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'Shrine Order ${widget.order}');
  }

  Order get currentOrder => ShrineOrderRoute.of(context).order;

  set currentOrder(Order value) {
    ShrineOrderRoute.of(context).order = value;
  }

  void updateOrder({ int quantity, bool inCart }) {
    final Order newOrder = currentOrder.copyWith(quantity: quantity, inCart: inCart);
    if (currentOrder != newOrder) {
      setState(() {
        widget.shoppingCart[newOrder.product] = newOrder;
        currentOrder = newOrder;
      });
    }
  }

  void showSnackBarMessage(String message) {
    scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ShrinePage(
      scaffoldKey: scaffoldKey,
      products: widget.products,
      shoppingCart: widget.shoppingCart,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          updateOrder(inCart: true);
          final int n = currentOrder.quantity;
          final String item = currentOrder.product.name;
          showSnackBarMessage(
            'There ${ n == 1 ? "is one $item item" : "are $n $item items" } in the shopping cart.'
          );
        },
        backgroundColor: const Color(0xFF16F0F0),
        tooltip: 'Add to cart',
        child: const Icon(
          Icons.add_shopping_cart,
          color: Colors.black,
        ),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Heading(
              product: widget.order.product,
              quantity: currentOrder.quantity,
              quantityChanged: (int value) { updateOrder(quantity: value); },
            ),
          ),
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(8.0, 32.0, 8.0, 8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 248.0,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              delegate: SliverChildListDelegate(
                widget.products
                  .where((Product product) => product != widget.order.product)
                  .map((Product product) {
                    return Card(
                      elevation: 1.0,
                      child: Image.asset(
                        product.imageAsset,
                        package: product.imageAssetPackage,
                        fit: BoxFit.contain,
                      ),
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

// Displays a full-screen modal OrderPage.
//
// The order field will be replaced each time the user reconfigures the order.
// When the user backs out of this route the completer's value will be the
// final value of the order field.
class ShrineOrderRoute extends ShrinePageRoute<Order> {
  ShrineOrderRoute({
    @required this.order,
    WidgetBuilder builder,
    RouteSettings settings,
  }) : assert(order != null),
       super(builder: builder, settings: settings);

  Order order;

  @override
  Order get currentResult => order;

  static ShrineOrderRoute of(BuildContext context) => ModalRoute.of<Order>(context);
}
