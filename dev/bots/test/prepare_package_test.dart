// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
    Directory outputDir;
    File versionFile;
    MockProcessStarter starter;
    List<MockProcess> results;
    final List<List<String>> args = <List<String>>[];
    final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
    final String zipExe = Platform.isWindows ? '7za.exe' : 'zip';
    final String tarExe = Platform.isWindows ? 'tar.exe' : 'tar';
    final String gitExe = Platform.isWindows ? 'git.bat' : 'git';
    String flutterExe;
    final String tagResults =
        <String>['2.3.4', '1.2.2', '0.1.2', 'arbitrary_tag', '0.1.1-alpha'].join('\n');

    void _verifyCommand(List<dynamic> args, String expected) {
      final List<String> expectedList = expected.split(' ');
      final String executable = expectedList.removeAt(0);
      expect(args[0], executable);
      expect(args[1], orderedEquals(expectedList));
    }

    Future<Process> _nextResult(Invocation invocation) async {
      args.add(invocation.positionalArguments);
      namedArgs.add(invocation.namedArguments);
      final Process result = results.isEmpty ? new MockProcess('', '', 0) : results.removeAt(0);
      return new Future<Process>.value(result);
    }

    void _answerWithResults() {
      when(
        starter.call(
          typed(captureAny),
          typed(captureAny),
          environment: typed(captureAny, named: 'environment'),
          workingDirectory: typed(captureAny, named: 'workingDirectory'),
        ),
      ).thenAnswer(_nextResult);
    }

    void _createVersionFile(String version) {
      versionFile = new File(path.join(flutterDir.path, 'VERSION'));
      versionFile.writeAsStringSync('''
      # This is a comment.
      
      $version
      ''');
    }

    setUp(() async {
      starter = new MockProcessStarter();
      args.clear();
      namedArgs.clear();
      tmpDir = await Directory.systemTemp.createTemp('flutter_');
      outputDir = new Directory(path.join(tmpDir.absolute.path, 'output'));
      flutterDir = new Directory(path.join(tmpDir.path, 'flutter'));
      flutterDir.createSync(recursive: true);
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
      _createVersionFile('1.2.3-dev');
      preparer = new ArchiveCreator(tmpDir, outputDir, starter: starter, subprocessOutput: false);
      results = new List<MockProcess>.filled(12, new MockProcess('', '', 0), growable: true);
      results.add(new MockProcess(tagResults, '', 0));
      _answerWithResults();
      await preparer.createArchive('master');
      expect(
        verify(starter.call(
          captureAny,
          captureAny,
          workingDirectory: captureAny,
          environment: captureAny,
        )).captured[2]['PUB_CACHE'],
        endsWith(path.join('flutter', '.pub-cache')),
      );
    });

    test('filename is correct with dev version.', () async {
      _createVersionFile('1.2.3-dev');
      preparer = new ArchiveCreator(tmpDir, outputDir, starter: starter, subprocessOutput: false);
      results = <MockProcess>[];
      results.add(new MockProcess(tagResults, '', 0));
      results.add(new MockProcess('deadbeef\n', '', 0));
      results.add(new MockProcess('42\n', '', 0));
      _answerWithResults();
      final String name = await preparer.getArchiveName('master');
      expect(
          name,
          equals(path.join(outputDir.path,
              'flutter_${Platform.operatingSystem.toLowerCase()}_1.2.3-dev.42.tar.xz')));
    });

    test('filename is correct with alpha version.', () async {
      _createVersionFile('1.2.3');
      preparer = new ArchiveCreator(tmpDir, outputDir, starter: starter, subprocessOutput: false);
      results = <MockProcess>[];
      _answerWithResults();
      final String name = await preparer.getArchiveName('master');
      expect(
          name,
          equals(path.join(outputDir.path,
              'flutter_${Platform.operatingSystem.toLowerCase()}_1.2.3.alpha.tar.xz')));
    });

    test('calls the right commands for archive output', () async {
      _createVersionFile('1.2.3-dev');
      preparer = new ArchiveCreator(tmpDir, outputDir, starter: starter, subprocessOutput: false);
      results = new List<MockProcess>.filled(
          Platform.isWindows ? 13 : 12, new MockProcess('', '', 0),
          growable: true);
      results.add(new MockProcess(tagResults, '', 0));
      results.add(new MockProcess('deadbeef\n', '', 0));
      results.add(new MockProcess('42\n', '', 0));
      _answerWithResults();
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
        '$gitExe tag -l',
        '$gitExe tag -l 1.2.2 --format %(objectname)',
        '$gitExe rev-list --first-parent --count deadbeef..HEAD',
      ]);
      if (Platform.isWindows) {
        commands.add(
            '$zipExe a -tzip -mx=9 ${path.join(outputDir.path, 'flutter_windows_0.1.2-dev.42.zip')} flutter');
      } else {
        commands.add(
            '$tarExe cJf ${path.join(outputDir.path, 'flutter_${Platform.operatingSystem.toLowerCase()}_1.2.3-dev.42.tar.xz')} flutter');
      }
      int step = 0;
      for (String command in commands) {
        _verifyCommand(args[step++], command);
      }
    });

    test('throws when a command errors out', () async {
      preparer = new ArchiveCreator(tmpDir, outputDir, starter: starter, subprocessOutput: false);

      results = <MockProcess>[
        new MockProcess('', '', 0),
        new MockProcess('', "Don't panic.\n", -1)
      ];
      _answerWithResults();
      expect(expectAsync1<Null, String>(preparer.checkoutFlutter)('master'),
          throwsA(const isInstanceOf<ProcessFailedException>()));
    });
  });
}

class MockProcessStarter extends Mock implements Function {
  Future<Process> call(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment,
      bool runInShell,
      ProcessStartMode mode});
}

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
