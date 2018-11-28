// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../constants.dart';
import '../welcome_step_state.dart';
import 'step_container.dart';

const String _kTitle = 'Complete, flexible APIs';
const String _kSubtitle = 'View full API documentation, when you need it, with a quick tap. Look for the documentation icon in the app bar.';

class DocumentationWelcomeStep extends StatefulWidget {
  const DocumentationWelcomeStep({Key key}) : super(key: key);

  @override
  _DocumentationWelcomeStepState createState() => _DocumentationWelcomeStepState();
}

class _DocumentationWelcomeStepState extends WelcomeStepState<DocumentationWelcomeStep> with TickerProviderStateMixin {

  AnimationController _animationController;
  AnimationController _quickAnimationController;
  Animation<double> _barScaleAnimation;
  Animation<double> _barOpacityAnimation;
  Animation<double> _focusScaleAnimation;
  Animation<double> _focusOpacityAnimation;
  Animation<double> _iconOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: _kTitle,
      subtitle: _kSubtitle,
      imageContentBuilder: () => buildImageWidget()
    );
  }

  Widget buildImageWidget() {
    final Image barImage = Image.asset('welcome/welcome_documentation.png', package: kWelcomeGalleryAssetsPackage);
    return Stack(
      children: <Widget>[
        Center(
          child: FadeTransition(
            opacity: _barOpacityAnimation,
            child: ScaleTransition(
              scale: _barScaleAnimation,
              child: barImage,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FadeTransition(
            opacity: _iconOpacityAnimation,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Image.asset(
                'welcome/ic_documentation.png',
                package: kWelcomeGalleryAssetsPackage,
                width: 20.0,
                height: 20.0,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ScaleTransition(
            scale: _focusScaleAnimation,
            child: FadeTransition(
              opacity: _focusOpacityAnimation,
              child: Image.asset(
                'welcome/welcome_documentation_focus.png',
                package: kWelcomeGalleryAssetsPackage,
                width: 85.0,
                height: 85.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void animate({bool restart = false}) {
    if (restart) {
      _animationController.reset();
      _quickAnimationController.reset();
    }
    Future<void>.delayed(Duration(milliseconds: 500), () {
      _animationController.forward();
      _quickAnimationController.forward();
    });
  }

  void _configureAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _quickAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
    );
    _barScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
    _barOpacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_quickAnimationController);
    _focusScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _focusOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _iconOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_quickAnimationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quickAnimationController.dispose();
    super.dispose();
  }
}