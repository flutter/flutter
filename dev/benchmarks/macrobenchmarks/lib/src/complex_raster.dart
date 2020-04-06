// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

const Duration kComplexRasterAnimationDuration = Duration(milliseconds: 200);

const double _kContainerWidth = 500;
const double _kContainerHeight = 500;
const int _kNumBackdropFilters = 100;

// Frames that build fast and raster slow.
// See https://github.com/flutter/flutter/issues/54117.
class ComplexRasterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: AnimatedImageTransforms());
  }
}

class ImageWithStackedTransforms extends AnimatedWidget {
  const ImageWithStackedTransforms({Key key, Animation<double> animation})
      : super(key: key, listenable: animation);

  static final Tween<double> _opacityTween = Tween<double>(
    begin: 0.1,
    end: 0.2,
  );
  static final ColorTween _colorTween = ColorTween(
    begin: Colors.grey,
    end: Colors.black,
  );
  static final Tween<double> _blurTween = Tween<double>(
    begin: 0.1,
    end: 10.0,
  );

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;

    final Color color = _colorTween.evaluate(animation);
    final double sigma = _blurTween.evaluate(animation);
    final double opacity = _opacityTween.evaluate(animation);

    final Image image = Image.asset(
      'assets/hi_res_splash.jpg',
      width: _kContainerWidth,
      height: _kContainerHeight,
      fit: BoxFit.contain,
    );

    final List<Widget> imageAndFilters = <Widget>[
      image,
      _createBackdropFilter(
        sigma,
        color.withOpacity(opacity),
      ),
    ];

    // add additional layers to make things slower.
    for (int i = 1; i <= _kNumBackdropFilters; i++) {
      final double sigma = pow(10, -2 * i).toDouble();
      final double opacity = pow(10, -2 * i).toDouble();
      imageAndFilters.add(_createBackdropFilter(
        sigma,
        color.withOpacity(opacity),
      ));
    }

    return Stack(children: imageAndFilters);
  }

  Container _createBackdropFilter(double sigma, Color transparentColor) {
    return Container(
      width: _kContainerWidth,
      height: _kContainerHeight,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: Container(
          width: _kContainerWidth,
          height: _kContainerHeight,
          color: transparentColor,
        ),
      ),
    );
  }
}

class AnimatedImageTransforms extends StatefulWidget {
  @override
  AnimatedImageTransformsState createState() => AnimatedImageTransformsState();
}

class AnimatedImageTransformsState extends State<AnimatedImageTransforms>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  void _onStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      controller.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: kComplexRasterAnimationDuration,
      vsync: this,
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation.addStatusListener(_onStatusChange);
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ImageWithStackedTransforms(animation: animation);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
