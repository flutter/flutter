// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze_base.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:io/io.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

const String _kFlutterRoot = '/data/flutter';

void main() {
  Directory tempDir;
  FakePlatform fakePlatform;
  FileSystem fs;
  _MockProcessManager processManager;
  UpgradeCommandRunner realCommandRunner;

  setUp(() {
    fs = MemoryFileSystem();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
    Cache.flutterRoot = _kFlutterRoot;
    tempDir = fs.systemTempDirectory.createTempSync('flutter_analysis_test.');
    realCommandRunner = UpgradeCommandRunner();
    processManager = _MockProcessManager();
    fakePlatform = FakePlatform()..environment = Map<String, String>.unmodifiable(<String, String>{
        'ENV1': 'irrelevant',
        'ENV2': 'irrelevant',
    });
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  group('analyze', () {
    testUsingContext('inRepo', () {
      // Absolute paths
      expect(inRepo(<String>[tempDir.path]), isFalse);
      expect(inRepo(<String>[fs.path.join(tempDir.path, 'foo')]), isFalse);
      expect(inRepo(<String>[Cache.flutterRoot]), isTrue);
      expect(inRepo(<String>[fs.path.join(Cache.flutterRoot, 'foo')]), isTrue);

      // Relative paths
      fs.currentDirectory = Cache.flutterRoot;
      expect(inRepo(<String>['.']), isTrue);
      expect(inRepo(<String>['foo']), isTrue);
      fs.currentDirectory = tempDir.path;
      expect(inRepo(<String>['.']), isFalse);
      expect(inRepo(<String>['foo']), isFalse);

      // Ensure no exceptions
      inRepo(null);
      inRepo(<String>[]);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });

    testUsingContext('analyze --flutter-repo should run update-package first', () async {
      final List<String> analyzeCommand = <String>[
        fs.path.join('bin', 'flutter'),
        'analyze --flutter-repo',
        '--no-version-check',
        'precache',
      ];

      when(processManager.start(
        analyzeCommand,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) async {
        return Future<Process>.value(createMockProcess());
      });

      //await realCommandRunner.precacheArtifacts();

      final VerificationResult result = verify(processManager.start(
        analyzeCommand,
        environment: captureAnyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      ));

      print(result.captured.first);
      expect(result.captured.first,
          <String, String>{ 'Running "flutter pub get" in automated_tests...': 'true', ...fakePlatform.environment });
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });
  });
}

class _MockProcessManager extends Mock implements ProcessManager {}