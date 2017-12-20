// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import '../prepare_package.dart';

void main() {
  group('ArchiveCreator', () {
    ArchiveCreator preparer;
    Directory tmpDir;
    Directory flutterDir;
    File outputFile;
    MockProcessRunner runner;
    List<MockProcessResult> results;
    final List<List<String>> args = <List<String>>[];
    final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
    final String zipExe = Platform.isWindows ? '7za.exe' : 'zip';
    final String tarExe = Platform.isWindows ? 'tar.exe' : 'tar';
    final String gitExe = Platform.isWindows ? 'git.bat' : 'git';
    String flutterExe;

    void _verifyCommand(List<dynamic> args, String expected) {
      final List<String> expectedList = expected.split(' ');
      final String executable = expectedList.removeAt(0);
      expect(args[0], executable);
      expect(args[1], orderedEquals(expectedList));
    }

    ProcessResult _nextResult(Invocation invocation) {
      args.add(invocation.positionalArguments);
      namedArgs.add(invocation.namedArguments);
      return results.isEmpty ? new MockProcessResult('', '', 0) : results.removeAt(0);
    }

    void _answerWithResults() {
      when(
        runner.call(
          typed(captureAny),
          typed(captureAny),
          environment: typed(captureAny, named: 'environment'),
          workingDirectory: typed(captureAny, named: 'workingDirectory'),
          includeParentEnvironment: typed(captureAny, named: 'includeParentEnvironment'),
        ),
      ).thenAnswer(_nextResult);
    }

    setUp(() async {
      runner = new MockProcessRunner();
      args.clear();
      namedArgs.clear();
      tmpDir = await Directory.systemTemp.createTemp('flutter_');
      flutterDir = new Directory(path.join(tmpDir.path, 'flutter'));
      flutterExe =
          path.join(flutterDir.path, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
    });

    tearDown(() async {
      // On Windows, the directory is locked and not able to be deleted, because it is a
      // temporary directory. So we just leave some (very small, because we're not actually
      // building archives here) trash around to be deleted at the next reboot.
      if (!Platform.isWindows) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('sets PUB_CACHE properly', () async {
      outputFile = new File(path.join(tmpDir.absolute.path, 'flutter_master.tar.xz'));
      preparer = new ArchiveCreator(tmpDir, outputFile, runner: runner);
      _answerWithResults();
      results = <MockProcessResult>[new MockProcessResult('deadbeef\n', '', 0)];
      await preparer.createArchive('master');
      expect(
        verify(runner.call(
          captureAny,
          captureAny,
          workingDirectory: captureAny,
          environment: captureAny,
          includeParentEnvironment: typed(captureAny, named: 'includeParentEnvironment'),
        )).captured[2]['PUB_CACHE'],
        endsWith(path.join('flutter', '.pub-cache')),
      );
    });

    test('calls the right commands for tar output', () async {
      outputFile = new File(path.join(tmpDir.absolute.path, 'flutter_master.tar.xz'));
      preparer = new ArchiveCreator(tmpDir, outputFile, runner: runner);
      _answerWithResults();
      results = <MockProcessResult>[new MockProcessResult('deadbeef\n', '', 0)];
      await preparer.createArchive('master');
      final List<String> commands = <String>[
        '$gitExe clone -b master https://chromium.googlesource.com/external/github.com/flutter/flutter',
        '$gitExe reset --hard master',
        '$gitExe remote remove origin',
        '$gitExe remote add origin https://github.com/flutter/flutter.git',
      ];
      if (Platform.isWindows) {
        commands.add('$zipExe x ${path.join(tmpDir.path, 'mingit.zip')}');
      }
      commands.addAll(<String>[
        '$flutterExe doctor',
        '$flutterExe update-packages',
        '$flutterExe precache',
        '$flutterExe ide-config',
        '$flutterExe create --template=app ${path.join(tmpDir.path, 'create_app')}',
        '$flutterExe create --template=package ${path.join(tmpDir.path, 'create_package')}',
        '$flutterExe create --template=plugin ${path.join(tmpDir.path, 'create_plugin')}',
        '$gitExe clean -f -X **/.packages',
        '$tarExe cJf ${path.join(tmpDir.path, 'flutter_master.tar.xz')} flutter',
      ]);
      int step = 0;
      for (String command in commands) {
        _verifyCommand(args[step++], command);
      }
    });

    test('calls the right commands for zip output', () async {
      outputFile = new File(path.join(tmpDir.absolute.path, 'flutter_master.zip'));
      preparer = new ArchiveCreator(tmpDir, outputFile, runner: runner);
      _answerWithResults();
      results = <MockProcessResult>[new MockProcessResult('deadbeef\n', '', 0)];
      await preparer.createArchive('master');
      final List<String> commands = <String>[
        '$gitExe clone -b master https://chromium.googlesource.com/external/github.com/flutter/flutter',
        '$gitExe reset --hard master',
        '$gitExe remote remove origin',
        '$gitExe remote add origin https://github.com/flutter/flutter.git',
      ];
      if (Platform.isWindows) {
        commands.add('$zipExe x ${path.join(tmpDir.path, 'mingit.zip')}');
      }
      commands.addAll(<String>[
        '$flutterExe doctor',
        '$flutterExe update-packages',
        '$flutterExe precache',
        '$flutterExe ide-config',
        '$flutterExe create --template=app ${path.join(tmpDir.path, 'create_app')}',
        '$flutterExe create --template=package ${path.join(tmpDir.path, 'create_package')}',
        '$flutterExe create --template=plugin ${path.join(tmpDir.path, 'create_plugin')}',
        '$gitExe clean -f -X **/.packages',
      ]);
      if (Platform.isWindows) {
        commands.add('$zipExe a -tzip -mx=9 ${path.join(tmpDir.path, 'flutter_master.zip')} flutter');
      } else {
        commands.add('$zipExe -r -9 -q ${path.join(tmpDir.path, 'flutter_master.zip')} flutter');
      }

      int step = 0;
      for (String command in commands) {
        _verifyCommand(args[step++], command);
      }
    });

    test('throws when a command errors out', () async {
      outputFile = new File(path.join(tmpDir.absolute.path, 'flutter.tar.xz'));
      preparer = new ArchiveCreator(
        tmpDir,
        outputFile,
        runner: runner,
      );

      results = <MockProcessResult>[
        new MockProcessResult('', '', 0),
        new MockProcessResult('OMG! OMG! an ERROR!\n', '', -1)
      ];
      _answerWithResults();
      expect(() => preparer.checkoutFlutter('master'),
          throwsA(const isInstanceOf<ProcessFailedException>()));
      expect(args.length, 2);
      _verifyCommand(args[0],
          '$gitExe clone -b master https://chromium.googlesource.com/external/github.com/flutter/flutter');
      _verifyCommand(args[1], '$gitExe reset --hard master');
    });
  });
}

class MockProcessRunner extends Mock implements Function {
  ProcessResult call(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding stdoutEncoding,
    Encoding stderrEncoding,
  });
}

class MockProcessResult extends Mock implements ProcessResult {
  MockProcessResult(this.stdout, [this.stderr = '', this.exitCode = 0]);

  @override
  dynamic stdout = '';

  @override
  dynamic stderr;

  @override
  int exitCode;
}
