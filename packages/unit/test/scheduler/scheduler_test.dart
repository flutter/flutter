// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/task.dart';
import 'package:test/test.dart';

class TestStrategy implements SchedulingStrategy {
  int allowedPriority = 10000;

  bool shouldRunTaskWithPriority(int priority) {
    return priority >= allowedPriority;
  }
}

void main() {
  test("Tasks are executed in the right order", () {
    var strategy = new TestStrategy();
    tasks.schedulingStrategy = strategy;
    List input = [2, 23, 23, 11, 0, 80, 3];
    List executedTasks = [];

    void scheduleAddingTask(int x) {
      tasks.schedule(() { executedTasks.add(x); }, Priority.idle + x);
    }

    for (int x in input) {
      scheduleAddingTask(x);
    }
    strategy.allowedPriority = 100;
    for (int i = 0; i < 3; i++) tasks.tick();
    expect(executedTasks.isEmpty, isTrue);

    strategy.allowedPriority = 50;
    for (int i = 0; i < 3; i++) tasks.tick();
    expect(executedTasks.length, equals(1));
    expect(executedTasks.single, equals(80));
    executedTasks.clear();

    strategy.allowedPriority = 20;
    for (int i = 0; i < 3; i++) tasks.tick();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(23));
    expect(executedTasks[1], equals(23));
    executedTasks.clear();

    scheduleAddingTask(99);
    scheduleAddingTask(19);
    scheduleAddingTask(5);
    scheduleAddingTask(97);
    for (int i = 0; i < 3; i++) tasks.tick();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(99));
    expect(executedTasks[1], equals(97));
    executedTasks.clear();

    strategy.allowedPriority = 10;
    for (int i = 0; i < 3; i++) tasks.tick();
    expect(executedTasks.length, equals(2));
    expect(executedTasks[0], equals(19));
    expect(executedTasks[1], equals(11));
    executedTasks.clear();

    strategy.allowedPriority = 1;
    for (int i = 0; i < 4; i++) tasks.tick();
    expect(executedTasks.length, equals(3));
    expect(executedTasks[0], equals(5));
    expect(executedTasks[1], equals(3));
    expect(executedTasks[2], equals(2));
    executedTasks.clear();

    strategy.allowedPriority = 0;
    tasks.tick();
    expect(executedTasks.length, equals(1));
    expect(executedTasks[0], equals(0));
  });
}
