// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('Fingerprint', () {
    group('fromInputs', () {
      MemoryFileSystem fs;

      setUp(() {
        fs = new MemoryFileSystem();
      });

      testUsingContext('throws if any input file does not exist', () async {
        await fs.file('a.dart').create();
        expect(() => new Fingerprint.fromInputs(filePaths: <String>['a.dart', 'b.dart'].toSet()), throwsA(anything));
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('throws on file path and property collision', () async {
        await fs.file('a.dart').create();
        expect(() => new Fingerprint.fromInputs(filePaths: <String>['a.dart'].toSet(), properties: <String, String>{'a.dart': 'This is a'}), throwsA(anything));
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('populates fingerprint for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        final Fingerprint checksum = new Fingerprint.fromInputs(filePaths: <String>['a.dart', 'b.dart'].toSet());
        final String json = checksum.toJson();
        expect(json, '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      test('populates fingerprint for properties', () {
        final Fingerprint checksum = new Fingerprint.fromInputs(properties: <String, String>{'a': 'This is a', 'b': 'This is b'});
        final String json = checksum.toJson();
        expect(json, '{"a":"This is a","b":"This is b"}');
      });

      testUsingContext('populates fingerprint for valid files and properties', () async {
        await fs.file('a.dart').writeAsString('This is a');
        final Fingerprint checksum = new Fingerprint.fromInputs(filePaths: <String>['a.dart'].toSet(), properties: <String, String>{'b': 'This is b'});
        final String json = checksum.toJson();
        expect(json, '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b":"This is b"}');
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

    });

    group('fromJson', () {
      test('throws if JSON is invalid', () async {
        expect(() => new Fingerprint.fromJson('<xml></xml>'), throwsA(anything));
      });

      test('populates fingerprint for valid JSON', () async {
        final String json = '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}';
        final Fingerprint checksum = new Fingerprint.fromJson(json);
        expect(checksum.toJson(), '{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
      });
    });

    group('operator ==', () {
      test('reports not equal if values do not match', () async {
        final Fingerprint a = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Fingerprint b = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07d"}');
        expect(a == b, isFalse);
      });

      test('reports not equal if keys do not match', () async {
        final Fingerprint a = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Fingerprint b = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","c.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        expect(a == b, isFalse);
      });

      test('reports equal if all fingerprints match', () async {
        final Fingerprint a = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Fingerprint b = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        expect(a == b, isTrue);
      });
    });

    group('hashcode', () {
      test('equal instances have equal hashcode', () {
        final Fingerprint a = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        final Fingerprint b = new Fingerprint.fromJson('{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}');
        expect(a.hashCode == b.hashCode, isTrue);
      });
    });
  });
}
