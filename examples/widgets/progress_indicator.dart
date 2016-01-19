// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class ProgressIndicatorApp extends StatefulComponent {
  _ProgressIndicatorAppState createState() => new _ProgressIndicatorAppState();
}

class _ProgressIndicatorAppState extends State<ProgressIndicatorApp> {
  void initState() {
    super.initState();
    controller = new AnimationController(
      duration: const Duration(milliseconds: 1500)
    )..play(AnimationDirection.forward);

    animation = new CurvedAnimation(
      parent: controller,
      curve: new Interval(0.0, 0.9, curve: Curves.ease),
      reverseCurve: Curves.ease
    )..addStatusListener((PerformanceStatus status) {
      if (status == PerformanceStatus.dismissed || status == PerformanceStatus.completed)
        reverseValueAnimationDirection();
    });
  }

  Animation animation;
  AnimationController controller;

  void handleTap() {
    setState(() {
      // valueAnimation.isAnimating is part of our build state
      if (controller.isAnimating)
        controller.stop();
      else
        controller.resume();
    });
  }

  void reverseValueAnimationDirection() {
    AnimationDirection direction = (controller.direction == AnimationDirection.forward)
      ? AnimationDirection.reverse
      : AnimationDirection.forward;
    controller.play(direction);
  }

  Widget buildIndicators(BuildContext context) {
    List<Widget> indicators = <Widget>[
        new SizedBox(
          width: 200.0,
          child: new LinearProgressIndicator()
        ),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(value: animation.progress),
        new CircularProgressIndicator(),
        new SizedBox(
            width: 20.0,
            height: 20.0,
            child: new CircularProgressIndicator(value: animation.progress)
        ),
        new SizedBox(
          width: 50.0,
          height: 30.0,
          child: new CircularProgressIndicator(value: animation.progress)
        ),
        new Text("${(animation.progress * 100.0).toStringAsFixed(1)}%" + (controller.isAnimating ? '' : ' (paused)'))
    ];
    return new Column(
      children: indicators
        .map((Widget c) => new Container(child: c, margin: const EdgeDims.symmetric(vertical: 15.0, horizontal: 20.0)))
        .toList(),
      justifyContent: FlexJustifyContent.center
    );
  }

  Widget build(BuildContext context) {
    Widget body = new GestureDetector(
      onTap: handleTap,
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
        child: new AnimationWatchingBuilder(
          watchable: animation,
          builder: buildIndicators
        )
      )
    );

    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: Colors.blue,
          accentColor: Colors.redAccent[200]
        ),
        child: new Scaffold(
          toolBar: new ToolBar(center: new Text('Progress Indicators')),
          body: new DefaultTextStyle(
            style: Theme.of(context).text.title,
            child: body
          )
        )
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Progress Indicators',
    routes: {
      '/': (RouteArguments args) => new ProgressIndicatorApp()
    }
  ));
}
