// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

class Vendor {
  const Vendor({
    this.name,
    this.description,
    this.avatarAsset,
    this.avatarAssetPackage,
  });

  final String name;
  final String description;
  final String avatarAsset;
  final String avatarAssetPackage;

  bool isValid() {
    return name != null &&
      description != null &&
      avatarAsset != null;
  }

  @override
  String toString() => 'Vendor($name)';
}

class Product {
  const Product({
    this.name,
    this.description,
    this.featureTitle,
    this.featureDescription,
    this.imageAsset,
    this.imageAssetPackage,
    this.categories,
    this.price,
    this.vendor
  });

  final String name;
  final String description;
  final String featureTitle;
  final String featureDescription;
  final String imageAsset;
  final String imageAssetPackage;
  final List<String> categories;
  final double price;
  final Vendor vendor;

  String get tag => name; // Unique value for Heroes
  String get priceString => '\$${price.floor()}';

  bool isValid() {
    return name != null &&
      description != null &&
      imageAsset != null &&
      categories != null &&
      categories.isNotEmpty &&
      price != null &&
      vendor.isValid();
  }

  @override
  String toString() => 'Product($name)';
}

class Order {
  Order({ @required this.product, this.quantity = 1, this.inCart = false })
    : assert(product != null),
      assert(quantity != null && quantity >= 0),
      assert(inCart != null);

  final Product product;
  final int quantity;
  final bool inCart;

  Order copyWith({ Product product, int quantity, bool inCart }) {
    return Order(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      inCart: inCart ?? this.inCart
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final Order typedOther = other;
    return product == typedOther.product &&
           quantity == typedOther.quantity &&
           inCart == typedOther.inCart;
  }

  @override
  int get hashCode => hashValues(product, quantity, inCart);

  @override
  String toString() => 'Order($product, quantity=$quantity, inCart=$inCart)';
}
