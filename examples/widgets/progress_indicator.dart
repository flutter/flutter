// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

class ProgressIndicatorApp extends App {

  ValueAnimation<double> valueAnimation;
  Direction valueAnimationDirection = Direction.forward;

  void initState() {
    super.initState();
    valueAnimation = new ValueAnimation<double>()
      ..duration = const Duration(milliseconds: 1500)
      ..variable = new AnimatedValue<double>(
        0.0,
        end: 1.0,
        curve: ease,
        reverseCurve: ease,
        interval: new Interval(0.0, 0.9)
      );
  }

  void handleTap(sky.GestureEvent event) {
    if (valueAnimation.isAnimating)
      valueAnimation.stop();
    else
      valueAnimation.resume();
  }

  void reverseValueAnimationDirection() {
    setState(() {
      valueAnimationDirection = (valueAnimationDirection == Direction.forward)
        ? Direction.reverse
        : Direction.forward;
    });
  }

  Widget buildIndicators() {
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
        )
    ];
    return new Flex(
      indicators
        .map((c) => new Container(child: c, margin: const EdgeDims.symmetric(vertical: 20.0)))
        .toList(),
      direction: FlexDirection.vertical,
      justifyContent: FlexJustifyContent.center
    );
  }

  Widget build() {
    Widget body = new Listener(
      onGestureTap: (e) { handleTap(e); },
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: new BoxDecoration(backgroundColor: Theme.of(this).cardColor),
        child: new BuilderTransition(
          variables: [valueAnimation.variable],
          direction: valueAnimationDirection,
          performance: valueAnimation,
          onDismissed: reverseValueAnimationDirection,
          onCompleted: reverseValueAnimationDirection,
          builder: buildIndicators
        )
      )
    );

    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: colors.Blue,
          accentColor: colors.RedAccent[200]
        ),
        child: new Title(
          title: 'Cards',
          child: new Scaffold(
            toolbar: new ToolBar(center: new Text('Progress Indicators')),
            body: body
          )
        )
      )
    );
  }
}

void main() {
  runApp(new ProgressIndicatorApp());
}
