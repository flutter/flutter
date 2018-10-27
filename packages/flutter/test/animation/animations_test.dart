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
    CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: kAlwaysDismissedAnimation,
      curve: Curves.ease
    );
    expect(curvedAnimation, hasOneLineDescription);
    curvedAnimation.reverseCurve = Curves.elasticOut;
    expect(curvedAnimation, hasOneLineDescription);
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: const TestVSync(),
    );
    controller
      ..value = 0.5
      ..reverse();
    curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.ease,
      reverseCurve: Curves.elasticOut
    );
    expect(curvedAnimation, hasOneLineDescription);
    controller.stop();
  });

  test('ProxyAnimation.toString control test', () {
    final ProxyAnimation animation = ProxyAnimation();
    expect(animation.value, 0.0);
    expect(animation.status, AnimationStatus.dismissed);
    expect(animation, hasOneLineDescription);
    animation.parent = kAlwaysDismissedAnimation;
    expect(animation, hasOneLineDescription);
  });

  test('ProxyAnimation set parent generates value changed', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    controller.value = 0.5;
    bool didReceiveCallback = false;
    final ProxyAnimation animation = ProxyAnimation()
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
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    controller.value = 0.5;
    bool didReceiveCallback = false;
    void listener() {
      didReceiveCallback = true;
    }
    final ReverseAnimation animation = ReverseAnimation(controller)
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
    final AnimationController currentTrain = AnimationController(
      vsync: const TestVSync(),
    );
    final AnimationController nextTrain = AnimationController(
      vsync: const TestVSync(),
    );
    currentTrain.value = 0.5;
    nextTrain.value = 0.75;
    bool didSwitchTrains = false;
    final TrainHoppingAnimation animation = TrainHoppingAnimation(
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
    final AnimationController left = AnimationController(
      value: 0.5,
      vsync: const TestVSync(),
    );
    final AnimationController right = AnimationController(
      vsync: const TestVSync(),
    );

    final AnimationMean mean = AnimationMean(left: left, right: right);

    expect(mean, hasOneLineDescription);
    expect(mean.value, equals(0.25));

    final List<double> log = <double>[];
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

  test('AnimationMax control test', () {
    final AnimationController first = AnimationController(
      value: 0.5,
      vsync: const TestVSync(),
    );
    final AnimationController second = AnimationController(
      vsync: const TestVSync(),
    );

    final AnimationMax<double> max = AnimationMax<double>(first, second);

    expect(max, hasOneLineDescription);
    expect(max.value, equals(0.5));

    final List<double> log = <double>[];
    void logValue() {
      log.add(max.value);
    }

    max.addListener(logValue);

    second.value = 1.0;

    expect(max.value, equals(1.0));
    expect(log, equals(<double>[1.0]));
    log.clear();

    max.removeListener(logValue);

    first.value = 0.0;

    expect(max.value, equals(1.0));
    expect(log, isEmpty);
  });

  test('AnimationMin control test', () {
    final AnimationController first = AnimationController(
      value: 0.5,
      vsync: const TestVSync(),
    );
    final AnimationController second = AnimationController(
      vsync: const TestVSync(),
    );

    final AnimationMin<double> min = AnimationMin<double>(first, second);

    expect(min, hasOneLineDescription);
    expect(min.value, equals(0.0));

    final List<double> log = <double>[];
    void logValue() {
      log.add(min.value);
    }

    min.addListener(logValue);

    second.value = 1.0;

    expect(min.value, equals(0.5));
    expect(log, equals(<double>[0.5]));
    log.clear();

    min.removeListener(logValue);

    first.value = 0.25;

    expect(min.value, equals(0.25));
    expect(log, isEmpty);
  });

  test('CurvedAnimation with bogus curve', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    final CurvedAnimation curved = CurvedAnimation(parent: controller, curve: BogusCurve());

    expect(() { curved.value; }, throwsFlutterError);
  });

  test('TweenSequence', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );

    final Animation<double> animation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 5.0, end: 10.0),
          weight: 4.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(10.0),
          weight: 2.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 10.0, end: 5.0),
          weight: 4.0,
        ),
      ],
    ).animate(controller);

    expect(animation.value, 5.0);

    controller.value = 0.2;
    expect(animation.value, 7.5);

    controller.value = 0.4;
    expect(animation.value, 10.0);

    controller.value = 0.6;
    expect(animation.value, 10.0);

    controller.value = 0.8;
    expect(animation.value, 7.5);

    controller.value = 1.0;
    expect(animation.value, 5.0);
  });

  test('TweenSequence with curves', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );

    final Animation<double> animation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 5.0, end: 10.0)
            .chain(CurveTween(curve: const Interval(0.5, 1.0))),
          weight: 4.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(10.0)
            .chain(CurveTween(curve: Curves.linear)), // linear is a no-op
          weight: 2.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 10.0, end: 5.0)
            .chain(CurveTween(curve: const Interval(0.0, 0.5))),
          weight: 4.0,
        ),
      ],
    ).animate(controller);

    expect(animation.value, 5.0);

    controller.value = 0.2;
    expect(animation.value, 5.0);

    controller.value = 0.4;
    expect(animation.value, 10.0);

    controller.value = 0.6;
    expect(animation.value, 10.0);

    controller.value = 0.8;
    expect(animation.value, 5.0);

    controller.value = 1.0;
    expect(animation.value, 5.0);
  });

  test('TweenSequence, one tween', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );

    final Animation<double> animation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 5.0, end: 10.0),
          weight: 1.0,
        ),
      ],
    ).animate(controller);

    expect(animation.value, 5.0);

    controller.value = 0.5;
    expect(animation.value, 7.5);

    controller.value = 1.0;
    expect(animation.value, 10.0);
  });

}
