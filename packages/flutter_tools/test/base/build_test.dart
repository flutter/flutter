// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:convert' show json;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockArtifacts extends Mock implements Artifacts {}

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

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['files'], hasLength(2));
        expect(jsonObject['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(jsonObject['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('includes framework version', () {
        final Fingerprint fingerprint = new Fingerprint.fromBuildInputs(<String, String>{}, <String>[]);

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['version'], mockVersion.frameworkRevision);
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });

      testUsingContext('includes provided properties', () {
        final Fingerprint fingerprint = new Fingerprint.fromBuildInputs(<String, String>{'a': 'A', 'b': 'B'}, <String>[]);

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['properties'], hasLength(2));
        expect(jsonObject['properties']['a'], 'A');
        expect(jsonObject['properties']['b'], 'B');
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });
    });

    group('fromJson', () {
      testUsingContext('throws if JSON is invalid', () async {
        expect(() => new Fingerprint.fromJson('<xml></xml>'), throwsA(anything));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('creates fingerprint from valid JSON', () async {
        final String jsonString = json.encode(<String, dynamic>{
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
        final Fingerprint fingerprint = new Fingerprint.fromJson(jsonString);
        final Map<String, dynamic> content = json.decode(fingerprint.toJson());
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
        final String jsonString = json.encode(<String, dynamic>{
          'version': 'bad',
          'properties':<String, String>{},
          'files':<String, String>{},
        });
        expect(() => new Fingerprint.fromJson(jsonString), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError if version is not present', () async {
        final String jsonString = json.encode(<String, dynamic>{
          'properties':<String, String>{},
          'files':<String, String>{},
        });
        expect(() => new Fingerprint.fromJson(jsonString), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('treats missing properties and files entries as if empty', () async {
        final String jsonString = json.encode(<String, dynamic>{
          'version': kVersion,
        });
        expect(new Fingerprint.fromJson(jsonString), new Fingerprint.fromBuildInputs(<String, String>{}, <String>[]));
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
        expect(new Fingerprint.fromJson(json.encode(a)) == new Fingerprint.fromJson(json.encode(b)), isFalse);
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
        expect(new Fingerprint.fromJson(json.encode(a)) == new Fingerprint.fromJson(json.encode(b)), isFalse);
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
        expect(new Fingerprint.fromJson(json.encode(a)) == new Fingerprint.fromJson(json.encode(b)), isFalse);
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
        expect(new Fingerprint.fromJson(json.encode(a)) == new Fingerprint.fromJson(json.encode(a)), isTrue);
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

    final Map<Type, Generator> contextOverrides = <Type, Generator>{ FileSystem: () => fs };

    testUsingContext('returns one file if only one is listed', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>['/foo/a.dart']));
    }, overrides: contextOverrides);

    testUsingContext('returns multiple files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart /foo/b.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
      ]));
    }, overrides: contextOverrides);

    testUsingContext('trims extra spaces between files', () async {
      await fs.file('a.d').writeAsString('snapshot.d: /foo/a.dart    /foo/b.dart  /foo/c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
        '/foo/c.dart',
      ]));
    }, overrides: contextOverrides);

    testUsingContext('returns files with spaces and backslashes', () async {
      await fs.file('a.d').writeAsString(r'snapshot.d: /foo/a\ a.dart /foo/b\\b.dart /foo/c\\ c.dart');
      expect(await readDepfile('a.d'), unorderedEquals(<String>[
        r'/foo/a a.dart',
        r'/foo/b\b.dart',
        r'/foo/c\ c.dart',
      ]));
    }, overrides: contextOverrides);
  });

  group('Snapshotter', () {
    const String kVersion = '123456abcdef';
    const String kIsolateSnapshotData = 'isolate_snapshot.bin';
    const String kVmSnapshotData = 'vm_isolate_snapshot.bin';

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    MockFlutterVersion mockVersion;
    Snapshotter snapshotter;
    MockArtifacts mockArtifacts;

    setUp(() {
      fs = new MemoryFileSystem();
      fs.file(kIsolateSnapshotData).writeAsStringSync('snapshot data');
      fs.file(kVmSnapshotData).writeAsStringSync('vm data');
      genSnapshot = new _FakeGenSnapshot();
      mockVersion = new MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
      snapshotter = new Snapshotter();
      mockArtifacts = new MockArtifacts();
      when(mockArtifacts.getArtifactPath(Artifact.isolateSnapshotData)).thenReturn(kIsolateSnapshotData);
      when(mockArtifacts.getArtifactPath(Artifact.vmSnapshotData)).thenReturn(kVmSnapshotData);
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      Artifacts: () => mockArtifacts,
      FileSystem: () => fs,
      FlutterVersion: () => mockVersion,
      GenSnapshot: () => genSnapshot,
    };

    Future<Null> writeFingerprint({ Map<String, String> files = const <String, String>{} }) {
      return fs.file('output.snapshot.d.fingerprint').writeAsString(json.encode(<String, dynamic>{
        'version': kVersion,
        'properties': <String, String>{
          'buildMode': BuildMode.debug.toString(),
          'targetPlatform': '',
          'entryPoint': 'main.dart',
        },
        'files': <String, dynamic>{
          kVmSnapshotData: '2ec34912477a46c03ddef07e8b909b46',
          kIsolateSnapshotData: '621b3844bb7d4d17d2cfc5edf9a91c4c',
        }..addAll(files),
      }));
    }

    Future<Null> buildSnapshot({ String mainPath = 'main.dart' }) {
      return snapshotter.buildScriptSnapshot(
        mainPath: mainPath,
        snapshotPath: 'output.snapshot',
        depfilePath: 'output.snapshot.d',
        packagesPath: '.packages',
      );
    }

    void expectFingerprintHas({
      String entryPoint: 'main.dart',
      Map<String, String> checksums = const <String, String>{},
    }) {
      final Map<String, dynamic> jsonObject = json.decode(fs.file('output.snapshot.d.fingerprint').readAsStringSync());
      expect(jsonObject['properties']['entryPoint'], entryPoint);
      expect(jsonObject['files'], hasLength(checksums.length + 2));
      checksums.forEach((String path, String checksum) {
        expect(jsonObject['files'][path], checksum);
      });
      expect(jsonObject['files'][kVmSnapshotData], '2ec34912477a46c03ddef07e8b909b46');
      expect(jsonObject['files'][kIsolateSnapshotData], '621b3844bb7d4d17d2cfc5edf9a91c4c');
    }

    testUsingContext('builds snapshot and fingerprint when no fingerprint is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('snapshot : main.dart');
      await buildSnapshot();

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    testUsingContext('builds snapshot and fingerprint when fingerprints differ', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'deadbeef000b204e9800998ecaaaaa',
      });
      await buildSnapshot();

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    testUsingContext('builds snapshot and fingerprint when fingerprints match but previous snapshot not present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      await buildSnapshot();

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

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
      await writeFingerprint(files: <String, String>{
        'main.dart': 'bc096b33f14dde5e0ffaf93a1d03395c',
        'other.dart': 'e0c35f083f0ad76b2d87100ec678b516',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      await buildSnapshot(mainPath: 'other.dart');

      expect(genSnapshot.callCount, 1);
      expectFingerprintHas(
        entryPoint: 'other.dart',
        checksums: <String, String>{
          'main.dart': 'bc096b33f14dde5e0ffaf93a1d03395c',
          'other.dart': 'e0c35f083f0ad76b2d87100ec678b516',
          'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
        },
      );
    }, overrides: contextOverrides);

    testUsingContext('skips snapshot when fingerprints match and previous snapshot is present', () async {
      await fs.file('main.dart').writeAsString('void main() {}');
      await fs.file('output.snapshot').create();
      await fs.file('output.snapshot.d').writeAsString('output.snapshot : main.dart');
      await writeFingerprint(files: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      await buildSnapshot();

      expect(genSnapshot.callCount, 0);
      expectFingerprintHas(checksums: <String, String>{
        'main.dart': '27f5ebf0f8c559b2af9419d190299a5e',
        'output.snapshot': 'd41d8cd98f00b204e9800998ecf8427e',
      });
    }, overrides: contextOverrides);

    group('createFingerprint', () {
      final Map<Type, Generator> contextOverrides = <Type, Generator>{
        FileSystem: () => fs,
        Artifacts: () => mockArtifacts,
      };
      final List<String> artifactPaths = <String>[
        kVmSnapshotData,
        kIsolateSnapshotData,
      ];
      testUsingContext('creates fingerprint with target platform', () {
        final Fingerprint fingerprint = Snapshotter.createFingerprint(
          new SnapshotType(TargetPlatform.android_x64, BuildMode.release),
          'a.dart',
          <String>[],
        );
        expect(fingerprint, new Fingerprint.fromBuildInputs(<String, String>{
          'buildMode': 'BuildMode.release',
          'targetPlatform': 'TargetPlatform.android_x64',
          'entryPoint': 'a.dart',
        }, artifactPaths));
      }, overrides: contextOverrides);
      testUsingContext('creates fingerprint without target platform', () {
        final Fingerprint fingerprint = Snapshotter.createFingerprint(
          new SnapshotType(null, BuildMode.release),
          'a.dart',
          <String>[],
        );
        expect(fingerprint, new Fingerprint.fromBuildInputs(<String, String>{
          'buildMode': 'BuildMode.release',
          'targetPlatform': '',
          'entryPoint': 'a.dart',
        }, artifactPaths));
      }, overrides: contextOverrides);
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
        }, <String>[
          'a.dart',
          'b.dart',
        ]..addAll(artifactPaths)));
      }, overrides: contextOverrides);
    });
  });
}
