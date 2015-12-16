// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test is disabled because it triggers https://github.com/dart-lang/sdk/issues/25246

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

class TestSchedulerBinding extends BindingBase with Scheduler { }

class TestStrategy implements SchedulingStrategy {
  int allowedPriority = 10000;

  bool shouldRunTaskWithPriority({ int priority, Scheduler scheduler }) {
    return priority >= allowedPriority;
  }
}

void main() {
  test("Tasks are executed in the right order", () {
    Scheduler scheduler = new TestSchedulerBinding();
    TestStrategy strategy = new TestStrategy();
    scheduler.schedulingStrategy = strategy;
    List<int> input = <int>[2, 23, 23, 11, 0, 80, 3];
    List<int> executedTasks = <int>[];

    void scheduleAddingTask(int x) {
      scheduler.scheduleTask(() { executedTasks.add(x); }, Priority.idle + x);
    }

    for (int x in input)
      scheduleAddingTask(x);

    strategy.allowedPriority = 100;
    for (int i = 0; i < 3; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.isEmpty, isTrue);

    strategy.allowedPriority = 50;
    for (int i = 0; i < 3; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(1));
    expect(executedTasks.single, equals(80));
    executedTasks.clear();

    strategy.allowedPriority = 20;
    for (int i = 0; i < 3; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(23));
    expect(executedTasks[1], equals(23));
    executedTasks.clear();

    scheduleAddingTask(99);
    scheduleAddingTask(19);
    scheduleAddingTask(5);
    scheduleAddingTask(97);
    for (int i = 0; i < 3; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(99));
    expect(executedTasks[1], equals(97));
    executedTasks.clear();

    strategy.allowedPriority = 10;
    for (int i = 0; i < 3; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(19));
    expect(executedTasks[1], equals(11));
    executedTasks.clear();

    strategy.allowedPriority = 1;
    for (int i = 0; i < 4; i += 1)
      scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(3));
    expect(executedTasks[0], equals(5));
    expect(executedTasks[1], equals(3));
    expect(executedTasks[2], equals(2));
    executedTasks.clear();

    strategy.allowedPriority = 0;
    scheduler.handleEventLoopCallback();
    expect(executedTasks.length, equals(1));
    expect(executedTasks[0], equals(0));
  });
}
