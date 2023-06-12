// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';

import 'package:build_test/build_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils/build_descriptor.dart';

// test-package-start #########################################################
/// Copies an asset to both `.txt.copy` and `.txt.extra`.
final copyTwice = TestBuilder(buildExtensions: {
  '.txt': ['.txt.copy', '.txt.extra']
});

/// Reads `.txt.copy` files if the primary input contains "true".
final maybeReadCopy = TestBuilder(
    buildExtensions: appendExtension('.other', from: '.txt'),
    extraWork: (buildStep, _) async {
      if ((await buildStep.readAsString(buildStep.inputId)).contains('true')) {
        await buildStep.readAsString(buildStep.inputId.addExtension('.copy'));
      }
    });
// test-package-end ###########################################################

void main() {
  final builders = [
    builder('copyTwice', copyTwice, isOptional: true),
    builder('maybeReadCopy', maybeReadCopy, requiredInputs: ['.txt.copy'])
  ];

  BuildTool buildTool;

  setUpAll(() async {
    buildTool = await packageWithBuildScript(builders, contents: [
      d.dir('web', [d.file('a.txt', 'false')])
    ]);
  });

  Future<void> updateTxtContent(String content) {
    return d.dir('a', [
      d.dir('web', [d.file('a.txt', content)])
    ]).create();
  }

  group('serve', () {
    test('only serves assets that were actually required', () async {
      var server = await buildTool.serve();
      await server.started;

      await server.expect404('a.txt.copy');
      await server.expect404('a.txt.extra');

      await updateTxtContent('true');

      await server.nextSuccessfulBuild;

      await server.expectContent('a.txt.copy', 'true');
      await server.expectContent('a.txt.extra', 'true');

      await updateTxtContent('false');

      await server.nextSuccessfulBuild;

      await server.expect404('a.txt.copy');
      await server.expect404('a.txt.extra');

      await server.shutDown();
    });
  });

  group('build', () {
    /// Expects the build output based on [expectCopy].
    Future<void> expectBuildOutput(
        {@required bool expectCopy, @required String content}) async {
      await d.dir('a', [
        d.dir('build', [
          d.dir('web', [
            d.file('a.txt', content),
            d.file('a.txt.other', content),
            expectCopy
                ? d.file('a.txt.copy', content)
                : d.nothing('a.txt.copy'),
            expectCopy
                ? d.file('a.txt.extra', content)
                : d.nothing('a.txt.extra'),
          ]),
        ]),
      ]).validate();
    }

    test('only copies assets that were actually required', () async {
      await buildTool.build(args: const ['-o', 'build']);
      await expectBuildOutput(expectCopy: false, content: 'false');

      // Run another build but with the file indicating that the copy should be
      // read
      await updateTxtContent('true');
      await buildTool.build(args: const ['-o', 'build']);
      await expectBuildOutput(expectCopy: true, content: 'true');

      // Run again without reading the copy, should not copy over the .copy
      // file even though it does exist now.
      await updateTxtContent('false');
      await buildTool.build(args: const ['-o', 'build']);
      await expectBuildOutput(expectCopy: false, content: 'false');
    });
  });
}
