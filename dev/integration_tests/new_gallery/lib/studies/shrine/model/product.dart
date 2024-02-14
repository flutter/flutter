// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

class Category {
  const Category({
    required this.name,
  });

  // A function taking a BuildContext as input and
  // returns the internationalized name of the category.
  final String Function(BuildContext) name;
}

Category categoryAll = Category(
  name: (context) => GalleryLocalizations.of(context)!.shrineCategoryNameAll,
);

Category categoryAccessories = Category(
  name: (context) =>
      GalleryLocalizations.of(context)!.shrineCategoryNameAccessories,
);

Category categoryClothing = Category(
  name: (context) =>
      GalleryLocalizations.of(context)!.shrineCategoryNameClothing,
);

Category categoryHome = Category(
  name: (context) => GalleryLocalizations.of(context)!.shrineCategoryNameHome,
);

List<Category> categories = [
  categoryAll,
  categoryAccessories,
  categoryClothing,
  categoryHome,
];

class Product {
  const Product({
    required this.category,
    required this.id,
    required this.isFeatured,
    required this.name,
    required this.price,
    this.assetAspectRatio = 1,
  });

  final Category category;
  final int id;
  final bool isFeatured;
  final double assetAspectRatio;

  // A function taking a BuildContext as input and
  // returns the internationalized name of the product.
  final String Function(BuildContext) name;

  final int price;

  String get assetName => '$id-0.jpg';

  String get assetPackage => 'shrine_images';
}
