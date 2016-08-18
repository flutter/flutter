// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'drawer.dart';
import 'item.dart';

const double _kFlexibleSpaceMaxHeight = 256.0;

List<GalleryItem> _itemsWithCategory(String category) {
  return kAllGalleryItems.where((GalleryItem item) => item.category == category).toList();
}

final List<GalleryItem> _demoItems = _itemsWithCategory('Demos');
final List<GalleryItem> _componentItems = _itemsWithCategory('Components');
final List<GalleryItem> _styleItems = _itemsWithCategory('Style');

class _BackgroundLayer {
  _BackgroundLayer({ int level, double parallax })
    : assetName = 'packages/flutter_gallery_assets/appbar/appbar_background_layer$level.png',
      parallaxTween = new Tween<double>(begin: 0.0, end: parallax);
  final String assetName;
  final Tween<double> parallaxTween;
}

final List<_BackgroundLayer> _kBackgroundLayers = <_BackgroundLayer>[
  new _BackgroundLayer(level: 0, parallax: _kFlexibleSpaceMaxHeight),
  new _BackgroundLayer(level: 1, parallax: _kFlexibleSpaceMaxHeight),
  new _BackgroundLayer(level: 2, parallax: _kFlexibleSpaceMaxHeight / 2.0),
  new _BackgroundLayer(level: 3, parallax: _kFlexibleSpaceMaxHeight / 4.0),
  new _BackgroundLayer(level: 4, parallax: _kFlexibleSpaceMaxHeight / 2.0),
  new _BackgroundLayer(level: 5, parallax: _kFlexibleSpaceMaxHeight)
];

class _AppBarBackground extends StatelessWidget {
  _AppBarBackground({ Key key, this.animation }) : super(key: key);

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    // TODO(abarth): Wire up to the parallax of the FlexibleSpaceBar in a way
    // that doesn't pop during hero transition.
    Animation<double> effectiveAnimation = kAlwaysDismissedAnimation;
    return new AnimatedBuilder(
      animation: effectiveAnimation,
      builder: (BuildContext context, Widget child) {
        return new Stack(
          children: _kBackgroundLayers.map((_BackgroundLayer layer) {
            return new Positioned(
              top: -layer.parallaxTween.evaluate(effectiveAnimation),
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: new Image.asset(
                layer.assetName,
                fit: ImageFit.cover,
                height: _kFlexibleSpaceMaxHeight
              )
            );
          }).toList()
        );
      }
    );
  }
}

class GalleryHome extends StatefulWidget {
  GalleryHome({
    Key key,
    this.useLightTheme,
    this.onThemeChanged,
    this.timeDilation,
    this.onTimeDilationChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
    assert(onShowPerformanceOverlayChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  static final Key _homeKey = new ValueKey<String>("Gallery Home");
  static final GlobalKey<ScrollableState> _scrollableKey = new GlobalKey<ScrollableState>();
  final List<Widget> _listItems = <Widget>[];

  @override
  void initState() {
    super.initState();

    final ThemeData themeData = Theme.of(context);
    final TextStyle headerStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);
    String category;
    for (GalleryItem galleryItem in kAllGalleryItems) {
      if (category != galleryItem.category) {
        if (category != null)
          _listItems.add(new Divider());
        _listItems.add(
          new Container(
            height: 48.0,
            padding: const EdgeInsets.only(left: 16.0),
            align: FractionalOffset.centerLeft,
            child: new Text(galleryItem.category, style: headerStyle)
          )
        );
        category = galleryItem.category;
      }
      _listItems.add(galleryItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Scaffold(
      key: _homeKey,
      scrollableKey: _scrollableKey,
      drawer: new GalleryDrawer(
        useLightTheme: config.useLightTheme,
        onThemeChanged: config.onThemeChanged,
        timeDilation: config.timeDilation,
        onTimeDilationChanged: config.onTimeDilationChanged,
        showPerformanceOverlay: config.showPerformanceOverlay,
        onShowPerformanceOverlayChanged: config.onShowPerformanceOverlayChanged
      ),
      appBar: new AppBar(
        expandedHeight: _kFlexibleSpaceMaxHeight,
        flexibleSpace: new FlexibleSpaceBar(
          title: new Text('Flutter Gallery'),
          background: new Builder(
            builder: (BuildContext context) {
              return new _AppBarBackground(
                animation: Scaffold.of(context)?.appBarAnimation
              );
            }
          )
        )
      ),
      appBarBehavior: AppBarBehavior.under,
      // The block's padding just exists to occupy the space behind the flexible app bar.
      // As the block's padded region is scrolled upwards, the app bar's height will
      // shrink keep it above the block content's and over the padded region.
      body: new Block(
       scrollableKey: _scrollableKey,
       padding: new EdgeInsets.only(top: _kFlexibleSpaceMaxHeight + statusBarHeight),
       children: _listItems
      )
    );
  }
}
