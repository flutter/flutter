// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/widgets/framework.dart';

abstract class AnimatedComponent extends StatefulComponent {
  const AnimatedComponent({ Key key, this.direction, this.duration }) : super(key: key);

  final Duration duration;
  final AnimationDirection direction;
}

abstract class AnimatedState<T extends AnimatedComponent> extends State<T> {
  void initState() {
    super.initState();
    _performance = new Performance(duration: config.duration);
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

  Performance get performance => _performance;
  Performance _performance;

  void _handleAnimationStatusChanged(PerformanceStatus status) {
    if (status == PerformanceStatus.completed)
      handleCompleted();
    else if (status == PerformanceStatus.dismissed)
      handleDismissed();
  }

  bool get buildDependsOnPerformance => false;
  void handleCompleted() { }
  void handleDismissed() { }
}
