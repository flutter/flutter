// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

// animation durations
const int _kAnimationDuration = 175;
const int _kHeartAnimationDuration = 250;

// the stat item text style
const TextStyle _statsTextStyle = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w500,
  fontStyle: FontStyle.italic,
  color: Colors.white,
);

class RunStats extends StatefulWidget {

  const RunStats({ Key key }) : super(key: key);

  @override
  RunStatsState createState() => RunStatsState();
}

class RunStatsState extends State<RunStats> with TickerProviderStateMixin {

  AnimationController _animationController;
  AnimationController _heartAnimationController;
  List<Animation<double>> _statsAnimations;
  Animation<double> _heartAnimation;
  Timer _heartTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kAnimationDuration * 5),
    );
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kHeartAnimationDuration),
      vsync: this,
    );
    _statsAnimations = <Animation<double>>[
      _statsAnimation(0.2, 0.4),
      _statsAnimation(0.4, 0.6),
      _statsAnimation(0.6, 0.8),
      _statsAnimation(0.8, 1.0),
    ];
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(_heartAnimationController);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ScaleTransition(
            scale: _statsAnimations[0],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Icon(Icons.timer, color: Colors.white),
                Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    '00:26:13',
                    style: _statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimations[1],
            child: Row(
              children: const <Widget>[
                Icon(Icons.access_time, color: Colors.white),
                Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    "7'13\"",
                    style: _statsTextStyle,
                  ),
                )
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimations[2],
            child: Row(
              children: const <Widget>[
                Icon(Icons.landscape, color: Colors.white),
                Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    '120ft',
                    style: _statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimations[3],
            child: Row(
              children: <Widget>[
                ScaleTransition(
                  scale: _heartAnimation,
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    '97bpm',
                    style: _statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Animation<double> _statsAnimation(double begin, double end) {
    final Curve curve = Interval(
      begin, end, curve: Curves.easeInOut
    );
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: curve),
    );
  }

  void animate() {
    _animationController.forward().whenComplete(() {
      animateHeart().then((_) {
        if (_heartTimer != null && _heartTimer.isActive) {
          _heartTimer.cancel();
        }
        _heartTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
          animateHeart();
        });
      });
    });
  }

  void reverse() {
    _animationController.reverse();
  }

  Future<void> animateHeart() {
    if (!mounted) {
      return null;
    }
    return _heartAnimationController.forward().whenComplete(() {
      _heartAnimationController.reverse();
    });
  }

  void reset() {
    if (_heartTimer != null && _heartTimer.isActive) {
      _heartTimer.cancel();
      _heartTimer = null;
    }
    _heartAnimationController.reset();
    _animationController.reset();
  }

  @override
  void dispose() {
    reset();
    _heartAnimationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

}
