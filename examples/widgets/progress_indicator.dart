// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class ProgressIndicatorApp extends StatefulComponent {
  ProgressIndicatorAppState createState() => new ProgressIndicatorAppState();
}

class ProgressIndicatorAppState extends State<ProgressIndicatorApp> {
  void initState() {
    super.initState();
    valueAnimation = new ValuePerformance<double>()
      ..duration = const Duration(milliseconds: 1500)
      ..variable = new AnimatedValue<double>(
        0.0,
        end: 1.0,
        curve: new Interval(0.0, 0.9, curve: Curves.ease),
        reverseCurve: Curves.ease
      );
    valueAnimation.addStatusListener((PerformanceStatus status) {
      if (status == PerformanceStatus.dismissed || status == PerformanceStatus.completed)
        reverseValueAnimationDirection();
    });
    valueAnimation.play(valueAnimationDirection);
  }

  ValuePerformance<double> valueAnimation;
  AnimationDirection valueAnimationDirection = AnimationDirection.forward;

  void handleTap() {
    setState(() {
      // valueAnimation.isAnimating is part of our build state
      if (valueAnimation.isAnimating)
        valueAnimation.stop();
      else
        valueAnimation.resume();
    });
  }

  void reverseValueAnimationDirection() {
    valueAnimationDirection = (valueAnimationDirection == AnimationDirection.forward)
      ? AnimationDirection.reverse
      : AnimationDirection.forward;
    valueAnimation.play(valueAnimationDirection);
  }

  Widget buildIndicators(BuildContext context) {
    List<Widget> indicators = <Widget>[
        new SizedBox(
          width: 200.0,
          child: new LinearProgressIndicator()
        ),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(),
        new LinearProgressIndicator(value: valueAnimation.value),
        new CircularProgressIndicator(),
        new SizedBox(
            width: 20.0,
            height: 20.0,
            child: new CircularProgressIndicator(value: valueAnimation.value)
        ),
        new SizedBox(
          width: 50.0,
          height: 30.0,
          child: new CircularProgressIndicator(value: valueAnimation.value)
        ),
        new Text("${(valueAnimation.value * 100.0).toStringAsFixed(1)}%" + (valueAnimation.isAnimating ? '' : ' (paused)'))
    ];
    return new Column(
      indicators
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
        child: new BuilderTransition(
          variables: <AnimatedValue<double>>[valueAnimation.variable],
          performance: valueAnimation.view,
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
        child: new Title(
          title: 'Progress Indicators',
          child: new Scaffold(
            toolBar: new ToolBar(center: new Text('Progress Indicators')),
            body: new DefaultTextStyle(
              style: Theme.of(context).text.title,
              child: body
            )
          )
        )
      )
    );
  }
}

void main() {
  runApp(new ProgressIndicatorApp());
}
