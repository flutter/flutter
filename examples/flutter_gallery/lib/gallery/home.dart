// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

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
    this.onShowPerformanceOverlayChanged,
    this.checkerboardRasterCacheImages,
    this.onCheckerboardRasterCacheImagesChanged,
    this.onPlatformChanged,
    this.onSendFeedback,
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  final bool checkerboardRasterCacheImages;
  final ValueChanged<bool> onCheckerboardRasterCacheImagesChanged;

  final ValueChanged<TargetPlatform> onPlatformChanged;

  final VoidCallback onSendFeedback;

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> with SingleTickerProviderStateMixin {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  static final GlobalKey<ScrollableState> _scrollableKey = new GlobalKey<ScrollableState>();

  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 600),
      debugLabel: 'preview banner',
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _galleryListItems() {
    final List<Widget> listItems = <Widget>[];
    final ThemeData themeData = Theme.of(context);
    final TextStyle headerStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);
    String category;
    for (GalleryItem galleryItem in kAllGalleryItems) {
      if (category != galleryItem.category) {
        if (category != null)
          listItems.add(new Divider());
        listItems.add(
          new Container(
            height: 48.0,
            padding: const EdgeInsets.only(left: 16.0),
            alignment: FractionalOffset.centerLeft,
            child: new Text(galleryItem.category, style: headerStyle)
          )
        );
        category = galleryItem.category;
      }
      listItems.add(galleryItem);
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    Widget home = new Scaffold(
      key: _scaffoldKey,
      scrollableKey: _scrollableKey,
      drawer: new GalleryDrawer(
        useLightTheme: config.useLightTheme,
        onThemeChanged: config.onThemeChanged,
        timeDilation: config.timeDilation,
        onTimeDilationChanged: config.onTimeDilationChanged,
        showPerformanceOverlay: config.showPerformanceOverlay,
        onShowPerformanceOverlayChanged: config.onShowPerformanceOverlayChanged,
        checkerboardRasterCacheImages: config.checkerboardRasterCacheImages,
        onCheckerboardRasterCacheImagesChanged: config.onCheckerboardRasterCacheImagesChanged,
        onPlatformChanged: config.onPlatformChanged,
        onSendFeedback: config.onSendFeedback,
      ),
      appBar: new AppBar(
        expandedHeight: _kFlexibleSpaceMaxHeight,
        flexibleSpace: new FlexibleSpaceBar(
          title: new Text('Flutter Gallery'),
          background: new Builder(
            builder: (BuildContext context) {
              return new _AppBarBackground(
                animation: _scaffoldKey.currentState.appBarAnimation
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
       children: _galleryListItems()
      )
    );

    // In checked mode our MaterialApp will show the default "slow mode" banner.
    // Otherwise show the "preview" banner.
    bool showPreviewBanner = true;
    assert(() {
      showPreviewBanner = false;
      return true;
    });

    if (showPreviewBanner) {
      home = new Stack(
        children: <Widget>[
          home,
          new FadeTransition(
            opacity: new CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            child: new Banner(
              message: 'PREVIEW',
              location: BannerLocation.topRight,
            )
          ),
        ]
      );
    }

    return home;
  }
}
