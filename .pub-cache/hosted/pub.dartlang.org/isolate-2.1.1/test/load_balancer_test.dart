// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:isolate/isolate.dart';
import 'package:test/test.dart';

void main() {
  test('Simple use', () async {
    // The simplest possible case. Should not throw anywhere.
    // Load balancer with at least one isolate-runner.
    var lb = await LoadBalancer.create(1, () => IsolateRunner.spawn());
    // Run at least one task.
    await lb.run(runTask, null);
    // Close it.
    await lb.close();
  });

  /// Run multiple tasks one at a time.
  test("Run multiple indivudual jobs", () async {
    var lb = await createIsolateRunners(4);
    List<List<int>> results =
        await Future.wait([for (var i = 0; i < 10; i++) lb.run(getId, i)]);
    // All request numbers should be accounted for.
    var first = {for (var result in results) result.first};
    expect(first, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
    // All isolate runners should have been used.
    var last = {for (var result in results) result.last};
    expect(last, {1, 2, 3, 4});
    await lb.close();
  });
  test("Run multiple - zero", () async {
    var lb = createLocalRunners(4);
    expect(() => lb.runMultiple(0, runTask, 0), throwsArgumentError);
  });
  test("Run multiple - more than count", () async {
    var lb = createLocalRunners(4);
    expect(() => lb.runMultiple(5, runTask, 0), throwsArgumentError);
  });
  test("Run multiple - 1", () async {
    var lb = createLocalRunners(4);
    var results = await Future.wait(lb.runMultiple(1, LocalRunner.getId, 0));
    expect(results, hasLength(1));
  });
  test("Run multiple - more", () async {
    var lb = createLocalRunners(4);
    var results = await Future.wait(lb.runMultiple(2, LocalRunner.getId, 0));
    expect(results, hasLength(2));
    // Different runners.
    expect({for (var result in results) result.last}, hasLength(2));
  });
  test("Run multiple - all", () async {
    var lb = createLocalRunners(4);
    var results = await Future.wait(lb.runMultiple(4, LocalRunner.getId, 0));
    expect(results, hasLength(4));
    // Different runners.
    expect({for (var result in results) result.last}, hasLength(4));
  });
  test("Always lowest load runner", () async {
    var lb = createLocalRunners(4);
    // Run tasks with input numbers cooresponding to the other tasks they
    // expect to share runner with.
    // Loads: 0, 0, 0, 0.
    var r1 = lb.run(LocalRunner.getId, 0, load: 100);
    // Loads: 0, 0, 0, 100(1).
    var r2 = lb.run(LocalRunner.getId, 1, load: 50);
    // Loads: 0, 0, 50(2), 100(1).
    var r3 = lb.run(LocalRunner.getId, 2, load: 25);
    // Loads: 0, 25(3), 50(2), 100(1).
    var r4 = lb.run(LocalRunner.getId, 3, load: 10);
    // Loads: 10(4), 25(3), 50(2), 100(1).
    var r5 = lb.run(LocalRunner.getId, 3, load: 10);
    // Loads: 20(4, 4), 25(3), 50(2), 100(1).
    var r6 = lb.run(LocalRunner.getId, 3, load: 90);
    // Loads: 25(3), 50(2), 100(1), 110(4, 4, 4).
    var r7 = lb.run(LocalRunner.getId, 2, load: 90);
    // Loads: 50(2), 100(1), 110(4, 4, 4), 115(3, 3).
    var r8 = lb.run(LocalRunner.getId, 1, load: 64);
    // Loads: 100(1), 110(4, 4, 4), 114(2, 2), 115(3, 3).
    var r9 = lb.run(LocalRunner.getId, 0, load: 100);
    // Loads: 110(4, 4, 4), 114(2, 2), 115(3, 3), 200(1, 1).
    var results = await Future.wait([r1, r2, r3, r4, r5, r6, r7, r8, r9]);

    // Check that tasks with the same input numbers ran on the same runner.
    var runnerIds = [-1, -1, -1, -1];
    for (var result in results) {
      var expectedRunner = result.first;
      var actualRunnerId = result.last;
      var seenId = runnerIds[expectedRunner];
      if (seenId == -1) {
        runnerIds[expectedRunner] = actualRunnerId;
      } else if (seenId != actualRunnerId) {
        fail("Task did not run on lowest loaded runner\n$result");
      }
    }
    // Check that all four runners were used.
    var uniqueRunnerIds = {...runnerIds};
    expect(uniqueRunnerIds, {1, 2, 3, 4});
    await lb.close();
  });
}

void runTask(_) {
  // Trivial task.
}

// An isolate local ID.
int localId = -1;
void setId(int value) {
  localId = value;
}

// Request a response including input and local ID.
// Allows detecting which isolate the request is run on.
List<int> getId(int input) => [input, localId];

/// Creates isolate runners with `localId` in the range 1..count.
Future<LoadBalancer> createIsolateRunners(int count) async {
  var runners = <Runner>[];
  for (var i = 1; i <= count; i++) {
    var runner = await IsolateRunner.spawn();
    await runner.run(setId, i);
    runners.add(runner);
  }
  return LoadBalancer(runners);
}

LoadBalancer createLocalRunners(int count) =>
    LoadBalancer([for (var i = 1; i <= count; i++) LocalRunner(i)]);

class LocalRunner implements Runner {
  final int id;
  LocalRunner(this.id);

  static Future<List<int>> getId(int input) async =>
      [input, Zone.current[#runner].id as int];

  @override
  Future<void> close() async {}

  @override
  Future<R> run<R, P>(FutureOr<R> Function(P argument) function, P argument,
      {Duration? timeout, FutureOr<R> Function()? onTimeout}) {
    return runZoned(() {
      var result = Future.sync(() => function(argument));
      if (timeout != null) {
        result = result.timeout(timeout, onTimeout: onTimeout ?? _throwTimeout);
      }
      return result;
    }, zoneValues: {#runner: this});
  }

  static Never _throwTimeout() {
    throw TimeoutException("timeout");
  }
}
