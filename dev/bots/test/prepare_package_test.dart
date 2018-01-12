// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import '../prepare_package.dart';

void main() {
  group('ArchiveCreator', () {
    ArchiveCreator preparer;
    Directory tmpDir;
    Directory flutterDir;
    File outputFile;
    MockProcessManager processManager;
    List<MockProcess> results = <MockProcess>[];
    final List<List<String>> args = <List<String>>[];
    final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
    String flutterExe;

    void _verifyCommand(List<dynamic> args, String expected) {
      final List<String> expectedList = expected.split(' ');
      expect(args[0], orderedEquals(expectedList));
    }

    Future<Process> _nextResult(Invocation invocation) async {
      args.add(invocation.positionalArguments);
      namedArgs.add(invocation.namedArguments);
      final Process result = results.isEmpty ? new MockProcess('', '', 0) : results.removeAt(0);
      return new Future<Process>.value(result);
    }

    void _answerWithResults() {
      when(
        processManager.start(
          typed(captureAny),
          environment: typed(captureAny, named: 'environment'),
          workingDirectory: typed(captureAny, named: 'workingDirectory'),
        ),
      ).thenAnswer(_nextResult);
    }

    setUp(() async {
      processManager = new MockProcessManager();
      args.clear();
      namedArgs.clear();
      tmpDir = await Directory.systemTemp.createTemp('flutter_');
      outputFile =
          new File(path.join(tmpDir.absolute.path, ArchiveCreator.defaultArchiveName('master')));
      flutterDir = new Directory(path.join(tmpDir.path, 'flutter'));
      flutterDir.createSync(recursive: true);
      flutterExe =
          path.join(flutterDir.path, 'bin', 'flutter');
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
      preparer =
          new ArchiveCreator(tmpDir, processManager: processManager, subprocessOutput: false);
      _answerWithResults();
      await preparer.createArchive('master', outputFile);
      expect(
        verify(processManager.start(
          captureAny,
          workingDirectory: captureAny,
          environment: captureAny,
        )).captured[1]['PUB_CACHE'],
        endsWith(path.join('flutter', '.pub-cache')),
      );
    });

    test('calls the right commands for archive output', () async {
      preparer =
          new ArchiveCreator(tmpDir, processManager: processManager, subprocessOutput: false);
      _answerWithResults();
      await preparer.createArchive('master', outputFile);
      final List<String> commands = <String>[
        'git clone -b master https://chromium.googlesource.com/external/github.com/flutter/flutter',
        'git reset --hard master',
        'git remote remove origin',
        'git remote add origin https://github.com/flutter/flutter.git',
      ];
      if (Platform.isWindows) {
        commands.add('7za x ${path.join(tmpDir.path, 'mingit.zip')}');
      }
      commands.addAll(<String>[
        '$flutterExe doctor',
        '$flutterExe update-packages',
        '$flutterExe precache',
        '$flutterExe ide-config',
        '$flutterExe create --template=app ${path.join(tmpDir.path, 'create_app')}',
        '$flutterExe create --template=package ${path.join(tmpDir.path, 'create_package')}',
        '$flutterExe create --template=plugin ${path.join(tmpDir.path, 'create_plugin')}',
        'git clean -f -X **/.packages',
      ]);
      if (Platform.isWindows) {
        commands.add('7za a -tzip -mx=9 ${outputFile.absolute.path} flutter');
      } else {
        commands.add('tar cJf ${outputFile.absolute.path} flutter');
      }
      int step = 0;
      for (String command in commands) {
        _verifyCommand(args[step++], command);
      }
    });

    test('throws when a command errors out', () async {
      preparer =
          new ArchiveCreator(tmpDir, processManager: processManager, subprocessOutput: false);

      results = <MockProcess>[
        new MockProcess('', '', 0),
        new MockProcess('', "Don't panic.\n", -1)
      ];
      _answerWithResults();
      expect(expectAsync2<Null, String, File>(preparer.createArchive)('master', new File('foo')),
          throwsA(const isInstanceOf<ProcessFailedException>()));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {
  MockProcess(this._stdout, [this._stderr, this._exitCode]);

  String _stdout;
  String _stderr;
  int _exitCode;

  @override
  Stream<List<int>> get stdout =>
      new Stream<List<int>>.fromIterable(<List<int>>[_stdout.codeUnits]);

  @override
  Stream<List<int>> get stderr =>
      new Stream<List<int>>.fromIterable(<List<int>>[_stderr.codeUnits]);

  @override
  Future<int> get exitCode => new Future<int>.value(_exitCode);
}
