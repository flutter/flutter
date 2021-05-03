// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'common.dart';

import 'src/animated_image.dart';
import 'src/animated_placeholder.dart';
import 'src/animation_with_microtasks.dart';
import 'src/backdrop_filter.dart';
import 'src/color_filter_and_fade.dart';
import 'src/cubic_bezier.dart';
import 'src/cull_opacity.dart';
import 'src/filtered_child_animation.dart';
import 'src/fullscreen_textfield.dart';
import 'src/heavy_grid_view.dart';
import 'src/large_image_changer.dart';
import 'src/large_images.dart';
import 'src/multi_widget_construction.dart';
import 'src/picture_cache.dart';
import 'src/post_backdrop_filter.dart';
import 'src/simple_animation.dart';
import 'src/simple_scroll.dart';
import 'src/stack_size.dart';
import 'src/text.dart';

const String kMacrobenchmarks = 'Macrobenchmarks';

void main() => runApp(const MacrobenchmarksApp());

class MacrobenchmarksApp extends StatelessWidget {
  const MacrobenchmarksApp({Key key, this.initialRoute = '/'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kMacrobenchmarks,
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomePage(),
        kCullOpacityRouteName: (BuildContext context) => const CullOpacityPage(),
        kCubicBezierRouteName: (BuildContext context) => const CubicBezierPage(),
        kBackdropFilterRouteName: (BuildContext context) => const BackdropFilterPage(),
        kPostBackdropFilterRouteName: (BuildContext context) => const PostBackdropFilterPage(),
        kSimpleAnimationRouteName: (BuildContext context) => const SimpleAnimationPage(),
        kPictureCacheRouteName: (BuildContext context) => const PictureCachePage(),
        kLargeImageChangerRouteName: (BuildContext context) => const LargeImageChangerPage(),
        kLargeImagesRouteName: (BuildContext context) => const LargeImagesPage(),
        kTextRouteName: (BuildContext context) => const TextPage(),
        kFullscreenTextRouteName: (BuildContext context) => const TextFieldPage(),
        kAnimatedPlaceholderRouteName: (BuildContext context) => const AnimatedPlaceholderPage(),
        kColorFilterAndFadeRouteName: (BuildContext context) => const ColorFilterAndFadePage(),
        kFadingChildAnimationRouteName: (BuildContext context) => const FilteredChildAnimationPage(FilterType.opacity),
        kImageFilteredTransformAnimationRouteName: (BuildContext context) => const FilteredChildAnimationPage(FilterType.rotateFilter),
        kMultiWidgetConstructionRouteName: (BuildContext context) => const MultiWidgetConstructTable(10, 20),
        kHeavyGridViewRouteName: (BuildContext context) => const HeavyGridViewPage(),
        kSimpleScrollRouteName: (BuildContext context) => const SimpleScroll(),
        kStackSizeRouteName: (BuildContext context) => const StackSizePage(),
        kAnimationWithMicrotasksRouteName: (BuildContext context) => const AnimationWithMicrotasks(),
        kAnimatedImageRouteName: (BuildContext context) => const AnimatedImagePage(),
      },
    );
  }

  final String initialRoute;
}

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kMacrobenchmarks)),
      body: ListView(
        key: const Key(kScrollableName),
        children: <Widget>[
          ElevatedButton(
            key: const Key(kCullOpacityRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kCullOpacityRouteName);
            },
            child: const Text('Cull opacity'),
          ),
          ElevatedButton(
            key: const Key(kCubicBezierRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kCubicBezierRouteName);
            },
            child: const Text('Cubic Bezier'),
          ),
          ElevatedButton(
            key: const Key(kBackdropFilterRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kBackdropFilterRouteName);
            },
            child: const Text('Backdrop Filter'),
          ),
          ElevatedButton(
            key: const Key(kPostBackdropFilterRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kPostBackdropFilterRouteName);
            },
            child: const Text('Post Backdrop Filter'),
          ),
          ElevatedButton(
            key: const Key(kSimpleAnimationRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kSimpleAnimationRouteName);
            },
            child: const Text('Simple Animation'),
          ),
          ElevatedButton(
            key: const Key(kPictureCacheRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kPictureCacheRouteName);
            },
            child: const Text('Picture Cache'),
          ),
          ElevatedButton(
            key: const Key(kLargeImagesRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImagesRouteName);
            },
            child: const Text('Large Images'),
          ),
          ElevatedButton(
            key: const Key(kTextRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kTextRouteName);
            },
            child: const Text('Text'),
          ),
          ElevatedButton(
            key: const Key(kFullscreenTextRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kFullscreenTextRouteName);
            },
            child: const Text('Fullscreen Text'),
          ),
          ElevatedButton(
            key: const Key(kAnimatedPlaceholderRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kAnimatedPlaceholderRouteName);
            },
            child: const Text('Animated Placeholder'),
          ),
          ElevatedButton(
            key: const Key(kColorFilterAndFadeRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kColorFilterAndFadeRouteName);
            },
            child: const Text('Color Filter and Fade'),
          ),
          ElevatedButton(
            key: const Key(kFadingChildAnimationRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kFadingChildAnimationRouteName);
            },
            child: const Text('Fading Child Animation'),
          ),
          ElevatedButton(
            key: const Key(kImageFilteredTransformAnimationRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kImageFilteredTransformAnimationRouteName);
            },
            child: const Text('ImageFiltered Transform Animation'),
          ),
          ElevatedButton(
            key: const Key(kMultiWidgetConstructionRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kMultiWidgetConstructionRouteName);
            },
            child: const Text('Widget Construction and Destruction'),
          ),
          ElevatedButton(
            key: const Key(kHeavyGridViewRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kHeavyGridViewRouteName);
            },
            child: const Text('Heavy Grid View'),
          ),
          ElevatedButton(
            key: const Key(kLargeImageChangerRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImageChangerRouteName);
            },
            child: const Text('Large Image Changer'),
          ),
          ElevatedButton(
            key: const Key(kStackSizeRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kStackSizeRouteName);
            },
            child: const Text('Stack Size'),
          ),
          ElevatedButton(
            key: const Key(kAnimationWithMicrotasksRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kAnimationWithMicrotasksRouteName);
            },
            child: const Text('Animation With Microtasks'),
          ),
          ElevatedButton(
            key: const Key(kAnimatedImageRouteName),
            onPressed: () {
              Navigator.pushNamed(context, kAnimatedImageRouteName);
            },
            child: const Text('Animated Image'),
          ),
        ],
      ),
    );
  }
}
