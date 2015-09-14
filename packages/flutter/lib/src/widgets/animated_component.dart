// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/widgets/framework.dart';

abstract class AnimatedComponent extends StatefulComponent {

  AnimatedComponent({ Key key, this.direction, this.duration }) : super(key: key);

  Duration duration;
  Direction direction;

  void syncConstructorArguments(AnimatedComponent source) {
    bool resumePerformance = false;
    if (duration != source.duration) {
      duration = source.duration;
      resumePerformance = true;
    }
    if (direction != source.direction) {
      direction = source.direction;
      resumePerformance = true;
    }
    if (resumePerformance)
      performance.play(direction);
  }

  AnimationPerformance get performance => _performance;
  AnimationPerformance _performance;

  void initState() {
    _performance = new AnimationPerformance(duration: duration);
    performance.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed)
        handleCompleted();
      else if (status == AnimationStatus.dismissed)
        handleDismissed();
    });
    if (buildDependsOnPerformance) {
      performance.addListener(() {
        setState(() {
          // We don't actually have any state to change, per se,
          // we just know that we have in fact changed state.
        });
      });
    }
    performance.play(direction);
  }

  bool get buildDependsOnPerformance => false;
  void handleCompleted() { }
  void handleDismissed() { }

}
