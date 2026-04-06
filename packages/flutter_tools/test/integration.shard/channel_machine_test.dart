// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

void main() {
  group(
    'flutter channel --version --machine ',
    () {
      late Directory tempDir;

      setUpAll(() async {
        tempDir = createResolvedTempDirectorySync('run_test.');
        await globals.processManager.run(<String>[
          'flutter',
          'create',
          'test_project_1',
        ], workingDirectory: tempDir.path);
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      testUsingContext('produces valid json when using sudo', () async {
        final ProcessResult result = await globals.processManager.run(<String>[
          'sudo',
          'flutter',
          'channel',
          '--version',
          '--machine',
        ], workingDirectory: tempDir.childDirectory('test_project_1').path);

        expect(result.stdout is String, true);
        expect((result.stdout as String).startsWith('{\n'), true);
        expect(result.stdout, isNot(contains(',\n}')));
        expect((result.stdout as String).endsWith('}\n'), true);

        final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;

        expect(decoded.containsKey('frameworkVersion'), true);
        expect(decoded.containsKey('channel'), true);
        expect(decoded.containsKey('repositoryUrl'), true);
        expect(decoded.containsKey('frameworkRevision'), true);
        expect(decoded.containsKey('frameworkCommitDate'), true);
        expect(decoded.containsKey('engineRevision'), true);
        expect(decoded.containsKey('engineCommitDate'), true);
        expect(decoded.containsKey('engineContentHash'), true);
        expect(decoded.containsKey('engineBuildDate'), true);
        expect(decoded.containsKey('dartSdkVersion'), true);
        expect(decoded.containsKey('flutterVersion'), true);
        expect(decoded.containsKey('flutterRoot'), true);
      }, overrides: <Type, Generator>{});
    },
    skip: !(const LocalPlatform().isMacOS || const LocalPlatform().isLinux),
    // Intended: because sudo is available only on mac and linux
  );
  group(
    'flutter channel --version --machine ',
    () {
      late Directory tempDir;

      setUpAll(() async {
        tempDir = createResolvedTempDirectorySync('run_test.');
        await globals.processManager.run(<String>[
          'flutter',
          'create',
          'test_project_2',
        ], workingDirectory: tempDir.path);
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      testUsingContext('produces valid json', () async {
        final ProcessResult result = await globals.processManager.run(<String>[
          'flutter',
          'channel',
          '--version',
          '--machine',
        ], workingDirectory: tempDir.childDirectory('test_project_2').path);

        expect(result.stdout is String, true);
        expect((result.stdout as String).startsWith('{\n'), true);
        expect(result.stdout, isNot(contains(',\n}')));
        expect((result.stdout as String).endsWith('}\n'), true);

        final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;

        expect(decoded.containsKey('frameworkVersion'), true);
        expect(decoded.containsKey('channel'), true);
        expect(decoded.containsKey('repositoryUrl'), true);
        expect(decoded.containsKey('frameworkRevision'), true);
        expect(decoded.containsKey('frameworkCommitDate'), true);
        expect(decoded.containsKey('engineRevision'), true);
        expect(decoded.containsKey('engineCommitDate'), true);
        expect(decoded.containsKey('engineContentHash'), true);
        expect(decoded.containsKey('engineBuildDate'), true);
        expect(decoded.containsKey('dartSdkVersion'), true);
        expect(decoded.containsKey('flutterVersion'), true);
        expect(decoded.containsKey('flutterRoot'), true);
      }, overrides: <Type, Generator>{});
    },
    skip: !(const LocalPlatform().isMacOS || const LocalPlatform().isLinux),
    // Intended: because sudo is available only on mac and linux
  );
}
