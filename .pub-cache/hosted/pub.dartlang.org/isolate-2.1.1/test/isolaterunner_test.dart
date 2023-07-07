// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' show Capability;

import 'package:isolate/isolate_runner.dart';
import 'package:test/test.dart';

const _ms = Duration(milliseconds: 1);

void main() {
  group('create-close', testCreateClose);
  test('create-run-close', testCreateRunClose);
  test('separate-isolates', testSeparateIsolates);
  group('isolate functions', testIsolateFunctions);
}

void testCreateClose() {
  test('simple', () {
    return IsolateRunner.spawn().then((IsolateRunner runner) {
      return runner.close();
    });
  });
  test('close twice', () async {
    var runner = await IsolateRunner.spawn();
    await runner.close();
    // Shouldn't hang!
    await runner.close();
  });
}

Future testCreateRunClose() {
  return IsolateRunner.spawn().then((IsolateRunner runner) {
    return runner.run(id, 'testCreateRunClose').then((v) {
      expect(v, 'testCreateRunClose');
      return runner.close().then((_) => runner.onExit);
    });
  });
}

Future testSeparateIsolates() {
  // Check that each isolate has its own _global variable.
  return Future.wait(Iterable.generate(2, (_) => IsolateRunner.spawn()))
      .then((runners) {
    Future runAll(Future Function(IsolateRunner runner, int index) action) {
      final indices = Iterable<int>.generate(runners.length);
      return Future.wait(indices.map((i) => action(runners[i], i)));
    }

    return runAll((runner, i) => runner.run(setGlobal, i + 1)).then((values) {
      expect(values, [1, 2]);
      expect(_global, null);
      return runAll((runner, _) => runner.run(getGlobal, null));
    }).then((values) {
      expect(values, [1, 2]);
      expect(_global, null);
      return runAll((runner, _) => runner.close());
    });
  });
}

void testIsolateFunctions() {
  test('pause', () {
    var mayComplete = false;
    return IsolateRunner.spawn().then((isolate) {
      isolate.pause();
      Future.delayed(_ms * 500, () {
        mayComplete = true;
        isolate.resume();
      });
      isolate.run(id, 42).then((v) {
        expect(v, 42);
        expect(mayComplete, isTrue);
      }).whenComplete(isolate.close);
    });
  });
  test('pause2', () {
    var c1 = Capability();
    var c2 = Capability();
    var mayCompleteCount = 2;
    return IsolateRunner.spawn().then((isolate) {
      isolate.pause(c1);
      isolate.pause(c2);
      Future.delayed(_ms * 500, () {
        mayCompleteCount--;
        isolate.resume(c1);
      });
      Future.delayed(_ms * 500, () {
        mayCompleteCount--;
        isolate.resume(c2);
      });
      isolate.run(id, 42).then((v) {
        expect(v, 42);
        expect(mayCompleteCount, 0);
      }).whenComplete(isolate.close);
    });
  });
  test('ping', () {
    return IsolateRunner.spawn().then((isolate) {
      return isolate.ping().then((v) {
        expect(v, isTrue);
        return isolate.close();
      });
    });
  });
  test('kill', () {
    return IsolateRunner.spawn().then((isolate) {
      return isolate.kill();
    });
  });
}

dynamic id(x) => x;

Object? _global;

dynamic getGlobal(_) => _global;

void setGlobal(v) => _global = v;
