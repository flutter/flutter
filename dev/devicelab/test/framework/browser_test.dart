// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_devicelab/framework/browser.dart';

import '../common.dart';
import 'browser_test_json_samples.dart';

void main() {
  group('BlinkTraceEvent works with Chrome 89+', () {
    // Used to test 'false' results
    final unrelatedPhX = BlinkTraceEvent.fromJson(unrelatedPhXJson);
    final anotherUnrelated = BlinkTraceEvent.fromJson(anotherUnrelatedJson);

    test('isBeginFrame', () {
      final event = BlinkTraceEvent.fromJson(beginMainFrameJson_89plus);

      expect(event.isBeginFrame, isTrue);
      expect(unrelatedPhX.isBeginFrame, isFalse);
      expect(anotherUnrelated.isBeginFrame, isFalse);
    });

    test('isUpdateAllLifecyclePhases', () {
      final event = BlinkTraceEvent.fromJson(updateLifecycleJson_89plus);

      expect(event.isUpdateAllLifecyclePhases, isTrue);
      expect(unrelatedPhX.isUpdateAllLifecyclePhases, isFalse);
      expect(anotherUnrelated.isUpdateAllLifecyclePhases, isFalse);
    });

    test('isBeginMeasuredFrame', () {
      final event = BlinkTraceEvent.fromJson(beginMeasuredFrameJson_89plus);

      expect(event.isBeginMeasuredFrame, isTrue);
      expect(unrelatedPhX.isBeginMeasuredFrame, isFalse);
      expect(anotherUnrelated.isBeginMeasuredFrame, isFalse);
    });

    test('isEndMeasuredFrame', () {
      final event = BlinkTraceEvent.fromJson(endMeasuredFrameJson_89plus);

      expect(event.isEndMeasuredFrame, isTrue);
      expect(unrelatedPhX.isEndMeasuredFrame, isFalse);
      expect(anotherUnrelated.isEndMeasuredFrame, isFalse);
    });
  });

  group('Chrome.connect lifecycle', () {
    test('does not report premature exit when wrapped process exits cleanly with exitCode 0', () async {
      final fakeProcess = FakeProcess();
      final errors = <String>[];

      await Chrome.connect(
        fakeProcess,
        ChromeOptions(),
        onError: (String error) {
          errors.add(error);
        },
      );

      fakeProcess.completeExit(0);
      await pumpEventQueue();

      expect(errors, isEmpty);
    });

    test('does not throw Future already completed when wrapped process terminates after completer completes', () async {
      final fakeProcess = FakeProcess();
      final profileData = Completer<List<Map<String, dynamic>>>();

      await Chrome.connect(
        fakeProcess,
        ChromeOptions(),
        onError: (String error) {
          profileData.completeError(Exception(error));
        },
      );

      // Simulate benchmark completion
      profileData.complete(<Map<String, dynamic>>[]);
      await profileData.future;

      // Simulate graceful shutdown of the wrapped process (e.g. sending 'q' to flutter run)
      fakeProcess.completeExit(0);
      await pumpEventQueue();
    });

    test('reports premature exit when wrapped process crashes with non-zero exitCode', () async {
      final fakeProcess = FakeProcess();
      final errors = <String>[];

      await Chrome.connect(
        fakeProcess,
        ChromeOptions(),
        onError: (String error) {
          errors.add(error);
        },
      );

      fakeProcess.completeExit(1);
      await pumpEventQueue();

      expect(errors, <String>['Chrome process exited prematurely with exit code 1']);
    });
  });
}

class FakeProcess implements io.Process {
  final Completer<int> _exitCodeCompleter = Completer<int>();
  bool wasKilled = false;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    wasKilled = true;
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(-1);
    }
    return true;
  }

  void completeExit(int code) {
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(code);
    }
  }

  @override
  int get pid => 12345;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  io.IOSink get stdin => throw UnimplementedError();
}
