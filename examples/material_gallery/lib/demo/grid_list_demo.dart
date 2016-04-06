// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum GridDemoTileStyle {
  imageOnly,
  oneLine,
  twoLine
}

class Photo {
  const Photo({ this.assetName });

  final String assetName;

  String get title => 'Safari';
  String get caption => 'March 2015';

  bool get isValid => assetName != null;
}

final List<Photo> photos = new List<Photo>.generate(16, (int index) {
  return const Photo(assetName: 'packages/flutter_gallery_assets/kangaroo_valley_safari.png');
});

class GridDemoPhotoItem extends StatelessWidget {
  GridDemoPhotoItem({ Key key, this.photo, this.tileStyle }) : super(key: key) {
    assert(photo != null && photo.isValid);
    assert(tileStyle != null);
  }

  final Photo photo;
  final GridDemoTileStyle tileStyle;

  void showPhoto(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Scaffold(
          appBar: new AppBar(
            title: new Text(photo.title)
          ),
          body: new Material(
            child: new AssetImage(
              name: photo.assetName,
              fit: ImageFit.cover
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
      child: new AssetImage(
        name: photo.assetName,
        fit: ImageFit.cover
      )
    );

    switch(tileStyle) {
      case GridDemoTileStyle.imageOnly:
        return image;

      case GridDemoTileStyle.oneLine:
        return new GridTile(
          header: new GridTileBar(
            backgroundColor: Colors.black.withAlpha(0x08),
            leading: new Icon(icon: Icons.info, color: Colors.white70),
            title: new Text(photo.title)
          ),
          child: image
        );

      case GridDemoTileStyle.twoLine:
        return new GridTile(
          footer: new GridTileBar(
            backgroundColor: Colors.black.withAlpha(0x08),
            title: new Text(photo.title),
            subtitle: new Text(photo.caption),
            trailing: new Icon(icon: Icons.info, color: Colors.white70)
          ),
          child: image
        );
    }
  }
}

class GridListDemoGridDelegate extends FixedColumnCountGridDelegate {
  GridListDemoGridDelegate({
    this.columnCount,
    double columnSpacing: 0.0,
    double rowSpacing: 0.0,
    EdgeInsets padding: EdgeInsets.zero,
    this.tileHeightFactor: 2.75
  }) : super(columnSpacing: columnSpacing, rowSpacing: rowSpacing, padding: padding) {
    assert(columnCount != null && columnCount >= 0);
    assert(tileHeightFactor != null && tileHeightFactor > 0.0);
  }

  @override
  final int columnCount;

  final double tileHeightFactor;

  @override
  GridSpecification getGridSpecification(BoxConstraints constraints, int childCount) {
    assert(constraints.maxWidth < double.INFINITY);
    assert(constraints.maxHeight < double.INFINITY);
    return new GridSpecification.fromRegularTiles(
      tileWidth: math.max(0.0, constraints.maxWidth - padding.horizontal + columnSpacing) / columnCount,
      tileHeight: constraints.maxHeight / tileHeightFactor,
      columnCount: columnCount,
      rowCount: (childCount / columnCount).ceil(),
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      padding: padding
    );
  }

  @override
  bool shouldRelayout(GridListDemoGridDelegate oldDelegate) {
    return columnCount != oldDelegate.columnCount
        || tileHeightFactor != oldDelegate.tileHeightFactor
        || super.shouldRelayout(oldDelegate);
  }
}

class GridListDemo extends StatefulWidget {
  GridListDemo({ Key key }) : super(key: key);

  @override
  GridListDemoState createState() => new GridListDemoState();
}

class GridListDemoState extends State<GridListDemo> {
  GridDemoTileStyle tileStyle = GridDemoTileStyle.twoLine;

  void showTileStyleMenu(BuildContext context) {
    final List<PopupMenuItem<GridDemoTileStyle>> items = <PopupMenuItem<GridDemoTileStyle>>[
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
    ];

    final EdgeInsets padding = MediaQuery.of(context).padding;
    final ModalPosition position = new ModalPosition(
      right: padding.right + 16.0,
      top: padding.top + 16.0
    );

    showMenu(context: context, position: position, items: items).then((GridDemoTileStyle value) {
      setState(() {
        tileStyle = value;
      });
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
          new IconButton(
            icon: Icons.more_vert,
            onPressed: () { showTileStyleMenu(context); },
            tooltip: 'Show menu'
          )
        ]
      ),
      body: new ScrollableGrid(
        delegate: new GridListDemoGridDelegate(
          columnCount: (orientation == Orientation.portrait) ? 2 : 3,
          rowSpacing: 4.0,
          columnSpacing: 4.0,
          padding: const EdgeInsets.all(4.0),
          tileHeightFactor: (orientation == Orientation.portrait) ? 2.75 : 1.75
        ),
        children: photos.map((Photo photo) {
          return new GridDemoPhotoItem(photo: photo, tileStyle: tileStyle);
        })
        .toList()
      )
    );
  }
}
