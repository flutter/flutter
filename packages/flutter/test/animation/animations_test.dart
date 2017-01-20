// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

class BogusCurve extends Curve {
  @override
  double transform(double t) => 100.0;
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.resetEpoch();
  });

  test('toString control test', () {
    expect(kAlwaysCompleteAnimation, hasOneLineDescription);
    expect(kAlwaysDismissedAnimation, hasOneLineDescription);
    expect(const AlwaysStoppedAnimation<double>(0.5), hasOneLineDescription);
    CurvedAnimation curvedAnimation = new CurvedAnimation(
      parent: kAlwaysDismissedAnimation,
      curve: Curves.ease
    );
    expect(curvedAnimation, hasOneLineDescription);
    curvedAnimation.reverseCurve = Curves.elasticOut;
    expect(curvedAnimation, hasOneLineDescription);
    AnimationController controller = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: const TestVSync(),
    );
    controller
      ..value = 0.5
      ..reverse();
    curvedAnimation = new CurvedAnimation(
      parent: controller,
      curve: Curves.ease,
      reverseCurve: Curves.elasticOut
    );
    expect(curvedAnimation, hasOneLineDescription);
    controller.stop();
  });

  test('ProxyAnimation.toString control test', () {
    ProxyAnimation animation = new ProxyAnimation();
    expect(animation.value, 0.0);
    expect(animation.status, AnimationStatus.dismissed);
    expect(animation, hasOneLineDescription);
    animation.parent = kAlwaysDismissedAnimation;
    expect(animation, hasOneLineDescription);
  });

  test('ProxyAnimation set parent generates value changed', () {
    AnimationController controller = new AnimationController(
      vsync: const TestVSync(),
    );
    controller.value = 0.5;
    bool didReceiveCallback = false;
    ProxyAnimation animation = new ProxyAnimation()
      ..addListener(() {
        didReceiveCallback = true;
      });
    expect(didReceiveCallback, isFalse);
    animation.parent = controller;
    expect(didReceiveCallback, isTrue);
    didReceiveCallback = false;
    expect(didReceiveCallback, isFalse);
    controller.value = 0.6;
    expect(didReceiveCallback, isTrue);
  });

  test('ReverseAnimation calls listeners', () {
    AnimationController controller = new AnimationController(
      vsync: const TestVSync(),
    );
    controller.value = 0.5;
    bool didReceiveCallback = false;
    void listener() {
      didReceiveCallback = true;
    }
    ReverseAnimation animation = new ReverseAnimation(controller)
      ..addListener(listener);
    expect(didReceiveCallback, isFalse);
    controller.value = 0.6;
    expect(didReceiveCallback, isTrue);
    didReceiveCallback = false;
    animation.removeListener(listener);
    expect(didReceiveCallback, isFalse);
    controller.value = 0.7;
    expect(didReceiveCallback, isFalse);
    expect(animation, hasOneLineDescription);
  });

  test('TrainHoppingAnimation', () {
    AnimationController currentTrain = new AnimationController(
      vsync: const TestVSync(),
    );
    AnimationController nextTrain = new AnimationController(
      vsync: const TestVSync(),
    );
    currentTrain.value = 0.5;
    nextTrain.value = 0.75;
    bool didSwitchTrains = false;
    TrainHoppingAnimation animation = new TrainHoppingAnimation(
      currentTrain, nextTrain, onSwitchedTrain: () {
        didSwitchTrains = true;
      });
    expect(didSwitchTrains, isFalse);
    expect(animation.value, 0.5);
    expect(animation, hasOneLineDescription);
    nextTrain.value = 0.25;
    expect(didSwitchTrains, isTrue);
    expect(animation.value, 0.25);
    expect(animation, hasOneLineDescription);
    expect(animation.toString(), contains('no next'));
  });

  test('AnimationMean control test', () {
    AnimationController left = new AnimationController(
      value: 0.5,
      vsync: const TestVSync(),
    );
    AnimationController right = new AnimationController(
      vsync: const TestVSync(),
    );

    AnimationMean mean = new AnimationMean(left: left, right: right);

    expect(mean, hasOneLineDescription);
    expect(mean.value, equals(0.25));

    List<double> log = <double>[];
    void logValue() {
      log.add(mean.value);
    }

    mean.addListener(logValue);

    right.value = 1.0;

    expect(mean.value, equals(0.75));
    expect(log, equals(<double>[0.75]));
    log.clear();

    mean.removeListener(logValue);

    left.value = 0.0;

    expect(mean.value, equals(0.50));
    expect(log, isEmpty);
  });

  test('CurvedAnimation with bogus curve', () {
    AnimationController controller = new AnimationController(
      vsync: const TestVSync(),
    );
    CurvedAnimation curved = new CurvedAnimation(parent: controller, curve: new BogusCurve());

    expect(() { curved.value; }, throwsFlutterError);
  });
}
