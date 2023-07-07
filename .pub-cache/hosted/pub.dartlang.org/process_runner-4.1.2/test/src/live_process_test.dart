// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:process/process.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

void main() {
  if (!Platform.isLinux && !Platform.isMacOS) {
    print('Test only available on linux and macOS');
    return;
  }

  late Directory tmpdir;
  ProcessRunner processRunner = ProcessRunner(processManager: const LocalProcessManager());

  setUp(() {
    tmpdir = Directory.systemTemp.createTempSync('live_process_test.');
    processRunner =
        ProcessRunner(processManager: const LocalProcessManager(), defaultWorkingDirectory: tmpdir);
  });

  tearDown(() {
    tmpdir.deleteSync(recursive: true);
  });

  group('Output Capture', () {
    test('runProcess returns correct return value', () async {
      final ProcessRunnerResult result = await processRunner.runProcess(<String>['true']);
      expect(result.exitCode, equals(0));
      final ProcessRunnerResult result1 =
          await processRunner.runProcess(<String>['false'], failOk: true);
      expect(result1.exitCode, isNot(equals(0)));
    });
    test('runProcess captures stdout', () async {
      final ProcessRunnerResult result =
          await processRunner.runProcess(<String>['echo', 'process output']);
      expect(result.exitCode, equals(0));
      expect(result.stdout, equals('process output\n'));
    });
    test('runProcess captures stderr', () async {
      final ProcessRunnerResult result =
          await processRunner.runProcess(<String>['cat', '--flutter'], failOk: true);
      expect(result.exitCode, isNot(equals(0)));
      expect(result.stderr, contains(RegExp(r'(unrecognized|illegal) option')));
    });
    test('runProcess captures detachedWithStdio stdout', () async {
      final ProcessRunnerResult result = await processRunner.runProcess(
          <String>['echo', 'process output'],
          startMode: ProcessStartMode.detachedWithStdio);
      expect(result.exitCode, equals(0));
      expect(result.stdout, equals('process output\n'));
    });
    test('runProcess captures detachedWithStdio stderr', () async {
      final ProcessRunnerResult result = await processRunner.runProcess(
          <String>['cat', '--flutter'],
          failOk: true, startMode: ProcessStartMode.detachedWithStdio);
      expect(result.exitCode, equals(0)); // failed detached processes don't report an exit code.
      expect(result.stderr, contains(RegExp(r'(unrecognized|illegal) option')));
    });
    test('runProcess captures nothing with detached process', () async {
      final ProcessRunnerResult result = await processRunner
          .runProcess(<String>['echo', 'process output'], startMode: ProcessStartMode.detached);
      expect(result.exitCode, equals(0));
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
    });
    test('process failure throws exception without failOk', () async {
      expect(() async {
        await processRunner.runProcess(<String>['false']);
      }, throwsException);
    });
  });
}
