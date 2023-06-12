// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:io';

import 'package:build_runner_core/src/util/constants.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils/build_descriptor.dart';

// test-package-start #########################################################
// $comment$
final copyBuilder = TestBuilder();
// test-package-end ###########################################################

void main() {
  final builders = [
    builder('copyBuilder', copyBuilder),
  ];

  BuildTool buildTool;
  d.Descriptor builderPackage;

  setUpAll(() async {
    builderPackage = await packageWithBuilders(builders);
    buildTool = await package([
      builderPackage
    ], packageContents: [
      d.file('build.yaml', '#comment'),
      d.dir('web', [d.file('a.txt', 'a')])
    ]);
  });

  tearDown(() async {
    // Restore the files to their original state
    final builderFile =
        File(p.join(d.sandbox, builderPackage.name, 'lib', 'builders.dart'));
    await builderFile.writeAsString((await builderFile.readAsString())
        .replaceFirst(r'$updated$', r'$comment$'));
    final buildConfig = File(p.url.join(d.sandbox, 'a', 'build.yaml'));
    await buildConfig.writeAsString((await buildConfig.readAsString())
        .replaceFirst('#updated', '#comment'));
  });

  Future<void> changeBuilders() async {
    final builderFile =
        File(p.join(d.sandbox, builderPackage.name, 'lib', 'builders.dart'));
    await builderFile.writeAsString((await builderFile.readAsString())
        .replaceFirst(r'$comment$', r'$updated$'));
  }

  Future<void> changeBuildConfig() async {
    final buildConfig = File(p.url.join(d.sandbox, 'a', 'build.yaml'));
    // Update a comment
    await buildConfig.writeAsString((await buildConfig.readAsString())
        .replaceFirst('#comment', '#updated'));
  }

  group('Invalidates next build', () {
    File markerFile;
    setUp(() async {
      // Run a first build before invalidation.
      await buildTool.build();

      // Add a marker file to check that generated directory is cleaned.
      markerFile = File(p.join(d.sandbox, 'a', '.dart_tool', 'build',
          'generated', 'a', 'marker_file.txt'));
      await markerFile.writeAsString('marker');
    });

    tearDown(() async {
      expect(await markerFile.exists(), isFalse,
          reason: 'Cache dir should be cleaned on invalidated builds.');
    });

    test('for changed dart source', () async {
      await changeBuilders();

      final secondBuild = await buildTool.build();

      await expectOutput(secondBuild, [
        'Invalidating asset graph due to build script update',
        'Creating build script snapshot',
        'Building new asset graph',
      ]);
    });

    test('for invalid asset graph version', () async {
      final assetGraph = File(p.join(
          d.sandbox,
          'a',
          assetGraphPathFor(p.url.join(
              '.dart_tool', 'build', 'entrypoint', 'build.dart.snapshot'))));
      // Prepend a 1 to the version number
      await assetGraph.writeAsString((await assetGraph.readAsString())
          .replaceFirst('"version":', '"version":1'));

      final secondBuild = await buildTool.build();

      await expectOutput(secondBuild, [
        'Throwing away cached asset graph due to version mismatch',
        'Building new asset graph',
      ]);
    });
  });

  group('Recreates snapshot while serving', () {
    BuildServer server;

    setUp(() async {
      server = await buildTool.serve();
      await server.nextSuccessfulBuild;
    });

    test('for changed dart source', () async {
      await changeBuilders();

      await expectOutput(server.stdout, [
        'Terminating builds due to build script update',
        'Creating build script snapshot',
        'Building new asset graph',
      ]);

      await server.shutDown();
    });

    test('for changed build config', () async {
      await changeBuildConfig();

      // Terminates and reruns, but does not invalidate build
      await expectOutput(server.stdout, [
        'Terminating builds due to a:build.yaml update',
        'Builds finished. Safe to exit',
        'with 0 outputs',
      ]);

      await server.shutDown();
    });
  });

  test('Recreates snapshot for changed core dependency path', () async {
    // Run a first build before invalidation.
    await buildTool.build();

    final locationsFile = File(p.join(d.sandbox, 'a', '.dart_tool', 'build',
        'entrypoint', '.packageLocations'));
    // Modify the contents in some way
    await locationsFile.writeAsString('${await locationsFile.readAsString()}'
        '\nmodified!');

    final secondBuild = await buildTool.build();

    await expectOutput(secondBuild, [
      'Deleted previous snapshot due to core package update',
      'Creating build script snapshot',
    ]);
  });

  test('Does not recreate snapshot if nothing changes', () async {
    // Run a first build before invalidation.
    await buildTool.build();

    final secondBuild = await buildTool.build();
    await expectLater(secondBuild, neverEmits('Creating build script snapshot'),
        reason: 'should not invalidate the previous snapshot');
  });
}
