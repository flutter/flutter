// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ProgressIndicatorDemo extends StatefulWidget {
  @override
  _ProgressIndicatorDemoState createState() => new _ProgressIndicatorDemoState();
}

class _ProgressIndicatorDemoState extends State<ProgressIndicatorDemo> {

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
      duration: const Duration(milliseconds: 1500)
    )..forward();

    animation = new CurvedAnimation(
      parent: controller,
      curve: new Interval(0.0, 0.9, curve: Curves.ease),
      reverseCurve: Curves.ease
    )..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed)
        controller.forward();
      else if (status == AnimationStatus.completed)
        controller.reverse();
    });
  }

  Animation<double> animation;
  AnimationController controller;

  void _handleTap() {
    setState(() {
      // valueAnimation.isAnimating is part of our build state
      if (controller.isAnimating) {
        controller.stop();
      } else {
        switch (controller.status) {
          case AnimationStatus.dismissed:
          case AnimationStatus.forward:
            controller.forward();
            break;
          case AnimationStatus.reverse:
          case AnimationStatus.completed:
            controller.reverse();
            break;
        }
      }
    });
  }

  Widget _buildIndicators(BuildContext context, Widget child) {
    List<Widget> indicators = <Widget>[
        new SizedBox(
          width: 200.0,
          child: new LinearProgressIndicator()
        ),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(value: animation.value),
        new CircularProgressIndicator(),
        new SizedBox(
            width: 20.0,
            height: 20.0,
            child: new CircularProgressIndicator(value: animation.value)
        ),
        new SizedBox(
          width: 50.0,
          height: 30.0,
          child: new CircularProgressIndicator(value: animation.value)
        ),
        new Text('${(animation.value * 100.0).toStringAsFixed(1)}%${ controller.isAnimating ? "" : " (paused)" }')
    ];
    return new Column(
      children: indicators
        .map((Widget c) => new Container(child: c, margin: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0)))
        .toList(),
      mainAxisAlignment: MainAxisAlignment.center
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Progress indicators')),
      body: new DefaultTextStyle(
        style: Theme.of(context).textTheme.title,
        child: new GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: new Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: new AnimatedBuilder(
              animation: animation,
              builder: _buildIndicators
            )
          )
        )
      )
    );
  }
}
