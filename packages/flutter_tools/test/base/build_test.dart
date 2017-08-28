// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockFlutterVersion extends Mock implements FlutterVersion {}

void main() {
  group('Checksum', () {
    MockFlutterVersion mockVersion;
    const String kVersion = '123456abcdef';

    setUp(() {
      mockVersion = new MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    group('fromFiles', () {
      MemoryFileSystem fs;

      setUp(() {
        fs = new MemoryFileSystem();
      });

      testUsingContext('throws if any input file does not exist', () async {
        await fs.file('a.dart').create();
        expect(
          () => new Checksum.fromFiles(BuildMode.debug, TargetPlatform.ios, <String>['a.dart', 'b.dart'].toSet()),
          throwsA(anything),
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('throws if any build mode is null', () async {
        await fs.file('a.dart').create();
        expect(
          () => new Checksum.fromFiles(null, TargetPlatform.ios, <String>['a.dart', 'b.dart'].toSet()),
          throwsA(anything),
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('does not throw if any target platform is null', () async {
        await fs.file('a.dart').create();
        expect(
          new Checksum.fromFiles(BuildMode.debug, null, <String>['a.dart'].toSet()),
          isNotNull,
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs});

      testUsingContext('populates checksums for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        final Checksum checksum = new Checksum.fromFiles(BuildMode.debug, TargetPlatform.ios, <String>['a.dart', 'b.dart'].toSet());

        final Map<String, dynamic> json = JSON.decode(checksum.toJson());
        expect(json, hasLength(4));
        expect(json['version'], mockVersion.frameworkRevision);
        expect(json['buildMode'], BuildMode.debug.toString());
        expect(json['targetPlatform'], TargetPlatform.ios.toString());
        expect(json['files'], hasLength(2));
        expect(json['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(json['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        FlutterVersion: () => mockVersion,
      });
    });

    group('fromJson', () {
      testUsingContext('throws if JSON is invalid', () async {
        expect(() => new Checksum.fromJson('<xml></xml>'), throwsA(anything));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('populates checksums for valid JSON', () async {
        final String json = '{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}';
        final Checksum checksum = new Checksum.fromJson(json);

        final Map<String, dynamic> content = JSON.decode(checksum.toJson());
        expect(content, hasLength(4));
        expect(content['version'], mockVersion.frameworkRevision);
        expect(content['buildMode'], BuildMode.release.toString());
        expect(content['targetPlatform'], TargetPlatform.ios.toString());
        expect(content['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(content['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError for unknown versions', () async {
        final String json = '{"version":"bad","buildMode":"BuildMode.release","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}';
        expect(() => new Checksum.fromJson(json), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });

    group('operator ==', () {
      testUsingContext('reports not equal if build modes do not match', () async {
        final Checksum a = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.debug","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        final Checksum b = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        expect(a == b, isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if target platforms do not match', () async {
        final Checksum a = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        final Checksum b = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.fuchsia","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        expect(a == b, isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if checksums do not match', () async {
        final Checksum a = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        final Checksum b = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07d"}}');
        expect(a == b, isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if keys do not match', () async {
        final Checksum a = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        final Checksum b = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","c.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        expect(a == b, isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports equal if all checksums match', () async {
        final Checksum a = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        final Checksum b = new Checksum.fromJson('{"version":"$kVersion","buildMode":"BuildMode.release","targetPlatform":"TargetPlatform.ios","files":{"a.dart":"8a21a15fad560b799f6731d436c1b698","b.dart":"6f144e08b58cd0925328610fad7ac07c"}}');
        expect(a == b, isTrue);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
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
