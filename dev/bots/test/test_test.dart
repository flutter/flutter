// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:file/file.dart' as fs;
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;

import '../test.dart';
import 'common.dart';

class MockFile extends Mock implements File {}

void main() {
  MockFile file;
  setUp(() {
    file = MockFile();
    when(file.existsSync()).thenReturn(true);
  });
  group('verifyVersion()', () {
    test('passes for valid version strings', () async {
      const List<String> valid_versions = <String>[
        '1.2.3',
        '12.34.56',
        '1.2.3.pre.1',
        '1.2.3-4.5.pre',
        '1.2.3-5.0.pre.12',
      ];
      for (final String version in valid_versions) {
        when(file.readAsString()).thenAnswer((Invocation invocation) => Future<String>.value(version));
        expect(
          await verifyVersion(file),
          isNull,
          reason: '$version is valid but verifyVersionFile said it was bad',
        );
      }
    });

    test('fails for invalid version strings', () async {
      const List<String> invalid_versions = <String>[
        '1.2.3.4',
        '1.2.3.',
        '1.2.pre.1',
        '1.2.3-pre.1',
        '1.2.3-pre.1+hotfix.1',
        '  1.2.3',
        '1.2.3-hotfix.1',
      ];
      for (final String version in invalid_versions) {
        when(file.readAsString()).thenAnswer((Invocation invocation) => Future<String>.value(version));
        expect(
          await verifyVersion(file),
          'The version logic generated an invalid version string: "$version".',
          reason: '$version is invalid but verifyVersionFile said it was fine',
        );
      }
    });
  });

  group('flutter/plugins version', () {
    final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
    final fs.File pluginsVersionFile = memoryFileSystem.file(path.join('bin','internal','flutter_plugins.version'));
    const String kSampleHash = '592b5b27431689336fa4c721a099eedf787aeb56';
    setUpAll(() {
      pluginsVersionFile.createSync(recursive: true);
    });

    test('commit hash', () async {
      pluginsVersionFile.writeAsStringSync(kSampleHash);
      final String actualHash = await getFlutterPluginsVersion(fileSystem: memoryFileSystem, pluginsVersionFile: pluginsVersionFile.path);
      expect(actualHash, kSampleHash);
    });

    test('commit hash with newlines', () async {
      pluginsVersionFile.writeAsStringSync('\n$kSampleHash\n');
      final String actualHash = await getFlutterPluginsVersion(fileSystem: memoryFileSystem, pluginsVersionFile: pluginsVersionFile.path);
      expect(actualHash, kSampleHash);
    });
  });
}
