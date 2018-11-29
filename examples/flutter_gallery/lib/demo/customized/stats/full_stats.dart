// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const int _kAnimationDuration = 2100;

const TextStyle _figureStyle = TextStyle(
  fontSize: 24.0,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);
const TextStyle _titleStyle = TextStyle(
  fontSize: 9.0,
  fontWeight: FontWeight.w400,
  color: Colors.black,
);

class FullStats extends StatefulWidget {
  const FullStats({ Key key }) : super(key: key);

  @override
  FullStatsState createState() => FullStatsState();
}

class FullStatsState extends State<FullStats> with TickerProviderStateMixin {

  AnimationController _animationController;
  Animation<double> _numberCounterAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      color: const Color(0xFFF6FB09),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _smallStatsWidget('159', 'TOTAL RUNS'),
                _smallStatsWidget('6\'45\"', 'AVG PACE'),
                _smallStatsWidget('8,721', 'TOTAL ELEVATION'),
              ],
            ),
          ),
          Positioned.fill(
            top: 45.0,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _numberCounterAnimation,
                  builder: (BuildContext context, Widget child) {
                    return Text(
                      _numberCounterAnimation.value.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 82.0,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
                const Text(
                  'TOTAL MILES',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatsWidget(String value, String label) {
    return Column(
      children: <Widget>[
        Text(value, style: _figureStyle),
        Text(label, style: _titleStyle),
      ],
    );
  }

  void _configureAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimationDuration),
      vsync: this,
    );
    _numberCounterAnimation = Tween<double>(
      begin: 0.0,
      end: 646.3,
    ).animate(
      CurvedAnimation(
        curve: Curves.fastOutSlowIn,
        parent: _animationController,
      ),
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

