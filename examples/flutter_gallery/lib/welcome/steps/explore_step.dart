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
  _ExploreWelcomeStepState createState() => _ExploreWelcomeStepState();
}

class _ExploreWelcomeStepState extends WelcomeStepState<ExploreWelcomeStep> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: _kTitle,
      subtitle: _kSubtitle,
      imageContentBuilder: () => buildImageWidget(),
    );
  }

  Widget buildImageWidget() {
    final List<Widget> stackChildren = <Widget>[
      Positioned.fill(
        child: Image.asset(
          'welcome/welcome_flutter_logo.png',
          package: kWelcomeGalleryAssetsPackage,
        ),
      ),
    ];

    if (_popupAnimationWidgets.isEmpty) {
      for (int i = 0; i < _popWidgets.length; i++) {
        _popupAnimationWidgets.add(
            _addAnimationWidget(_popWidgets[i], _popupAnimationControllers[i]));
      }
    }
    stackChildren.addAll(_popupAnimationWidgets);
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
      for (AnimationController animationController in _popupAnimationControllers) {
        animationController.reset();
      }
    }
    Future<void>.delayed(Duration(milliseconds: 500), () {
      for (AnimationController animationController in _popupAnimationControllers) {
        animationController.forward();
      }
    });
  }

  List<AnimationController> _popupAnimationControllers = <AnimationController>[];
  final List<Animation<double>> _popupScaleAnimations = <Animation<double>>[];
  final List<Animation<double>> _popupOpacityAnimations = <Animation<double>>[];
  final List<Widget> _popupAnimationWidgets = <Widget>[];

  void _setupAnimations() {
    if (_popupAnimationControllers.isNotEmpty) {
      return;
    }
    _popupAnimationControllers = <AnimationController>[
      AnimationController(vsync: this, duration: Duration(milliseconds: 60)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 280)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 170)),
      AnimationController(vsync: this, duration: Duration(milliseconds: 120)),
    ];
  }

  Widget _addAnimationWidget(
      _PopupPosition popPosition, AnimationController animationController) {
    final Animation<double> scaleAnimation =
    Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    final Animation<double> opacityAnimation =
    Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    _popupScaleAnimations.add(scaleAnimation);
    _popupOpacityAnimations.add(opacityAnimation);
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

  final List<_PopupPosition> _popWidgets = <_PopupPosition>[
    _PopupPosition(
      top: 0.0,
      right: 30.0,
      child: Image.asset(
        'welcome/welcome_pop_1.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 80.0,
      ),
    ),
    _PopupPosition(
      top: 60.0,
      left: 20.0,
      child: Image.asset(
        'welcome/welcome_pop_2.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 54.0,
      ),
    ),
    _PopupPosition(
      bottom: 70.0,
      right: 40.0,
      child: Image.asset(
        'welcome/welcome_pop_3.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 40.0,
      ),
    ),
    _PopupPosition(
      bottom: 8.0,
      left: 30.0,
      child: Image.asset(
        'welcome/welcome_pop_4.png',
        package: kWelcomeGalleryAssetsPackage,
        width: 45.0,
      ),
    ),
  ];

  @override
  void dispose() {
    for (AnimationController controller in _popupAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _PopupPosition {
  _PopupPosition({ this.top, this.right, this.bottom, this.left, @required this.child });
  final double top;
  final double right;
  final double bottom;
  final double left;
  final Widget child;
}
