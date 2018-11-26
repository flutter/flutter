// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'step.dart';
import 'steps/all.dart';

const Color _kWelcomeBlue = Color(0xFF0175c2);
const int _kAutoProgressSeconds = 10;
const int _kAutoProgressTransitionMilliseconds = 520;
const Color footerColor = Color(0xffffffff);
const TextStyle footerButtonTextStyle = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.bold,
  color: _kWelcomeBlue,
);
const double footerButtonHeight = 60.0;

class Welcome extends StatefulWidget {
  const Welcome({Key key, this.onDismissed}) : super(key: key);
  final VoidCallback onDismissed;

  static const String routeName = '/welcome';

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  List<WelcomeStep> _steps;
  TabController _tabController;
  PageController _pageController;
  Timer _autoProgressTimer;

  @override
  void initState() {
    super.initState();
    _steps = <WelcomeStep>[
      FlutterWelcomeStep(tickerProvider: this),
      PlaygroundWelcomeStep(tickerProvider: this),
      DocumentationWelcomeStep(tickerProvider: this),
      ExploreWelcomeStep(tickerProvider: this),
    ];
    _tabController =
        TabController(initialIndex: 0, length: _steps.length, vsync: this);
    _pageController = PageController();
    _autoProgressTimer = _scheduleAutoProgressStepTimer();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double footerHeight = footerButtonHeight +
        (Platform.isIOS ? mediaQueryData.padding.bottom : 0.0);
    return Material(
      color: _kWelcomeBlue,
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
                  itemCount: _steps.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _steps[index].contentWidget(),
                  controller: _pageController,
                  onPageChanged: (int page) {
                    _tabController.animateTo(page);
                    _steps[page].animate(restart: true);
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
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
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
      if (nextPage == _steps.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: _kAutoProgressTransitionMilliseconds),
        curve: Curves.easeInOut,
      );
    });
  }
}
