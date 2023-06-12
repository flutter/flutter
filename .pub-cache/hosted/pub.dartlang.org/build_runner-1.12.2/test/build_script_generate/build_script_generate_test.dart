// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(4)

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/descriptors.dart';
import 'package:_test_common/sdk.dart';

void main() {
  group('Builder imports', () {
    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
        ]),
      ]).create();
      await runPub('a', 'get');
    });

    test('warn about deprecated ../ style imports', () async {
      await d.dir('a', [
        d.file('build.yaml', '''
builders:
  fake:
    import: "../../../tool/builder.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"foo": ["bar"]}
'''),
      ]).create();

      var result = await runPub('a', 'run', args: ['build_runner', 'build']);
      expect(result.stdout,
          contains('The `../` import syntax in build.yaml is now deprecated'));
    });

    test('support package relative imports', () async {
      await d.dir('a', [
        d.file('build.yaml', '''
builders:
  fake:
    import: "tool/builder.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"foo": ["bar"]}
'''),
      ]).create();

      var result = await runPub('a', 'run', args: ['build_runner', 'build']);
      expect(
          result.stdout,
          isNot(contains(
              'The `../` import syntax in build.yaml is now deprecated')));

      await d.dir('a', [
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('entrypoint', [
              d.file(
                  'build.dart', contains("import '../../../tool/builder.dart'"))
            ])
          ])
        ])
      ]).validate();
    });

    test('warns for builder config that leaves unparseable Dart', () async {
      await d.dir('a', [
        d.file('build.yaml', '''
builders:
  fake:
    import: "tool/builder.dart"
    builder_factories: ["not an identifier"]
    build_extensions: {"foo": ["bar"]}
''')
      ]).create();
      var result = await runPub('a', 'run', args: ['build_runner', 'build']);
      expect(result.stdout, contains('could not be parsed'));
    });
  });
}
