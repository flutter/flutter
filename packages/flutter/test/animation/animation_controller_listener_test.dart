// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('Disposing controller removes listeners to avoid memory leaks', () {
    final _TestAnimationController controller = _TestAnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    int statusListener = 0;
    int listener = 0;
    controller.addListener(() {
      listener++;
    });
    controller.addStatusListener((AnimationStatus _) {
      statusListener++;
    });
    expect(statusListener, 0);
    expect(listener, 0);

    controller.publicNotifyListeners();
    controller.publicNotifyStatusListeners(AnimationStatus.completed);
    expect(statusListener, 1);
    expect(listener, 1);

    controller.dispose();
    controller.publicNotifyListeners();
    controller.publicNotifyStatusListeners(AnimationStatus.completed);
    expect(statusListener, 1);
    expect(listener, 1);
  });
}

class _TestAnimationController extends AnimationController {
  _TestAnimationController({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    required TickerProvider vsync,
  }) : super(
      value: value,
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
      vsync: vsync,
  );

  void publicNotifyListeners() {
    super.notifyListeners();
  }

  void publicNotifyStatusListeners(AnimationStatus status) {
    super.notifyStatusListeners(status);
  }
}
