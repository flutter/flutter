// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'shrine_types.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

const Vendor _ali = Vendor(
  name: 'Ali’s shop',
  avatarAsset: 'people/square/ali.png',
  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Ali Connor’s makes custom goods for folks of all shapes and sizes '
    'made by hand and sometimes by machine, but always with love and care. '
    'Custom orders are available upon request if you need something extra special.'
);

const Vendor _peter = Vendor(
  name: 'Peter’s shop',
  avatarAsset: 'people/square/peter.png',
  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Peter makes great stuff for awesome people like you. Super cool and extra '
    'awesome all of his shop’s goods are handmade with love. Custom orders are '
    'available upon request if you need something extra special.'
);

const Vendor _sandra = Vendor(
    name: 'Sandra’s shop',
    avatarAsset: 'people/square/sandra.png',
    avatarAssetPackage: _kGalleryAssetsPackage,
    description:
    'Sandra specializes in furniture, beauty and travel products with a classic vibe. '
        'Custom orders are available if you’re looking for a certain color or material.'
);

const Vendor _stella = Vendor(
  name: 'Stella’s shop',
  avatarAsset: 'people/square/stella.png',
  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Stella sells awesome stuff at lovely prices. made by hand and sometimes by '
    'machine, but always with love and care. Custom orders are available upon request '
    'if you need something extra special.'
);

const Vendor _trevor = Vendor(
    name: 'Trevor’s shop',
    avatarAsset: 'people/square/trevor.png',
    avatarAssetPackage: _kGalleryAssetsPackage,
    description:
    'Trevor makes great stuff for awesome people like you. Super cool and extra '
        'awesome all of his shop’s goods are handmade with love. Custom orders are '
        'available upon request if you need something extra special.'
);

const List<Product> _allProducts = <Product> [
  Product(
    name: 'Vintage Brown Belt',
    imageAsset: 'products/belt.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion', 'latest'],
    price: 300.00,
    vendor: _sandra,
    description:
      'Isn’t it cool when things look old, but they\'re not. Looks Old But Not makes '
      'awesome vintage goods that are super smart. This ol’ belt just got an upgrade. '
  ),
  Product(
    name: 'Sunglasses',
    imageAsset: 'products/sunnies.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'fashion', 'beauty'],
    price: 20.00,
    vendor: _trevor,
    description:
      'Be an optimist. Carry Sunglasses with you at all times. All Tints and '
      'Shades products come with polarized lenses and super duper UV protection '
      'so you can look at the sun for however long you want. Sunglasses make you '
      'look cool, wear them.'
  ),
  Product(
    name: 'Flatwear',
    imageAsset: 'products/flatwear.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['furniture'],
    price: 30.00,
    vendor: _trevor,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Salmon Sweater',
    imageAsset: 'products/sweater.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion'],
    price: 300.00,
    vendor: _stella,
    description:
      'Looks can be deceiving. This sweater comes in a wide variety of '
      'flavors, including salmon, that pop as soon as they hit your eyes. '
      'Sweaters heat quickly, so savor the warmth.'
  ),
  Product(
    name: 'Pine Table',
    imageAsset: 'products/table.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['furniture'],
    price: 63.00,
    vendor: _stella,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Green Comfort Jacket',
    imageAsset: 'products/jacket.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion'],
    price: 36.00,
    vendor: _ali,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Chambray Top',
    imageAsset: 'products/top.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion'],
    price: 125.00,
    vendor: _peter,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Blue Cup',
    imageAsset: 'products/cup.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'furniture'],
    price: 75.00,
    vendor: _sandra,
    description:
      'Drinksy has been making extraordinary mugs for decades. With each '
      'cup purchased Drinksy donates a cup to those in need. Buy yourself a mug, '
      'buy someone else a mug.'
  ),
  Product(
    name: 'Tea Set',
    imageAsset: 'products/teaset.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['furniture', 'fashion'],
    price: 70.00,
    vendor: _trevor,
    featureTitle: 'Beautiful glass teapot',
    featureDescription:
      'Teapot holds extremely hot liquids and pours them from the spout.',
    description:
      'Impress your guests with Tea Set by Kitchen Stuff. Teapot holds extremely '
      'hot liquids and pours them from the spout. Use the handle, shown on the right, '
      'so your fingers don’t get burnt while pouring.'
  ),
  Product(
    name: 'Blue linen napkins',
    imageAsset: 'products/napkins.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['furniture', 'fashion'],
    price: 89.00,
    vendor: _trevor,
    description:
      'Blue linen napkins were meant to go with friends, so you may want to pick '
      'up a bunch of these. These things are absorbant.'
  ),
  Product(
    name: 'Dipped Earrings',
    imageAsset: 'products/earrings.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion', 'beauty'],
    price: 25.00,
    vendor: _stella,
    description:
      'WeDipIt does it again. These hand-dipped 4 inch earrings are perfect for '
      'the office or the beach. Just be sure you don’t drop it in a bucket of '
      'red paint, then they won’t look dipped anymore.'
  ),
  Product(
    name: 'Perfect Planters',
    imageAsset: 'products/planters.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['latest', 'furniture'],
    price: 30.00,
    vendor: _ali,
    description:
      'The Perfect Planter Co makes the best vessels for just about anything you '
      'can pot. This set of Perfect Planters holds succulents and cuttings perfectly. '
      'Looks great in any room. Keep out of reach from cats.'
  ),
  Product(
    name: 'Cloud-White Dress',
    imageAsset: 'products/dress.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['fashion'],
    price: 54.00,
    vendor: _sandra,
    description:
      'Trying to find the perfect outift to match your mood? Try no longer. '
      'This Cloud-White Dress has you covered for those nights when you need '
      'to get out, or even if you’re just headed to work.'
  ),
  Product(
    name: 'Backpack',
    imageAsset: 'products/backpack.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'fashion'],
    price: 25.00,
    vendor: _peter,
    description:
      'This backpack by Bags ‘n’ stuff can hold just about anything: a laptop, '
      'a pen, a protractor, notebooks, small animals, plugs for your devices, '
      'sunglasses, gym clothes, shoes, gloves, two kittens, and even lunch!'
  ),
  Product(
    name: 'Charcoal Straw Hat',
    imageAsset: 'products/hat.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'fashion', 'latest'],
    price: 25.00,
    vendor: _ali,
    description:
      'This is the  helmet for those warm summer days on the road. '
      'Jetset approved, these hats have been rigorously tested. Keep that face '
      'protected from the sun.'
  ),
  Product(
    name: 'Ginger Scarf',
    imageAsset: 'products/scarf.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['latest', 'fashion'],
    price: 17.00,
    vendor: _peter,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Blush Sweats',
    imageAsset: 'products/sweats.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'fashion', 'latest'],
    price: 25.00,
    vendor: _stella,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Mint Jumper',
    imageAsset: 'products/jumper.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>['travel', 'fashion', 'beauty'],
    price: 25.00,
    vendor: _peter,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  Product(
    name: 'Ochre Shirt',
    imageAsset: 'products/shirt.png',
    imageAssetPackage: _kGalleryAssetsPackage,
    categories: <String>[ 'fashion', 'latest'],
    price: 120.00,
    vendor: _stella,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  )
];

List<Product> allProducts() {
  assert(_allProducts.every((Product product) => product.isValid()));
  return List<Product>.unmodifiable(_allProducts);
}
