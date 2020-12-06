// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../scheduler/scheduler_tester.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.resetEpoch();
    ui.window.onBeginFrame = null;
    ui.window.onDrawFrame = null;
  });

  test('Can set value during status callback', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    bool didComplete = false;
    bool didDismiss = false;
    controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        didComplete = true;
        controller.value = 0.0;
        controller.forward();
      } else if (status == AnimationStatus.dismissed) {
        didDismiss = true;
        controller.value = 0.0;
        controller.forward();
      }
    });

    controller.forward();
    expect(didComplete, isFalse);
    expect(didDismiss, isFalse);
    tick(const Duration(seconds: 1));
    expect(didComplete, isFalse);
    expect(didDismiss, isFalse);
    tick(const Duration(seconds: 2));
    expect(didComplete, isTrue);
    expect(didDismiss, isTrue);

    controller.stop();
  });

  test('Receives status callbacks for forward and reverse', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    final List<double> valueLog = <double>[];
    final List<AnimationStatus> log = <AnimationStatus>[];
    controller
      ..addStatusListener(log.add)
      ..addListener(() {
        valueLog.add(controller.value);
      });

    expect(log, equals(<AnimationStatus>[]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.forward();

    expect(log, equals(<AnimationStatus>[AnimationStatus.forward]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.reverse();

    expect(log, equals(<AnimationStatus>[AnimationStatus.forward, AnimationStatus.dismissed]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.reverse();

    expect(log, equals(<AnimationStatus>[AnimationStatus.forward, AnimationStatus.dismissed]));
    expect(valueLog, equals(<AnimationStatus>[]));

    log.clear();
    controller.forward();

    expect(log, equals(<AnimationStatus>[AnimationStatus.forward]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.forward();

    expect(log, equals(<AnimationStatus>[AnimationStatus.forward]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.reverse();
    log.clear();

    tick(const Duration(seconds: 10));
    expect(log, equals(<AnimationStatus>[]));
    expect(valueLog, equals(<AnimationStatus>[]));
    tick(const Duration(seconds: 20));
    expect(log, equals(<AnimationStatus>[]));
    expect(valueLog, equals(<AnimationStatus>[]));
    tick(const Duration(seconds: 30));
    expect(log, equals(<AnimationStatus>[]));
    expect(valueLog, equals(<AnimationStatus>[]));
    tick(const Duration(seconds: 40));
    expect(log, equals(<AnimationStatus>[]));
    expect(valueLog, equals(<AnimationStatus>[]));

    controller.stop();
  });

  test('Forward and reverse from values', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    final List<double> valueLog = <double>[];
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    controller
      ..addStatusListener(statusLog.add)
      ..addListener(() {
        valueLog.add(controller.value);
      });

    controller.reverse(from: 0.2);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.reverse ]));
    expect(valueLog, equals(<double>[ 0.2 ]));
    expect(controller.value, equals(0.2));
    statusLog.clear();
    valueLog.clear();

    controller.forward(from: 0.0);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.dismissed, AnimationStatus.forward ]));
    expect(valueLog, equals(<double>[ 0.0 ]));
    expect(controller.value, equals(0.0));
  });

  test('Forward and reverse with different durations', () {
    AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 50),
      vsync: const TestVSync(),
    );

    controller.forward();
    tick(const Duration(milliseconds: 10));
    tick(const Duration(milliseconds: 30));
    expect(controller.value, moreOrLessEquals(0.2));
    tick(const Duration(milliseconds: 60));
    expect(controller.value, moreOrLessEquals(0.5));
    tick(const Duration(milliseconds: 90));
    expect(controller.value, moreOrLessEquals(0.8));
    tick(const Duration(milliseconds: 120));
    expect(controller.value, moreOrLessEquals(1.0));
    controller.stop();

    controller.reverse();
    tick(const Duration(milliseconds: 210));
    tick(const Duration(milliseconds: 220));
    expect(controller.value, moreOrLessEquals(0.8));
    tick(const Duration(milliseconds: 230));
    expect(controller.value, moreOrLessEquals(0.6));
    tick(const Duration(milliseconds: 240));
    expect(controller.value, moreOrLessEquals(0.4));
    tick(const Duration(milliseconds: 260));
    expect(controller.value, moreOrLessEquals(0.0));
    controller.stop();

    // Swap which duration is longer.
    controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );

    controller.forward();
    tick(const Duration(milliseconds: 10));
    tick(const Duration(milliseconds: 30));
    expect(controller.value, moreOrLessEquals(0.4));
    tick(const Duration(milliseconds: 60));
    expect(controller.value, moreOrLessEquals(1.0));
    tick(const Duration(milliseconds: 90));
    expect(controller.value, moreOrLessEquals(1.0));
    controller.stop();

    controller.reverse();
    tick(const Duration(milliseconds: 210));
    tick(const Duration(milliseconds: 220));
    expect(controller.value, moreOrLessEquals(0.9));
    tick(const Duration(milliseconds: 230));
    expect(controller.value, moreOrLessEquals(0.8));
    tick(const Duration(milliseconds: 240));
    expect(controller.value, moreOrLessEquals(0.7));
    tick(const Duration(milliseconds: 260));
    expect(controller.value, moreOrLessEquals(0.5));
    tick(const Duration(milliseconds: 310));
    expect(controller.value, moreOrLessEquals(0.0));
    controller.stop();
  });

  test('Forward only from value', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    final List<double> valueLog = <double>[];
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    controller
      ..addStatusListener(statusLog.add)
      ..addListener(() {
        valueLog.add(controller.value);
      });

    controller.forward(from: 0.2);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward ]));
    expect(valueLog, equals(<double>[ 0.2 ]));
    expect(controller.value, equals(0.2));
  });

  test('Can fling to upper and lower bounds', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );

    controller.fling();
    tick(const Duration(seconds: 1));
    tick(const Duration(seconds: 2));
    expect(controller.value, 1.0);
    controller.stop();

    final AnimationController largeRangeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      lowerBound: -30.0,
      upperBound: 45.0,
      vsync: const TestVSync(),
    );

    largeRangeController.fling();
    tick(const Duration(seconds: 3));
    tick(const Duration(seconds: 4));
    expect(largeRangeController.value, 45.0);
    largeRangeController.fling(velocity: -1.0);
    tick(const Duration(seconds: 5));
    tick(const Duration(seconds: 6));
    expect(largeRangeController.value, -30.0);
    largeRangeController.stop();
  });

  test('lastElapsedDuration control test', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    controller.forward();
    tick(const Duration(milliseconds: 20));
    tick(const Duration(milliseconds: 30));
    tick(const Duration(milliseconds: 40));
    expect(controller.lastElapsedDuration, equals(const Duration(milliseconds: 20)));
    controller.stop();
  });

  test('toString control test', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    expect(controller, hasOneLineDescription);
    controller.forward();
    tick(const Duration(milliseconds: 10));
    tick(const Duration(milliseconds: 20));
    expect(controller, hasOneLineDescription);
    tick(const Duration(milliseconds: 30));
    expect(controller, hasOneLineDescription);
    controller.reverse();
    tick(const Duration(milliseconds: 40));
    tick(const Duration(milliseconds: 50));
    expect(controller, hasOneLineDescription);
    controller.stop();
  });

  test('velocity test - linear', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: const TestVSync(),
    );

    // mid-flight
    controller.forward();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 500));
    expect(controller.velocity, inInclusiveRange(0.9, 1.1));

    // edges
    controller.forward();
    expect(controller.velocity, inInclusiveRange(0.4, 0.6));
    tick(Duration.zero);
    expect(controller.velocity, inInclusiveRange(0.4, 0.6));
    tick(const Duration(milliseconds: 5));
    expect(controller.velocity, inInclusiveRange(0.9, 1.1));

    controller.forward(from: 0.5);
    expect(controller.velocity, inInclusiveRange(0.4, 0.6));
    tick(Duration.zero);
    expect(controller.velocity, inInclusiveRange(0.4, 0.6));
    tick(const Duration(milliseconds: 5));
    expect(controller.velocity, inInclusiveRange(0.9, 1.1));

    // stopped
    controller.forward(from: 1.0);
    expect(controller.velocity, 0.0);
    tick(Duration.zero);
    expect(controller.velocity, 0.0);
    tick(const Duration(milliseconds: 500));
    expect(controller.velocity, 0.0);

    controller.forward();
    tick(Duration.zero);
    tick(const Duration(milliseconds: 1000));
    expect(controller.velocity, 0.0);

    controller.stop();
  });

  test('Disposed AnimationController toString works', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );
    controller.dispose();
    expect(controller, hasOneLineDescription);
  });

  test('AnimationController error handling', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );

    expect(controller.forward, throwsFlutterError);
    expect(controller.reverse, throwsFlutterError);
    expect(() { controller.animateTo(0.5); }, throwsFlutterError);
    expect(controller.repeat, throwsFlutterError);

    controller.dispose();
    FlutterError result;
    try {
      controller.dispose();
    } on FlutterError catch (e) {
      result = e;
    }
    expect(result, isNotNull);
    expect(
      result.toStringDeep(),
      equalsIgnoringHashCodes(
        'FlutterError\n'
        '   AnimationController.dispose() called more than once.\n'
        '   A given AnimationController cannot be disposed more than once.\n'
        '   The following AnimationController object was disposed multiple\n'
        '   times:\n'
        '     AnimationController#00000(⏮ 0.000; paused; DISPOSED)\n'
      ),
    );
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    result.debugFillProperties(builder);
    final DiagnosticsNode controllerProperty = builder.properties.last;
    expect(controllerProperty.name, 'The following AnimationController object was disposed multiple times');
    expect(controllerProperty.value, controller);
  });

  test('AnimationController repeat() throws if period is not specified', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    expect(() { controller.repeat(); }, throwsFlutterError);
    expect(() { controller.repeat(period: null); }, throwsFlutterError);
  });

  test('Do not animate if already at target', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];

    final AnimationController controller = AnimationController(
      value: 0.5,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, equals(0.5));
    controller.animateTo(0.5, duration: const Duration(milliseconds: 100));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.completed ]));
    expect(controller.value, equals(0.5));
  });

  test('Do not animate to upperBound if already at upperBound', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];

    final AnimationController controller = AnimationController(
      value: 1.0,
      upperBound: 1.0,
      lowerBound: 0.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, equals(1.0));
    controller.animateTo(1.0, duration: const Duration(milliseconds: 100));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.completed ]));
    expect(controller.value, equals(1.0));
  });

  test('Do not animate to lowerBound if already at lowerBound', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];

    final AnimationController controller = AnimationController(
      value: 0.0,
      upperBound: 1.0,
      lowerBound: 0.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, equals(0.0));
    controller.animateTo(0.0, duration: const Duration(milliseconds: 100));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.completed ]));
    expect(controller.value, equals(0.0));
  });

  test('Do not animate if already at target mid-flight (forward)', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 1000),
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, equals(0.0));

    controller.forward();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 500));
    expect(controller.value, inInclusiveRange(0.4, 0.6));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward ]));

    final double currentValue = controller.value;
    controller.animateTo(currentValue, duration: const Duration(milliseconds: 100));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    expect(controller.value, currentValue);
  });

  test('Do not animate if already at target mid-flight (reverse)', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      value: 1.0,
      duration: const Duration(milliseconds: 1000),
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, equals(1.0));

    controller.reverse();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 500));
    expect(controller.value, inInclusiveRange(0.4, 0.6));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.reverse ]));

    final double currentValue = controller.value;
    controller.animateTo(currentValue, duration: const Duration(milliseconds: 100));
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.reverse, AnimationStatus.completed ]));
    expect(controller.value, currentValue);
  });

  test('animateTo can deal with duration == Duration.zero', () {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: const TestVSync(),
    );

    controller.forward(from: 0.2);
    expect(controller.value, 0.2);
    controller.animateTo(1.0, duration: Duration.zero);
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0), reason: 'Expected no animation.');
    expect(controller.value, 1.0);
  });

  test('resetting animation works at all phases', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);

    controller.reset();

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);

    statusLog.clear();
    controller.forward();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 50));
    expect(controller.status, AnimationStatus.forward);
    controller.reset();

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.dismissed ]));

    controller.value = 1.0;
    statusLog.clear();
    controller.reverse();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 50));
    expect(controller.status, AnimationStatus.reverse);
    controller.reset();

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.reverse, AnimationStatus.dismissed ]));

    statusLog.clear();
    controller.forward();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.status, AnimationStatus.completed);
    controller.reset();

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed, AnimationStatus.dismissed ]));
  });

  test('setting value directly sets correct status', () {
    final AnimationController controller = AnimationController(
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: const TestVSync(),
    );

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);

    controller.value = 0.5;
    expect(controller.value, 0.5);
    expect(controller.status, AnimationStatus.forward);

    controller.value = 1.0;
    expect(controller.value, 1.0);
    expect(controller.status, AnimationStatus.completed);

    controller.value = 0.5;
    expect(controller.value, 0.5);
    expect(controller.status, AnimationStatus.forward);

    controller.value = 0.0;
    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);
  });

  test('animateTo sets correct status', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);

    // Animate from 0.0 to 0.5
    controller.animateTo(0.5);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.5);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();

    // Animate from 0.5 to 1.0
    controller.animateTo(1.0);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 1.0);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();

    // Animate from 1.0 to 0.5
    controller.animateTo(0.5);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.5);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();

    // Animate from 0.5 to 1.0
    controller.animateTo(0.0);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.0);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();
  });

  test('after a reverse call animateTo sets correct status', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, 1.0);
    expect(controller.status, AnimationStatus.completed);

    controller.reverse();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.0);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.reverse, AnimationStatus.dismissed ]));
    statusLog.clear();

    controller.animateTo(0.5);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.5);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();
  });

  test('after a forward call animateTo sets correct status', () {
    final List<AnimationStatus> statusLog = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: const TestVSync(),
    )..addStatusListener(statusLog.add);

    expect(controller.value, 0.0);
    expect(controller.status, AnimationStatus.dismissed);

    controller.forward();
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 1.0);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();

    controller.animateTo(0.5);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 150));
    expect(controller.value, 0.5);
    expect(statusLog, equals(<AnimationStatus>[ AnimationStatus.forward, AnimationStatus.completed ]));
    statusLog.clear();
  });

  test(
    'calling repeat with reverse set to true makes the animation alternate '
    'between lowerBound and upperBound values on each repeat',
    () {
      final AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 100),
        value: 0.0,
        lowerBound: 0.0,
        upperBound: 1.0,
        vsync: const TestVSync(),
      );

      expect(controller.value, 0.0);

      controller.repeat(reverse: true);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 25));
      expect(controller.value, 0.25);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 125));
      expect(controller.value, 0.75);

      controller.reset();
      controller.value = 1.0;
      expect(controller.value, 1.0);

      controller.repeat(reverse: true);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 25));
      expect(controller.value, 0.75);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 125));
      expect(controller.value, 0.25);

      controller.reset();
      controller.value = 0.5;
      expect(controller.value, 0.5);

      controller.repeat(reverse: true);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 50));
      expect(controller.value, 1.0);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 150));
      expect(controller.value, 0.0);
    },
  );

  test(
    'calling repeat with specified min and max values makes the animation '
    'alternate between min and max values on each repeat',
    () {
      final AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 100),
        value: 0.0,
        lowerBound: 0.0,
        upperBound: 1.0,
        vsync: const TestVSync(),
      );

      expect(controller.value, 0.0);

      controller.repeat(reverse: true, min: 0.5, max: 1.0);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 50));
      expect(controller.value, 0.75);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 100));
      expect(controller.value, 1.00);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 200));
      expect(controller.value, 0.5);

      controller.reset();
      controller.value = 0.0;
      expect(controller.value, 0.0);

      controller.repeat(reverse: true, min: 1.0, max: 1.0);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 25));
      expect(controller.value, 1.0);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 125));
      expect(controller.value, 1.0);
    },
  );

  group('AnimationBehavior', () {
    test('Default values for constructor', () {
      final AnimationController controller = AnimationController(vsync: const TestVSync());
      expect(controller.animationBehavior, AnimationBehavior.normal);

      final AnimationController repeating = AnimationController.unbounded(vsync: const TestVSync());
      expect(repeating.animationBehavior, AnimationBehavior.preserve);
    });

    test('AnimationBehavior.preserve runs at normal speed when animatingTo', () async {
      debugSemanticsDisableAnimations = true;
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
        animationBehavior: AnimationBehavior.preserve,
      );

      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);

      controller.animateTo(1.0, duration: const Duration(milliseconds: 100));
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 50));

      expect(controller.value, 0.5);
      expect(controller.status, AnimationStatus.forward);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 150));

      expect(controller.value, 1.0);
      expect(controller.status, AnimationStatus.completed);
      debugSemanticsDisableAnimations = false;
    });

    test('AnimationBehavior.normal runs at 20x speed when animatingTo', () async {
      debugSemanticsDisableAnimations = true;
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
        animationBehavior: AnimationBehavior.normal,
      );

      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);

      controller.animateTo(1.0, duration: const Duration(milliseconds: 100));
      tick(const Duration(milliseconds: 0));
      tick(const Duration(microseconds: 2500));

      expect(controller.value, 0.5);
      expect(controller.status, AnimationStatus.forward);

      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 5, microseconds: 1000));

      expect(controller.value, 1.0);
      expect(controller.status, AnimationStatus.completed);
      debugSemanticsDisableAnimations = null;
    });

    test('AnimationBehavior.normal runs "faster" than AnimationBehavior.preserve', () {
      debugSemanticsDisableAnimations = true;
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
      );
      final AnimationController fastController = AnimationController(
        vsync: const TestVSync(),
      );

      controller.fling(velocity: 1.0, animationBehavior: AnimationBehavior.preserve);
      fastController.fling(velocity: 1.0, animationBehavior: AnimationBehavior.normal);
      tick(const Duration(milliseconds: 0));
      tick(const Duration(milliseconds: 50));

      // We don't assert a specific faction that normal animation.
      expect(controller.value < fastController.value, true);
      debugSemanticsDisableAnimations = null;
    });
  });

  test('AnimationController methods assert _ticker is not null', () {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );

    controller.dispose();

    expect(() => controller.animateBack(0), throwsAssertionError);
    expect(() => controller.animateTo(0), throwsAssertionError);
    expect(() => controller.animateWith(GravitySimulation(0, 0, 0, 0)), throwsAssertionError);
    expect(() => controller.stop(), throwsAssertionError);
    expect(() => controller.forward(), throwsAssertionError);
    expect(() => controller.reverse(), throwsAssertionError);
  });

  test('Simulations run forward', () {
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    )..addStatusListener((AnimationStatus status) {
      statuses.add(status);
    });

    controller.animateWith(TestSimulation());
    tick(const Duration(milliseconds: 0));
    tick(const Duration(seconds: 2));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
  });

  test('Simulations run forward even after a reverse run', () {
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    )..addStatusListener((AnimationStatus status) {
      statuses.add(status);
    });
    controller.reverse(from: 1.0);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(seconds: 2));
    expect(statuses, <AnimationStatus>[AnimationStatus.completed, AnimationStatus.reverse, AnimationStatus.dismissed]);
    statuses.clear();

    controller.animateWith(TestSimulation());
    tick(const Duration(milliseconds: 0));
    tick(const Duration(seconds: 2));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
  });

  test('Repeating animation with reverse: true report as forward and reverse', () {
    final List<AnimationStatus> statuses = <AnimationStatus>[];
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    )..addStatusListener((AnimationStatus status) {
      statuses.add(status);
    });

    controller.repeat(reverse: true);
    tick(const Duration(milliseconds: 0));
    tick(const Duration(milliseconds: 999));
    expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
    statuses.clear();
    tick(const Duration(seconds: 1));
    expect(statuses, <AnimationStatus>[AnimationStatus.reverse]);
  });
}

class TestSimulation extends Simulation {
  @override
  double dx(double time) => time;

  @override
  bool isDone(double time) => false;

  @override
  double x(double time) => time;
}
