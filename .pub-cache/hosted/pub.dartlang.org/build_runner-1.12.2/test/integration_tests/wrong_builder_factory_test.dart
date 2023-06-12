// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:io/io.dart' show ExitCode;

import 'utils/build_descriptor.dart';

// test-package-start #########################################################
final correctKey = TestBuilder(buildExtensions: {
  '.txt': ['.txt.copy', '.txt.extra']
});
// test-package-end ###########################################################

void main() {
  final builders = [
    builder('wrongKey', correctKey),
  ];

  BuildTool buildTool;

  setUpAll(() async {
    buildTool = await package([await packageWithBuilders(builders)]);
  });

  group('build', () {
    test('warns when builder definition produces invalid build script',
        () async {
      var result = await buildTool.build(expectExitCode: ExitCode.config.code);
      expect(result, emitsThrough(contains('Getter not found: \'wrongKey\'')));
      expect(
          result, emitsThrough(contains('misconfigured builder definition')));
    });
  });
}
