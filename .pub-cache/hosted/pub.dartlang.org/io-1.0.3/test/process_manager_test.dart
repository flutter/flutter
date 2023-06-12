// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart' hide sharedStdIn;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  StreamController<String> fakeStdIn;
  late ProcessManager processManager;
  SharedStdIn sharedStdIn;
  late List<String> stdoutLog;
  late List<String> stderrLog;

  test('spawn functions should match the type definition of Process.start', () {
    const isStartProcess = TypeMatcher<StartProcess>();
    expect(Process.start, isStartProcess);
    final manager = ProcessManager();
    expect(manager.spawn, isStartProcess);
    expect(manager.spawnBackground, isStartProcess);
    expect(manager.spawnDetached, isStartProcess);
  });

  group('spawn', () {
    setUp(() async {
      fakeStdIn = StreamController<String>(sync: true);
      sharedStdIn = SharedStdIn(fakeStdIn.stream.map((s) => s.codeUnits));
      stdoutLog = <String>[];
      stderrLog = <String>[];

      final stdoutController = StreamController<List<int>>(sync: true);
      stdoutController.stream.map(utf8.decode).listen(stdoutLog.add);
      final stdout = IOSink(stdoutController);
      final stderrController = StreamController<List<int>>(sync: true);
      stderrController.stream.map(utf8.decode).listen(stderrLog.add);
      final stderr = IOSink(stderrController);

      processManager = ProcessManager(
        stdin: sharedStdIn,
        stdout: stdout,
        stderr: stderr,
      );
    });

    final dart = Platform.executable;

    test('should output Hello from another process [via stdout]', () async {
      final spawn = await processManager.spawn(
        dart,
        [p.join('test', '_files', 'stdout_hello.dart')],
      );
      await spawn.exitCode;
      expect(stdoutLog, ['Hello']);
    });

    test('should output Hello from another process [via stderr]', () async {
      final spawn = await processManager.spawn(
        dart,
        [p.join('test', '_files', 'stderr_hello.dart')],
      );
      await spawn.exitCode;
      expect(stderrLog, ['Hello']);
    });

    test('should forward stdin to another process', () async {
      final spawn = await processManager.spawn(
        dart,
        [p.join('test', '_files', 'stdin_echo.dart')],
      );
      spawn.stdin.writeln('Ping');
      await spawn.exitCode;
      expect(stdoutLog.join(), contains('You said: Ping'));
    });

    group('should return a Process where', () {
      test('.stdout is readable', () async {
        final spawn = await processManager.spawn(
          dart,
          [p.join('test', '_files', 'stdout_hello.dart')],
        );
        expect(await spawn.stdout.transform(utf8.decoder).first, 'Hello');
      });

      test('.stderr is readable', () async {
        final spawn = await processManager.spawn(
          dart,
          [p.join('test', '_files', 'stderr_hello.dart')],
        );
        expect(await spawn.stderr.transform(utf8.decoder).first, 'Hello');
      });
    });
  });
}
