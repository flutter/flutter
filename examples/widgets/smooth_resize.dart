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
    this.animation,
    this.x,
    this.opacity,
    this.scale
  });

  final Widget child;
  final Animation<double> animation;
  final Animatable<double> x;
  final Animatable<double> opacity;
  final Animatable<double> scale;

  Widget build(BuildContext context) {
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        double currentScale = scale.evaluate(animation);
        Matrix4 transform = new Matrix4.identity()
          ..translate(x.evaluate(animation))
          ..scale(currentScale, currentScale);
        return new Opacity(
          opacity: opacity.evaluate(animation),
          child: new Transform(
            transform: transform,
            child: child
          )
        );
      },
      child: child
    );
  }
}

class SmoothBlockState extends State<SmoothBlock> {

  double _height = 100.0;

  Widget _handleEnter(Animation<double> animation, Widget child) {
    return new CardTransition(
      x: new Tween<double>(begin: -200.0, end: 0.0),
      opacity: new Tween<double>(begin: 0.0, end: 1.0),
      scale: new Tween<double>(begin: 0.8, end: 1.0),
      animation: new CurvedAnimation(parent: animation, curve: Curves.ease),
      child: child
    );
  }

  Widget _handleExit(Animation<double> animation, Widget child) {
    return new CardTransition(
      x: new Tween<double>(begin: 0.0, end: 200.0),
      opacity: new Tween<double>(begin: 1.0, end: 0.0),
      scale: new Tween<double>(begin: 1.0, end: 0.8),
      animation: new CurvedAnimation(parent: animation, curve: Curves.ease),
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
