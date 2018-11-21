// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/steps/playground_step.dart';

import 'step.dart';
import 'steps/all.dart';

const Color _kWelcomeBlue = Color(0xFF0175c2);

class Welcome extends StatefulWidget {
  const Welcome({Key key}) : super(key: key);
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  List<WelcomeStep> _steps;
  TabController _tabController;

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
  }

  final Color footerColor = const Color(0xffffffff);
  final TextStyle footerButtonTextStyle = const TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: _kWelcomeBlue,
  );
  final double footerButtonHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double footerHeight = footerButtonHeight +
        (Platform.isIOS ? mediaQueryData.padding.bottom : 0.0);
    return Material(
      color: _kWelcomeBlue,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: footerHeight),
              child: PageView(
                children: _steps
                    .map((WelcomeStep step) => step.contentWidget())
                    .toList(),
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
                    child: Text(
                      'START EXPLORING',
                      style: footerButtonTextStyle,
                    ),
                    onPressed: () {},
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
    );
  }

  TabPageSelector _pageIndicator() => TabPageSelector(
        controller: _tabController,
        color: const Color(0x99ffffff),
        selectedColor: const Color(0xffffffff),
      );
}
