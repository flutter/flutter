// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'animation_helpers.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';
const int _kAnimationDuration = 1200;
// add a (positioned) negative bottom offset to the hero image so that the
// image is a bit better positioned on the screen on larger screens
const double _kHeroImageBottomOffset = -50.0;

class InitialWelcome extends StatefulWidget {
  const InitialWelcome({ Key key }) : super(key: key);

  @override
  InitialWelcomeState createState() => InitialWelcomeState();
}

class InitialWelcomeState extends State<InitialWelcome> with TickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _heroFadeInAnimation;
  Animation<double> _textFadeInAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
    animate();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          bottom: _kHeroImageBottomOffset,
          child: FadeTransition(
            opacity: _heroFadeInAnimation,
            child: Image(
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
              image: const AssetImage('customized/fg_hero.png', package: _kGalleryAssetsPackage),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FadeTransition(
              opacity: _textFadeInAnimation,
              child: _buildTextBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: Text(
            'EASILY TRACK YOUR ACTIVITY',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 40.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Align(
            alignment: FractionalOffset.centerLeft,
            child: Container(
              height: 3.0,
              width: 66.0,
              color: Colors.white,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 50.0),
          child: Text(
            'Keep your phone with you while running, cycling, or walking to get stats on your activity.',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _configureAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimationDuration),
      vsync: this,
    );
    _heroFadeInAnimation = initAnimation(
      from: 0.0,
      to: 1.0,
      curve: Curves.easeOut,
      controller: _animationController,
    );
    _textFadeInAnimation = initAnimation(
      from: 0.0,
      to: 1.0,
      curve: Curves.easeIn,
      controller: _animationController,
    );
  }

  void animate() {
    _animationController.forward();
  }

  void reverse() {
    _animationController.reverse();
  }

  void reset() {
    _animationController.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
