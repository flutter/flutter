// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/widgets/basic.dart';

abstract class AnimatedComponent extends StatefulComponent {

  AnimatedComponent({ String key }) : super(key: key);

  void syncFields(AnimatedComponent source) { }

  final List<AnimationPerformance> _watchedPerformances = new List<AnimationPerformance>();

  void watch(AnimationPerformance performance) {
    assert(!_watchedPerformances.contains(performance));
    _watchedPerformances.add(performance);
    if (mounted)
      performance.addListener(scheduleBuild);
  }

  void didMount() {
    for (AnimationPerformance performance in _watchedPerformances)
      performance.addListener(scheduleBuild);
    super.didMount();
  }

  void didUnmount() {
    for (AnimationPerformance performance in _watchedPerformances)
      performance.removeListener(scheduleBuild);
    super.didUnmount();
  }

}
