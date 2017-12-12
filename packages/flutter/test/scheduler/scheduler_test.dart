// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

class TestSchedulerBinding extends BindingBase with ServicesBinding, SchedulerBinding { }

class TestStrategy {
  int allowedPriority = 10000;

  bool shouldRunTaskWithPriority({ int priority, SchedulerBinding scheduler }) {
    return priority >= allowedPriority;
  }
}

void main() {
  test('Tasks are executed in the right order', () {
    final SchedulerBinding scheduler = new TestSchedulerBinding();
    final TestStrategy strategy = new TestStrategy();
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
}
