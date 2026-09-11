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
    test(
      'does not report premature exit when wrapped process exits cleanly with exitCode 0',
      () async {
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
      },
    );

    test(
      'does not throw Future already completed when wrapped process terminates after completer completes',
      () async {
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
      },
    );

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

    test(
      'does not report premature exit after disconnect even if wrapped process crashes',
      () async {
        final fakeProcess = FakeProcess();
        final errors = <String>[];

        final Chrome chrome = await Chrome.connect(
          fakeProcess,
          ChromeOptions(),
          onError: (String error) {
            errors.add(error);
          },
        );

        chrome.disconnect();

        fakeProcess.completeExit(1);
        await pumpEventQueue();

        expect(errors, isEmpty);
        expect(fakeProcess.wasKilled, isFalse);
      },
    );
  });

  group('Chrome lifecycle edge cases', () {
    test(
      're-entrant and redundant lifecycle calls do not throw and kill process on stop',
      () async {
        final fakeProcess = FakeProcess();
        final errors = <String>[];

        final Chrome chrome = await Chrome.connect(
          fakeProcess,
          ChromeOptions(),
          onError: (String error) {
            errors.add(error);
          },
        );

        // Multiple disconnect calls sequentially should not throw
        expect(() {
          chrome.disconnect();
          chrome.disconnect();
          chrome.disconnect();
        }, returnsNormally);

        expect(fakeProcess.wasKilled, isFalse);

        // Calling stop after disconnect should not throw and should kill underlying process
        expect(() {
          chrome.stop();
          chrome.stop();
        }, returnsNormally);

        expect(fakeProcess.wasKilled, isTrue);

        // Redundant disconnect after stop should not throw
        expect(() {
          chrome.disconnect();
        }, returnsNormally);

        await pumpEventQueue();
        expect(errors, isEmpty);
      },
    );

    test(
      'pre-exited process boundary handles exitCode 0 without error and exitCode 1 with error',
      () async {
        // 1. Process that has already exited with exitCode 0 before connection
        final cleanProcess = FakeProcess()..completeExit(0);
        final cleanErrors = <String>[];

        await Chrome.connect(
          cleanProcess,
          ChromeOptions(),
          onError: (String error) {
            cleanErrors.add(error);
          },
        );

        await pumpEventQueue();
        expect(cleanErrors, isEmpty);

        // 2. Process that has already exited with exitCode 1 before connection
        final crashedProcess = FakeProcess()..completeExit(1);
        final crashErrors = <String>[];

        await Chrome.connect(
          crashedProcess,
          ChromeOptions(),
          onError: (String error) {
            crashErrors.add(error);
          },
        );

        await pumpEventQueue();
        expect(crashErrors, <String>['Chrome process exited prematurely with exit code 1']);

        // 3. Process that completes exitCode 0 immediately upon connection
        final immediateCleanProcess = FakeProcess();
        final immediateCleanErrors = <String>[];

        final Chrome immediateCleanChrome = await Chrome.connect(
          immediateCleanProcess,
          ChromeOptions(),
          onError: (String error) {
            immediateCleanErrors.add(error);
          },
        );

        immediateCleanProcess.completeExit(0);
        await pumpEventQueue();
        expect(immediateCleanErrors, isEmpty);
        immediateCleanChrome.disconnect();

        // 4. Process that completes exitCode 1 immediately upon connection
        final immediateCrashProcess = FakeProcess();
        final immediateCrashErrors = <String>[];

        await Chrome.connect(
          immediateCrashProcess,
          ChromeOptions(),
          onError: (String error) {
            immediateCrashErrors.add(error);
          },
        );

        immediateCrashProcess.completeExit(1);
        await pumpEventQueue();
        expect(immediateCrashErrors, <String>[
          'Chrome process exited prematurely with exit code 1',
        ]);
      },
    );

    test('handles rapid disposal and immediate process exit in the same microtask turn', () async {
      // 1. Process exits in the same microtask turn as disconnect()
      final process1 = FakeProcess();
      final errors1 = <String>[];

      final Chrome chrome1 = await Chrome.connect(
        process1,
        ChromeOptions(),
        onError: (String error) {
          errors1.add(error);
        },
      );

      // Exit and disconnect within the same synchronous turn
      process1.completeExit(1);
      chrome1.disconnect();

      await pumpEventQueue();
      expect(errors1, isEmpty);
      expect(process1.wasKilled, isFalse);

      // 2. Disconnect called first, then process exits in the same synchronous turn
      final process2 = FakeProcess();
      final errors2 = <String>[];

      final Chrome chrome2 = await Chrome.connect(
        process2,
        ChromeOptions(),
        onError: (String error) {
          errors2.add(error);
        },
      );

      chrome2.disconnect();
      process2.completeExit(1);

      await pumpEventQueue();
      expect(errors2, isEmpty);
      expect(process2.wasKilled, isFalse);

      // 3. Process exits in the same microtask turn as stop()
      final process3 = FakeProcess();
      final errors3 = <String>[];

      final Chrome chrome3 = await Chrome.connect(
        process3,
        ChromeOptions(),
        onError: (String error) {
          errors3.add(error);
        },
      );

      // stop() calls disconnect() and kills process in the same turn
      chrome3.stop();

      await pumpEventQueue();
      expect(errors3, isEmpty);
      expect(process3.wasKilled, isTrue);

      // 4. Process exits with non-zero exit code immediately before stop() in same turn
      final process4 = FakeProcess();
      final errors4 = <String>[];

      final Chrome chrome4 = await Chrome.connect(
        process4,
        ChromeOptions(),
        onError: (String error) {
          errors4.add(error);
        },
      );

      process4.completeExit(1);
      chrome4.stop();

      await pumpEventQueue();
      expect(errors4, isEmpty);
      expect(process4.wasKilled, isTrue);
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
