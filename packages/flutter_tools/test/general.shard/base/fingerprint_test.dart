// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/fingerprint.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('Fingerprinter', () {
    const String kVersion = '123456abcdef';

    MemoryFileSystem fileSystem;
    MockFlutterVersion mockVersion;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      mockVersion = MockFlutterVersion();
      when(mockVersion.frameworkRevision).thenReturn(kVersion);
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    };

    testUsingContext('throws when depfile is malformed', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();
      fileSystem.file('depfile').createSync();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(fingerprinter.buildFingerprint, throwsA(anything));
    }, overrides: contextOverrides);

    testUsingContext('creates fingerprint with specified properties and files', () {
      fileSystem.file('a.dart').createSync();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        properties: <String, String>{
          'foo': 'bar',
          'wibble': 'wobble',
        },
      );
      final Fingerprint fingerprint = fingerprinter.buildFingerprint();
      expect(fingerprint, Fingerprint.fromBuildInputs(const <String, String>{
        'foo': 'bar',
        'wibble': 'wobble',
      }, const <String>['a.dart']));
    }, overrides: contextOverrides);

    testUsingContext('creates fingerprint with file checksums', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();
      fileSystem.file('depfile').writeAsStringSync('depfile : b.dart');

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      final Fingerprint fingerprint = fingerprinter.buildFingerprint();
      expect(fingerprint, Fingerprint.fromBuildInputs(const <String, String>{
        'bar': 'baz',
        'wobble': 'womble',
      }, const <String>['a.dart', 'b.dart']));
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if not present', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(fingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does match if different', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();

      final Fingerprinter fingerprinter1 = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      fingerprinter1.writeFingerprint();

      final Fingerprinter fingerprinter2 = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'elbmow',
        },
      );
      expect(fingerprinter2.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if depfile is malformed', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();
      fileSystem.file('depfile').writeAsStringSync('depfile : b.dart');

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
      fingerprinter.writeFingerprint();

      // Write a corrupt depfile.
      fileSystem.file('depfile').writeAsStringSync('');
      final Fingerprinter badFingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );

      expect(badFingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does not match if previous fingerprint is malformed', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();
      fileSystem.file('out.fingerprint').writeAsStringSync('** not JSON **');

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        depfilePaths: <String>['depfile'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      expect(fingerprinter.doesFingerprintMatch(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('fingerprint does match if identical', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('b.dart').createSync();

      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart', 'b.dart'],
        properties: <String, String>{
          'bar': 'baz',
          'wobble': 'womble',
        },
      );
      fingerprinter.writeFingerprint();
      expect(fingerprinter.doesFingerprintMatch(), isTrue);
    }, overrides: contextOverrides);

    testUsingContext('fails to write fingerprint if inputs are missing', () {
      final Fingerprinter fingerprinter = Fingerprinter(
        fingerprintPath: 'out.fingerprint',
        paths: <String>['a.dart'],
        properties: <String, String>{
          'foo': 'bar',
          'wibble': 'wobble',
        },
      );
      fingerprinter.writeFingerprint();
      expect(fileSystem.file('out.fingerprint').existsSync(), isFalse);
    }, overrides: contextOverrides);

    testUsingContext('applies path filter to inputs paths', () {
      fileSystem.file('a.dart').createSync();
      fileSystem.file('ab.dart').createSync();
      fileSystem.file('depfile').writeAsStringSync('depfile : ab.dart c.dart');

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
      fingerprinter.writeFingerprint();
      expect(fileSystem.file('out.fingerprint').existsSync(), isTrue);
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
      MemoryFileSystem fileSystem;

      setUp(() {
        fileSystem = MemoryFileSystem.test();
      });

      testUsingContext('throws if any input file does not exist', () {
        fileSystem.file('a.dart').createSync();
        expect(
          () => Fingerprint.fromBuildInputs(const <String, String>{}, const <String>['a.dart', 'b.dart']),
          throwsException,
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('populates checksums for valid files', () {
        fileSystem.file('a.dart').writeAsStringSync('This is a');
        fileSystem.file('b.dart').writeAsStringSync('This is b');
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(const <String, String>{}, const <String>['a.dart', 'b.dart']);

        final Map<String, dynamic> jsonObject = castStringKeyedMap(json.decode(fingerprint.toJson()));
        expect(jsonObject['files'], hasLength(2));
        expect(jsonObject['files']['a.dart'], '8a21a15fad560b799f6731d436c1b698');
        expect(jsonObject['files']['b.dart'], '6f144e08b58cd0925328610fad7ac07c');
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('includes framework version', () {
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(const <String, String>{}, const <String>[]);

        final Map<String, dynamic> jsonObject = castStringKeyedMap(json.decode(fingerprint.toJson()));
        expect(jsonObject['version'], mockVersion.frameworkRevision);
      }, overrides: <Type, Generator>{FlutterVersion: () => mockVersion});

      testUsingContext('includes provided properties', () {
        final Fingerprint fingerprint = Fingerprint.fromBuildInputs(const <String, String>{'a': 'A', 'b': 'B'}, const <String>[]);

        final Map<String, dynamic> jsonObject = castStringKeyedMap(json.decode(fingerprint.toJson()));
        expect(jsonObject['properties'], hasLength(2));
        expect(jsonObject['properties']['a'], 'A');
        expect(jsonObject['properties']['b'], 'B');
      }, overrides: <Type, Generator>{FlutterVersion: () => mockVersion});
    });

    group('fromJson', () {
      testUsingContext('throws if JSON is invalid', () {
        expect(() => Fingerprint.fromJson('<xml></xml>'), throwsA(anything));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('creates fingerprint from valid JSON', () {
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
        final Map<String, dynamic> content = castStringKeyedMap(json.decode(fingerprint.toJson()));
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

      testUsingContext('throws ArgumentError for unknown versions', () {
        final String jsonString = json.encode(<String, dynamic>{
          'version': 'bad',
          'properties': <String, String>{},
          'files': <String, String>{},
        });
        expect(() => Fingerprint.fromJson(jsonString), throwsException);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('throws ArgumentError if version is not present', () {
        final String jsonString = json.encode(<String, dynamic>{
          'properties': <String, String>{},
          'files': <String, String>{},
        });
        expect(() => Fingerprint.fromJson(jsonString), throwsException);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('treats missing properties and files entries as if empty', () {
        final String jsonString = json.encode(<String, dynamic>{
          'version': kVersion,
        });
        expect(Fingerprint.fromJson(jsonString), Fingerprint.fromBuildInputs(const <String, String>{}, const <String>[]));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });
    });

    group('operator ==', () {
      testUsingContext('reports not equal if properties do not match', () {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{
            'buildMode': BuildMode.debug.toString(),
          },
          'files': <String, dynamic>{},
        };
        final Map<String, dynamic> b = Map<String, dynamic>.of(a);
        b['properties'] = <String, String>{
          'buildMode': BuildMode.release.toString(),
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if file checksums do not match', () {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{},
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = Map<String, dynamic>.of(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'b.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports not equal if file paths do not match', () {
        final Map<String, dynamic> a = <String, dynamic>{
          'version': kVersion,
          'properties': <String, String>{},
          'files': <String, dynamic>{
            'a.dart': '8a21a15fad560b799f6731d436c1b698',
            'b.dart': '6f144e08b58cd0925328610fad7ac07c',
          },
        };
        final Map<String, dynamic> b = Map<String, dynamic>.of(a);
        b['files'] = <String, dynamic>{
          'a.dart': '8a21a15fad560b799f6731d436c1b698',
          'c.dart': '6f144e08b58cd0925328610fad7ac07d',
        };
        expect(Fingerprint.fromJson(json.encode(a)) == Fingerprint.fromJson(json.encode(b)), isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockVersion,
      });

      testUsingContext('reports equal if properties and file checksums match', () {
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
      testUsingContext('is consistent with equals, even if map entries are reordered', () {
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
    MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    };

    testUsingContext('returns one file if only one is listed', () {
      fileSystem.file('a.d').writeAsStringSync('snapshot.d: /foo/a.dart');
      expect(readDepfile('a.d'), unorderedEquals(<String>['/foo/a.dart']));
    }, overrides: contextOverrides);

    testUsingContext('returns multiple files', () {
      fileSystem.file('a.d').writeAsStringSync('snapshot.d: /foo/a.dart /foo/b.dart');
      expect(readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
      ]));
    }, overrides: contextOverrides);

    testUsingContext('trims extra spaces between files', () {
      fileSystem.file('a.d').writeAsStringSync('snapshot.d: /foo/a.dart    /foo/b.dart  /foo/c.dart');
      expect(readDepfile('a.d'), unorderedEquals(<String>[
        '/foo/a.dart',
        '/foo/b.dart',
        '/foo/c.dart',
      ]));
    }, overrides: contextOverrides);

    testUsingContext('returns files with spaces and backslashes', () {
      fileSystem.file('a.d').writeAsStringSync(r'snapshot.d: /foo/a\ a.dart /foo/b\\b.dart /foo/c\\ c.dart');
      expect(readDepfile('a.d'), unorderedEquals(<String>[
        r'/foo/a a.dart',
        r'/foo/b\b.dart',
        r'/foo/c\ c.dart',
      ]));
    }, overrides: contextOverrides);
  });
}
