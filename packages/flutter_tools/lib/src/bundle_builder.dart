// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'asset.dart' hide defaultManifestPath;
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/depfile.dart';
import 'build_system/targets/common.dart';
import 'bundle.dart';
import 'cache.dart';
import 'devfs.dart';
import 'globals.dart' as globals;
import 'project.dart';


/// Provides a `build` method that builds the bundle.
class BundleBuilder {
  /// Builds the bundle for the given target platform.
  ///
  /// The default `mainPath` is `lib/main.dart`.
  /// The default  `manifestPath` is `pubspec.yaml`
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    @visibleForTesting BuildSystem? buildSystem,
  }) async {
    project ??= FlutterProject.current();
    mainPath ??= defaultMainPath;
    depfilePath ??= defaultDepfilePath;
    assetDirPath ??= getAssetBuildDirectory();
    buildSystem ??= globals.buildSystem;

    // If the precompiled flag was not passed, force us into debug mode.
    final Environment environment = Environment(
      projectDir: project.directory,
      outputDir: globals.fs.directory(assetDirPath),
      buildDir: project.dartTool.childDirectory('flutter_build'),
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      engineVersion: globals.artifacts!.isLocalEngine
          ? null
          : globals.flutterVersion.engineRevision,
      defines: <String, String>{
        // used by the KernelSnapshot target
        kTargetPlatform: getNameForTargetPlatform(platform),
        kTargetFile: mainPath,
        kDeferredComponents: 'false',
        ...buildInfo.toBuildSystemEnvironment(),
      },
      artifacts: globals.artifacts!,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      platform: globals.platform,
      generateDartPluginRegistry: true,
    );
    final Target target = buildInfo.mode == BuildMode.debug
        ? const CopyFlutterBundle()
        : const ReleaseCopyFlutterBundle();
    final BuildResult result = await buildSystem.build(target, environment);

    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: measurement.fatal
              ? measurement.stackTrace
              : null,
        );
      }
      throwToolExit('Failed to build bundle.');
    }
    if (depfilePath != null) {
      final Depfile depfile = Depfile(result.inputFiles, result.outputFiles);
      final File outputDepfile = globals.fs.file(depfilePath);
      if (!outputDepfile.parent.existsSync()) {
        outputDepfile.parent.createSync(recursive: true);
      }
      final DepfileService depfileService = DepfileService(
        fileSystem: globals.fs,
        logger: globals.logger,
      );
      depfileService.writeToFile(depfile, outputDepfile);
    }

    // Work around for flutter_tester placing kernel artifacts in odd places.
    if (applicationKernelFilePath != null) {
      final File outputDill = globals.fs.directory(assetDirPath).childFile('kernel_blob.bin');
      if (outputDill.existsSync()) {
        outputDill.copySync(applicationKernelFilePath);
      }
    }
    return;
  }
}

Future<AssetBundle?> buildAssets({
  required String manifestPath,
  String? assetDirPath,
  String? packagesPath,
  TargetPlatform? targetPlatform,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  packagesPath ??= globals.fs.path.absolute('.packages');

  // Build the asset bundle.
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    assetDirPath: assetDirPath,
    packagesPath: packagesPath,
    targetPlatform: targetPlatform,
  );
  if (result != 0) {
    return null;
  }

  return assetBundle;
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, DevFSContent> assetEntries,
  { Logger? loggerOverride }
) async {
  loggerOverride ??= globals.logger;
  if (bundleDir.existsSync()) {
    try {
      bundleDir.deleteSync(recursive: true);
    } on FileSystemException catch (err) {
      loggerOverride.printWarning(
        'Failed to clean up asset directory ${bundleDir.path}: $err\n'
        'To clean build artifacts, use the command "flutter clean".'
      );
    }
  }
  bundleDir.createSync(recursive: true);

  // Limit number of open files to avoid running out of file descriptors.
  final Pool pool = Pool(64);
  await Future.wait<void>(
    assetEntries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`.  However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = globals.fs.file(globals.fs.path.join(bundleDir.path, entry.key));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      } finally {
        resource.release();
      }
    }));
}
