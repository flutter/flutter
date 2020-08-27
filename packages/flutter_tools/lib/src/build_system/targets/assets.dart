// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../../asset.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../build_info.dart';
import '../../convert.dart';
import '../../devfs.dart';
import '../build_system.dart';
import '../depfile.dart';
import 'common.dart';
import 'icon_tree_shaker.dart';

/// The input key for an SkSL bundle path.
const String kBundleSkSLPath = 'BundleSkSLPath';

/// A helper function to copy an asset bundle into an [environment]'s output
/// directory.
///
/// Throws [Exception] if [AssetBundle.build] returns a non-zero exit code.
///
/// [additionalContent] may contain additional DevFS entries that will be
/// included in the final bundle, but not the AssetManifest.json file.
///
/// Returns a [Depfile] containing all assets used in the build.
Future<Depfile> copyAssets(Environment environment, Directory outputDirectory, {
  Map<String, DevFSContent> additionalContent,
  @required TargetPlatform targetPlatform,
}) async {
  // Check for an SkSL bundle.
  final String shaderBundlePath = environment.inputs[kBundleSkSLPath];
  final DevFSContent skslBundle = processSkSLBundle(
    shaderBundlePath,
    engineVersion: environment.engineVersion,
    fileSystem: environment.fileSystem,
    logger: environment.logger,
    targetPlatform: targetPlatform,
  );

  final File pubspecFile =  environment.projectDir.childFile('pubspec.yaml');
  // Only the default asset bundle style is supported in assemble.
  final AssetBundle assetBundle = AssetBundleFactory.defaultInstance.createBundle();
  final int resultCode = await assetBundle.build(
    manifestPath: pubspecFile.path,
    packagesPath: environment.projectDir.childFile('.packages').path,
    assetDirPath: null,
  );
  if (resultCode != 0) {
    throw Exception('Failed to bundle asset files.');
  }
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
    processManager: environment.processManager,
    logger: environment.logger,
    fileSystem: environment.fileSystem,
    artifacts: environment.artifacts,
  );

  final Map<String, DevFSContent> assetEntries = <String, DevFSContent>{
    ...assetBundle.entries,
    ...?additionalContent,
    if (skslBundle != null)
      kSkSLShaderBundlePath: skslBundle,
  };

  await Future.wait<void>(
    assetEntries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`. However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = environment.fileSystem.file(
          environment.fileSystem.path.join(outputDirectory.path, entry.key));
        outputs.add(file);
        file.parent.createSync(recursive: true);
        final DevFSContent content = entry.value;
        if (content is DevFSFileContent && content.file is File) {
          inputs.add(content.file as File);
          if (!await iconTreeShaker.subsetFont(
            input: content.file as File,
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
  final Depfile depfile = Depfile(inputs + assetBundle.additionalDependencies, outputs);
  if (shaderBundlePath != null) {
    final File skSLBundleFile = environment.fileSystem
      .file(shaderBundlePath).absolute;
    depfile.inputs.add(skSLBundleFile);
  }
  return depfile;
}

/// The path of the SkSL JSON bundle included in flutter_assets.
const String kSkSLShaderBundlePath = 'io.flutter.shaders.json';

/// Validate and process an SkSL asset bundle in a [DevFSContent].
///
/// Returns `null` if the bundle was not provided, otherwise attempts to
/// validate the bundle.
///
/// Throws [Exception] if the bundle is invalid due to formatting issues.
///
/// If the current target platform is different than the platform constructed
/// for the bundle, a warning will be printed.
DevFSContent processSkSLBundle(String bundlePath, {
  @required TargetPlatform targetPlatform,
  @required FileSystem fileSystem,
  @required Logger logger,
  @required String engineVersion,
}) {
  if (bundlePath == null) {
    return null;
  }
  // Step 1: check that file exists.
  final File skSLBundleFile = fileSystem.file(bundlePath);
  if (!skSLBundleFile.existsSync()) {
    logger.printError('$bundlePath does not exist.');
    throw Exception('SkSL bundle was invalid.');
  }

  // Step 2: validate top level bundle structure.
  Map<String, Object> bundle;
  try {
    final Object rawBundle = json.decode(skSLBundleFile.readAsStringSync());
    if (rawBundle is Map<String, Object>) {
      bundle = rawBundle;
    } else {
      logger.printError('"$bundle" was not a JSON object: $rawBundle');
      throw Exception('SkSL bundle was invalid.');
    }
  } on FormatException catch (err) {
    logger.printError('"$bundle" was not a JSON object: $err');
    throw Exception('SkSL bundle was invalid.');
  }
  // Step 3: Validate that:
  // * The engine revision the bundle was compiled with
  //   is the same as the current revision.
  // * The target platform is the same (this one is a warning only).
  final String bundleEngineRevision = bundle['engineRevision'] as String;
  if (bundleEngineRevision != engineVersion) {
    logger.printError(
      'Expected Flutter $bundleEngineRevision, but found $engineVersion\n'
      'The SkSL bundle was produced with a different engine version. It must '
      'be recreated for the current Flutter version.'
    );
    throw Exception('SkSL bundle was invalid');
  }

  final TargetPlatform bundleTargetPlatform = getTargetPlatformForName(
    bundle['platform'] as String);
  if (bundleTargetPlatform != targetPlatform) {
    logger.printError(
      'The SkSL bundle was created for $bundleTargetPlatform, but the curent '
      'platform is $targetPlatform. This may lead to less efficient shader '
      'caching.'
    );
  }
  return DevFSStringContent(json.encode(<String, Object>{
    'data': bundle['data'],
  }));
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
    final Depfile depfile = await copyAssets(
      environment,
      output,
      targetPlatform: TargetPlatform.android,
    );
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );
  }
}
