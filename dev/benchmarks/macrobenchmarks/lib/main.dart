// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'common.dart';

import 'src/animated_placeholder.dart';
import 'src/backdrop_filter.dart';
import 'src/color_filter_and_fade.dart';
import 'src/cubic_bezier.dart';
import 'src/cull_opacity.dart';
import 'src/filtered_child_animation.dart';
import 'src/heavy_grid_view.dart';
import 'src/large_image_changer.dart';
import 'src/large_images.dart';
import 'src/multi_widget_construction.dart';
import 'src/picture_cache.dart';
import 'src/post_backdrop_filter.dart';
import 'src/simple_animation.dart';
import 'src/simple_scroll.dart';
import 'src/text.dart';

const String kMacrobenchmarks = 'Macrobenchmarks';

void main() => runApp(const MacrobenchmarksApp());

class MacrobenchmarksApp extends StatelessWidget {
  const MacrobenchmarksApp({this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kMacrobenchmarks,
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => HomePage(),
        kCullOpacityRouteName: (BuildContext context) => CullOpacityPage(),
        kCubicBezierRouteName: (BuildContext context) => CubicBezierPage(),
        kBackdropFilterRouteName: (BuildContext context) => BackdropFilterPage(),
        kPostBackdropFilterRouteName: (BuildContext context) => PostBackdropFilterPage(),
        kSimpleAnimationRouteName: (BuildContext context) => SimpleAnimationPage(),
        kPictureCacheRouteName: (BuildContext context) => PictureCachePage(),
        kLargeImageChangerRouteName: (BuildContext context) => LargeImageChangerPage(),
        kLargeImagesRouteName: (BuildContext context) => LargeImagesPage(),
        kTextRouteName: (BuildContext context) => TextPage(),
        kAnimatedPlaceholderRouteName: (BuildContext context) => AnimatedPlaceholderPage(),
        kColorFilterAndFadeRouteName: (BuildContext context) => ColorFilterAndFadePage(),
        kFadingChildAnimationRouteName: (BuildContext context) => const FilteredChildAnimationPage(FilterType.opacity),
        kImageFilteredTransformAnimationRouteName: (BuildContext context) => const FilteredChildAnimationPage(FilterType.rotateFilter),
        kMultiWidgetConstructionRouteName: (BuildContext context) => const MultiWidgetConstructTable(10, 20),
        kHeavyGridViewRouteName: (BuildContext context) => HeavyGridViewPage(),
        kSimpleScrollRouteName: (BuildContext context) => SimpleScroll(),
      },
    );
  }

  final String initialRoute;
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kMacrobenchmarks)),
      body: ListView(
        key: const Key(kScrollableName),
        children: <Widget>[
          RaisedButton(
            key: const Key(kCullOpacityRouteName),
            child: const Text('Cull opacity'),
            onPressed: () {
              Navigator.pushNamed(context, kCullOpacityRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kCubicBezierRouteName),
            child: const Text('Cubic Bezier'),
            onPressed: () {
              Navigator.pushNamed(context, kCubicBezierRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kBackdropFilterRouteName),
            child: const Text('Backdrop Filter'),
            onPressed: () {
              Navigator.pushNamed(context, kBackdropFilterRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kPostBackdropFilterRouteName),
            child: const Text('Post Backdrop Filter'),
            onPressed: () {
              Navigator.pushNamed(context, kPostBackdropFilterRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kSimpleAnimationRouteName),
            child: const Text('Simple Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kSimpleAnimationRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kPictureCacheRouteName),
            child: const Text('Picture Cache'),
            onPressed: () {
              Navigator.pushNamed(context, kPictureCacheRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kLargeImagesRouteName),
            child: const Text('Large Images'),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImagesRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kTextRouteName),
            child: const Text('Text'),
            onPressed: () {
              Navigator.pushNamed(context, kTextRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kAnimatedPlaceholderRouteName),
            child: const Text('Animated Placeholder'),
            onPressed: () {
              Navigator.pushNamed(context, kAnimatedPlaceholderRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kColorFilterAndFadeRouteName),
            child: const Text('Color Filter and Fade'),
            onPressed: () {
              Navigator.pushNamed(context, kColorFilterAndFadeRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kFadingChildAnimationRouteName),
            child: const Text('Fading Child Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kFadingChildAnimationRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kImageFilteredTransformAnimationRouteName),
            child: const Text('ImageFiltered Transform Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kImageFilteredTransformAnimationRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kMultiWidgetConstructionRouteName),
            child: const Text('Widget Construction and Destruction'),
            onPressed: () {
              Navigator.pushNamed(context, kMultiWidgetConstructionRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kHeavyGridViewRouteName),
            child: const Text('Heavy Grid View'),
            onPressed: () {
              Navigator.pushNamed(context, kHeavyGridViewRouteName);
            },
          ),
          RaisedButton(
            key: const Key(kLargeImageChangerRouteName),
            child: const Text('Large Image Changer'),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImageChangerRouteName);
            },
          ),
        ],
      ),
    );
  }
}
