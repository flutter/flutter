// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../animation_helpers.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';
const int _kAnimationDuration = 100;

class MyStatsBar extends StatefulWidget {
  const MyStatsBar({ Key key, @required this.onTapped, this.height = 70.0 })
      : assert(onTapped != null),
        super(key: key);

  final VoidCallback onTapped;
  final double height;

  @override
  MyStatsBarState createState() => MyStatsBarState();
}

class MyStatsBarState extends State<MyStatsBar> with TickerProviderStateMixin {

  AnimationController _animationController;
  Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapped,
      child: Container(
        color: const Color(0xFF212024),
        height: widget.height,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              left: 26.0,
              right: null,
              child: Center(
                child: Text(
                  'VIEW MY STATS',
                  style: TextStyle(
                    color: Color(0xFF02CEA1),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              right: 20.0,
              left: null,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: const RotatedBox(
                  quarterTurns: 2,
                  child: ImageIcon(
                    AssetImage(
                      'customized/ic_circle_arrow.png',
                      package: _kGalleryAssetsPackage,
                    ),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _configureAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimationDuration),
      vsync: this,
    );
    _rotationAnimation = initAnimation(
      from: 0.0,
      to: 0.5,
      curve: Curves.easeOut,
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
