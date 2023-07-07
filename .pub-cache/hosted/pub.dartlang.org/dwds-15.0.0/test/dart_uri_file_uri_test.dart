// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:io';

import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixtures/context.dart';

final context = TestContext(
    directory: '../fixtures/_testPackage',
    path: 'index.html',
    pathToServe: 'web');

String get dwdsDir => Directory.current.absolute.path;

/// The directory for the general _test package.
String get testDir => p.join(p.dirname(dwdsDir), 'fixtures', '_test');

/// The directory for the _testPackage package (contained within dwds), which
/// imports _test.
String get testPackageDir => context.workingDirectory;

// This tests converting file Uris into our internal paths.
//
// These tests are separated out because we need a running isolate in order to
// look up packages.
void main() {
  setUpAll(() async {
    await context.setUp();
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('file path to org-dartlang-app', () {
    final webMain = Uri.file(p.join(testPackageDir, 'web', 'main.dart'));
    final uri = DartUri('$webMain');
    expect(uri.serverPath, 'main.dart');
  });

  test('file path to this package', () {
    final testPackageLib =
        Uri.file(p.join(testPackageDir, 'lib', 'test_library.dart'));
    final uri = DartUri('$testPackageLib');
    expect(uri.serverPath, 'packages/_test_package/test_library.dart');
  });

  test('file path to another package', () {
    final testLib = Uri.file(p.join(testDir, 'lib', 'library.dart'));
    final dartUri = DartUri('$testLib');
    expect(dartUri.serverPath, 'packages/_test/library.dart');
  });
}
