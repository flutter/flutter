// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_tool/src/gn.dart';
import 'package:engine_tool/src/label.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('gn.desc handles a non-zero exit code', () async {
    final TestEnvironment testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: <CannedProcess>[
        CannedProcess(
          (List<String> command) => command.contains('desc'),
          exitCode: 1,
          stdout: 'stdout',
          stderr: 'stderr',
        ),
      ],
    );
    try {
      final Gn gn = Gn.fromEnvironment(testEnv.environment);
      await gn.desc('out/Release', TargetPattern('//foo', 'bar'));
      fail('Expected an exception');
    } catch (e) {
      final String message = '$e';
      expect(message, contains('Failed to run'));
      expect(message, contains('exit code 1'));
      expect(message, contains('STDOUT:\nstdout'));
      expect(message, contains('STDERR:\nstderr'));
    } finally {
      testEnv.cleanup();
    }
  });

  test('gn.desc handles unparseable stdout', () async {
    final TestEnvironment testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: <CannedProcess>[
        CannedProcess(
          (List<String> command) => command.contains('desc'),
          stdout: 'not json',
        ),
      ],
    );
    try {
      final Gn gn = Gn.fromEnvironment(testEnv.environment);
      await gn.desc('out/Release', TargetPattern('//foo', 'bar'));
      fail('Expected an exception');
    } catch (e) {
      final String message = '$e';
      expect(message, contains('Failed to parse JSON'));
      expect(message, contains('not json'));
    } finally {
      testEnv.cleanup();
    }
  });

  test('gn.desc parses build targets', () async {
    final TestEnvironment testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: <CannedProcess>[
        CannedProcess(
          (List<String> command) => command.contains('desc'),
          stdout: '''
            {
              "//foo/bar:baz_test": {
                "outputs": ["//out/host_debug/foo/bar/baz_test"],
                "testonly": true,
                "type": "executable"
              },
              "//foo/bar:baz_shared_library": {
                "testonly": false,
                "type": "shared_library"
              },
              "//foo/bar:baz_static_library": {
                "testonly": false,
                "type": "static_library"
              }
            }
          ''',
        ),
      ],
    );
    try {
      final Gn gn = Gn.fromEnvironment(testEnv.environment);
      final List<BuildTarget> targets = await gn.desc('out/Release', TargetPattern('//foo', 'bar'));
      expect(targets, hasLength(3));

      // There should be exactly one binary test target and two library targets.
      final ExecutableBuildTarget testTarget = targets.whereType<ExecutableBuildTarget>().single;
      expect(testTarget, ExecutableBuildTarget(
        label: Label('//foo/bar', 'baz_test'),
        testOnly: true,
        executable: 'out/host_debug/foo/bar/baz_test',
      ));

      final List<LibraryBuildTarget> libraryTargets = targets.whereType<LibraryBuildTarget>().toList();
      expect(libraryTargets, hasLength(2));
      expect(libraryTargets.contains(LibraryBuildTarget(
        label: Label('//foo/bar', 'baz_shared_library'),
        testOnly: false,
      )), isTrue);
      expect(libraryTargets.contains(LibraryBuildTarget(
        label: Label('//foo/bar', 'baz_static_library'),
        testOnly: false,
      )), isTrue);
    } finally {
      testEnv.cleanup();
    }
  });
}
