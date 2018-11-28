// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
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
  final GlobalKey<RunSummaryState> _runSummaryKey = GlobalKey<RunSummaryState>();
  final GlobalKey<FullStatsState> _fullDetailsKey = GlobalKey<FullStatsState>();

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Container(
      height: mediaQueryData.size.height - mediaQueryData.padding.top,
      color: const Color(0xFF212024),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            bottom: null,
            child: MyStatsBar(
              key: _myStatsBarKey,
              onTapped: widget.onHeaderTapped,
              height: widget.peekAmount,
            ),
          ),
          Positioned.fill(
            top: 70.0,
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: RunSummary(key: _runSummaryKey),
          ),
          Positioned.fill(
            top: null,
            child: FullStats(key: _fullDetailsKey),
          ),
        ],
      ),
    );
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
