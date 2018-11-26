// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/customized/stats_row.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import 'snapping_scroll_physics.dart';

// the duration of each of the stat item's animation
const int _kStatsAnimationDuration = 175;
const int _kHeartAnimationDuration = 250;
const int _kTopSectionAnimationDuration = 1500;

const int _kAnimateHeroFadeDuration = 1000;
const int _kAnimateTextDuration = 400;
const double _kDetailTabHeight = 70.0;
const int _kRotationAnimationDuration = 100;
const int _kAnimateNumberCounterDuration = 1000;

const int _kStartingElevationCount = 8365;
const int _kStartingRunCount = 158;

class CustomizedDesign extends StatefulWidget {
  static const String routeName = '/customized';

  @override
  _CustomizedDesignState createState() => _CustomizedDesignState();
}

class _CustomizedDesignState extends State<CustomizedDesign>
    with TickerProviderStateMixin {

  TargetPlatform _targetPlatform;
  TextAlign _platformTextAlignment;
  ThemeData _themeData;
  Widget _mainContentWidget;
  final int _elevationCounter = _kStartingElevationCount;

  Animation<double> _heroFadeInAnimation;
  Animation<double> _textFadeInAnimation;
  Animation<double> _rotationAnimation;
  Animation<double> _runnerFadeAnimation;
  Animation<double> _pathFadeAnimation;
  Animation<double> _statsSummaryAnimation;
  Animation<double> _numberCounterAnimation;

  AnimationController _heroAnimationController;
  AnimationController _textAnimationController;
  AnimationController _rotationAnimationController;
  AnimationController _topSectionAnimationController;
  AnimationController _numberCounterAnimationController;
  AnimationController _statsRowAnimationController;
  AnimationController _heartAnimationController;
  Timer _heartTimer;

  StatsRow _statsRow;
  bool animatedStats = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureThemes();
  }

  @override
  void initState() {
    super.initState();
    _configureAnimation();
    _heroAnimationController.forward().whenComplete(() {
      _textAnimationController.forward();
    });
    _statsRowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kStatsAnimationDuration * 5),
    );
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kHeartAnimationDuration),
      vsync: this,
    );
    _statsRow = StatsRow(
      statsAnimationController: _statsRowAnimationController,
      heartAnimationController: _heartAnimationController,
    );
  }

  @override
  Widget build(BuildContext context) {
    _mainContentWidget ??= _contentWidget();
    return Theme(
      data: _themeData,
      child: Material(
        color: const Color(0x00FFFFFF),
        child: _mainContentWidget,
      ),
    );
  }

  GestureDetector _buildAppBar() {
    return GestureDetector(
      onTap: tappedStatsBar,
      child: Container(
        color: const Color(0xFF212024),
        height: 70.0,
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: 26.0,
              top: 0.0,
              bottom: 0.0,
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
            Positioned(
              right: 20.0,
              top: 0.0,
              bottom: 0.0,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: const RotatedBox(
                  quarterTurns: 2,
                  child: ImageIcon(
                    AssetImage('assets/images/customized/ic_circle_arrow.png'),
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

  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        FadeTransition(
          opacity: _heroFadeInAnimation,
          child: OverflowBox(
            alignment: FractionalOffset.topLeft,
            maxHeight: 1000.0,
            child: Image(
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
              image: const AssetImage(
                'assets/images/customized/fg_hero.png',
              ),
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

  Container _buildPathContent() {
    return Container(
      color: const Color(0xFF333333),
      child: Stack(
        children: <Positioned>[
          Positioned(
            top: 0.0,
            right: 0.0,
            child: FadeTransition(
              opacity: _runnerFadeAnimation,
              child: const Image(
                image: AssetImage('assets/images/customized/bg_runner.png'),
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
                  scale: _statsSummaryAnimation,
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
              opacity: _pathFadeAnimation,
              child: const Image(
                image: AssetImage('assets/images/customized/run_path.png'),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            bottom: 15.0,
            right: 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 25.0, bottom: 15.0),
                    child: Text(
                      '4/9/17 Run',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  _statsRow,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildStatsBox() {
    const TextStyle figureStyle = TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    const TextStyle titleStyle = TextStyle(
      fontSize: 9.0,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    );
    final NumberFormat elevation = NumberFormat('#,###.#', 'en_US');
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
                Column(
                  children: <Widget>[
                    Text(
                      _kStartingRunCount.toString(),
                      style: figureStyle,
                    ),
                    const Text(
                      'TOTAL RUNS',
                      style: titleStyle,
                    ),
                  ],
                ),
                Column(
                  children: const <Widget>[
                    Text(
                      "6'45\"",
                      style: figureStyle,
                    ),
                    Text(
                      'AVG PACE',
                      style: titleStyle,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      elevation.format(_elevationCounter).toString(),
                      style: figureStyle,
                    ),
                    const Text(
                      'TOTAL ELEVATION',
                      style: titleStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 45.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
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

  Widget _buildStatsContentWidget() {
    return Container(
      color: const Color(0xFF212024),
      height: MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          _buildAppBar(),
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 70.0,
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: _buildPathContent(),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: _buildStatsBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBody() {
    final Text firstText = Text(
      'EASILY TRACK YOUR ACTIVITY',
      textAlign: _platformTextAlignment,
      style: const TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 40.0,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
    final Text combinedText = firstText;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: combinedText,
        ),
        Padding(
          padding: _targetPlatform == TargetPlatform.android
              ? const EdgeInsets.only(left: 20.0)
              : const EdgeInsets.only(left: 0.0, right: 0.0),
          child: Align(
            alignment: _targetPlatform == TargetPlatform.android
                ? FractionalOffset.centerLeft
                : FractionalOffset.center,
            child: Container(
              height: 3.0,
              width: 66.0,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 50.0),
          child: Text(
            'Keep your phone with you while running, cycling, or walking to get stats on your activity.',
            textAlign: _platformTextAlignment,
            style: const TextStyle(
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

  void _configureAnimation() {
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimateHeroFadeDuration),
      vsync: this,
    );
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimateTextDuration),
      vsync: this,
    );
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kRotationAnimationDuration),
      vsync: this,
    );
    _topSectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kTopSectionAnimationDuration),
      vsync: this,
    );
    _numberCounterAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimateNumberCounterDuration),
      vsync: this,
    );
    _heroFadeInAnimation = _initAnimation(
      from: 0.0,
      to: 1.0,
      curve: Curves.easeOut,
      controller: _heroAnimationController,
    );
    _textFadeInAnimation = _initAnimation(
      from: 0.0,
      to: 1.0,
      curve: Curves.easeIn,
      controller: _textAnimationController,
    );
    _rotationAnimation = _initAnimation(
        from: 0.0,
        to: 0.5,
        curve: Curves.easeOut,
        controller: _rotationAnimationController);
    _runnerFadeAnimation = _initAnimation(
        from: 0.0,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _topSectionAnimationController);
    _numberCounterAnimation = _numberCounterAnimationController;
    _numberCounterAnimation = Tween<double>(
      begin: 0.0,
      end: 646.3,
    ).animate(
      CurvedAnimation(
        curve: Curves.fastOutSlowIn,
        parent: _numberCounterAnimationController,
      ),
    );
    _pathFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _topSectionAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    _statsSummaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _topSectionAnimationController,
      curve: const Interval(0.4, 0.55, curve: Curves.easeInOut),
    ));
  }

  void _configureThemes() {
    _targetPlatform = Theme.of(context).platform;
    _platformTextAlignment = _targetPlatform == TargetPlatform.android
        ? TextAlign.left
        : TextAlign.center;
    _themeData = ThemeData(
      primaryColor: const Color(0xFF212024),
      buttonColor: const Color(0xFF3D3D3D),
      iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
      brightness: Brightness.light,
      platform: _targetPlatform,
    );
  }

  Widget _contentWidget() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final String backTitle =
        _targetPlatform == TargetPlatform.android ? 'TrackFit' : '';
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
                title: Text(
                  backTitle,
                ),
                expandedHeight: screenHeight -
                    _kDetailTabHeight -
                    MediaQuery.of(context).padding.top,
                leading: const BackButton(
                  color: Colors.white,
                ),
                backgroundColor: const Color(0xFF212024),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildBody(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildStatsContentWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Animation<double> _initAnimation({
    @required double from,
    @required double to,
    @required Curve curve,
    @required AnimationController controller,
  }) {
    final CurvedAnimation animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    return Tween<double>(begin: from, end: to).animate(animation);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final double scrollPosition = notification.metrics.pixels;
    final double screenHeight = MediaQuery.of(context).size.height -
        _kDetailTabHeight - MediaQuery.of(context).padding.top;
    final double screenOffset = scrollPosition / screenHeight;
    if (screenOffset >= 0.75 && !animatedStats) {
      animatedStats = true;
      _textAnimationController.reset();
      _rotationAnimationController.forward();
      _animateAllStatsControllers();
    } else if (screenOffset < 0.2) {
      animatedStats = false;
      _rotationAnimationController.reverse();
      _resetStatsAnimationControllers();
      _textAnimationController.forward();
    }
    return true;
  }

  /// display the 'stats' content when the 'view my stats' bar is tapped
  void tappedStatsBar() {
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

  void _resetStatsAnimationControllers() {
    _topSectionAnimationController.reset();
    _numberCounterAnimationController.reset();
    _statsRowAnimationController.reset();
  }

  void _animateAllStatsControllers() {
    _numberCounterAnimationController.forward();
    _topSectionAnimationController.forward();
    _statsRowAnimationController.forward().whenComplete(() {
      _animateHeart().then((_) {
        if (_heartTimer != null) {
          _heartTimer.cancel();
        }
        _heartTimer =
            Timer.periodic(const Duration(seconds: 3), (Timer timer) {
              _animateHeart();
            });
      });
    });
  }

  Future<void> _animateHeart() {
    if (!mounted) {
      return null;
    }
    return _heartAnimationController.forward().whenComplete(() {
      _heartAnimationController.reverse();
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _textAnimationController.dispose();
    _rotationAnimationController.dispose();
    _numberCounterAnimationController.dispose();
    _topSectionAnimationController.dispose();
    _heartAnimationController.dispose();
    if (_heartTimer != null) {
      _heartTimer.cancel();
      _heartTimer = null;
    }
    super.dispose();
  }
}
