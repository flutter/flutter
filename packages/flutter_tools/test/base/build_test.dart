// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('Checksum', () {
    group('fromFiles', () {
      MemoryFileSystem fs;

      setUp(() {
        fs = new MemoryFileSystem();
      });

      testUsingContext('throws if any input file does not exist', () async {
        await fs.file('a.dart').create();
        expect(() => new Checksum.fromFiles(<String>['a.dart', 'b.dart'].toSet()), throwsA(anything));
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('populates checksums for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        final Checksum checksum = new Checksum.fromFiles(<String>['a.dart', 'b.dart'].toSet());
        final String json = checksum.toJson();
        expect(json, '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
      }, overrides: <Type, Generator>{ FileSystem: () => fs});
    });

    group('fromJson', () {
      test('throws if JSON is invalid', () async {
        expect(() => new Checksum.fromJson('<xml></xml>'), throwsA(anything));
      });

      test('populates checksums for valid JSON', () async {
        final String json = '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}';
        final Checksum checksum = new Checksum.fromJson(json);
        expect(checksum.toJson(), '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
      });
    });

    group('operator ==', () {
      test('reports not equal if checksums do not match', () async {
        final Checksum a = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Checksum b = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07d"}');
        expect(a == b, isFalse);
      });

      test('reports not equal if keys do not match', () async {
        final Checksum a = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Checksum b = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","c.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        expect(a == b, isFalse);
      });

      test('reports equal if all checksums match', () async {
        final Checksum a = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Checksum b = new Checksum.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        expect(a == b, isTrue);
      });
    });
  });

  group('readDepfile', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = new MemoryFileSystem();
    });

    testUsingContext('returns one file if only one is listed', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>['/foo/a.dart']));
    }, overrides: <Type, Generator>{ FileSystem: () => fs});

    testUsingContext('returns multiple files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart /foo/b.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs});

    testUsingContext('trims extra spaces between files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart    /foo/b.dart  /foo/c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
        '/foo/c.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs});

    testUsingContext('returns files with spaces and backslashes', () async {
      await fs.file('a.d').writeAsString(r'snapshot.d: /foo/a\ a.dart /foo/b\\b.dart /foo/c\\ c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        r'/foo/a a.dart',
        r'/foo/b\b.dart',
        r'/foo/c\ c.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs});
  });
}
