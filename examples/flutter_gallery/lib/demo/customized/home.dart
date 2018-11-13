// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'snapping_scroll_physics.dart';

class CustomizedDesign extends StatefulWidget {
  @override
  _CustomizedDesignState createState() => _CustomizedDesignState();
}

class _CustomizedDesignState extends State<CustomizedDesign>
    with TickerProviderStateMixin {
  static const int _kAnimateHeroFadeDuration = 1000;
  static const int _kAnimateTextDuration = 400;
  static const double _kDetailTabHeight = 70.0;
  static const int _kStatsFirstAnimationDuration = 500;
  static const int _kStatsAnimationDuration = 175;
  static const int _kRotationAnimationDuration = 100;
  static const int _kAnimateRunnerHeroFadeDuration = 450;
  static const int _kAnimateNumberCounterDuration = 1000;

  static const int _kStartingElevationCount = 8365;
  static const int _kStartingRunCount = 158;

  List<Widget> _stats;
  TargetPlatform _targetPlatform;
  TextAlign _platformTextAlignment;
  ThemeData _themeData;
  double _statsOpacity = 1.0;
  int _elevationCounter = _kStartingElevationCount;
  int _runCounter = _kStartingRunCount;
  bool _isStatsBoxFullScreen = false;
  bool _hasRunAnimation = false;

  Animation<double> _heroFadeInAnimation;
  Animation<double> _textFadeInAnimation;
  Animation<double> _statsAnimationOne;
  Animation<double> _statsAnimationTwo;
  Animation<double> _statsAnimationThree;
  Animation<double> _statsAnimationFour;
  Animation<double> _rotationAnimation;
  Animation<double> _runnerFadeAnimation;
  Animation<double> _numberCounterAnimation;
  Animation<double> _heartAnimation;

  AnimationController _heroAnimationController;
  AnimationController _textAnimationController;
  AnimationController _statsAnimationControllerOne;
  AnimationController _statsAnimationControllerTwo;
  AnimationController _statsAnimationControllerThree;
  AnimationController _statsAnimationControllerFour;
  AnimationController _rotationAnimationController;
  AnimationController _runnerAnimationController;
  AnimationController _numberCounterAnimationController;
  AnimationController _heartAnimationController;

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    _configureThemes();
    _stats = <Widget>[_buildStatsContentWidget()];
    return Theme(
      data: _themeData,
      child: Material(
        color: const Color(0x00FFFFFF),
        child: _contentWidget(),
      ),
    );
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _textAnimationController.dispose();
    _statsAnimationControllerOne.dispose();
    _statsAnimationControllerTwo.dispose();
    _statsAnimationControllerThree.dispose();
    _statsAnimationControllerFour.dispose();
    _rotationAnimationController.dispose();
    _runnerAnimationController.dispose();
    _numberCounterAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _configureAnimation();
    _heroAnimationController.forward().whenComplete(() {
      _textAnimationController.forward();
    });
  }

  void _animateCounters() {
    if (!_hasRunAnimation) {
      _animateRunCounter();
      _animateElevationCounter();
      _animateMileCounter();
      _hasRunAnimation = true;
    }
  }

  Timer _animateElevationCounter() {
    const Duration duration = Duration(milliseconds: 500);
    return Timer(duration, _updateElevationCounter);
  }

  void _animateMileCounter() {
    setState(() {
      _numberCounterAnimation = Tween<double>(
        begin: 0.0,
        end: 646.3,
      ).animate(
        CurvedAnimation(
          curve: Curves.fastOutSlowIn,
          parent: _numberCounterAnimationController,
        ),
      );
    });
    _numberCounterAnimationController.forward(from: 0.0);
  }

  Timer _animateRunCounter() {
    const Duration duration = Duration(milliseconds: 300);
    return Timer(duration, _updateRunCounter);
  }

  GestureDetector _buildAppBar() {
    return GestureDetector(
      onTap: () {
        double screenHeight = MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top;
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          screenHeight -= 70.0;
        }
        final double halfScreen = screenHeight * 0.5;
        double scrollToOffset =
            _scrollController.offset <= halfScreen ? 0.0 : screenHeight;
        if (_scrollController.offset == 0) {
          scrollToOffset = screenHeight;
        } else if (_isStatsBoxFullScreen) {
          scrollToOffset = 0.0;
        }
        _scrollController.animateTo(
          scrollToOffset,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        color: const Color(0xFF212024),
        height: 70.0,
        child: Stack(
          children: <Positioned>[
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
                    AssetImage('assets/icons/ic_custom_circle_arrow.png'),
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

  Widget _buildBackButton() {
    final TargetPlatform platform = Theme.of(context).platform;
    final IconData backIcon = platform == TargetPlatform.android
        ? Icons.arrow_back
        : Icons.arrow_back_ios;
    return Container(
      height: 70.0,
      width: 70.0,
      child: Material(
        color: const Color(0x00FFFFFF),
        child: IconButton(
          icon: Icon(backIcon, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Opacity(
      opacity: _statsOpacity,
      child: Stack(
        children: <Widget>[
          FadeTransition(
            opacity: _heroFadeInAnimation,
            child: OverflowBox(
              alignment: FractionalOffset.topLeft,
              maxHeight: 1000.0,
              child: Image(
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
                image: const AssetImage(
                  'assets/images/custom_hero.png',
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
      ),
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
                image: AssetImage('assets/images/custom_runner_bg.png'),
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
                  scale: _statsAnimationThree,
                  child: const Text(
                    '3.5mi',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFFF6FB09),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _statsAnimationThree,
                  child: const Text(
                    '974 calories',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 5.0,
            right: 5.0,
            top: 15.0,
            child: FadeTransition(
              opacity: _statsAnimationTwo,
              child: const Image(
                image: AssetImage('assets/images/custom_path.png'),
              ),
            ),
          ),
          Positioned(
            left: 14.0,
            bottom: 50.0,
            child: ScaleTransition(
              scale: _statsAnimationOne,
              child: const Text(
                '4/9/17 Run',
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            bottom: 15.0,
            right: 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: _buildPathStatsRow(),
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildPathStatsRow() {
    const TextStyle statsTextStyle = TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      color: Colors.white,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ScaleTransition(
            scale: _statsAnimationOne,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    '00:26:13',
                    style: statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimationTwo,
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    "7'13\"",
                    style: statsTextStyle,
                  ),
                )
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimationThree,
            child: Row(
              children: [
                const Icon(Icons.landscape, color: Colors.white),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    '120ft',
                    style: statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _statsAnimationFour,
            child: Row(
              children: [
                ScaleTransition(
                  scale: _heartAnimation,
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '97bpm',
                    style: statsTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildStatsBox() {
    final TextStyle figureStyle = TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final TextStyle titleStyle = TextStyle(
      fontSize: 9.0,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    );
    final NumberFormat elevation = NumberFormat('#,###.#', 'en_US');
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      color: const Color(0xFFF6FB09),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _runCounter.toString(),
                      style: figureStyle,
                    ),
                    Text(
                      'TOTAL RUNS',
                      style: titleStyle,
                    ),
                  ],
                ),
                Column(
                  children: [
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
                  children: [
                    Text(
                      elevation.format(_elevationCounter).toString(),
                      style: figureStyle,
                    ),
                    Text(
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
              children: [
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
        children: [
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
    // final Text secondText = Text(
    //   'ACTIVITY',
    //   style: const TextStyle(
    //     fontStyle: FontStyle.italic,
    //     fontSize: 40.0,
    //     fontWeight: FontWeight.w900,
    //     color: Color(0xFFF6F309),
    //   ),
    // );
    final Text combinedText = firstText;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
    _statsAnimationControllerOne = AnimationController(
      duration: const Duration(milliseconds: _kStatsFirstAnimationDuration),
      vsync: this,
    );
    _statsAnimationControllerTwo = AnimationController(
      duration: const Duration(milliseconds: _kStatsAnimationDuration),
      vsync: this,
    );
    _statsAnimationControllerThree = AnimationController(
      duration: const Duration(milliseconds: _kStatsAnimationDuration),
      vsync: this,
    );
    _statsAnimationControllerFour = AnimationController(
      duration: const Duration(milliseconds: _kStatsAnimationDuration),
      vsync: this,
    );
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kStatsAnimationDuration),
      vsync: this,
    );
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kRotationAnimationDuration),
      vsync: this,
    );
    _runnerAnimationController = AnimationController(
      duration: const Duration(milliseconds: _kAnimateRunnerHeroFadeDuration),
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
    _statsAnimationOne = _initAnimation(
        from: 0.01,
        to: 1.0,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
        controller: _statsAnimationControllerOne);
    _statsAnimationTwo = _initAnimation(
        from: 0.01,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _statsAnimationControllerTwo);
    _statsAnimationThree = _initAnimation(
        from: 0.01,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _statsAnimationControllerThree);
    _statsAnimationFour = _initAnimation(
        from: 0.01,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _statsAnimationControllerFour);
    _heartAnimation = _initAnimation(
        from: 1.0,
        to: 1.25,
        curve: Curves.easeOut,
        controller: _heartAnimationController);
    _rotationAnimation = _initAnimation(
        from: 0.0,
        to: 0.5,
        curve: Curves.easeOut,
        controller: _rotationAnimationController);
    _runnerFadeAnimation = _initAnimation(
        from: 0.0,
        to: 1.0,
        curve: Curves.easeOut,
        controller: _runnerAnimationController);
    _numberCounterAnimation = _numberCounterAnimationController;
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
    final TargetPlatform platform = Theme.of(context).platform;
    final String backTitle =
        platform == TargetPlatform.android ? 'TrackFit' : '';
    return Scaffold(
      backgroundColor: const Color(0xFF212024),
      body: NotificationListener<Notification>(
        onNotification: _handleScrollNotification,
        child: GlowingOverscrollIndicator(
          color: const Color(0x00FFFFFF),
          axisDirection: AxisDirection.down,
          showLeading: false,
          showTrailing: false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: SnappingScrollPhysics(midScrollOffset: screenHeight),
            shrinkWrap: true,
            slivers: [
              SliverAppBar(
                pinned: false,
                title: Text(
                  backTitle,
                ),
                expandedHeight: screenHeight -
                    _kDetailTabHeight -
                    MediaQuery.of(context).padding.top,
                leading: _buildBackButton(),
                backgroundColor: const Color(0xFF212024),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildBody(),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(_stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(Notification notification) {
    if (notification is OverscrollIndicatorNotification) {
      notification.disallowGlow();
    }
    if (notification is ScrollNotification) {
      final double visibleStatsHeight = notification.metrics.pixels;
      final double screenHeight = MediaQuery.of(context).size.height -
          _kDetailTabHeight -
          MediaQuery.of(context).padding.top;
      final double opacity = visibleStatsHeight / screenHeight;
      final double calculatedOpacity = 1.0 - opacity;
      if (calculatedOpacity > 1.0) {
        _statsOpacity = 1.0;
      } else if (calculatedOpacity < 0.0) {
        _statsOpacity = 0.0;
      } else {
        _statsOpacity = calculatedOpacity;
      }
    }
    if (_statsOpacity == 0.0) {
      _startAnimation();
    } else if (_statsOpacity == 1.0) {
      _rotationAnimationController.reverse().whenComplete(() {
        _isStatsBoxFullScreen = false;
      });
      _statsAnimationControllerOne.value = 0.0;
      _statsAnimationControllerTwo.value = 0.0;
      _statsAnimationControllerThree.value = 0.0;
      _statsAnimationControllerFour.value = 0.0;
      _runnerAnimationController.value = 0.0;
      _numberCounterAnimationController.value = 0.0;
      _runCounter = _kStartingRunCount;
      _elevationCounter = _kStartingElevationCount;
      _hasRunAnimation = false;
    }
    setState(() {});
    return false;
  }

  Animation<double> _initAnimation(
      {@required double from,
      @required double to,
      @required Curve curve,
      @required AnimationController controller}) {
    final CurvedAnimation animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    return Tween<double>(begin: from, end: to).animate(animation);
  }

  void _startAnimation() {
    _rotationAnimationController.forward().whenComplete(() {
      _isStatsBoxFullScreen = true;
    });
    _runnerAnimationController.forward();
    _statsAnimationControllerOne.forward().whenComplete(() {
      _statsAnimationControllerTwo.forward().whenComplete(() {
        _statsAnimationControllerThree.forward().whenComplete(() {
          _statsAnimationControllerFour.forward().whenComplete(() {
            _heartAnimationController.forward().whenComplete(() {
              _heartAnimationController.reverse();
            });
            _animateCounters();
          });
        });
      });
    });
  }

  // Timer _startAnimationDelay() {
  //   Duration duration = Duration(milliseconds: 1000);
  //   return Timer(duration, _startAnimation());
  // }

  void _updateElevationCounter() {
    setState(() {
      _elevationCounter += 356;
    });
  }

  void _updateRunCounter() {
    setState(() {
      _runCounter += 1;
    });
  }
}
