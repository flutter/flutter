// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

class PopPosition {
  PopPosition(
      {this.top, this.right, this.bottom, this.left, @required this.child});
  final double top;
  final double right;
  final double bottom;
  final double left;
  final Widget child;
}

class ExploreWelcomeStep extends WelcomeStep {
  ExploreWelcomeStep({TickerProvider tickerProvider})
      : super(tickerProvider: tickerProvider);

  @override
  String title() => 'Explore Flutter!';
  @override
  String subtitle() =>
      'Start being highly productive and do more with less code. Explore what you can do with Flutter!';

  @override
  Widget imageWidget() {
    _setupAnimations();
    final List<Widget> stackChildren = <Widget>[
      Positioned.fill(
        child: Image.asset(
          'assets/images/welcome/welcome_flutter_logo.png',
        ),
      ),
    ];

    if (_popAnimationWidgets.isEmpty) {
      for (int i = 0; i < _popWidgets.length; i++) {
        _popAnimationWidgets.add(
            _addAnimationWidget(_popWidgets[i], _popAnimationControllers[i]));
      }
    }
    stackChildren.addAll(_popAnimationWidgets);
    return Center(
      child: Container(
        width: 300.0,
        child: Stack(
          children: stackChildren,
        ),
      ),
    );
  }

  @override
  void animate({bool restart = false}) {
    if (restart) {
      for (AnimationController animationController
          in _popAnimationControllers) {
        animationController.reset();
      }
    }
    Future<void>.delayed(Duration(milliseconds: 500), () {
      for (AnimationController animationController
          in _popAnimationControllers) {
        animationController.forward();
      }
    });
  }

  // pop animations
  List<AnimationController> _popAnimationControllers = <AnimationController>[];
  final List<Animation<double>> _popScaleAnimations = <Animation<double>>[];
  final List<Animation<double>> _popOpacityAnimations = <Animation<double>>[];
  final List<Widget> _popAnimationWidgets = <Widget>[];

  void _setupAnimations() {
    if (_popAnimationControllers.isNotEmpty) {
      return;
    }
    _popAnimationControllers = <AnimationController>[
      AnimationController(
          vsync: tickerProvider, duration: Duration(milliseconds: 60)),
      AnimationController(
          vsync: tickerProvider, duration: Duration(milliseconds: 280)),
      AnimationController(
          vsync: tickerProvider, duration: Duration(milliseconds: 170)),
      AnimationController(
          vsync: tickerProvider, duration: Duration(milliseconds: 120)),
    ];
  }

  Widget _addAnimationWidget(
      PopPosition popPosition, AnimationController animationController) {
    final Animation<double> scaleAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    final Animation<double> opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    _popScaleAnimations.add(scaleAnimation);
    _popOpacityAnimations.add(opacityAnimation);
    return Positioned(
      top: popPosition.top,
      right: popPosition.right,
      bottom: popPosition.bottom,
      left: popPosition.left,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: opacityAnimation,
          child: popPosition.child,
        ),
      ),
    );
  }

  // pop widgets
  final List<PopPosition> _popWidgets = <PopPosition>[
    PopPosition(
      top: 0.0,
      right: 30.0,
      child: Image.asset(
        'assets/images/welcome/welcome_pop_1.png',
        width: 80.0,
      ),
    ),
    PopPosition(
      top: 60.0,
      left: 20.0,
      child: Image.asset(
        'assets/images/welcome/welcome_pop_2.png',
        width: 54.0,
      ),
    ),
    PopPosition(
      bottom: 70.0,
      right: 40.0,
      child: Image.asset(
        'assets/images/welcome/welcome_pop_3.png',
        width: 40.0,
      ),
    ),
    PopPosition(
      bottom: 8.0,
      left: 30.0,
      child: Image.asset(
        'assets/images/welcome/welcome_pop_4.png',
        width: 45.0,
      ),
    ),
  ];
}
