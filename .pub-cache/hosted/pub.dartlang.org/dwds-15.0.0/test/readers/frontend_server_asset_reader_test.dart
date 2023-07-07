// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../fixtures/utilities.dart';

final packagesDir = p.relative('../fixtures/_test', from: p.current);

void main() {
  FrontendServerAssetReader assetReader;
  Directory tempFixtures;
  File jsonOriginal;
  File mapOriginal;

  Future<void> createTempFixtures() async {
    final fixtures = p.join('test', 'fixtures');
    tempFixtures = await Directory.systemTemp.createTemp('dwds_test_fixtures');
    await tempFixtures.create();
    jsonOriginal = await File(p.join(fixtures, 'main.dart.dill.json'))
        .copy(p.join(tempFixtures.path, 'main.dart.dill.json'));
    mapOriginal = await File(p.join(fixtures, 'main.dart.dill.map'))
        .copy(p.join(tempFixtures.path, 'main.dart.dill.map'));
  }

  setUpAll(() async {
    await Process.run(dartPath, ['pub', 'upgrade'],
        workingDirectory: packagesDir);
  });

  setUp(() async {
    await createTempFixtures();
    assetReader = FrontendServerAssetReader(
      p.join(tempFixtures.path, 'main.dart.dill'),
      packagesDir,
    );
    await assetReader.updateCaches();
  });

  tearDown(() async {
    if (await tempFixtures.exists()) await tempFixtures.delete(recursive: true);
  });

  group('FrontendServerAssetReader', () {
    group('sources', () {
      test('as packages path can be read', () async {
        final result =
            await assetReader.dartSourceContents('packages/path/path.dart');
        expect(result, isNotNull);
      });

      test('as relative path can be read', () async {
        final result = await assetReader.dartSourceContents('lib/library.dart');
        expect(result, isNotNull);
      });

      test('are null if the path does not exist', () async {
        final result = await assetReader.dartSourceContents('foo/blah.dart');
        expect(result, isNull);
      });
    });

    group('source maps', () {
      test('can be read', () async {
        final result =
            await assetReader.sourceMapContents('web/main.dart.lib.js.map');
        expect(result, isNotNull);
      });

      test('are cached', () async {
        // Remove the underlying fixtures.
        await tempFixtures.delete(recursive: true);

        final cachedResult =
            await assetReader.sourceMapContents('web/main.dart.lib.js.map');
        expect(cachedResult, isNotNull);
      });

      test('are null if the path does not exist', () async {
        final result =
            await assetReader.sourceMapContents('web/foo.dart.lib.js.map');
        expect(result, isNull);
      });

      test('are updated with new incremental results', () async {
        final missingResult =
            await assetReader.sourceMapContents('web/foo.dart.lib.js.map');
        expect(missingResult, isNull);

        // Update fixture.
        await File(p.join(tempFixtures.path, 'main.dart.dill.incremental.json'))
            .writeAsString((await jsonOriginal.readAsString())
                .replaceAll('web/main.dart.lib.js', 'web/foo.dart.lib.js'));
        await File(p.join(tempFixtures.path, 'main.dart.dill.incremental.map'))
            .writeAsString((await mapOriginal.readAsString())
                .replaceAll('web/main.dart.lib.js', 'web/foo.dart.lib.js'));

        await assetReader.updateCaches();

        final newResult =
            await assetReader.sourceMapContents('web/foo.dart.lib.js.map');
        expect(newResult, isNotNull);
      });
    });
  });
}
