// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'steps/all.dart';
import 'welcome_step_state.dart';

const int _kSteps = 4;
const int _kAutoProgressSeconds = 10;
const int _kAutoProgressTransitionMilliseconds = 520;
const Color footerColor = Color(0xffffffff);
const TextStyle footerButtonTextStyle = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.bold,
  color: kWelcomeBlue,
);
const double footerButtonHeight = 60.0;

class Welcome extends StatefulWidget {
  const Welcome({ Key key, this.onDismissed }) : super(key: key);
  final VoidCallback onDismissed;

  static const String routeName = '/welcome';

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  List<_WelcomeStep<StatefulWidget>> _steps;
  TabController _tabController;
  PageController _pageController;
  Timer _autoProgressTimer;


  @override
  void initState() {
    super.initState();
    // lock orientation to portrait
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    final GlobalKey<WelcomeStepState<FlutterWelcomeStep>> initialStepKey = GlobalKey<WelcomeStepState<FlutterWelcomeStep>>();
    final GlobalKey<WelcomeStepState<PlaygroundWelcomeStep>> playgroundStepKey = GlobalKey<WelcomeStepState<PlaygroundWelcomeStep>>();
    final GlobalKey<WelcomeStepState<DocumentationWelcomeStep>> documentationStepKey = GlobalKey<WelcomeStepState<DocumentationWelcomeStep>>();
    final GlobalKey<WelcomeStepState<ExploreWelcomeStep>> exploreStepKey = GlobalKey<WelcomeStepState<ExploreWelcomeStep>>();
    _steps = <_WelcomeStep<StatefulWidget>>[
      _WelcomeStep<FlutterWelcomeStep>(initialStepKey, FlutterWelcomeStep(key: initialStepKey)),
      _WelcomeStep<PlaygroundWelcomeStep>(playgroundStepKey, PlaygroundWelcomeStep(key: playgroundStepKey)),
      _WelcomeStep<DocumentationWelcomeStep>(documentationStepKey, DocumentationWelcomeStep(key: documentationStepKey)),
      _WelcomeStep<ExploreWelcomeStep>(exploreStepKey, ExploreWelcomeStep(key: exploreStepKey)),
    ];
    _tabController = TabController(initialIndex: 0, length: _steps.length, vsync: this);
    _pageController = PageController();
    _autoProgressTimer = _scheduleAutoProgressStepTimer();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    // We need to account for the bottom padding on ios so that we can draw
    // a solid color in that space. Don't use safearea or it will avoid that
    // space totally and not paint a color. Not needed on android as it has
    // a fixed navigation bar.
    final double footerHeight = footerButtonHeight +
        (Platform.isIOS ? mediaQueryData.padding.bottom : 0.0);
    return WillPopScope(
      onWillPop: () => Future<bool>.value(false),
      child: Material(
        color: kWelcomeBlue,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            _autoProgressTimer.cancel();
            _autoProgressTimer = _scheduleAutoProgressStepTimer();
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: footerHeight),
                  child: PageView.builder(
                    itemCount: _kSteps,
                    itemBuilder: (BuildContext context, int index) => _steps[index].widget,
                    controller: _pageController,
                    onPageChanged: (int page) {
                      _tabController.animateTo(page);
                      _steps[page].key.currentState.animate(restart: true);
                    },
                  ),
                ),
              ),
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: footerHeight + 20.0),
                  child: _pageIndicator(),
                ),
              ),
              Positioned.fill(
                top: null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: footerButtonHeight,
                      child: FlatButton(
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        color: footerColor,
                        child: const Text(
                          'START EXPLORING',
                          style: footerButtonTextStyle,
                        ),
                        onPressed: () {
                          _autoProgressTimer.cancel();
                          if (widget.onDismissed != null) {
                            widget.onDismissed();
                          }
                        },
                      ),
                    ),
                    Container(
                      color: footerColor,
                      height: mediaQueryData.padding.bottom,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TabPageSelector _pageIndicator() {
    return TabPageSelector(
      controller: _tabController,
      color: const Color(0x99ffffff),
      selectedColor: const Color(0xffffffff),
    );
  }

  Timer _scheduleAutoProgressStepTimer() {
    return Timer.periodic(Duration(seconds: _kAutoProgressSeconds), (_) {
      int nextPage = _pageController.page.ceil() + 1;
      if (nextPage == _kSteps) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: _kAutoProgressTransitionMilliseconds),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
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

class _WelcomeStep<T extends StatefulWidget> {
  _WelcomeStep(this.key, this.widget);
  final GlobalKey<WelcomeStepState<T>> key;
  final Widget widget;
}
