// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:standard_message_codec/standard_message_codec.dart' show StandardMessageCodec;

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'record_use_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllRecordUse);
  setUp(setUpRecordUse);
  tearDown(tearDownRecordUse);

  group('record use', () {
    for (final target in <List<String>>[
      [hostOs],
      ['web'],
      ['web', '--wasm'],
    ]) {
      testWithoutContext('flutter build ${target.join(' ')} --release', () async {
        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', ...target, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}${target.first}')],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
        final Directory buildTargetDir = appRoot
            .childDirectory('build')
            .childDirectory(target.first);

        final List<File> manifestFiles = buildTargetDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('AssetManifest.bin'))
            .toList();

        if (manifestFiles.isEmpty) {
          throw Exception('Expected a `AssetManifest.bin` to be avilable in the $buildTargetDir.');
        }
        for (final manifestFile in manifestFiles) {
          final Uint8List manifestData = manifestFile.readAsBytesSync();
          final manifest =
              const StandardMessageCodec().decodeMessage(ByteData.sublistView(manifestData))
                  as Map<Object?, Object?>;
          const id1Key = 'packages/record_use_test_package/data/translations.json';
          expect(manifest.containsKey(id1Key), isTrue, reason: 'id1.json should be present');
          final File id1File = manifestFile.parent.childFile(id1Key);
          expect(id1File.existsSync(), isTrue);
          final translations = jsonDecode(id1File.readAsStringSync()) as Map<String, dynamic>;
          expect(translations.length, expectedTranslationCount);
        }
      });
    }
  });
}
