// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Increase timeouts on this test which resolves source code and can be slow.
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  late LibraryReader reader;

  final packageA = Uri.parse('package:a/a.dart');
  final packageB = Uri.parse('package:b/b.dart');
  final assetPackageA = Uri.parse('asset:a/lib/a.dart');
  final assetPackageB = Uri.parse('asset:b/lib/b.dart');
  final packageATestDir = Uri.parse('asset:a/test/a.dart');
  final packageATestDirFileB = Uri.parse('asset:a/test/b.dart');
  final packageATestDirDeepFile = Uri.parse('asset:a/test/in/a/folder/a.dart');
  final packageBTestDir = Uri.parse('asset:b/test/b.dart');
  final dartAsync = Uri.parse('dart:async');
  final dartAsyncPrivate = Uri.parse('dart:async/zone.dart');

  group('from a package URL to', () {
    setUpAll(() {
      reader = LibraryReader(_FakeLibraryElement(packageA));
    });

    test('a dart SDK library', () {
      expect(reader.pathToUrl(dartAsync), dartAsync);
    });

    test('a dart SDK private library', () {
      expect(reader.pathToUrl(dartAsyncPrivate), dartAsync);
    });

    test('the same package', () {
      expect(reader.pathToUrl(packageA), packageA);
    });

    test('the same package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageA), packageA);
    });

    test('another package', () {
      expect(reader.pathToUrl(packageB), packageB);
    });

    test('another package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageB), packageB);
    });

    test('the same package outside of lib should throw', () {
      expect(() => reader.pathToUrl(packageATestDir), throwsArgumentError);
    });

    test('another package outside of lib should throw', () {
      expect(() => reader.pathToUrl(packageBTestDir), throwsArgumentError);
    });
  });

  group('from an asset URL representing a package to', () {
    setUpAll(() {
      reader = LibraryReader(_FakeLibraryElement(assetPackageA));
    });

    test('a dart SDK library', () {
      expect(reader.pathToUrl(dartAsync), dartAsync);
    });

    test('a dart SDK private library', () {
      expect(reader.pathToUrl(dartAsyncPrivate), dartAsync);
    });

    test('the same package', () {
      expect(reader.pathToUrl(packageA), packageA);
    });

    test('the same package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageA), packageA);
    });

    test('another package', () {
      expect(reader.pathToUrl(packageB), packageB);
    });

    test('another package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageB), packageB);
    });

    test('the same package outside of lib should throw', () {
      expect(() => reader.pathToUrl(packageATestDir), throwsArgumentError);
    });

    test('another package outside of lib should throw', () {
      expect(() => reader.pathToUrl(packageBTestDir), throwsArgumentError);
    });
  });

  group('from an asset URL representing a test directory to', () {
    setUpAll(() {
      reader = LibraryReader(_FakeLibraryElement(packageATestDir));
    });

    test('a dart SDK library', () {
      expect(reader.pathToUrl(dartAsync), dartAsync);
    });

    test('a dart SDK private library', () {
      expect(reader.pathToUrl(dartAsyncPrivate), dartAsync);
    });

    test('the same package', () {
      expect(reader.pathToUrl(packageA), packageA);
    });

    test('the same package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageA), packageA);
    });

    test('another package', () {
      expect(reader.pathToUrl(packageB), packageB);
    });

    test('another package as an asset URL', () {
      expect(reader.pathToUrl(assetPackageB), packageB);
    });

    test('the same package in the test directory', () {
      expect(reader.pathToUrl(packageATestDir), Uri.parse('a.dart'));
    });

    test('the same package in the test directory, different file', () {
      expect(reader.pathToUrl(packageATestDirFileB), Uri.parse('b.dart'));
    });

    test('the same package in the test directory, different deeper file', () {
      expect(
        reader.pathToUrl(packageATestDirDeepFile),
        Uri.parse('in/a/folder/a.dart'),
      );
    });

    test('in the same package in the test directory, a shallow file', () {
      reader = LibraryReader(
        _FakeLibraryElement(packageATestDirDeepFile),
      );
      expect(
        reader.pathToUrl(packageATestDir),
        Uri.parse('../../../a.dart'),
      );
    });

    test('the same package in the tool directory should throw', () {
      final packageAToolDir = Uri.parse('asset:a/tool/a.dart');
      expect(() => reader.pathToUrl(packageAToolDir), throwsArgumentError);
    });

    test('another package in the test directory should throw', () {
      expect(() => reader.pathToUrl(packageBTestDir), throwsArgumentError);
    });
  });
}

class _FakeLibraryElement implements LibraryElement {
  final Uri _sourceUri;

  _FakeLibraryElement(this._sourceUri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Source get source => _FakeSource(_sourceUri);
}

class _FakeSource implements Source {
  @override
  final Uri uri;

  const _FakeSource(this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
