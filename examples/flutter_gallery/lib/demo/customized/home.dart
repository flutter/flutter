// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'initial_welcome.dart';
import 'run_stats_content.dart';
import 'snapping_scroll_physics.dart';

const double _kStatsSectionPeekAmount = 70.0;

class CustomizedDesign extends StatefulWidget {

  static const String routeName = '/customized';

  @override
  _CustomizedDesignState createState() => _CustomizedDesignState();
}

class _CustomizedDesignState extends State<CustomizedDesign> with TickerProviderStateMixin {

  ThemeData _themeData;
  bool _animatedStats = false;
  Widget _mainContentWidget;
  final GlobalKey<RunStatsContentState> _statsContentKey = GlobalKey<RunStatsContentState>();
  Widget _statsContentWidget;
  final GlobalKey<InitialWelcomeState> _initialWelcomeKey = GlobalKey<InitialWelcomeState>();
  Widget _initialContentWidget;
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureThemes();
  }

  @override
  void initState() {
    super.initState();
    _initialContentWidget ??= InitialWelcome(key: _initialWelcomeKey);
    _statsContentWidget ??= RunStatsContent(
      key: _statsContentKey,
      peekAmount: _kStatsSectionPeekAmount,
      onHeaderTapped: tappedStatsDetailBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    _mainContentWidget ??= _contentWidget();
    return WillPopScope(
      onWillPop: () {
        if (_animatedStats) {
          _scrollController.animateTo(
            0.0,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        }
        return Future<bool>.value(!_animatedStats);
      },
      child: Theme(
        data: _themeData,
        child: Material(
          color: const Color(0x00FFFFFF),
          child: _mainContentWidget,
        ),
      ),
    );
  }

  void _configureThemes() {
    _themeData = ThemeData(
      primaryColor: const Color(0xFF212024),
      buttonColor: const Color(0xFF3D3D3D),
      iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
      brightness: Brightness.light,
    );
  }

  Widget _contentWidget() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final String backTitle = Platform.isAndroid ? 'TrackFit' : '';
    return Scaffold(
      backgroundColor: const Color(0xFF212024),
      body: GlowingOverscrollIndicator(
        color: const Color(0x00FFFFFF),
        axisDirection: AxisDirection.down,
        showLeading: false,
        showTrailing: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: CustomScrollView(
            controller: _scrollController,
            physics: SnappingScrollPhysics(midScrollOffset: screenHeight),
            shrinkWrap: true,
            slivers: <Widget>[
              SliverAppBar(
                pinned: false,
                title: Text(backTitle),
                expandedHeight: screenHeight - _kStatsSectionPeekAmount - MediaQuery.of(context).padding.top,
                leading: const BackButton(
                  color: Colors.white,
                ),
                backgroundColor: const Color(0xFF212024),
                flexibleSpace: FlexibleSpaceBar(
                  background: _initialContentWidget,
                ),
              ),
              SliverToBoxAdapter(
                child: _statsContentWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final double scrollPosition = notification.metrics.pixels;
    final double screenHeight = MediaQuery.of(context).size.height -
        _kStatsSectionPeekAmount - MediaQuery.of(context).padding.top;
    final double screenOffset = scrollPosition / screenHeight;
    if (screenOffset >= 0.75 && !_animatedStats) {
      _animatedStats = true;
      _initialWelcomeKey.currentState.reverse();
      _statsContentKey.currentState.animate();
    } else if (screenOffset < 0.2) {
      _animatedStats = false;
      _statsContentKey.currentState.reverse();
      _initialWelcomeKey.currentState.animate();
    }
    return true;
  }

  /// display the 'stats' content when the 'view my stats' bar is tapped
  void tappedStatsDetailBar() {
    double scrollToOffset = 0.0;
    if (_scrollController.offset == 0.0) {
      scrollToOffset = _scrollController.position.maxScrollExtent;
    }
    _scrollController.animateTo(
      scrollToOffset,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }
}
