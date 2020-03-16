// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pool/pool.dart';

import '../../asset.dart';
import '../../base/file_system.dart';
import '../../devfs.dart';
import '../../globals.dart' as globals;
import '../build_system.dart';
import '../depfile.dart';
import 'dart.dart';
import 'icon_tree_shaker.dart';

/// A helper function to copy an asset bundle into an [environment]'s output
/// directory.
///
/// Returns a [Depfile] containing all assets used in the build.
Future<Depfile> copyAssets(Environment environment, Directory outputDirectory) async {
  final File pubspecFile =  environment.projectDir.childFile('pubspec.yaml');
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: pubspecFile.path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  final Pool pool = Pool(kMaxOpenFiles);
  final List<File> inputs = <File>[
    // An asset manifest with no assets would have zero inputs if not
    // for this pubspec file.
    pubspecFile,
  ];
  final List<File> outputs = <File>[];

  final IconTreeShaker iconTreeShaker = IconTreeShaker(
    environment,
    assetBundle.entries[kFontManifestJson] as DevFSStringContent,
    processManager: globals.processManager,
    logger: globals.logger,
    fileSystem: globals.fs,
    artifacts: globals.artifacts,
  );

  await Future.wait<void>(
    assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`. However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = globals.fs.file(globals.fs.path.join(outputDirectory.path, entry.key));
        outputs.add(file);
        file.parent.createSync(recursive: true);
        final DevFSContent content = entry.value;
        if (content is DevFSFileContent && content.file is File) {
          inputs.add(globals.fs.file(content.file.path));
          if (!await iconTreeShaker.subsetFont(
            inputPath: content.file.path,
            outputPath: file.path,
            relativePath: entry.key,
          )) {
            await (content.file as File).copy(file.path);
          }
        } else {
          await file.writeAsBytes(await entry.value.contentsAsBytes());
        }
      } finally {
        resource.release();
      }
  }));
  return Depfile(inputs + assetBundle.additionalDependencies, outputs);
}

/// Copy the assets defined in the flutter manifest into a build directory.
class CopyAssets extends Target {
  const CopyAssets();

  @override
  String get name => 'copy_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/assets.dart'),
    ...IconTreeShaker.inputs,
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d'
  ];

  @override
  Future<void> build(Environment environment) async {
    final Directory output = environment
      .buildDir
      .childDirectory('flutter_assets');
    output.createSync(recursive: true);
    final Depfile depfile = await copyAssets(environment, output);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}
