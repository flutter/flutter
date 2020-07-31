// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/analyze_size.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const FakeCommand unzipCommmand = FakeCommand(
  command: <String>[
    'unzip',
    '-o',
    '-v',
    'test.apk',
    '-d',
    '/.tmp_rand0/flutter_tools.rand0'
  ],
  stdout: '''
Length   Method    Size  Cmpr    Date    Time   CRC-32   Name
--------  ------  ------- ---- ---------- ----- --------  ----
11708  Defl:N     2592  78% 00-00-1980 00:00 07733eef  AndroidManifest.xml
1399  Defl:N     1092  22% 00-00-1980 00:00 f53d952a  META-INF/CERT.RSA
46298  Defl:N    14530  69% 00-00-1980 00:00 17df02b8  META-INF/CERT.SF
46298  Defl:N    14530  69% 00-00-1980 00:00 17df02b8  lib/arm64-v8a/libapp.so
46298  Defl:N    14530  69% 00-00-1980 00:00 17df02b8  lib/arm64-v8a/libflutter.so
''',
);

const String aotSizeOutput = '''[
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
  FakeProcessManager processManager;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    processManager = FakeProcessManager.list(<FakeCommand>[unzipCommmand]);
  });

  test('builds APK analysis correctly', () async {
    final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
      fileSystem: fileSystem,
      logger: logger,
      processUtils: ProcessUtils(
        processManager: processManager,
        logger: logger,
      ),
    );

    final File apk = fileSystem.file('test.apk')..createSync();
    final File aotSizeJson = fileSystem.file('test.json')
      ..createSync()
      ..writeAsStringSync(aotSizeOutput);
    final Map<String, dynamic> result = await sizeAnalyzer.analyzeApkSizeAndAotSnapshot(apk: apk, aotSnapshot: aotSizeJson);

    expect(result['type'], contains('apk'));

    final Map<String, dynamic> androidManifestMap = result['children'][0] as Map<String, dynamic>;
    expect(androidManifestMap['n'], equals('AndroidManifest.xml'));
    expect(androidManifestMap['value'], equals(2592));

    final Map<String, dynamic> metaInfMap = result['children'][1] as Map<String, dynamic>;
    expect(metaInfMap['n'], equals('META-INF'));
    expect(metaInfMap['value'], equals(15622));
    final Map<String, dynamic> certRsaMap = metaInfMap['children'][0] as Map<String, dynamic>;
    expect(certRsaMap['n'], equals('CERT.RSA'));
    expect(certRsaMap['value'], equals(1092));
    final Map<String, dynamic> certSfMap = metaInfMap['children'][1] as Map<String, dynamic>;
    expect(certSfMap['n'], equals('CERT.SF'));
    expect(certSfMap['value'], equals(14530));

    final Map<String, dynamic> libMap = result['children'][2] as Map<String, dynamic>;
    expect(libMap['n'], equals('lib'));
    expect(libMap['value'], equals(29060));
    final Map<String, dynamic> arm64Map = libMap['children'][0] as Map<String, dynamic>;
    expect(arm64Map['n'], equals('arm64-v8a'));
    expect(arm64Map['value'], equals(29060));
    final Map<String, dynamic> libAppMap = arm64Map['children'][0] as Map<String, dynamic>;
    expect(libAppMap['n'], equals('libapp.so (Dart AOT)'));
    expect(libAppMap['value'], equals(14530));
    expect(libAppMap['children'].length, equals(3));
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
    expect(libFlutterMap['n'], equals('libflutter.so (Flutter Engine)'));
    expect(libFlutterMap['value'], equals(14530));
  });

  test('outputs summary to command line correctly', () async {
    final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
      fileSystem: fileSystem,
      logger: logger,
      processUtils: ProcessUtils(
        processManager: processManager,
        logger: logger,
      ),
    );

    final File apk = fileSystem.file('test.apk')..createSync();
    final File aotSizeJson = fileSystem.file('test.json')
      ..createSync()
      ..writeAsStringSync(aotSizeOutput);
    await sizeAnalyzer.analyzeApkSizeAndAotSnapshot(apk: apk, aotSnapshot: aotSizeJson);

    final List<String> stdout = logger.statusText.split('\n');
    expect(
      stdout,
      containsAll(<String>[
        '  AndroidManifest.xml                                                       3 KB',
        '  META-INF                                                                 15 KB',
        '  lib                                                                      28 KB',
        '    lib/arm64-v8a/libapp.so (Dart AOT)                                     14 KB',
        '      Dart AOT symbols accounted decompressed size                         14 KB',
        '        dart:_internal/SubListIterable                                      6 KB',
        '        @stubs/allocation-stubs/dart:core/ArgumentError                     5 KB',
        '        dart:core/RangeError                                                4 KB',
        '    lib/arm64-v8a/libflutter.so (Flutter Engine)                           14 KB',
      ]),
    );
  });
}
