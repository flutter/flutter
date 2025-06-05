// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:dev_tools/check_engine_version.dart' as lib;
import 'package:file/memory.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late StringBuffer stderr;
  late String versionPath;
  late String scriptPath;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    versionPath = fileSystem.path.join('bin', 'internal', 'engine.version');
    scriptPath = fileSystem.path.join('bin', 'internal', 'last_engine_commit.sh');

    stderr = StringBuffer();
  });

  tearDown(() {
    printOnFailure('$stderr');
  });

  test('skips check, returning true, if the file is missing', () async {
    final ProcessRunner noRuns = FakeProcessRunner(<String, ProcessRunnerResult>{});
    await expectLater(
      lib.checkEngineVersion(
        versionPath: versionPath,
        scriptPath: scriptPath,
        fileSystem: fileSystem,
        runner: noRuns,
        stderr: stderr,
      ),
      completion(isTrue),
    );

    expect('$stderr', contains('does not exist, skipping engine.version check'));
  });

  test('skips check, returning true, if file was not changed', () async {
    fileSystem
        .directory('bin')
        .childDirectory('internal')
        .childFile('engine.version')
        .createSync(recursive: true);

    final ProcessRunner gitExec = FakeProcessRunner(<String, ProcessRunnerResult>{
      'git diff --name-only --relative master...HEAD -- $versionPath': ProcessRunnerResult(
        0,
        utf8.encode('dev/another/file.txt\n'),
        <int>[],
        <int>[],
      ),
    });

    await expectLater(
      lib.checkEngineVersion(
        versionPath: versionPath,
        scriptPath: scriptPath,
        fileSystem: fileSystem,
        runner: gitExec,
        stderr: stderr,
      ),
      completion(isTrue),
    );

    expect('$stderr', contains('has not changed, skipping engine.version check'));
  });

  test('fails if the SHAs are different', () async {
    fileSystem.directory('bin').childDirectory('internal').childFile('engine.version')
      ..createSync(recursive: true)
      ..writeAsStringSync('def456');

    final ProcessRunner scriptExec = FakeProcessRunner(<String, ProcessRunnerResult>{
      scriptPath: ProcessRunnerResult(0, utf8.encode('abc123'), <int>[], <int>[]),
    });

    await expectLater(
      lib.checkEngineVersion(
        versionPath: versionPath,
        scriptPath: scriptPath,
        fileSystem: fileSystem,
        runner: scriptExec,
        stderr: stderr,
        onlyIfVersionChanged: false,
      ),
      completion(isFalse),
    );

    expect('$stderr', stringContainsInOrder(<String>['output abc123', 'is def456']));
  });

  test('succeeds if the SHAs are the same', () async {
    fileSystem.directory('bin').childDirectory('internal').childFile('engine.version')
      ..createSync(recursive: true)
      ..writeAsStringSync('abc123');

    final ProcessRunner scriptExec = FakeProcessRunner(<String, ProcessRunnerResult>{
      scriptPath: ProcessRunnerResult(0, utf8.encode('abc123'), <int>[], <int>[]),
    });

    await expectLater(
      lib.checkEngineVersion(
        versionPath: versionPath,
        scriptPath: scriptPath,
        fileSystem: fileSystem,
        runner: scriptExec,
        stderr: stderr,
        onlyIfVersionChanged: false,
      ),
      completion(isTrue),
    );

    expect('$stderr', isEmpty);
  });
}

final class FakeProcessRunner extends Fake implements ProcessRunner {
  FakeProcessRunner(this._cannedResponses);
  final Map<String, ProcessRunnerResult> _cannedResponses;

  @override
  Future<ProcessRunnerResult> runProcess(
    List<String> commandLine, {
    io.Directory? workingDirectory,
    bool? printOutput,
    bool failOk = false,
    Stream<List<int>>? stdin,
    bool runInShell = false,
    io.ProcessStartMode startMode = io.ProcessStartMode.normal,
  }) async {
    final ProcessRunnerResult? command = _cannedResponses[commandLine.join(' ')];
    if (command == null) {
      fail('Unexpected process: ${commandLine.join(' ')}');
    }
    return command;
  }
}
