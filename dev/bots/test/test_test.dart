// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:file/file.dart' as fs;
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import '../test.dart';
import 'common.dart';

/// Fails a test if the exit code of `result` is not the expected value. This
/// is favored over `expect(result.exitCode, expectedExitCode)` because this
/// will include the process result's stdio in the failure message.
void expectExitCode(ProcessResult result, int expectedExitCode) {
  if (result.exitCode != expectedExitCode) {
    fail('Failure due to exit code ${result.exitCode}\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}');
  }
}

void main() {
  group('verifyVersion()', () {
    MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    test('passes for valid version strings', () async {
      const List<String> valid_versions = <String>[
        '1.2.3',
        '12.34.56',
        '1.2.3.pre.1',
        '1.2.3-4.5.pre',
        '1.2.3-5.0.pre.12',
      ];
      for (final String version in valid_versions) {
        final File file = fileSystem.file('version');
        file.writeAsStringSync(version);

        expect(
          await verifyVersion(file),
          isNull,
          reason: '$version is valid but verifyVersionFile said it was bad',
        );
      }
    });

    test('fails for invalid version strings', () async {
      const List<String> invalid_versions = <String>[
        '1.2.3.4',
        '1.2.3.',
        '1.2.pre.1',
        '1.2.3-pre.1',
        '1.2.3-pre.1+hotfix.1',
        '  1.2.3',
        '1.2.3-hotfix.1',
      ];
      for (final String version in invalid_versions) {
        final File file = fileSystem.file('version');
        file.writeAsStringSync(version);

        expect(
          await verifyVersion(file),
          'The version logic generated an invalid version string: "$version".',
          reason: '$version is invalid but verifyVersionFile said it was fine',
        );
      }
    });
  });

  group('flutter/plugins version', () {
    final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
    final fs.File pluginsVersionFile = memoryFileSystem.file(path.join('bin','internal','flutter_plugins.version'));
    const String kSampleHash = '592b5b27431689336fa4c721a099eedf787aeb56';
    setUpAll(() {
      pluginsVersionFile.createSync(recursive: true);
    });

    test('commit hash', () async {
      pluginsVersionFile.writeAsStringSync(kSampleHash);
      final String actualHash = await getFlutterPluginsVersion(fileSystem: memoryFileSystem, pluginsVersionFile: pluginsVersionFile.path);
      expect(actualHash, kSampleHash);
    });

    test('commit hash with newlines', () async {
      pluginsVersionFile.writeAsStringSync('\n$kSampleHash\n');
      final String actualHash = await getFlutterPluginsVersion(fileSystem: memoryFileSystem, pluginsVersionFile: pluginsVersionFile.path);
      expect(actualHash, kSampleHash);
    });
  });

  group('test.dart script', () {
    const ProcessManager processManager = LocalProcessManager();

    Future<ProcessResult> runScript(
        [Map<String, String> environment, List<String> otherArgs = const <String>[]]) async {
      final String dart = path.absolute(
          path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
      final ProcessResult scriptProcess = processManager.runSync(<String>[
        dart,
        'test.dart',
        ...otherArgs,
      ], environment: environment);
      return scriptProcess;
    }

    test('subshards tests correctly', () async {
      ProcessResult result = await runScript(
        <String, String>{'SHARD': 'smoke_tests', 'SUBSHARD': '1_3'},
      );
      expectExitCode(result, 0);
      // There are currently 6 smoke tests. This shard should contain test 1 and 2.
      expect(result.stdout, contains('Selecting subshard 1 of 3 (range 1-2 of 6)'));

      result = await runScript(
        <String, String>{'SHARD': 'smoke_tests', 'SUBSHARD': '5_6'},
      );
      expectExitCode(result, 0);
      // This shard should contain only test 5.
      expect(result.stdout, contains('Selecting subshard 5 of 6 (range 5-5 of 6)'));
    });

    test('exits with code 1 when SUBSHARD index greater than total', () async {
      final ProcessResult result = await runScript(
        <String, String>{'SHARD': 'smoke_tests', 'SUBSHARD': '100_99'},
      );
      expectExitCode(result, 1);
      expect(result.stdout, contains('Invalid subshard name'));
    });
  });
}
