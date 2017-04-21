// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

// Each TabBarView contains a _Page and for each _Page there is a list
// of _CardData objects. Each _CardData object is displayed by a _CardItem.

class _Page {
  _Page({ this.label });
  final String label;
  String get id => label[0];
}

class _CardData {
  const _CardData({ this.title, this.imageAsset });
  final String title;
  final String imageAsset;
}

final Map<_Page, List<_CardData>> _allPages = <_Page, List<_CardData>>{
  new _Page(label: 'LEFT'): <_CardData>[
    const _CardData(
      title: 'Vintage Bluetooth Radio',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/radio.png',
    ),
    const _CardData(
      title: 'Sunglasses',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/sunnies.png',
    ),
    const _CardData(
      title: 'Clock',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/clock.png',
    ),
    const _CardData(
      title: 'Red popsicle',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/popsicle.png',
    ),
    const _CardData(
      title: 'Folding Chair',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/lawn_chair.png',
    ),
    const _CardData(
      title: 'Green comfort chair',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/chair.png',
    ),
  ],
  new _Page(label: 'RIGHT'): <_CardData>[
    const _CardData(
      title: 'Beachball',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/beachball.png',
    ),
    const _CardData(
      title: 'Old Binoculars',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/binoculars.png',
    ),
    const _CardData(
      title: 'Teapot',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/teapot.png',
    ),
    const _CardData(
      title: 'Blue suede shoes',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/chucks.png',
    ),
    const _CardData(
      title: 'Dipped Brush',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/brush.png',
    ),
    const _CardData(
      title: 'Perfect Goldfish Bowl',
      imageAsset: 'packages/flutter_gallery_assets/shrine/products/fish_bowl.png',
    ),
  ],
};

class _CardDataItem extends StatelessWidget {
  const _CardDataItem({ this.page, this.data });

  static final double height = 272.0;
  final _Page page;
  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Padding(
        padding: const EdgeInsets.all(16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Align(
              alignment: page.id == 'L'
                ? FractionalOffset.centerLeft
                : FractionalOffset.centerRight,
              child: new CircleAvatar(child: new Text('${page.id}')),
            ),
            new SizedBox(
              width: 144.0,
              height: 144.0,
              child: new Image.asset(data.imageAsset, fit: BoxFit.contain),
            ),
            new Center(
              child: new Text(data.title, style: Theme.of(context).textTheme.title),
            ),
          ],
        ),
      ),
    );
  }
}

class TabsDemo extends StatelessWidget {
  static const String routeName = '/material/tabs';

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: _allPages.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: const Text('Tabs and scrolling'),
          bottom: new TabBar(
            tabs: _allPages.keys.map((_Page page) => new Tab(text: page.label)).toList(),
          ),
        ),
        body: new TabBarView(
          children: _allPages.keys.map((_Page page) {
            return new ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              itemExtent: _CardDataItem.height,
              children: _allPages[page].map((_CardData data) {
                return new Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: new _CardDataItem(page: page, data: data),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
