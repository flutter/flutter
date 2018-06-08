// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'shrine_types.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

const Vendor _ali = const Vendor(
  name: 'Ali’s shop',
  avatarAsset: '/Users/larche/flutter_gallery_assets/lib/people/square/ali.png',
//  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Ali Connor’s makes custom goods for folks of all shapes and sizes '
    'made by hand and sometimes by machine, but always with love and care. '
    'Custom orders are available upon request if you need something extra special.'
);

const Vendor _peter = const Vendor(
  name: 'Peter’s shop',
  avatarAsset: '/Users/larche/flutter_gallery_assets/lib/people/square/peter.png',
//  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Peter makes great stuff for awesome people like you. Super cool and extra '
    'awesome all of his shop’s goods are handmade with love. Custom orders are '
    'available upon request if you need something extra special.'
);

const Vendor _sandra = const Vendor(
    name: 'Sandra’s shop',
    avatarAsset: '/Users/larche/flutter_gallery_assets/lib/people/square/sandra.png',
//    avatarAssetPackage: _kGalleryAssetsPackage,
    description:
    'Sandra specializes in furniture, beauty and travel products with a classic vibe. '
        'Custom orders are available if you’re looking for a certain color or material.'
);

const Vendor _stella = const Vendor(
  name: 'Stella’s shop',
  avatarAsset: '/Users/larche/flutter_gallery_assets/lib/people/square/stella.png',
//  avatarAssetPackage: _kGalleryAssetsPackage,
  description:
    'Stella sells awesome stuff at lovely prices. made by hand and sometimes by '
    'machine, but always with love and care. Custom orders are available upon request '
    'if you need something extra special.'
);

const Vendor _trevor = const Vendor(
    name: 'Trevor’s shop',
    avatarAsset: '/Users/larche/flutter_gallery_assets/lib/people/square/trevor.png',
//    avatarAssetPackage: _kGalleryAssetsPackage,
    description:
    'Trevor makes great stuff for awesome people like you. Super cool and extra '
        'awesome all of his shop’s goods are handmade with love. Custom orders are '
        'available upon request if you need something extra special.'
);

const List<Product> _allProducts = const <Product> [
  const Product(
    name: 'Vintage Brown Belt',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/belt.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion', 'latest'],
    price: 300.00,
    vendor: _sandra,
    description:
      'Isn’t it cool when things look old, but they\'re not. Looks Old But Not makes '
      'awesome vintage goods that are super smart. This ol’ belt just got an upgrade. '
  ),
  const Product(
    name: 'Sunglasses',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/sunnies.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'fashion', 'beauty'],
    price: 20.00,
    vendor: _trevor,
    description:
      'Be an optimist. Carry Sunglasses with you at all times. All Tints and '
      'Shades products come with polarized lenses and super duper UV protection '
      'so you can look at the sun for however long you want. Sunglasses make you '
      'look cool, wear them.'
  ),
  const Product(
    name: 'Flatwear',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/flatwear.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['furniture'],
    price: 30.00,
    vendor: _trevor,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Salmon Sweater',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/sweater.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion'],
    price: 300.00,
    vendor: _stella,
    description:
      'Looks can be deceiving. This sweater comes in a wide variety of '
      'flavors, including salmon, that pop as soon as they hit your eyes. '
      'Sweaters heat quickly, so savor the warmth.'
  ),
  const Product(
    name: 'Pine Table',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/table.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['furniture'],
    price: 63.00,
    vendor: _stella,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Green Comfort Jacket',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/jacket.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion'],
    price: 36.00,
    vendor: _ali,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Chambray Top',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/top.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion'],
    price: 125.00,
    vendor: _peter,
    description:
      'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Blue Cup',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/cup.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'furniture'],
    price: 75.00,
    vendor: _sandra,
    description:
      'Drinksy has been making extraordinary mugs for decades. With each '
      'cup purchased Drinksy donates a cup to those in need. Buy yourself a mug, '
      'buy someone else a mug.'
  ),
  const Product(
    name: 'Tea Set',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/teaset.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['furniture', 'fashion'],
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
  const Product(
    name: 'Blue linen napkins',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/napkins.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['furniture', 'fashion'],
    price: 89.00,
    vendor: _trevor,
    description:
      'Blue linen napkins were meant to go with friends, so you may want to pick '
      'up a bunch of these. These things are absorbant.'
  ),
  const Product(
    name: 'Dipped Earrings',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/earrings.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion', 'beauty'],
    price: 25.00,
    vendor: _stella,
    description:
      'WeDipIt does it again. These hand-dipped 4 inch earrings are perfect for '
      'the office or the beach. Just be sure you don’t drop it in a bucket of '
      'red paint, then they won’t look dipped anymore.'
  ),
  const Product(
    name: 'Perfect Planters',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/planters.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['latest', 'furniture'],
    price: 30.00,
    vendor: _ali,
    description:
      'The Perfect Planter Co makes the best vessels for just about anything you '
      'can pot. This set of Perfect Planters holds succulents and cuttings perfectly. '
      'Looks great in any room. Keep out of reach from cats.'
  ),
  const Product(
    name: 'Cloud-White Dress',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/dress.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['fashion'],
    price: 54.00,
    vendor: _sandra,
    description:
      'Trying to find the perfect outift to match your mood? Try no longer. '
      'This Cloud-White Dress has you covered for those nights when you need '
      'to get out, or even if you’re just headed to work.'
  ),
  const Product(
    name: 'Backpack',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/backpack.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'fashion'],
    price: 25.00,
    vendor: _peter,
    description:
      'This backpack by Bags ‘n’ stuff can hold just about anything: a laptop, '
      'a pen, a protractor, notebooks, small animals, plugs for your devices, '
      'sunglasses, gym clothes, shoes, gloves, two kittens, and even lunch!'
  ),
  const Product(
    name: 'Charcoal Straw Hat',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/hat.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'fashion', 'latest'],
    price: 25.00,
    vendor: _ali,
    description:
      'This is the  helmet for those warm summer days on the road. '
      'Jetset approved, these hats have been rigorously tested. Keep that face '
      'protected from the sun.'
  ),
  const Product(
    name: 'Ginger Scarf',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/scarf.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['latest', 'fashion'],
    price: 17.00,
    vendor: _peter,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Blush Sweats',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/sweats.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'fashion', 'latest'],
    price: 25.00,
    vendor: _stella,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Mint Jumper',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/jumper.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>['travel', 'fashion', 'beauty'],
    price: 25.00,
    vendor: _peter,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  ),
  const Product(
    name: 'Ochre Shirt',
    imageAsset: '/Users/larche/flutter_gallery_assets/lib/products/shirt.png',
//    imageAssetPackage: _kGalleryAssetsPackage,
    categories: const <String>[ 'fashion', 'latest'],
    price: 120.00,
    vendor: _stella,
    description:
    'Leave the tunnel and the rain is fallin amazing things happen when you wait'
  )
];

List<Product> allProducts() {
  assert(_allProducts.every((Product product) => product.isValid()));
  return new List<Product>.unmodifiable(_allProducts);
}
