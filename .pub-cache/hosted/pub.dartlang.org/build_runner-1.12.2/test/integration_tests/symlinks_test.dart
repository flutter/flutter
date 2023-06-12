// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:io';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:path/path.dart' as p;

import 'utils/build_descriptor.dart';

// test-package-start #########################################################
/// Reads a `.link` asset which is not the primary input and copies it.
final readThroughLink = TestBuilder(
    buildExtensions: appendExtension('.copy', from: '.txt'),
    build: (buildStep, _) {
      buildStep.writeAsString(buildStep.inputId.addExtension('.copy'),
          buildStep.readAsString(buildStep.inputId.changeExtension('.link')));
    });
// test-package-end ###########################################################

void main() {
  final builders = [builder('readThroughLink', readThroughLink)];

  BuildTool buildTool;

  setUpAll(() async {
    buildTool = await packageWithBuildScript(builders, contents: [
      d.dir('web', [d.file('a.txt', 'a')]),
    ]);
    await Link(p.join(buildTool.rootPackageDir, 'web', 'a.link'))
        .create(p.join(buildTool.rootPackageDir, 'outside_build', 'linked'));
  });

  Future<void> updateLinkContent(String content) {
    return d.dir('a', [
      d.dir('outside_build', [d.file('linked', content)])
    ]).create();
  }

  setUp(() async {
    await updateLinkContent('linked');
  });

  Future<void> expectGeneratedContent(String content) async {
    await d.dir('a', [
      d.dir('.dart_tool', [
        d.dir('build', [
          d.dir('generated', [
            d.dir('a', [
              d.dir('web', [d.file('a.txt.copy', content)])
            ])
          ])
        ])
      ])
    ]).validate();
  }

  group('build', () {
    test('reads from a linked file', () async {
      await buildTool.build();
      await expectGeneratedContent('linked');

      await updateLinkContent('new content');
      await buildTool.build();
      await expectGeneratedContent('new content');
    });
  });

  group('serve', () {
    test('watches a linked file', () async {
      var server = await buildTool.serve();
      await server.nextSuccessfulBuild;
      await expectGeneratedContent('linked');

      await updateLinkContent('new content');
      await server.nextSuccessfulBuild;
      await expectGeneratedContent('new content');
    }, skip: 'Watcher package does not support watching symlink targets');
  });
}
