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
    this.depfileContent: 'output.snapshot.d : main.dart',
  });

  final bool succeed;
  final String snapshotPath;
  final String snapshotContent;
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
  group('SnapshotType', () {
    test('throws, if build mode is null', () {
      expect(
        () => new SnapshotType(TargetPlatform.android_x64, null),
        throwsA(anything),
      );
    });
    test('does not throw, if target platform is null', () {
      expect(new SnapshotType(null, BuildMode.release), isNotNull);
    });
  });
  group('Fingerprint', () {
    MockFlutterVersion mockVersion;
    const String kVersion = '123456abcdef';

    setUp(() {
      mockVersion = new MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    group('fromBuildInputs', () {
      MemoryFileSystem fs;

      setUp(() {
        fs = new MemoryFileSystem();
      });

      testUsingContext('throws if any input file does not exist', () async {
        await fs.file('a.dart').create();
        expect(
          () => new Fingerprint.fromBuildInputs(<String, String>{}, <String>['a.dart', 'b.dart']),
          throwsArgumentError,
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('populates checksums for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        final Fingerprint fingerprint = new Fingerprint.fromBuildInputs(<String, String>{}, <String>['a.dart', 'b.dart']);

        final Map<String, dynamic> json = JSON.decode(fingerprint.toJson());
        expect(json['files'], hasLength(2));
        expect(json['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(json['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('includes framework version', () {
        final Fingerprint fingerprint = new Fingerprint.fromBuildInputs(<String, String>{}, <String>[]);

        final Map<String, dynamic> json = JSON.decode(fingerprint.toJson());
        expect(json['version'], mockVersion.frameworkRevision);
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });

      testUsingContext('includes provided properties', () {
        final Fingerprint fingerprint = new Fingerprint.fromBuildInputs(<String, String>{'a': 'A', 'b': 'B'}, <String>[]);

        final Map<String, dynamic> json = JSON.decode(fingerprint.toJson());
        expect(json['properties'], hasLength(2));
        expect(json['properties']['a'], 'A');
        expect(json['properties']['b'], 'B');
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });
    });

    group('fromJson', () {
      testUsingContext('throws if JSON is invalid', () async {
        expect(() => new Fingerprint.fromJson('<xml></xml>'), throwsA(anything));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('creates fingerprint from valid JSON', () async {
        final String json = JSON.encode(<String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{
            'buildMode': BuildMode.release.toString(),
            'targetPlatform': TargetPlatform.ios.toString(),
            'entryPoint': 'a.dart',
          },
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        });
        final Fingerprint fingerprint = new Fingerprint.fromJson(json);
        final Map<String, dynamic> content = JSON.decode(fingerprint.toJson());
        expect(content, hasLength(3));
        expect(content['version'], mockVersion.frameworkRevision);
        expect(content['properties'], hasLength(3));
        expect(content['properties']['buildMode'], BuildMode.release.toString());
        expect(content['properties']['targetPlatform'], TargetPlatform.ios.toString());
        expect(content['properties']['entryPoint'], 'a.dart');
        expect(content['files'], hasLength(2));
        expect(content['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(content['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError for unknown versions', () async {
        final String json = JSON.encode(<String, dynamic>{
          'version': 'bad',
          'properties':<String, String>{},
          'files':<String, String>{},
        });
        expect(() => new Fingerprint.fromJson(json), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError if version is not present', () async {
        final String json = JSON.encode(<String, dynamic>{
          'properties':<String, String>{},
          'files':<String, String>{},
        });
        expect(() => new Fingerprint.fromJson(json), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('treats missing properties and files entries as if empty', () async {
        final String json = JSON.encode(<String, dynamic>{
          'version': kVersion,
        });
        expect(new Fingerprint.fromJson(json), new Fingerprint.fromBuildInputs(<String, String>{}, <String>[]));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });

    group('operator ==', () {
      testUsingContext('reports not equal if properties do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{
            'buildMode': BuildMode.debug.toString(),
          },
          'files': <String, dynamic>{},
        };
        final Map<String, dynamic> b = new Map<String, dynamic>.from(a);
        b['properties'] = <String, String>{
          'buildMode': BuildMode.release.toString(),
        };
        expect(new Fingerprint.fromJson(JSON.encode(a)) == new Fingerprint.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if file checksums do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{},
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
        expect(new Fingerprint.fromJson(JSON.encode(a)) == new Fingerprint.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if file paths do not match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{},
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
        expect(new Fingerprint.fromJson(JSON.encode(a)) == new Fingerprint.fromJson(JSON.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports equal if properties and file checksums match', () async {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{
            'buildMode': BuildMode.debug.toString(),
            'targetPlatform': TargetPlatform.ios.toString(),
            'entryPoint': 'a.dart',
          },
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        expect(new Fingerprint.fromJson(JSON.encode(a)) == new Fingerprint.fromJson(JSON.encode(a)), isTrue);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });
    group('hashCode', () {
      testUsingContext('is consistent with equals, even if map entries are reordered', () async {
        final Fingerprint a = new Fingerprint.fromJson('{"version":"$kVersion","properties":{"a":"A","b":"B"},"files":{}}');
        final Fingerprint b = new Fingerprint.fromJson('{"version":"$kVersion","properties":{"b":"B","a":"A"},"files":{}}');
        expect(a, b);
        expect(a.hashCode, b.hashCode);
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

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.fingerprint').readAsString());
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
      await fs.file('output.snapshot.d.fingerprint').writeAsString(JSON.encode(<String, dynamic>{
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

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.fingerprint').readAsString());
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
      await fs.file('output.snapshot.d.fingerprint').writeAsString(JSON.encode(<String, dynamic>{
        'version': '$kVersion',
        'properties': <String, String>{
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': '',
          'entryPoint': 'main.dart',
        },
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

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.fingerprint').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });

    testUsingContext('builds snapshot and fingerprint when main entry point changes to other dependency', () async {
      final _FakeGenSnapshot genSnapshot = new _FakeGenSnapshot(
        snapshotPath: 'output.snapshot',
        depfileContent: 'output.snapshot : main.dart other.dart',
      );
      context.setVariable(GenSnapshot, genSnapshot);

      await fs.file('main.dart').writeAsString('import "other.dart";\nvoid main() {}');
      await fs.file('other.dart').writeAsString('import "main.dart";\nvoid main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.fingerprint').writeAsString(JSON.encode(<String, dynamic>{
        'version': kVersion,
        'properties': <String, String>{
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': '',
          'entryPoint': 'main.dart',
        },
        'files': <String, dynamic>{
          'main.dart': 'bc096b33f14dde5e0ffaf93a1d03395c',
          'other.dart': 'e0c35f083f0ad76b2d87100ec678b516',
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
      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.fingerprint').readAsString());
      expect(json['properties']['entryPoint'], 'other.dart');
      expect(json['files'], hasLength(3));
      expect(json['files']['main.dart'], 'bc096b33f14dde5e0ffaf93a1d03395c');
      expect(json['files']['other.dart'], 'e0c35f083f0ad76b2d87100ec678b516');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('skips snapshot when fingerprints match and previous snapshot is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await fs.file('output.snapshot.d.fingerprint').writeAsString(JSON.encode(<String, dynamic>{
        'version': kVersion,
        'properties': <String, String>{
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': '',
          'entryPoint': 'main.dart',
        },
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

      final Map<String, dynamic> json = JSON.decode(await fs.file('output.snapshot.d.fingerprint').readAsString());
      expect(json['files'], hasLength(2));
      expect(json['files']['main.dart'], '27f5ebf0f8c559b2af9419d190299a5e');
      expect(json['files']['output.snapshot'], 'd41d8cd98f00b204e9800998ecf8427e');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    });

    group('createFingerprint', () {
      test('creates fingerprint with target platform', () {
        final Fingerprint fingerprint = Snapshotter.createFingerprint(
          new SnapshotType(TargetPlatform.android_x64, BuildMode.release),
          'a.dart',
          <String>[],
        );
        expect(fingerprint, new Fingerprint.fromBuildInputs(<String, String>{
          'buildMode': 'BuildMode.release',
          'targetPlatform': 'TargetPlatform.android_x64',
          'entryPoint': 'a.dart',
        }, <String>[]));
      });
      test('creates fingerprint without target platform', () {
        final Fingerprint fingerprint = Snapshotter.createFingerprint(
          new SnapshotType(null, BuildMode.release),
          'a.dart',
          <String>[],
        );
        expect(fingerprint, new Fingerprint.fromBuildInputs(<String, String>{
          'buildMode': 'BuildMode.release',
          'targetPlatform': '',
          'entryPoint': 'a.dart',
        }, <String>[]));
      });
      testUsingContext('creates fingerprint with file checksums', () async {
        await fs.file('a.dart').create();
        await fs.file('b.dart').create();
        final Fingerprint fingerprint = Snapshotter.createFingerprint(
          new SnapshotType(TargetPlatform.android_x64, BuildMode.release),
          'a.dart',
          <String>['a.dart', 'b.dart'],
        );
        expect(fingerprint, new Fingerprint.fromBuildInputs(<String, String>{
          'buildMode': 'BuildMode.release',
          'targetPlatform': 'TargetPlatform.android_x64',
          'entryPoint': 'a.dart',
        }, <String>['a.dart', 'b.dart']));
      }, overrides: <Type, Generator>{ FileSystem: () => fs });
    });
  });
}
