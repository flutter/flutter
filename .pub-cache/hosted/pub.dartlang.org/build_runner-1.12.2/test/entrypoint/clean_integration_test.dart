// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  group('clean command', () {
    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
          'glob'
        ]),
        d.dir('tool', [d.file('build.dart', buildFile)]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      // Run a build and validate the output.
      var buildResult = await runDart('a', 'tool/build.dart', args: ['build']);
      expect(buildResult.exitCode, 0);
      await d.dir('a', [
        d.dir('web', [
          d.file('a.txt.copy', 'a'),
        ]),
        d.dir('.dart_tool', [
          d.dir('build'),
        ]),
      ]).validate();
    });

    test('cleans up .dart_tool and generated source files', () async {
      var cleanResult = await runDart('a', 'tool/build.dart', args: ['clean']);
      expect(cleanResult.exitCode, 0);
      await d.dir('a', [
        d.dir('web', [
          d.nothing('a.txt.copy'),
        ]),
        d.dir('.dart_tool', [
          d.nothing('build'),
        ]),
      ]).validate();
    });
  });
}

const buildFile = '''
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  await run(
      args, [applyToRoot(new TestBuilder())]);
}
''';
