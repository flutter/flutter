// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scheduler_tester.dart';

class TestSchedulerBinding extends BindingBase with SchedulerBinding, ServicesBinding {
  final Map<String, List<Map<String, dynamic>>> eventsDispatched = <String, List<Map<String, dynamic>>>{};

  @override
  void postEvent(String eventKind, Map<String, dynamic> eventData) {
    getEventsDispatched(eventKind).add(eventData);
  }

  List<Map<String, dynamic>> getEventsDispatched(String eventKind) {
    return eventsDispatched.putIfAbsent(eventKind, () => <Map<String, dynamic>>[]);
  }
}

class TestStrategy {
  int allowedPriority = 10000;

  bool shouldRunTaskWithPriority({ required int priority, required SchedulerBinding scheduler }) {
    return priority >= allowedPriority;
  }
}

void main() {
  late TestSchedulerBinding scheduler;

  setUpAll(() {
    scheduler = TestSchedulerBinding();
  });

  test('Tasks are executed in the right order', () {
    final TestStrategy strategy = TestStrategy();
    scheduler.schedulingStrategy = strategy.shouldRunTaskWithPriority;
    final List<int> input = <int>[2, 23, 23, 11, 0, 80, 3];
    final List<int> executedTasks = <int>[];

    void scheduleAddingTask(int x) {
      scheduler.scheduleTask(() { executedTasks.add(x); }, Priority.idle + x);
    }

    input.forEach(scheduleAddingTask);

    strategy.allowedPriority = 100;
    for (int i = 0; i < 3; i += 1)
      expect(scheduler.handleEventLoopCallback(), isFalse);
    expect(executedTasks.isEmpty, isTrue);

    strategy.allowedPriority = 50;
    for (int i = 0; i < 3; i += 1)
      expect(scheduler.handleEventLoopCallback(), i == 0 ? isTrue : isFalse);
    expect(executedTasks, hasLength(1));
    expect(executedTasks.single, equals(80));
    executedTasks.clear();

    strategy.allowedPriority = 20;
    for (int i = 0; i < 3; i += 1)
      expect(scheduler.handleEventLoopCallback(), i < 2 ? isTrue : isFalse);
    expect(executedTasks, hasLength(2));
    expect(executedTasks[0], equals(23));
    expect(executedTasks[1], equals(23));
    executedTasks.clear();

    scheduleAddingTask(99);
    scheduleAddingTask(19);
    scheduleAddingTask(5);
    scheduleAddingTask(97);
    for (int i = 0; i < 3; i += 1)
      expect(scheduler.handleEventLoopCallback(), i < 2 ? isTrue : isFalse);
    expect(executedTasks, hasLength(2));
    expect(executedTasks[0], equals(99));
    expect(executedTasks[1], equals(97));
    executedTasks.clear();

    strategy.allowedPriority = 10;
    for (int i = 0; i < 3; i += 1)
      expect(scheduler.handleEventLoopCallback(), i < 2 ? isTrue : isFalse);
    expect(executedTasks, hasLength(2));
    expect(executedTasks[0], equals(19));
    expect(executedTasks[1], equals(11));
    executedTasks.clear();

    strategy.allowedPriority = 1;
    for (int i = 0; i < 4; i += 1)
      expect(scheduler.handleEventLoopCallback(), i < 3 ? isTrue : isFalse);
    expect(executedTasks, hasLength(3));
    expect(executedTasks[0], equals(5));
    expect(executedTasks[1], equals(3));
    expect(executedTasks[2], equals(2));
    executedTasks.clear();

    strategy.allowedPriority = 0;
    expect(scheduler.handleEventLoopCallback(), isFalse);
    expect(executedTasks, hasLength(1));
    expect(executedTasks[0], equals(0));
  });

  test('2 calls to scheduleWarmUpFrame just schedules it once', () {
    final List<VoidCallback> timerQueueTasks = <VoidCallback>[];
    bool taskExecuted = false;
    runZoned<void>(
      () {
        // Run it twice without processing the queued tasks.
        scheduler.scheduleWarmUpFrame();
        scheduler.scheduleWarmUpFrame();
        scheduler.scheduleTask(() { taskExecuted = true; }, Priority.touch);
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() f) {
          // Don't actually run the tasks, just record that it was scheduled.
          timerQueueTasks.add(f);
          return DummyTimer();
        },
      ),
    );

    // scheduleWarmUpFrame scheduled 2 Timers, scheduleTask scheduled 0 because
    // events are locked.
    expect(timerQueueTasks.length, 2);
    expect(taskExecuted, false);

    // Run the timers so that the scheduler is no longer in warm-up state.
    for (final VoidCallback timer in timerQueueTasks) {
      timer();
    }

    // As events are locked, make scheduleTask execute after the test or it
    // will execute during following tests and risk failure.
    addTearDown(() => scheduler.handleEventLoopCallback());
  });

  test('Flutter.Frame event fired', () async {
    window.onReportTimings!(<FrameTiming>[FrameTiming(
      vsyncStart: 5000,
      buildStart: 10000,
      buildFinish: 15000,
      rasterStart: 16000,
      rasterFinish: 20000,
      rasterFinishWallTime: 20010,
      frameNumber: 1991
    )]);

    final List<Map<String, dynamic>> events = scheduler.getEventsDispatched('Flutter.Frame');
    expect(events, hasLength(1));

    final Map<String, dynamic> event = events.first;
    expect(event['number'], 1991);
    expect(event['startTime'], 10000);
    expect(event['elapsed'], 15000);
    expect(event['build'], 5000);
    expect(event['raster'], 4000);
    expect(event['vsyncOverhead'], 5000);
  });

  test('TimingsCallback exceptions are caught', () {
    FlutterErrorDetails? errorCaught;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorCaught = details;
    };
    SchedulerBinding.instance!.addTimingsCallback((List<FrameTiming> timings) {
      throw Exception('Test');
    });
    window.onReportTimings!(<FrameTiming>[]);
    expect(errorCaught!.exceptionAsString(), equals('Exception: Test'));
  });

  test('currentSystemFrameTimeStamp is the raw timestamp', () {
    // Undo epoch set by previous tests.
    scheduler.resetEpoch();

    late Duration lastTimeStamp;
    late Duration lastSystemTimeStamp;

    void frameCallback(Duration timeStamp) {
      expect(timeStamp, scheduler.currentFrameTimeStamp);
      lastTimeStamp = scheduler.currentFrameTimeStamp;
      lastSystemTimeStamp = scheduler.currentSystemFrameTimeStamp;
    }

    scheduler.scheduleFrameCallback(frameCallback);
    tick(const Duration(seconds: 2));
    expect(lastTimeStamp, Duration.zero);
    expect(lastSystemTimeStamp, const Duration(seconds: 2));

    scheduler.scheduleFrameCallback(frameCallback);
    tick(const Duration(seconds: 4));
    expect(lastTimeStamp, const Duration(seconds: 2));
    expect(lastSystemTimeStamp, const Duration(seconds: 4));

    timeDilation = 2;
    scheduler.scheduleFrameCallback(frameCallback);
    tick(const Duration(seconds: 6));
    expect(lastTimeStamp, const Duration(seconds: 2)); // timeDilation calls SchedulerBinding.resetEpoch
    expect(lastSystemTimeStamp, const Duration(seconds: 6));

    scheduler.scheduleFrameCallback(frameCallback);
    tick(const Duration(seconds: 8));
    expect(lastTimeStamp, const Duration(seconds: 3)); // 2s + (8 - 6)s / 2
    expect(lastSystemTimeStamp, const Duration(seconds: 8));
  });

  test('Animation frame scheduled in the middle of the warm-up frame', () {
    expect(scheduler.schedulerPhase, SchedulerPhase.idle);
    final List<VoidCallback> timers = <VoidCallback>[];
    final ZoneSpecification timerInterceptor = ZoneSpecification(
      createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() callback) {
        timers.add(callback);
        return DummyTimer();
      },
    );

    // Schedule a warm-up frame.
    // Expect two timers, one for begin frame, and one for draw frame.
    runZoned<void>(scheduler.scheduleWarmUpFrame, zoneSpecification: timerInterceptor);
    expect(timers.length, 2);
    final VoidCallback warmUpBeginFrame = timers.first;
    final VoidCallback warmUpDrawFrame = timers.last;
    timers.clear();

    warmUpBeginFrame();

    // Simulate an animation frame firing between warm-up begin frame and warm-up draw frame.
    // Expect a timer that reschedules the frame.
    expect(scheduler.hasScheduledFrame, isFalse);
    window.onBeginFrame!(Duration.zero);
    expect(scheduler.hasScheduledFrame, isFalse);
    window.onDrawFrame!();
    expect(scheduler.hasScheduledFrame, isFalse);

    // The draw frame part of the warm-up frame will run the post-frame
    // callback that reschedules the engine frame.
    warmUpDrawFrame();
    expect(scheduler.hasScheduledFrame, isTrue);
  });
}

class DummyTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}
