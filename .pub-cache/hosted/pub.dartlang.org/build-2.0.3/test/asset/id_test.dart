// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:build/build.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('normalizes the path', () {
      var id = AssetId('app', r'path/././/to/drop/..//asset.txt');
      expect(id.path, equals('path/to/asset.txt'));
    });

    test('normalizes backslashes to slashes in the path', () {
      var id = AssetId('app', r'path\to/asset.txt');
      expect(id.path, equals('path/to/asset.txt'));
    });
  });

  group('parse', () {
    test('parses the package and path', () {
      var id = AssetId.parse('package|path/to/asset.txt');
      expect(id.package, equals('package'));
      expect(id.path, equals('path/to/asset.txt'));
    });

    test("throws if there are multiple '|'", () {
      expect(() => AssetId.parse('app|path|wtf'), throwsFormatException);
    });

    test("throws if the package name is empty '|'", () {
      expect(() => AssetId.parse('|asset.txt'), throwsFormatException);
    });

    test("throws if the path is empty '|'", () {
      expect(() => AssetId.parse('app|'), throwsFormatException);
    });

    test('normalizes the path', () {
      var id = AssetId.parse(r'app|path/././/to/drop/..//asset.txt');
      expect(id.path, equals('path/to/asset.txt'));
    });

    test('normalizes backslashes to slashes in the path', () {
      var id = AssetId.parse(r'app|path\to/asset.txt');
      expect(id.path, equals('path/to/asset.txt'));
    });
  });

  group('resolve', () {
    test('should parse a package: URI', () {
      var id = AssetId.resolve(Uri.parse(r'package:app/app.dart'));
      expect(id, AssetId('app', 'lib/app.dart'));
    });

    test('should parse a package: URI with a long path', () {
      var id = AssetId.resolve(Uri.parse(r'package:app/src/some/path.dart'));
      expect(id, AssetId('app', 'lib/src/some/path.dart'));
    });

    test('should parse an asset: URI', () {
      var id = AssetId.resolve(Uri.parse(r'asset:app/test/foo_test.dart'));
      expect(id, AssetId('app', 'test/foo_test.dart'));
    });

    test('should throw for a file: URI', () {
      expect(() => AssetId.resolve(Uri.parse(r'file://localhost/etc/fstab1')),
          throwsUnsupportedError);
    });

    test('should throw for a dart: URI', () {
      expect(() => AssetId.resolve(Uri.parse(r'dart:collection')),
          throwsUnsupportedError);
    });

    test('should throw parsing a relative package URI without an origin', () {
      expect(() => AssetId.resolve(Uri.parse('some/relative/path.dart')),
          throwsArgumentError);
    });

    test('should parse a relative URI within the test/ folder', () {
      var id = AssetId.resolve(Uri.parse('common.dart'),
          from: AssetId('app', 'test/some_test.dart'));
      expect(id, AssetId('app', 'test/common.dart'));
    });

    test('should parse a relative package URI', () {
      var id = AssetId.resolve(Uri.parse('some/relative/path.dart'),
          from: AssetId('app', 'lib/app.dart'));
      expect(id, AssetId('app', 'lib/some/relative/path.dart'));
    });

    test('should parse a relative package URI pointing back', () {
      var id = AssetId.resolve(Uri.parse('../src/some/path.dart'),
          from: AssetId('app', 'folder/folder.dart'));
      expect(id, AssetId('app', 'src/some/path.dart'));
    });

    test('should parse an empty url in lib/', () {
      var source = AssetId('foo', 'lib/src/bar.dart');
      expect(AssetId.resolve(Uri.parse(''), from: source), source);
    });

    test('should parse an empty url in test/', () {
      var source = AssetId('foo', 'test/bar.dart');
      expect(AssetId.resolve(Uri.parse(''), from: source), source);
    });
  });

  group('to URI', () {
    test('uses `package:` URIs inside lib/', () {
      expect(AssetId('foo', 'lib/bar.dart').uri,
          Uri.parse('package:foo/bar.dart'));
    });

    test('uses `asset:` URIs outside lib/', () async {
      expect(AssetId('foo', 'web/main.dart').uri,
          Uri.parse('asset:foo/web/main.dart'));
    });

    test('handles characters that are valid in a file path', () {
      expect(AssetId('foo', 'lib/#bar.dart').uri,
          Uri.parse('package:foo/%23bar.dart'));
    });
  });

  test('equals another ID with the same package and path', () {
    expect(
        AssetId.parse('foo|asset.txt'), equals(AssetId.parse('foo|asset.txt')));

    expect(AssetId.parse('foo|asset.txt'),
        isNot(equals(AssetId.parse('bar|asset.txt'))));

    expect(AssetId.parse('foo|asset.txt'),
        isNot(equals(AssetId.parse('bar|other.txt'))));
  });

  test('identical assets are treated as the same in a Map/Set', () {
    var id1 = AssetId('a', 'web/a.txt');
    var id2 = AssetId('a', 'web/a.txt');

    expect({id1: true}.containsKey(id2), isTrue);
    expect(<AssetId>{id1}, contains(id2));
  });
}
