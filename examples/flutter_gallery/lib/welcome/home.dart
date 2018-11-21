// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'manager.dart';
import 'step.dart';

class Welcome extends StatefulWidget {
  const Welcome({Key key}) : super(key: key);
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  
  final List<WelcomeStep> _steps = WelcomeManager().steps();
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(initialIndex: 0, length: _steps.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // final List<Widget> children = <Widget>[];
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: PageView(
            children:
                _steps.map((WelcomeStep step) => step.contentWidget()).toList(),
            onPageChanged: (int page) {
              _tabController.animateTo(page);
            },
          ),
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: _pageIndicator(),
          ),
        ),
      ],
    );
  }

  TabPageSelector _pageIndicator() => TabPageSelector(
        controller: _tabController,
        color: const Color(0x99ffffff),
        selectedColor: const Color(0xffffffff),
      );
}
