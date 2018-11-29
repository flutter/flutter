// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showingStatsContent = false;
  final GlobalKey<RunStatsContentState> _statsContentKey = GlobalKey<RunStatsContentState>();
  final GlobalKey<InitialWelcomeState> _initialWelcomeKey = GlobalKey<InitialWelcomeState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // lock orientation to portrait
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureThemes();
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContentWidget = _contentWidget();
    return WillPopScope(
      onWillPop: () {
        if (_showingStatsContent) {
          _scrollController.animateTo(
            0.0,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        }
        return Future<bool>.value(!_showingStatsContent);
      },
      child: Theme(
        data: _themeData,
        child: mainContentWidget,
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
    final Widget welcomeWidget = InitialWelcome(key: _initialWelcomeKey);
    final Widget statsContentWidget = RunStatsContent(
      key: _statsContentKey,
      peekAmount: _kStatsSectionPeekAmount,
      onHeaderTapped: tappedStatsDetailBar,
    );
    final double screenHeight = MediaQuery.of(context).size.height;
    final String title = Platform.isAndroid ? 'TrackFit' : '';
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
                title: Text(title),
                expandedHeight: screenHeight - _kStatsSectionPeekAmount - MediaQuery.of(context).padding.top,
                leading: const BackButton(
                  color: Colors.white,
                ),
                backgroundColor: const Color(0xFF212024),
                flexibleSpace: FlexibleSpaceBar(
                  background: welcomeWidget,
                ),
              ),
              SliverToBoxAdapter(
                child: statsContentWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final double scrollPosition = notification.metrics.pixels;
    final double statsContentScrollAmount = MediaQuery.of(context).size.height -
        _kStatsSectionPeekAmount - MediaQuery.of(context).padding.top;
    final double screenOffset = scrollPosition / statsContentScrollAmount;
    if (screenOffset >= 0.75 && !_showingStatsContent) {
      _showingStatsContent = true;
      _initialWelcomeKey.currentState.reverse();
      _statsContentKey.currentState.animate();
    } else if (screenOffset < 0.2) {
      _showingStatsContent = false;
      _statsContentKey.currentState.reverse();
      _initialWelcomeKey.currentState.animate();
    }
    return true;
  }

  /// This method is called when the details bar is tapped. It will scroll the
  /// run details section in to place.
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

  @override
  void dispose() {
    // reset orientations
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}
