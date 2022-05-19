// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:fake_async/fake_async.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

void main() {
  group(FakeProcess, () {
    testWithoutContext('exits with specified exit code', () async {
      final FakeProcess process = FakeProcess(exitCode: 42);
      expect(await process.exitCode, 42);
    });

    testWithoutContext('exits with specified stderr, stdout', () async {
      final FakeProcess process = FakeProcess(
        stderr: 'stderr\u{FFFD}'.codeUnits,
        stdout: 'stdout\u{FFFD}'.codeUnits,
      );
      await process.exitCode;

      // Verify that no encoding changes have been applied to output.
      //
      // In the past, we had hardcoded UTF-8 encoding for these streams in
      // FakeProcess. When a specific encoding is desired, it can be specified
      // on FakeCommand or in the encoding parameter of FakeProcessManager.run
      // or FakeProcessManager.runAsync.
      expect((await process.stderr.toList()).expand((List<int> x) => x), 'stderr\u{FFFD}'.codeUnits);
      expect((await process.stdout.toList()).expand((List<int> x) => x), 'stdout\u{FFFD}'.codeUnits);
    });

    testWithoutContext('exits after specified delay (if no completer specified)', () {
      final bool done = FakeAsync().run<bool>((FakeAsync time) {
        final FakeProcess process = FakeProcess(
          duration: const Duration(seconds: 30),
        );

        bool hasExited = false;
        unawaited(process.exitCode.then((int _) { hasExited = true; }));

        // Verify process hasn't exited before specified delay.
        time.elapse(const Duration(seconds: 15));
        expect(hasExited, isFalse);

        // Verify process has exited after specified delay.
        time.elapse(const Duration(seconds: 20));
        expect(hasExited, isTrue);

        return true;
      });
      expect(done, isTrue);
    });

    testWithoutContext('exits when completer completes (if no duration specified)', () {
      final bool done = FakeAsync().run<bool>((FakeAsync time) {
        final Completer<void> completer = Completer<void>();
        final FakeProcess process = FakeProcess(
          completer: completer,
        );

        bool hasExited = false;
        unawaited(process.exitCode.then((int _) { hasExited = true; }));

        // Verify process hasn't exited when all async tasks flushed.
        time.elapse(Duration.zero);
        expect(hasExited, isFalse);

        // Verify process has exited after completer completes.
        completer.complete();
        time.flushMicrotasks();
        expect(hasExited, isTrue);

        return true;
      });
      expect(done, isTrue);
    });

    testWithoutContext('when completer and duration are specified, does not exit until completer is completed', () {
      final bool done = FakeAsync().run<bool>((FakeAsync time) {
        final Completer<void> completer = Completer<void>();
        final FakeProcess process = FakeProcess(
          duration: const Duration(seconds: 30),
          completer: completer,
        );

        bool hasExited = false;
        unawaited(process.exitCode.then((int _) { hasExited = true; }));

        // Verify process hasn't exited before specified delay.
        time.elapse(const Duration(seconds: 15));
        expect(hasExited, isFalse);

        // Verify process hasn't exited until the completer completes.
        time.elapse(const Duration(seconds: 20));
        expect(hasExited, isFalse);

        // Verify process exits after the completer completes.
        completer.complete();
        time.flushMicrotasks();
        expect(hasExited, isTrue);

        return true;
      });
      expect(done, isTrue);
    });

    testWithoutContext('when completer and duration are specified, does not exit until duration has elapsed', () {
      final bool done = FakeAsync().run<bool>((FakeAsync time) {
        final Completer<void> completer = Completer<void>();
        final FakeProcess process = FakeProcess(
          duration: const Duration(seconds: 30),
          completer: completer,
        );

        bool hasExited = false;
        unawaited(process.exitCode.then((int _) { hasExited = true; }));

        // Verify process hasn't exited before specified delay.
        time.elapse(const Duration(seconds: 15));
        expect(hasExited, isFalse);

        // Verify process does not exit until duration has elapsed.
        completer.complete();
        expect(hasExited, isFalse);

        // Verify process exits after the duration elapses.
        time.elapse(const Duration(seconds: 20));
        expect(hasExited, isTrue);

        return true;
      });
      expect(done, isTrue);
    });

    testWithoutContext('process exit is asynchronous', () async {
      final FakeProcess process = FakeProcess();

      bool hasExited = false;
      unawaited(process.exitCode.then((int _) { hasExited = true; }));

      // Verify process hasn't completed.
      expect(hasExited, isFalse);

      // Flush async tasks. Verify process completes.
      await Future<void>.delayed(Duration.zero);
      expect(hasExited, isTrue);
    });

    testWithoutContext('stderr, stdout stream data after exit when outputFollowsExit is true', () async {
      final FakeProcess process = FakeProcess(
        stderr: 'stderr'.codeUnits,
        stdout: 'stdout'.codeUnits,
        outputFollowsExit: true,
      );

      final List<int> stderr = <int>[];
      final List<int> stdout = <int>[];
      process.stderr.listen(stderr.addAll);
      process.stdout.listen(stdout.addAll);

      // Ensure that no bytes have been received at process exit.
      await process.exitCode;
      expect(stderr, isEmpty);
      expect(stdout, isEmpty);

      // Flush all remaining async work. Ensure stderr, stdout is received.
      await Future<void>.delayed(Duration.zero);
      expect(stderr, 'stderr'.codeUnits);
      expect(stdout, 'stdout'.codeUnits);
    });
  });
}
