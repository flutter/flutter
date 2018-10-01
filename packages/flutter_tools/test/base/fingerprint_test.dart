// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/fingerprint.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Fingerprinter', () {
    const String kVersion = '123456abcdef';

    MemoryFileSystem fs;
    MockFlutterVersion mockVersion;

    setUp(() {
      fs = MemoryFileSystem();
      mockVersion = MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      FileSystem: () => fs,
    };

    testUsingContext('throws when depfile is malformed', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();
      await fs.file('depfile').create();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(() async => await fingerprinter.buildFingerprint(), throwsA(anything));
    }, overrides: contextOverrides);

    testUsingContext('creates fingerprint with specified properties and files', () async {
      await fs.file('a.dart').create();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        properties: <String, String>{
          'foo': 'bar',
          'wibble': 'wobble',
        },
      );
      final Fingerprint fingerprint = await fingerprinter.buildFingerprint();
      expect(fingerprint, Fingerprint.fromBuildInputs(<String, String>{
        'foo': 'bar',
        'wibble': 'wobble',
      }, <String>['a.dart']));
    }, overrides: contextOverrides);

    testUsingContext('creates fingerprint with file checksums', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();
      await fs.file('depfile').writeAsString('depfile : b.dart');

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      final Fingerprint fingerprint = await fingerprinter.buildFingerprint();
      expect(fingerprint, Fingerprint.fromBuildInputs(<String, String>{
        'bar': 'baz',
        'wobble': 'womble',
      }, <String>['a.dart', 'b.dart']));
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if not present', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(await fingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does match if different', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();

      final Fingerprinter fingerprinter1 = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      await fingerprinter1.writeFingerprint();

      final Fingerprinter fingerprinter2 = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'elbmow',
        },
      );
      expect(await fingerprinter2.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if depfile is malformed', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();
      await fs.file('depfile').writeAsString('depfile : b.dart');

      // Write a valid fingerprint
      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      await fingerprinter.writeFingerprint();

      // Write a corrupt depfile.
      await fs.file('depfile').writeAsString('');
      final Fingerprinter badFingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );

      expect(await badFingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if previous fingerprint is malformed', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();
      await fs.file('out.fingerprint').writeAsString('** not JSON **');

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(await fingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does match if identical', () async {
      await fs.file('a.dart').create();
      await fs.file('b.dart').create();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      await fingerprinter.writeFingerprint();
      expect(await fingerprinter.doesFingerprintMatch(), isTrue);
    }, overrides: contextOverrides);

    testUsingContext('fails to write fingerprint if inputs are missing', () async {
      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        properties: <String, String>{
          'foo': 'bar',
          'wibble': 'wobble',
        },
      );
      await fingerprinter.writeFingerprint();
      expect(fs.file('out.fingerprint').existsSync(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('applies path filter to inputs paths', () async {
      await fs.file('a.dart').create();
      await fs.file('ab.dart').create();
      await fs.file('depfile').writeAsString('depfile : ab.dart c.dart');

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'foo': 'bar',
          'wibble': 'wobble',
        },
        pathFilter: (String path) => path.startsWith('a'),
      );
      await fingerprinter.writeFingerprint();
      expect(fs.file('out.fingerprint').existsSync(), isTrue);
    }, overrides: contextOverrides);
  });

  group('Fingerprint', () {
    MockFlutterVersion mockVersion;
    const String kVersion = '123456abcdef';

    setUp(() {
      mockVersion = MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    group('fromBuildInputs', () {
      MemoryFileSystem fs;

      setUp(() {
        fs = MemoryFileSystem();
      });

      testUsingContext('throws if any input file does not exist', () async {
        await fs.file('a.dart').create();
        expect(
          () => Fingerprint.fromBuildInputs(<String, String>{}, <String>['a.dart', 'b.dart']),
          throwsArgumentError,
        );
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('populates checksums for valid files', () async {
        await fs.file('a.dart').writeAsString('This is a');
        await fs.file('b.dart').writeAsString('This is b');
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(<String, String>{}, <String>['a.dart', 'b.dart']);

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['files'], hasLength(2));
        expect(jsonObject['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(jsonObject['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{ FileSystem: () => fs });

      testUsingContext('includes framework version', () {
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(<String, String>{}, <String>[]);

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['version'], mockVersion.frameworkRevision);
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });

      testUsingContext('includes provided properties', () {
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(<String, String>{'a': 'A', 'b': 'B'}, <String>[]);

        final Map<String, dynamic> jsonObject = json.decode(fingerprint.toJson());
        expect(jsonObject['properties'], hasLength(2));
        expect(jsonObject['properties']['a'], 'A');
        expect(jsonObject['properties']['b'], 'B');
      }, overrides: <Type, Generator>{ FlutterVersion: () => mockVersion });
    });

    group('fromJson', () {
      testUsingContext('throws if JSON is invalid', () async {
        expect(() => Fingerprint.fromJson('<xml></xml>'), throwsA(anything));
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
        final Fingerprint fingerprint = Fingerprint.fromJson(jsonString);
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
        expect(() => Fingerprint.fromJson(jsonString), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError if version is not present', () async {
        final String jsonString = json.encode(<String, dynamic>{
          'properties':<String, String>{},
          'files':<String, String>{},
        });
        expect(() => Fingerprint.fromJson(jsonString), throwsArgumentError);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('treats missing properties and files entries as if empty', () async {
        final String jsonString = json.encode(<String, dynamic>{
          'version': kVersion,
        });
        expect(Fingerprint.fromJson(jsonString), Fingerprint.fromBuildInputs(<String, String>{}, <String>[]));
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
        final Map<String, dynamic> b = Map<String, dynamic>.from(a);
        b['properties'] = <String, String>{
          'buildMode': BuildMode.release.toString(),
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
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
        final Map<String, dynamic> b = Map<String, dynamic>.from(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'b.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
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
        final Map<String, dynamic> b = Map<String, dynamic>.from(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'c.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
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
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(a)), isTrue);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });
    group('hashCode', () {
      testUsingContext('is consistent with equals, even if map entries are reordered', () async {
        final Fingerprint a = Fingerprint.fromJson('{"version":"$kVersion","properties":{"a":"A","b":"B"},"files":{}}');
        final Fingerprint b = Fingerprint.fromJson('{"version":"$kVersion","properties":{"b":"B","a":"A"},"files":{}}');
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
      fs = MemoryFileSystem();
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
}
