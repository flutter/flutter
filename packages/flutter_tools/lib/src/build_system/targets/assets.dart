// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../asset.dart';
import '../../base/file_system.dart';
import '../../devfs.dart';
import '../build_system.dart';

/// The copying logic for flutter assets.
// TODO(jonahwilliams): combine the asset bundle logic with this rule so that
// we can compute the key for deleted assets. This is required to remove assets
// from build directories that are no longer part of the manifest and to unify
// the update/diff logic.
class AssetBehavior extends SourceBehavior {
  const AssetBehavior();

  @override
  List<FileSystemEntity> inputs(Environment environment) {
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    assetBundle.build(
      manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
    );
    final List<File> results = <File>[];
    final Iterable<DevFSFileContent> files = assetBundle.entries.values.whereType<DevFSFileContent>();
    for (DevFSFileContent devFsContent in files) {
      results.add(fs.file(devFsContent.file.path));
    }
    return results;
  }

  @override
  List<FileSystemEntity> outputs(Environment environment) {
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    assetBundle.build(
      manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
      packagesPath: environment.projectDir.childFile('.packages').path,
    );
    final List<File> results = <File>[];
    for (MapEntry<String, DevFSContent> entry in assetBundle.entries.entries) {
      final File file = fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', entry.key));
      results.add(file);
    }
    return results;
  }
}

/// Copies the asset files from the [copyAssets] rule into place.
///
/// Based on the contents of [updates], we copy the file in the case of
/// [ChangeType.Added] and [ChangeType.Modified].
Future<void> copyAssetsInvocation(Map<String, ChangeType> updates, Environment environment) async {
  final Directory output = environment
    .buildDir
    .childDirectory('flutter_assets');
  if (!output.existsSync()) {
    output.createSync(recursive: true);
  }
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  // TODO(jonahwilliams): replace with pool.
  for (MapEntry<String, DevFSContent> entry in assetBundle.entries.entries) {
    final File file = fs.file(fs.path.join(environment.buildDir.path, 'flutter_assets', entry.key));
    file.createSync(recursive: true);
    await file.writeAsBytes(await entry.value.contentsAsBytes());
  }
}

/// Copy the assets used in the application into a build directory.
const Target copyAssets = Target(
  name: 'copy_assets',
  inputs: <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.behavior(AssetBehavior()),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/flutter_assets/AssetManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/FontManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/LICENSE'),
    Source.behavior(AssetBehavior()), // <- everything in this subdirectory.
  ],
  dependencies: <Target>[],
  invocation: copyAssetsInvocation,
);
