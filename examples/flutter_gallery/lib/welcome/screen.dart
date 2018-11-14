// ignore: invalid_constant
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'constants.dart';
import 'manager.dart';
import 'models.dart';

class SecondaryWidgetHolder {
  SecondaryWidgetHolder(
      {this.top, this.right, this.bottom, this.left, @required this.child});

  double top;
  double right;
  double bottom;
  double left;
  Widget child;
}

class WarmWelcomeScreen extends StatefulWidget {
  const WarmWelcomeScreen({Key key, this.isInitialScreen = true, this.onSkipPressed})
      : super(key: key);

  // is the screen being displayed as a demo item or not?
  final bool isInitialScreen;

  // callback when button is pressed
  final VoidCallback onSkipPressed;

  @override
  _WarmWelcomeScreenState createState() =>
      _WarmWelcomeScreenState(isInitialScreen: isInitialScreen);
}

class _WarmWelcomeScreenState extends State<WarmWelcomeScreen>
    with TickerProviderStateMixin {
  _WarmWelcomeScreenState({this.isInitialScreen});

  // static const int _kParallaxAnimationDuration = 400;

  // is the screen being displayed as a demo item or not?
  bool isInitialScreen = true;

  final List<WelcomeStep> _steps = WelcomeManager().steps();
  TabController _tabController;
  int _currentPage = 0; // for page indicator
  // double _bgOffset = 0.0;

  // animations
  final List<AnimationController> _inAnimationControllers =
      <AnimationController>[];
  final List<AnimationController> _outAnimationControllers =
      <AnimationController>[];
  final Map<int, AnimationController> _secondaryAnimationControllers =
      <int, AnimationController>{};
  AnimationController _parallaxController;

  ScaleTransition _makeAnimatedContentWidget({Widget child}) {
    // out animation
    final AnimationController outAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    final Animation<double> outScaleAnimation = CurvedAnimation(
      parent: outAnimationController,
      curve: Curves.easeOut,
    );
    final Animation<double> outScaleTween = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(outScaleAnimation);
    final Animation<double> slideAnimation = CurvedAnimation(
      parent: outAnimationController,
      curve: Curves.easeOut,
    );
    final Animation<Offset> outSlideTween = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(1.0, 0.0),
    ).animate(slideAnimation);
    _outAnimationControllers.add(outAnimationController);

    // in animation
    final AnimationController inAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    final Animation<double> inScaleAnimation = CurvedAnimation(
      parent: inAnimationController,
      curve: Curves.linear,
    );
    final Animation<double> inScaleTween = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(inScaleAnimation);
    _inAnimationControllers.add(inAnimationController);

    // widgets
    final SlideTransition outAnimationWrapper = SlideTransition(
      position: outSlideTween,
      child: ScaleTransition(
        scale: outScaleTween,
        child: child,
      ),
    );
    final ScaleTransition inAnimationWrapper = ScaleTransition(
      scale: inScaleTween,
      child: outAnimationWrapper,
    );
    return inAnimationWrapper;
  }

  Stack _contentWidget(
      {Widget contentChild,
      String title,
      String subtitle,
      bool hasSecondary = false,
      int pageIndex}) {
    final List<Widget> contentStackChildren = <Widget>[];
    contentStackChildren.add(contentChild);
    if (hasSecondary) {
      contentStackChildren.addAll(_secondaryWidgets(pageIndex));
    }

    final List<Widget> stackChildren = <Widget>[
      Positioned.fill(
        top: 65.0,
        child: Padding(
          padding: const EdgeInsets.only(left: 45.0, right: 45.0),
          child: Column(
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22.0,
                  color: Color(Constants.ColorPrimary),
                  letterSpacing: 0.25,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(subtitle, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
      Center(
        child: _makeAnimatedContentWidget(
            child: Container(
          width: 300.0,
          height: 300.0,
          child: Stack(
            children: contentStackChildren,
          ),
        )),
      ),
    ];

    return Stack(
      children: stackChildren,
    );
  }

  List<Widget> _secondaryWidgets(int index) {
    List<SecondaryWidgetHolder> holders = <SecondaryWidgetHolder>[];
    final List<Widget> widgets = <Widget>[];

    if (index == 2) {
      final AnimationController controller = AnimationController(
        duration: Duration(milliseconds: 750),
        vsync: this,
      );
      _secondaryAnimationControllers[index] = controller;

      final List<double> begins = <double>[0.0, 0.55, 0.25, 0.75];
      final List<double> ends = <double>[0.5, 1.0, 0.75, 1.0];
      final Map<int, Animation<double>> scaleAnimations =
          <int, Animation<double>>{};
      for (int a = 0; a < 4; a++) {
        final Animation<double> scaleAnimation = CurvedAnimation(
          parent: controller,
          curve: Interval(begins[a], ends[a], curve: Curves.easeIn),
        );
        final Animation<double> scaleTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(scaleAnimation);
        scaleAnimations[a] = scaleTween;
      }

      holders = <SecondaryWidgetHolder>[
        SecondaryWidgetHolder(
          top: 25.0,
          left: 10.0,
          child: ScaleTransition(
            scale: scaleAnimations[0],
            child: Image(
              height: 55.0,
              image: AssetImage(_steps[index].imageUris[1]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          top: 70.0,
          right: 30.0,
          child: ScaleTransition(
            scale: scaleAnimations[1],
            child: Image(
              height: 40.0,
              image: AssetImage(_steps[index].imageUris[2]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          bottom: 70.0,
          left: 25.0,
          child: ScaleTransition(
            scale: scaleAnimations[2],
            child: Image(
              height: 35.0,
              image: AssetImage(_steps[index].imageUris[3]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          bottom: 10.0,
          right: 55.0,
          child: ScaleTransition(
            scale: scaleAnimations[3],
            child: Image(
              height: 30.0,
              image: AssetImage(_steps[index].imageUris[4]),
            ),
          ),
        ),
      ];
    } else if (index == 3) {
      final AnimationController controller = AnimationController(
        duration: Duration(milliseconds: 750),
        vsync: this,
      );
      _secondaryAnimationControllers[index] = controller;

      final List<double> begins = <double>[0.0, 0.55, 0.25, 0.75, 0.3];
      final List<double> ends = <double>[0.5, 1.0, 0.75, 1.0, 0.9];
      final Map<int, Animation<double>> scaleAnimations =
          <int, Animation<double>>{};
      for (int a = 0; a < 5; a++) {
        final Animation<double> scaleAnimation = CurvedAnimation(
          parent: controller,
          curve: Interval(begins[a], ends[a], curve: Curves.easeIn),
        );
        final Animation<double> scaleTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(scaleAnimation);
        scaleAnimations[a] = scaleTween;
      }

      holders = <SecondaryWidgetHolder>[
        SecondaryWidgetHolder(
          top: 35.0,
          left: 10.0,
          child: ScaleTransition(
            scale: scaleAnimations[0],
            child: Image(
              height: 50.0,
              image: AssetImage(_steps[index].imageUris[1]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          top: 30.0,
          right: 20.0,
          child: ScaleTransition(
            scale: scaleAnimations[1],
            child: Image(
              height: 60.0,
              image: AssetImage(_steps[index].imageUris[2]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          top: 135.0,
          right: 35.0,
          child: ScaleTransition(
            scale: scaleAnimations[2],
            child: Image(
              height: 35.0,
              image: AssetImage(_steps[index].imageUris[3]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          bottom: 30.0,
          left: 18.0,
          child: ScaleTransition(
            scale: scaleAnimations[3],
            child: Image(
              height: 30.0,
              image: AssetImage(_steps[index].imageUris[4]),
            ),
          ),
        ),
        SecondaryWidgetHolder(
          bottom: 20.0,
          right: 30.0,
          child: ScaleTransition(
            scale: scaleAnimations[4],
            child: Image(
              height: 65.0,
              image: AssetImage(_steps[index].imageUris[5]),
            ),
          ),
        ),
      ];
    }

    for (int i = 0; i < holders.length; i++) {
      final SecondaryWidgetHolder holder = holders[i];
      widgets.add(
        Positioned(
          top: holder.top,
          right: holder.right,
          bottom: holder.bottom,
          left: holder.left,
          child: holder.child,
        ),
      );
    }
    return widgets;
  }

  TabPageSelector _pageIndicator() {
    _tabController = TabController(initialIndex: 0, length: 4, vsync: this);
    return TabPageSelector(controller: _tabController);
  }

  Container _continueButton() {
    return Container(
      width: 200.0,
      height: 54.0,
      child: RaisedButton(
        color: const Color(Constants.ColorPrimary),
        child: const Text(
          'START EXPLORING',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 12.0,
          ),
        ),
        onPressed: _tappedContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < _steps.length; i++) {
      children.add(
        _contentWidget(
          contentChild: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 27.0),
              child: Image(
                width: math.min(280.0, MediaQuery.of(context).size.width),
                fit: BoxFit.fitHeight,
                image: AssetImage(_steps[i].imageUris[0]),
              ),
            ),
          ),
          title: _steps[i].title,
          subtitle: _steps[i].subtitle,
          hasSecondary: i == 2 || i == 3,
          pageIndex: i,
        ),
      );
    }

    double startPixels = 0.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    _inAnimationControllers[0].value = 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        actions: const <Widget>[],
      ),
      body: Material(
        color: Colors.blue, // const Color(0xFFFFFFFF),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollStartNotification) {
              final PageMetrics metrics = notification.metrics;
              startPixels = metrics.pixels;
              final AnimationController secondaryAnimationController =
                  _secondaryAnimationControllers[_currentPage];
              if (secondaryAnimationController != null &&
                  secondaryAnimationController.value != 0) {
                secondaryAnimationController.duration =
                    Duration(milliseconds: 150);
                secondaryAnimationController.reverse();
              }
            } else if (notification is ScrollUpdateNotification) {
              final PageMetrics metrics = notification.metrics;
              final int page = (metrics.pixels / screenWidth).floor();
              final num offset = (metrics.pixels - (page * screenWidth))
                  .clamp(0, double.maxFinite);
              _outAnimationControllers[page].value = offset / screenWidth;
              if (page < (_inAnimationControllers.length - 1)) {
                _inAnimationControllers[page + 1].value = offset / screenWidth;
              }
              final int moveDelta = startPixels < metrics.pixels ? 1 : -1;
              _parallaxController.value += moveDelta * 0.001;
            } else if (notification is ScrollEndNotification) {
              final PageMetrics metrics = notification.metrics;
              _currentPage = metrics.page.round();

              final AnimationController secondaryAnimationController =
                  _secondaryAnimationControllers[_currentPage];

              if (secondaryAnimationController != null) {
                secondaryAnimationController.value = 0.0;
                secondaryAnimationController.duration =
                    Duration(milliseconds: 450);
                secondaryAnimationController.forward();
              }
              _tabController.animateTo(_currentPage);
            }
            return false;
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: PageView(
                  children: children,
                ),
              ),
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _pageIndicator(),
                      ),
                      _continueButton()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // actions
  void _tappedContinue() {
    // TODO route to the actual gallery
    if (isInitialScreen) {
      if (widget.onSkipPressed != null) {
        widget.onSkipPressed();
      }
    } else {
      Navigator.of(context).pop();
    }
  }
}
