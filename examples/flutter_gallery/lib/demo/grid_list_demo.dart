// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../gallery/demo.dart';

const String _kExampleCode = 'gridlists';

enum GridDemoTileStyle {
  imageOnly,
  oneLine,
  twoLine
}

class Photo {
  Photo({ this.assetName, this.title, this.caption, this.isFavorite: false });

  final String assetName;
  final String title;
  final String caption;

  bool isFavorite;

  bool get isValid => assetName != null && title != null && caption != null && isFavorite != null;
}

const String photoHeroTag = 'Photo';

typedef void BannerTapCallback(Photo photo);

class GridDemoPhotoItem extends StatelessWidget {
  GridDemoPhotoItem({
    Key key,
    this.photo,
    this.tileStyle,
    this.onBannerTap
  }) : super(key: key) {
    assert(photo != null && photo.isValid);
    assert(tileStyle != null);
    assert(onBannerTap != null);
  }

  final Photo photo;
  final GridDemoTileStyle tileStyle;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.

  void showPhoto(BuildContext context) {
    Key photoKey = new Key(photo.assetName);
    Set<Key> mostValuableKeys = new HashSet<Key>();
    mostValuableKeys.add(photoKey);

    Navigator.push(context, new MaterialPageRoute<Null>(
      settings: new RouteSettings(
        mostValuableKeys: mostValuableKeys
      ),
      builder: (BuildContext context) {
        return new Scaffold(
          appBar: new AppBar(
            title: new Text(photo.title)
          ),
          body: new Material(
            child: new Hero(
              tag: photoHeroTag,
              child: new AssetImage(
                name: photo.assetName,
                fit: ImageFit.cover
              )
            )
          )
        );
      }
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = new GestureDetector(
      onTap: () { showPhoto(context); },
      child: new Hero(
        key: new Key(photo.assetName),
        tag: photoHeroTag,
        child: new AssetImage(
          name: photo.assetName,
          fit: ImageFit.cover
        )
      )
    );

    IconData icon = photo.isFavorite ? Icons.star : Icons.star_border;

    switch(tileStyle) {
      case GridDemoTileStyle.imageOnly:
        return image;

      case GridDemoTileStyle.oneLine:
        return new GridTile(
          header: new GestureDetector(
            onTap: () { onBannerTap(photo); },
            child: new GridTileBar(
              title: new Text(photo.title),
              backgroundColor: Colors.black45,
              leading: new Icon(
                icon: icon,
                color: Colors.white
              )
            )
          ),
          child: image
        );

      case GridDemoTileStyle.twoLine:
        return new GridTile(
          footer: new GestureDetector(
            onTap: () { onBannerTap(photo); },
            child: new GridTileBar(
              backgroundColor: Colors.black45,
              title: new Text(photo.title),
              subtitle: new Text(photo.caption),
              trailing: new Icon(
                icon: icon,
                color: Colors.white
              )
            )
          ),
          child: image
        );
    }
    assert(tileStyle != null);
    return null;
  }
}

class GridListDemo extends StatefulWidget {
  GridListDemo({ Key key }) : super(key: key);

  static const String routeName = '/grid-list';

  @override
  GridListDemoState createState() => new GridListDemoState();
}

class GridListDemoState extends State<GridListDemo> {
  GridDemoTileStyle tileStyle = GridDemoTileStyle.twoLine;

  List<Photo> photos = <Photo>[
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_0.jpg',
      title: 'Philippines',
      caption: 'Batad rice terraces'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_1.jpg',
      title: 'Italy',
      caption: 'Ceresole Reale'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_2.jpg',
      title: 'Somewhere',
      caption: 'Beautiful mountains'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_3.jpg',
      title: 'A place',
      caption: 'Beautiful hills'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_4.jpg',
      title: 'New Zealand',
      caption: 'View from the van'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_5.jpg',
      title: 'Autumn',
      caption: 'The golden season'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_6.jpg',
      title: 'Germany',
      caption: 'Englischer Garten'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_7.jpg',
      title: 'A country',
      caption: 'Grass fields'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_8.jpg',
      title: 'Mountain country',
      caption: 'River forest'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_9.jpg',
      title: 'Alpine place',
      caption: 'Green hills'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_10.jpg',
      title: 'Desert land',
      caption: 'Blue skies'
    ),
    new Photo(
      assetName: 'packages/flutter_gallery_assets/landscape_11.jpg',
      title: 'Narnia',
      caption: 'Rocks and rivers'
    ),
  ];

  void changeTileStyle(GridDemoTileStyle value) {
    setState(() {
      tileStyle = value;
    });
  }

  // When the ScrollableGrid first appears we want the last row to only be
  // partially visible, to help the user recognize that the grid is scrollable.
  // The GridListDemoGridDelegate's tileHeightFactor is used for this.
  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Grid list'),
        actions: <Widget>[
          new PopupMenuButton<GridDemoTileStyle>(
            onSelected: changeTileStyle,
            itemBuilder: (BuildContext context) => <PopupMenuItem<GridDemoTileStyle>>[
              new PopupMenuItem<GridDemoTileStyle>(
                value: GridDemoTileStyle.imageOnly,
                child: new Text('Image only')
              ),
              new PopupMenuItem<GridDemoTileStyle>(
                value: GridDemoTileStyle.oneLine,
                child: new Text('One line')
              ),
              new PopupMenuItem<GridDemoTileStyle>(
                value: GridDemoTileStyle.twoLine,
                child: new Text('Two line')
              )
            ]
          )
        ]
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new ScrollableGrid(
              delegate: new FixedColumnCountGridDelegate(
                columnCount: (orientation == Orientation.portrait) ? 2 : 3,
                rowSpacing: 4.0,
                columnSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                tileAspectRatio: (orientation == Orientation.portrait) ? 1.0 : 1.3
              ),
              children: photos.map((Photo photo) {
                return new GridDemoPhotoItem(
                  photo: photo,
                  tileStyle: tileStyle,
                  onBannerTap: (Photo photo) {
                    setState(() {
                      photo.isFavorite = !photo.isFavorite;
                    });
                  }
                );
              })
            )
          ),
          new DemoBottomBar(
            exampleCodeTag: _kExampleCode
          )
        ]
      )
    );
  }
}
