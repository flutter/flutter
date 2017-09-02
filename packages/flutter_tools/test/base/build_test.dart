// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:convert' show JSON;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockFlutterVersion extends Mock implements FlutterVersion {}

class _FakeGenSnapshot implements GenSnapshot {
  _FakeGenSnapshot({
    this.succeed: true,
    this.snapshotPath: 'output.snapshot',
    this.snapshotContent: '',
    this.depfilePath: 'output.snapshot.d',
    this.depfileContent: 'output.snapshot.d : main.dart',
  });

  final bool succeed;
  final String snapshotPath;
  final String snapshotContent;
  final String depfilePath;
  final String depfileContent;
  int _callCount = 0;

  int get callCount => _callCount;

  @override
  Future<int> run({
    SnapshotType snapshotType,
    String packagesPath,
    String depfilePath,
    Iterable<String> additionalArgs,
  }) async {
    _callCount += 1;

    if (!succeed)
      return 1;
    await fs.file(snapshotPath).writeAsString(snapshotContent);
    await fs.file(depfilePath).writeAsString(depfileContent);
    return 0;
  }
}

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
        const SnapshotType snapshotType = const SnapshotType(TargetPlatform.ios, BuildMode.debug);
        expect(
          () => new Checksum.fromFiles(snapshotType, <String>['a.dart', 'b.dart'].toSet()),
          throwsA(anything),
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('throws if any build mode is null', () async {
        await fs.file('a.dart').create();
        const SnapshotType snapshotType = const SnapshotType(TargetPlatform.ios, null);
        expect(
          () => new Checksum.fromFiles(snapshotType, <String>['a.dart', 'b.dart'].toSet()),
          throwsA(anything),
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('does not throw if any target platform is null', () async {
        await fs.file('a.dart').create();
        const SnapshotType snapshotType = const SnapshotType(null, BuildMode.debug);
        expect(
          new Checksum.fromFiles(snapshotType, <String>['a.dart'].toSet()),
          isNotNull,
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('populates checksums for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        const SnapshotType snapshotType = const SnapshotType(TargetPlatform.ios, BuildMode.debug);
        final Checksum checksum = new Checksum.fromFiles(snapshotType, <String>['a.dart', 'b.dart'].toSet());

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
        final String json = JSON.encode(<String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.release.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        });
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
        final String json = JSON.encode(<String, dynamic>{
          'version': 'bad',
          'buildMode': BuildMode.release.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        });
        expect(() => new Checksum.fromJson(json), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });

    group('operator ==', () {
      testUsingContext('reports not equal if build modes do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = new Map<String, dynamic>.from(a);
        b['buildMode'] = BuildMode.release.toString();
        expect(new Checksum.fromJson(JSON.encode(a)) == new Checksum.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if target platforms do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = new Map<String, dynamic>.from(a);
        b['targetPlatform'] = TargetPlatform.android_arm.toString();
        expect(new Checksum.fromJson(JSON.encode(a)) == new Checksum.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if checksums do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = new Map<String, dynamic>.from(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'b.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(new Checksum.fromJson(JSON.encode(a)) == new Checksum.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if keys do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = new Map<String, dynamic>.from(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'c.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(new Checksum.fromJson(JSON.encode(a)) == new Checksum.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports equal if all checksums match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': TargetPlatform.ios.toString(),
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        expect(new Checksum.fromJson(JSON.encode(a)) == new Checksum.fromJson(JSON.encode(a)), isTrue);
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
    }, overrides: <Type, Generator>{ FileSystem: () => fs });

    testUsingContext('returns multiple files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart /foo/b.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs });

    testUsingContext('trims extra spaces between files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart    /foo/b.dart  /foo/c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
        '/foo/c.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs });

    testUsingContext('returns files with spaces and backslashes', () async {
      await fs.file('a.d').writeAsString(r'snapshot.d: /foo/a\ a.dart /foo/b\\b.dart /foo/c\\ c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        r'/foo/a a.dart',
        r'/foo/b\b.dart',
        r'/foo/c\ c.dart',
      ]));
    }, overrides: <Type, Generator>{ FileSystem: () => fs });
  });

  group('Snapshotter', () {
    const String kVersion = '123456abcdef';

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    MockFlutterVersion mockVersion;
    Snapshotter snapshotter;

    setUp(() {
      fs = new MemoryFileSystem();
      genSnapshot = new _FakeGenSnapshot();
      mockVersion = new MockFlutterVersion();
      snapshotter = new Snapshotter();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    testUsingContext('builds snapshot and checksums when no checksums are present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('snapshot : main.dart');
      await snapshotter.buildScriptSnapshot(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.checksums').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });

    testUsingContext('builds snapshot and checksums when checksums differ', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.checksums').writeAsString(JSON.encode(<String, dynamic>{
        'version': '$kVersion',
        'buildMode': BuildMode.debug.toString(),
        'files': <String, dynamic>{
          'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
          'output.snapshot': 'deadbeef01234567890abcdef0123456',
        },
      }));
      await snapshotter.buildScriptSnapshot(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.checksums').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });

    testUsingContext('builds snapshot and checksums when checksums match but previous snapshot not present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.checksums').writeAsString(JSON.encode(<String, dynamic>{
        'version': '$kVersion',
        'buildMode': BuildMode.debug.toString(),
        'files': <String, dynamic>{
          'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
          'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
        },
      }));
      await snapshotter.buildScriptSnapshot(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.checksums').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });

    testUsingContext('builds snapshot and checksums when main entry point changes', () async {
      final _FakeGenSnapshot genSnapshot = new _FakeGenSnapshot(
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        depfileContent: 'output.snapshot : other.dart',
      );
      context.setVariable(GenSnapshot, genSnapshot);

      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('other.dart').writeAsString('void main() { print("Kanpai ima kimi wa jinsei no ookina ookina butai ni tachi"); }');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.checksums').writeAsString(JSON.encode(<String, dynamic>{
        'version': '$kVersion',
        'buildMode': BuildMode.debug.toString(),
        'targetPlatform': '',
        'files': <String, dynamic>{
          'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
          'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
        },
      }));
      await snapshotter.buildScriptSnapshot(
        mainPath: 'other.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 1);
      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.checksums').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['other.dart'], '3238d0ae341339b1731d3c2e195ad177');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('skips snapshot when checksums match and previous snapshot is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.checksums').writeAsString(JSON.encode(<String, dynamic>{
        'version': '$kVersion',
        'buildMode': BuildMode.debug.toString(),
        'targetPlatform': '',
        'files': <String, dynamic>{
          'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
          'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
        },
      }));
      await snapshotter.buildScriptSnapshot(
        mainPath: 'main.dart',
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );

      expect(genSnapshot.callCount, 0);

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.checksums').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });
  });
}
