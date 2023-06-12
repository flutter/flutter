// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:convert';
import 'dart:isolate';

import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  late PackageConfig currentPackageConfig;

  setUpAll(() async {
    await precompileTestExecutable();
    currentPackageConfig =
        await loadPackageConfigUri((await Isolate.packageConfig)!);
  });

  setUp(() async {
    await d
        .file('package_config.json',
            jsonEncode(PackageConfig.toJson(currentPackageConfig)))
        .create();
  });

  group('The data isolate strategy', () {
    test('can be enabled', () async {
      // We confirm it is enabled by checking the error output for an invalid
      // test, it looks a bit different.
      await d.file('test.dart', 'invalid Dart file').create();
      var test = await runTest(['--use-data-isolate-strategy', 'test.dart']);

      expect(
          test.stdout,
          containsInOrder([
            'Failed to load "test.dart":',
            "Unable to spawn isolate: test.dart:1:9: Error: Expected ';' after this.",
            'invalid Dart file'
          ]));

      await test.shouldExit(1);
    });

    test('can run tests', () async {
      await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  test('true is true', () {
    expect(true, isTrue);
  });
}
      ''').create();
      var test = await runTest(['--use-data-isolate-strategy', 'test.dart']);

      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });
}
