// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:standard_message_codec/standard_message_codec.dart' show StandardMessageCodec;

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'dart_data_asset_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllDataAssets);
  setUp(setUpDataAssets);
  tearDown(tearDownDataAssets);

  group('dart data assets', () {
    for (final target in <String>[hostOs, 'web']) {
      testWithoutContext('flutter build $target', () async {
        final assets = <String, String>{'id1.txt': 'content1', 'id2.txt': 'content2'};
        final available = <String>['id1.txt'];
        writeAssets(assets, appRoot);
        writeHookLibrary(appRoot, assets, available: <String>['id1.txt']);
        writeHelperLibrary(appRoot, 'version1', assets.keys.toList());

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$target')],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
        final Directory buildTargetDir = appRoot.childDirectory('build').childDirectory(target);

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
          for (final id in available) {
            final key = 'packages/$packageName/data/$id';
            final entry = manifest[key]! as List<Object?>;
            expect(
              entry,
              equals([
                {'asset': key},
              ]),
            );

            final File file = manifestFile.parent.childFile(key);
            expect(file.readAsStringSync(), assets[id]);
          }
        }
      });
    }
  });
}
