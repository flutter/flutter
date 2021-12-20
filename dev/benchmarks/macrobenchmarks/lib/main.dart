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
import 'src/opacity_peephole.dart';
import 'src/picture_cache.dart';
import 'src/post_backdrop_filter.dart';
import 'src/simple_animation.dart';
import 'src/simple_scroll.dart';
import 'src/stack_size.dart';
import 'src/text.dart';

const String kMacrobenchmarks = 'Macrobenchmarks';

void main() => runApp(const MacrobenchmarksApp());

class MacrobenchmarksApp extends StatelessWidget {
  const MacrobenchmarksApp({Key? key, this.initialRoute = '/'}) : super(key: key);

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
        kOpacityPeepholeRouteName: (BuildContext context) => const OpacityPeepholePage(),
        ...opacityPeepholeRoutes,
      },
    );
  }

  final String initialRoute;
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kMacrobenchmarks)),
      body: ListView(
        key: const Key(kScrollableName),
        children: <Widget>[
          ElevatedButton(
            key: const Key(kCullOpacityRouteName),
            child: const Text('Cull opacity'),
            onPressed: () {
              Navigator.pushNamed(context, kCullOpacityRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kCubicBezierRouteName),
            child: const Text('Cubic Bezier'),
            onPressed: () {
              Navigator.pushNamed(context, kCubicBezierRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kBackdropFilterRouteName),
            child: const Text('Backdrop Filter'),
            onPressed: () {
              Navigator.pushNamed(context, kBackdropFilterRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kPostBackdropFilterRouteName),
            child: const Text('Post Backdrop Filter'),
            onPressed: () {
              Navigator.pushNamed(context, kPostBackdropFilterRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kSimpleAnimationRouteName),
            child: const Text('Simple Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kSimpleAnimationRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kPictureCacheRouteName),
            child: const Text('Picture Cache'),
            onPressed: () {
              Navigator.pushNamed(context, kPictureCacheRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kLargeImagesRouteName),
            child: const Text('Large Images'),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImagesRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kTextRouteName),
            child: const Text('Text'),
            onPressed: () {
              Navigator.pushNamed(context, kTextRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kFullscreenTextRouteName),
            child: const Text('Fullscreen Text'),
            onPressed: () {
              Navigator.pushNamed(context, kFullscreenTextRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kAnimatedPlaceholderRouteName),
            child: const Text('Animated Placeholder'),
            onPressed: () {
              Navigator.pushNamed(context, kAnimatedPlaceholderRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kColorFilterAndFadeRouteName),
            child: const Text('Color Filter and Fade'),
            onPressed: () {
              Navigator.pushNamed(context, kColorFilterAndFadeRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kFadingChildAnimationRouteName),
            child: const Text('Fading Child Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kFadingChildAnimationRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kImageFilteredTransformAnimationRouteName),
            child: const Text('ImageFiltered Transform Animation'),
            onPressed: () {
              Navigator.pushNamed(context, kImageFilteredTransformAnimationRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kMultiWidgetConstructionRouteName),
            child: const Text('Widget Construction and Destruction'),
            onPressed: () {
              Navigator.pushNamed(context, kMultiWidgetConstructionRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kHeavyGridViewRouteName),
            child: const Text('Heavy Grid View'),
            onPressed: () {
              Navigator.pushNamed(context, kHeavyGridViewRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kLargeImageChangerRouteName),
            child: const Text('Large Image Changer'),
            onPressed: () {
              Navigator.pushNamed(context, kLargeImageChangerRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kStackSizeRouteName),
            child: const Text('Stack Size'),
            onPressed: () {
              Navigator.pushNamed(context, kStackSizeRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kAnimationWithMicrotasksRouteName),
            child: const Text('Animation With Microtasks'),
            onPressed: () {
              Navigator.pushNamed(context, kAnimationWithMicrotasksRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kAnimatedImageRouteName),
            child: const Text('Animated Image'),
            onPressed: () {
              Navigator.pushNamed(context, kAnimatedImageRouteName);
            },
          ),
          ElevatedButton(
            key: const Key(kOpacityPeepholeRouteName),
            child: const Text('Opacity Peephole tests'),
            onPressed: () {
              Navigator.pushNamed(context, kOpacityPeepholeRouteName);
            },
          ),
        ],
      ),
    );
  }
}
