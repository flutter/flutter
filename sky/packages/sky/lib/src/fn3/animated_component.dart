// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/framework.dart';

abstract class AnimatedComponent extends StatefulComponent {
  const AnimatedComponent({ Key key, this.direction, this.duration }) : super(key: key);

  final Duration duration;
  final Direction direction;
}

abstract class AnimatedComponentState<T extends AnimatedComponent> extends ComponentState<T> {
  AnimatedComponentState(T config) : super(config) {
    _performance = new AnimationPerformance(duration: config.duration);
    performance.addStatusListener(_handleAnimationStatusChanged);
    if (buildDependsOnPerformance) {
      performance.addListener(() {
        setState(() {
          // We don't actually have any state to change, per se,
          // we just know that we have in fact changed state.
        });
      });
    }
    performance.play(config.direction);
  }

  void didUpdateConfig(T oldConfig) {
    performance.duration = config.duration;
    if (config.duration != oldConfig.duration || config.direction != oldConfig.direction)
      performance.play(config.direction);
  }

  AnimationPerformance get performance => _performance;
  AnimationPerformance _performance;

  void _handleAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      handleCompleted();
    else if (status == AnimationStatus.dismissed)
      handleDismissed();
  }

  bool get buildDependsOnPerformance => false;
  void handleCompleted() { }
  void handleDismissed() { }
}
