// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils/build_descriptor.dart';

// test-package-start #########################################################
final alwaysThrow = TestBuilder(
    buildExtensions: {
      '.txt': ['.txt.copy'],
    },
    build: (_, __) {
      throw StateError('Build action failure');
    });
// test-package-end ###########################################################

void main() {
  final builders = [
    builder('alwaysThrow', alwaysThrow),
  ];

  BuildTool buildTool;

  setUpAll(() async {
    buildTool = await packageWithBuildScript(builders, contents: [
      d.dir('web', [d.file('a.txt', 'a')])
    ]);
  });

  group('build', () {
    test('replays errors on builds with no change', () async {
      final firstBuild = await buildTool.build(expectExitCode: 1);
      await expectLater(
          firstBuild, emitsThrough(contains('Build action failure')));

      // Run another build, no action should run but the failure will be logged
      // again
      final nextBuild = await buildTool.build(expectExitCode: 1);
      await expectLater(
          nextBuild, emitsThrough(contains('Build action failure')));
    });
  });
}
