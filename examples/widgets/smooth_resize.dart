// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final List<Map<int, Color>> _kColors = <Map<int, Color>>[
  Colors.amber,
  Colors.yellow,
  Colors.blue,
  Colors.purple,
  Colors.indigo,
  Colors.deepOrange,
];

class SmoothBlock extends StatefulComponent {
  SmoothBlock({ this.color });

  final Map<int, Color> color;

  SmoothBlockState createState() => new SmoothBlockState();
}

class CardTransition extends StatelessComponent {
  CardTransition({
    this.child,
    this.performance,
    this.x,
    this.opacity,
    this.scale
  });

  final Widget child;
  final Performance performance;
  final AnimatedValue<double> x;
  final AnimatedValue<double> opacity;
  final AnimatedValue<double> scale;

  Widget build(BuildContext context) {

    return new BuilderTransition(
      performance: performance,
      variables: <AnimatedValue<double>>[x, opacity, scale],
      builder: (BuildContext context) {
        Matrix4 transform = new Matrix4.identity()
          ..translate(x.value)
          ..scale(scale.value, scale.value);
        return new Opacity(
          opacity: opacity.value,
          child: new Transform(
            transform: transform,
            child: child
          )
        );
      }
    );
  }
}

class SmoothBlockState extends State<SmoothBlock> {

  double _height = 100.0;

  Widget _handleEnter(PerformanceView performance, Widget child) {
    return new CardTransition(
      x: new AnimatedValue<double>(-200.0, end: 0.0, curve: Curves.ease),
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.ease),
      scale: new AnimatedValue<double>(0.8, end: 1.0, curve: Curves.ease),
      performance: performance,
      child: child
    );
  }

  Widget _handleExit(PerformanceView performance, Widget child) {
    return new CardTransition(
      x: new AnimatedValue<double>(0.0, end: 200.0, curve: Curves.ease),
      opacity: new AnimatedValue<double>(1.0, end: 0.0, curve: Curves.ease),
      scale: new AnimatedValue<double>(1.0, end: 0.8, curve: Curves.ease),
      performance: performance,
      child: child
    );
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        setState(() {
          _height = _height == 100.0 ? 200.0 : 100.0;
        });
      },
      child: new EnterExitTransition(
        duration: const Duration(milliseconds: 1500),
        onEnter: _handleEnter,
        onExit: _handleExit,
        child: new Container(
          key: new ValueKey(_height),
          height: _height,
          decoration: new BoxDecoration(backgroundColor: config.color[_height.floor() * 4])
        )
      )
    );
  }
}

class SmoothResizeDemo extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Block(_kColors.map((Map<int, Color> color) => new SmoothBlock(color: color)).toList());
  }
}

void main() {
  runApp(new SmoothResizeDemo());
}
