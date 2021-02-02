// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:archive/archive.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/analyze_size.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';

const String aotSizeOutput = '''
[
    {
        "l": "dart:_internal",
        "c": "SubListIterable",
        "n": "[Optimized] skip",
        "s": 2400
    },
    {
        "l": "dart:_internal",
        "c": "SubListIterable",
        "n": "[Optimized] new SubListIterable.",
        "s": 3560
    },
    {
        "l": "dart:core",
        "c": "RangeError",
        "n": "[Optimized] new RangeError.range",
        "s": 3920
    },
    {
        "l": "dart:core",
        "c": "ArgumentError",
        "n": "[Stub] Allocate ArgumentError",
        "s": 4650
    }
]
''';

void main() {
  MemoryFileSystem fileSystem;
  BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  test('matchesPattern matches only entire strings', () {
    expect(matchesPattern('', pattern: ''), isNotNull);
    expect(matchesPattern('', pattern: 'foo'), null);
    expect(matchesPattern('foo', pattern: ''), null);
    expect(matchesPattern('foo', pattern: 'foo'), isNotNull);
    expect(matchesPattern('foo', pattern: 'foobar'), null);
    expect(matchesPattern('foobar', pattern: 'foo'), null);
    expect(matchesPattern('foobar', pattern: RegExp(r'.*b.*')), isNotNull);
    expect(matchesPattern('foobar', pattern: RegExp(r'.*b')), null);
  });

  test('builds APK analysis correctly', () async {
    final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
      fileSystem: fileSystem,
      logger: logger,
      appFilenamePattern: RegExp(r'lib.*app\.so'),
      flutterUsage: TestUsage(),
    );

    final Archive archive = Archive()
      ..addFile(ArchiveFile('AndroidManifest.xml', 100,  List<int>.filled(100, 0)))
      ..addFile(ArchiveFile('META-INF/CERT.RSA', 10,  List<int>.filled(10, 0)))
      ..addFile(ArchiveFile('META-INF/CERT.SF', 10,  List<int>.filled(10, 0)))
      ..addFile(ArchiveFile('lib/arm64-v8a/libxyzzyapp.so', 50,  List<int>.filled(50, 0)))
      ..addFile(ArchiveFile('lib/arm64-v8a/libflutter.so', 50, List<int>.filled(50, 0)));

    final File apk = fileSystem.file('test.apk')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
    final File aotSizeJson = fileSystem.file('test.json')
      ..createSync()
      ..writeAsStringSync(aotSizeOutput);
    final File precompilerTrace = fileSystem.file('trace.json')
      ..writeAsStringSync('{}');
    final Map<String, dynamic> result = await sizeAnalyzer.analyzeZipSizeAndAotSnapshot(
      zipFile: apk,
      aotSnapshot: aotSizeJson,
      precompilerTrace: precompilerTrace,
      kind: 'apk',
    );

    expect(result['type'], 'apk');

    final Map<String, dynamic> androidManifestMap = result['children'][0] as Map<String, dynamic>;
    expect(androidManifestMap['n'], 'AndroidManifest.xml');
    expect(androidManifestMap['value'], 6);

    final Map<String, dynamic> metaInfMap = result['children'][1] as Map<String, dynamic>;
    expect(metaInfMap['n'], 'META-INF');
    expect(metaInfMap['value'], 10);
    final Map<String, dynamic> certRsaMap = metaInfMap['children'][0] as Map<String, dynamic>;
    expect(certRsaMap['n'], 'CERT.RSA');
    expect(certRsaMap['value'], 5);
    final Map<String, dynamic> certSfMap = metaInfMap['children'][1] as Map<String, dynamic>;
    expect(certSfMap['n'], 'CERT.SF');
    expect(certSfMap['value'], 5);

    final Map<String, dynamic> libMap = result['children'][2] as Map<String, dynamic>;
    expect(libMap['n'], 'lib');
    expect(libMap['value'], 12);
    final Map<String, dynamic> arm64Map = libMap['children'][0] as Map<String, dynamic>;
    expect(arm64Map['n'], 'arm64-v8a');
    expect(arm64Map['value'], 12);
    final Map<String, dynamic> libAppMap = arm64Map['children'][0] as Map<String, dynamic>;
    expect(libAppMap['n'], 'libxyzzyapp.so (Dart AOT)');
    expect(libAppMap['value'], 6);
    expect(libAppMap['children'].length, 3);
    final Map<String, dynamic> internalMap = libAppMap['children'][0] as Map<String, dynamic>;
    final Map<String, dynamic> skipMap = internalMap['children'][0] as Map<String, dynamic>;
    expect(skipMap['n'], 'skip');
    expect(skipMap['value'], 2400);
    final Map<String, dynamic> subListIterableMap = internalMap['children'][1] as Map<String, dynamic>;
    expect(subListIterableMap['n'], 'new SubListIterable.');
    expect(subListIterableMap['value'], 3560);
    final Map<String, dynamic> coreMap = libAppMap['children'][1] as Map<String, dynamic>;
    final Map<String, dynamic> rangeErrorMap = coreMap['children'][0] as Map<String, dynamic>;
    expect(rangeErrorMap['n'], 'new RangeError.range');
    expect(rangeErrorMap['value'], 3920);
    final Map<String, dynamic> stubsMap = libAppMap['children'][2] as Map<String, dynamic>;
    final Map<String, dynamic> allocateMap = stubsMap['children'][0] as Map<String, dynamic>;
    expect(allocateMap['n'], 'Allocate ArgumentError');
    expect(allocateMap['value'], 4650);
    final Map<String, dynamic> libFlutterMap = arm64Map['children'][1] as Map<String, dynamic>;
    expect(libFlutterMap['n'], 'libflutter.so (Flutter Engine)');
    expect(libFlutterMap['value'], 6);

    expect(result['precompiler-trace'], <String, Object>{});
  });

  test('outputs summary to command line correctly', () async {
    final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
      fileSystem: fileSystem,
      logger: logger,
      appFilenamePattern: RegExp(r'lib.*app\.so'),
      flutterUsage: TestUsage(),
    );

    final Archive archive = Archive()
      ..addFile(ArchiveFile('AndroidManifest.xml', 100,  List<int>.filled(100, 0)))
      ..addFile(ArchiveFile('META-INF/CERT.RSA', 10,  List<int>.filled(10, 0)))
      ..addFile(ArchiveFile('META-INF/CERT.SF', 10,  List<int>.filled(10, 0)))
      ..addFile(ArchiveFile('lib/arm64-v8a/libxyzzyapp.so', 50,  List<int>.filled(50, 0)))
      ..addFile(ArchiveFile('lib/arm64-v8a/libflutter.so', 50, List<int>.filled(50, 0)));

    final File apk = fileSystem.file('test.apk')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
    final File aotSizeJson = fileSystem.file('test.json')
      ..writeAsStringSync(aotSizeOutput);
    final File precompilerTrace = fileSystem.file('trace.json')
      ..writeAsStringSync('{}');
    await sizeAnalyzer.analyzeZipSizeAndAotSnapshot(
      zipFile: apk,
      aotSnapshot: aotSizeJson,
      precompilerTrace: precompilerTrace,
      kind: 'apk',
    );

    final List<String> stdout = logger.statusText.split('\n');
    expect(
      stdout,
      containsAll(<String>[
        'test.apk (total compressed)                                                644 B',
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        '  lib                                                                       12 B',
        '  Dart AOT symbols accounted decompressed size                             14 KB',
        '    dart:core/',
        '      RangeError                                                            4 KB',
      ]),
    );
  });

  test('can analyze contents of output directory', () async {
    final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
      fileSystem: fileSystem,
      logger: logger,
      appFilenamePattern: RegExp(r'lib.*app\.so'),
      flutterUsage: TestUsage(),
    );

    final Directory outputDirectory = fileSystem.directory('example/out/foo.app')
      ..createSync(recursive: true);
    outputDirectory.childFile('a.txt')
      ..createSync()
      ..writeAsStringSync('hello');
    outputDirectory.childFile('libapp.so')
      ..createSync()
      ..writeAsStringSync('goodbye');
    final File aotSizeJson = fileSystem.file('test.json')
      ..writeAsStringSync(aotSizeOutput);
    final File precompilerTrace = fileSystem.file('trace.json')
      ..writeAsStringSync('{}');

    final Map<String, Object> result = await sizeAnalyzer.analyzeAotSnapshot(
      outputDirectory: outputDirectory,
      aotSnapshot: aotSizeJson,
      precompilerTrace: precompilerTrace,
      type: 'linux',
    );

    final List<String> stdout = logger.statusText.split('\n');
    expect(
      stdout,
      containsAll(<String>[
        '  foo.app                                                                   12 B',
        '  foo.app                                                                   12 B',
        '  Dart AOT symbols accounted decompressed size                             14 KB',
        '    dart:core/',
        '      RangeError                                                            4 KB',
      ]),
    );
    expect(result['type'], 'linux');
    expect(result['precompiler-trace'], <String, Object>{});
  });
}
