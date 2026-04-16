// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml_edit/yaml_edit.dart' show YamlEditor;

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
      testWithoutContext('flutter build $target with conflicting assets', () async {
        final assets = <String, String>{'id1.txt': 'content1', 'id2.txt': 'content2'};
        final available = <String>['id1.txt'];
        writeAssets(assets, appRoot, subdir: '');
        writeAssets(assets, dependencyRoot, subdir: '');
        writeHookLibrary(appRoot, assets, available: available, namePrefix: '', filePrefix: '');
        writeHookLibrary(
          dependencyRoot,
          assets,
          available: available,
          namePrefix: '',
          filePrefix: '',
        );
        writeHelperLibrary(appRoot, 'version1', assets.keys.toList());

        await modifyPubspec(appRoot, (YamlEditor editor) {
          editor.update(
            <String>['dependencies', packageNameDependency],
            <String, String>{'path': '../$packageNameDependency'},
          );
        });

        await modifyPubspec(dependencyRoot, (YamlEditor editor) {
          editor
            ..update(<String>['flutter', 'assets'], <String>[assets.keys.first])
            ..update(
              <String>['dependencies'],
              <String, String>{'hooks': '^1.0.2', 'data_assets': '^0.19.6'},
            );
        });

        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', target],
          appRoot.path,
          <Transition>[
            Barrier.contains(
              'Conflicting assets: The asset "asset: packages/data_asset_package/id1.txt" was declared in the pubspec and the hook',
            ),
          ],
        );
        expect(result.exitCode, isNonZero);
      });
    }
  });
}
