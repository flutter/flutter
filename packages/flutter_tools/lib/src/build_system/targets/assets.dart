// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../asset.dart';
import '../../base/file_system.dart';
import '../../devfs.dart';
import '../build_system.dart';

/// List all asset files in a project by parsing the asset manfiest.
List<File> listAssets(Environment environment) {
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

/// List all output files in a project by parsing the asset manfiest and
/// replacing the path with the output directory.
List<File> listOutputAssets(Environment environment) {
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

/// Copies the asset files from the [copyAssets] rule into place.
Future<void> copyAssetsInvocation(List<FileSystemEntity> inputs, Environment environment) async {
  final Directory output = environment.buildDir.childDirectory('flutter_assets');
  if (!output.existsSync()) {
    output.createSync(recursive: true);
  }
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: environment.projectDir.childFile('pubspec.yaml').path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  for (MapEntry<String, DevFSContent> entry in assetBundle.entries.entries) {
    final File file = fs.file(fs.path.join(output.path, entry.key));
    // TODO(jonahwilliams): use copyFile method once that lands on master.
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(entry.value.contentsAsBytes());
  }
}

/// Assemble the assets used in the application into a build directory.
const Target copyAssets = Target(
  name: 'copy_assets',
  inputs: <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.function(listAssets),
  ],
  outputs: <Source>[
    Source.pattern('{BUILD_DIR}/flutter_assets/AssetManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/FontManifest.json'),
    Source.pattern('{BUILD_DIR}/flutter_assets/LICENSE'),
    Source.function(listOutputAssets), // <- everything in this subdirectory.
  ],
  dependencies: <Target>[],
  invocation: copyAssetsInvocation,
);
