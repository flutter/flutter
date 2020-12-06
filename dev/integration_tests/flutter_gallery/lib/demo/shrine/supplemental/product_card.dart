// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';
import 'package:flutter_gallery/demo/shrine/model/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({ this.imageAspectRatio = 33 / 49, this.product })
      : assert(imageAspectRatio == null || imageAspectRatio > 0);

  final double imageAspectRatio;
  final Product product;

  static const double kTextBoxHeight = 65.0;

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(
      decimalDigits: 0,
      locale: Localizations.localeOf(context).toString(),
    );

    final ThemeData theme = Theme.of(context);

    final Image imageWidget = Image.asset(
      product.assetName,
      package: product.assetPackage,
      fit: BoxFit.cover,
    );

    return ScopedModelDescendant<AppStateModel>(
      builder: (BuildContext context, Widget child, AppStateModel model) {
        return GestureDetector(
          onTap: () {
            model.addProductToCart(product.id);
          },
          child: child,
        );
      },
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AspectRatio(
                aspectRatio: imageAspectRatio,
                child: imageWidget,
              ),
              SizedBox(
                height: kTextBoxHeight * MediaQuery.of(context).textScaleFactor,
                width: 121.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      product == null ? '' : product.name,
                      style: theme.textTheme.button,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      product == null ? '' : formatter.format(product.price),
                      style: theme.textTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
    );
  }
}
