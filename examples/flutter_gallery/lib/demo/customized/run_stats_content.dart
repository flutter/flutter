// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'animation_helpers.dart';
import 'stats/full_stats.dart';
import 'stats/my_stats_bar.dart';
import 'stats/run_summary.dart';

class RunStatsContent extends StatefulWidget {
  const RunStatsContent({ Key key, @required this.onHeaderTapped, this.peekAmount = 70.0 })
      : assert(onHeaderTapped != null),
        super(key: key);

  final VoidCallback onHeaderTapped;

  /// The stats content will peek out this amount. This will also be the
  /// size of the "show details" bar.
  final double peekAmount;

  @override
  RunStatsContentState createState() => RunStatsContentState();
}

class RunStatsContentState extends State<RunStatsContent> {

  final GlobalKey<MyStatsBarState> _myStatsBarKey = GlobalKey<MyStatsBarState>();
  Widget _myStatsBar;
  final GlobalKey<RunSummaryState> _runSummaryKey = GlobalKey<RunSummaryState>();
  Widget _runSummary;
  final GlobalKey<FullStatsState> _fullDetailsKey = GlobalKey<FullStatsState>();
  Widget _fullDetails;

  AnimationController _animationController;

  Animation<double> _rotationAnimation;
  Animation<double> _runnerFadeAnimation;
  Animation<double> _pathFadeAnimation;
  Animation<double> _statsSummaryAnimation;
  Animation<double> _numberCounterAnimation;

  @override
  Widget build(BuildContext context) {
    _myStatsBar ??= MyStatsBar(
      key: _myStatsBarKey,
      onTapped: widget.onHeaderTapped,
      height: widget.peekAmount,
    );
    _runSummary ??= RunSummary(key: _runSummaryKey);
    _fullDetails ??= FullStats(key: _fullDetailsKey);
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Container(
      height: mediaQueryData.size.height - mediaQueryData.padding.top,
      color: const Color(0xFF212024),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            bottom: null,
            child: _myStatsBar,
          ),
          Positioned.fill(
            top: 70.0,
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: _runSummary,
          ),
          Positioned.fill(
            top: null,
            child: _fullDetails,
          ),
        ],
      ),
    );
  }

  void _configureAnimations() {
    _runnerFadeAnimation = initAnimation(
        from: 0.0,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _animationController);
    _numberCounterAnimation = Tween<double>(
      begin: 0.0,
      end: 646.3,
    ).animate(
      CurvedAnimation(
        curve: Curves.fastOutSlowIn,
        parent: _animationController,
      ),
    );
    _pathFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    _statsSummaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController,
      curve: const Interval(0.4, 0.55, curve: Curves.easeInOut),
    ));
  }

  void animate() {
    _myStatsBarKey.currentState.animate();
    _runSummaryKey.currentState.animate();
    _fullDetailsKey.currentState.animate();
  }

  void reverse() {
    _myStatsBarKey.currentState.reverse();
    _runSummaryKey.currentState.reverse();
    _fullDetailsKey.currentState.reverse();
  }

  void reset() {
    _myStatsBarKey.currentState.reset();
    _runSummaryKey.currentState.reset();
    _fullDetailsKey.currentState.reset();
  }

}
