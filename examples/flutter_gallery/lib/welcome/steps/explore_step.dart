// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../constants.dart';
import '../welcome_step_state.dart';
import 'step_container.dart';

const String _kTitle = 'Explore Flutter!';
const String _kSubtitle = 'Start being highly productive and do more with less code. Explore what you can do with Flutter!';

class ExploreWelcomeStep extends StatefulWidget {
  const ExploreWelcomeStep({Key key}) : super(key: key);
  @override
  ExploreWelcomeStepState createState() => ExploreWelcomeStepState();
}

class ExploreWelcomeStepState extends WelcomeStepState<ExploreWelcomeStep> with TickerProviderStateMixin {

  Widget _imageWidget;

  @override
  Widget build(BuildContext context) {
    _imageWidget ??= imageWidget();
    return StepContainer(
      title: _kTitle,
      subtitle: _kSubtitle,
      imageContentBuilder: () => _imageWidget,
    );
  }

  Widget imageWidget() {
    _setupAnimations();
    final List<Widget> stackChildren = <Widget>[
      Positioned.fill(
        child: Image.asset(
          'welcome/welcome_flutter_logo.png',
          package: kWelcomeGalleryAssetsPackage,
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
      for (AnimationController animationController in _popAnimationControllers) {
        animationController.reset();
      }
    }
    Future<void>.delayed(Duration(milliseconds: 500), () {
      for (AnimationController animationController in _popAnimationControllers) {
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
      AnimationController(vsync: this, duration: Duration(milliseconds: 60)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 280)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 170)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 120)),
    ];
  }

  Widget _addAnimationWidget(
      _PopPosition popPosition, AnimationController animationController) {
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
  final List<_PopPosition> _popWidgets = <_PopPosition>[
    _PopPosition(
      top: 0.0,
      right: 30.0,
      child: Image.asset(
        'welcome/welcome_pop_1.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 80.0,
      ),
    ),
    _PopPosition(
      top: 60.0,
      left: 20.0,
      child: Image.asset(
        'welcome/welcome_pop_2.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 54.0,
      ),
    ),
    _PopPosition(
      bottom: 70.0,
      right: 40.0,
      child: Image.asset(
        'welcome/welcome_pop_3.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 40.0,
      ),
    ),
    _PopPosition(
      bottom: 8.0,
      left: 30.0,
      child: Image.asset(
        'welcome/welcome_pop_4.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 45.0,
      ),
    ),
  ];
}

class _PopPosition {
  _PopPosition({ this.top, this.right, this.bottom, this.left, @required this.child });
  final double top;
  final double right;
  final double bottom;
  final double left;
  final Widget child;
}
