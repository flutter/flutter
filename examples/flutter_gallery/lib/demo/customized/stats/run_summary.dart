// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../animation_helpers.dart';
import 'run_stats.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';
const int _kAnimationDuration = 1500;

const TextStyle _kSummaryTextStyle = TextStyle(
  color: Colors.white,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.bold,
  fontSize: 16.0,
);

class RunSummary extends StatefulWidget {
  const RunSummary({ Key key }) : super(key: key);
  @override
  RunSummaryState createState() => RunSummaryState();
}

class RunSummaryState extends State<RunSummary> with TickerProviderStateMixin {

  final GlobalKey<RunStatsState> _runStatsKey = GlobalKey();
  RunStats _runStats;
  AnimationController _animationController;
  Animation<double> _statsAnimation;
  Animation<double> _pathAnimation;
  Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  Widget build(BuildContext context) {
    _runStats ??= RunStats(key: _runStatsKey);
    return Container(
      color: const Color(0xFF333333),
      child: Stack(
        children: <Positioned>[
          Positioned(
            top: 0.0,
            right: 0.0,
            child: FadeTransition(
              opacity: _backgroundAnimation,
              child: const Image(
                image: AssetImage(
                  'customized/bg_runner.png',
                  package: _kGalleryAssetsPackage,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18.0,
            top: 30.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <ScaleTransition>[
                ScaleTransition(
                    scale: _statsAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          '3.5mi',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color(0xFFF6FB09),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '974 calories',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                ),
              ],
            ),
          ),
          Positioned(
            left: 5.0,
            right: 5.0,
            top: 15.0,
            child: FadeTransition(
              opacity: _pathAnimation,
              child: const Image(
                image: AssetImage(
                  'customized/run_path.png',
                  package: _kGalleryAssetsPackage,
                ),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 15.0,
            top: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25.0, bottom: 15.0),
                    child: Text(
                      '4/9/17 Run',
                      style: _kSummaryTextStyle,
                    ),
                  ),
                  _runStats,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _configureAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: _kAnimationDuration),
      vsync: this,
    );
    _backgroundAnimation = initAnimation(
      from: 0.0,
      to: 1.0,
      curve: Curves.easeOut,
      controller: _animationController,
    );
    _pathAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController,
      curve: const Interval(0.4, 0.55, curve: Curves.easeInOut),
    ));  }

  void animate() {
    _animationController.forward();
    _runStatsKey.currentState.animate();
  }

  void reverse() {
    _animationController.reverse();
    _runStatsKey.currentState.reverse();
  }

  void reset() {
    _animationController.reset();
    _runStatsKey.currentState.reset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
