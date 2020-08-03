// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/depfile.dart';
import 'build_system/targets/common.dart';
import 'build_system/targets/icon_tree_shaker.dart';
import 'cache.dart';
import 'convert.dart';
import 'devfs.dart';
import 'globals.dart' as globals;
import 'project.dart';

String get defaultMainPath => globals.fs.path.join('lib', 'main.dart');
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultDepfilePath => globals.fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');

String getDefaultApplicationKernelPath({ @required bool trackWidgetCreation }) {
  return getKernelPathForTransformerOptions(
    globals.fs.path.join(getBuildDirectory(), 'app.dill'),
    trackWidgetCreation: trackWidgetCreation,
  );
}

String getDefaultCachedKernelPath({
  @required bool trackWidgetCreation,
  @required List<String> dartDefines,
  @required List<String> extraFrontEndOptions,
}) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeAll(dartDefines);
  buffer.writeAll(extraFrontEndOptions ?? <String>[]);
  String buildPrefix = '';
  if (buffer.isNotEmpty) {
    final String output = buffer.toString();
    final Digest digest = md5.convert(utf8.encode(output));
    buildPrefix = '${hex.encode(digest.bytes)}.';
  }
  return getKernelPathForTransformerOptions(
    globals.fs.path.join(getBuildDirectory(), '${buildPrefix}cache.dill'),
    trackWidgetCreation: trackWidgetCreation,
  );
}

String getKernelPathForTransformerOptions(
  String path, {
  @required bool trackWidgetCreation,
}) {
  if (trackWidgetCreation) {
    path += '.track.dill';
  }
  return path;
}

const String defaultPrivateKeyPath = 'privatekey.der';

/// Provides a `build` method that builds the bundle.
class BundleBuilder {
  /// Builds the bundle for the given target platform.
  ///
  /// The default `mainPath` is `lib/main.dart`.
  /// The default  `manifestPath` is `pubspec.yaml`
  Future<void> build({
    @required TargetPlatform platform,
    BuildInfo buildInfo,
    String mainPath,
    String manifestPath = defaultManifestPath,
    String applicationKernelFilePath,
    String depfilePath,
    String privateKeyPath = defaultPrivateKeyPath,
    String assetDirPath,
    String packagesPath,
    bool precompiledSnapshot = false,
    bool reportLicensedPackages = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    List<String> fileSystemRoots,
    String fileSystemScheme,
    @required bool treeShakeIcons,
  }) async {
    mainPath ??= defaultMainPath;
    depfilePath ??= defaultDepfilePath;
    assetDirPath ??= getAssetBuildDirectory();
    packagesPath ??= globals.fs.path.absolute('.packages');
    final FlutterProject flutterProject = FlutterProject.current();
    await buildWithAssemble(
      buildMode: buildInfo.mode,
      targetPlatform: platform,
      mainPath: mainPath,
      flutterProject: flutterProject,
      outputDir: assetDirPath,
      depfilePath: depfilePath,
      precompiled: precompiledSnapshot,
      trackWidgetCreation: trackWidgetCreation,
      treeShakeIcons: treeShakeIcons,
      dartDefines: buildInfo.dartDefines,
    );
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

/// Build an application bundle using flutter assemble.
///
/// This is a temporary shim to migrate the build implementations.
Future<void> buildWithAssemble({
  @required FlutterProject flutterProject,
  @required BuildMode buildMode,
  @required TargetPlatform targetPlatform,
  @required String mainPath,
  @required String outputDir,
  @required String depfilePath,
  @required bool precompiled,
  bool trackWidgetCreation,
  @required bool treeShakeIcons,
  List<String> dartDefines,
}) async {
  // If the precompiled flag was not passed, force us into debug mode.
  buildMode = precompiled ? buildMode : BuildMode.debug;
  final Environment environment = Environment(
    projectDir: flutterProject.directory,
    outputDir: globals.fs.directory(outputDir),
    buildDir: flutterProject.dartTool.childDirectory('flutter_build'),
    cacheDir: globals.cache.getRoot(),
    flutterRootDir: globals.fs.directory(Cache.flutterRoot),
    engineVersion: globals.artifacts.isLocalEngine
      ? null
      : globals.flutterVersion.engineRevision,
    defines: <String, String>{
      kTargetFile: mainPath,
      kBuildMode: getNameForBuildMode(buildMode),
      kTargetPlatform: getNameForTargetPlatform(targetPlatform),
      kTrackWidgetCreation: trackWidgetCreation?.toString(),
      kIconTreeShakerFlag: treeShakeIcons ? 'true' : null,
      if (dartDefines != null && dartDefines.isNotEmpty)
        kDartDefines: encodeDartDefines(dartDefines),
    },
    artifacts: globals.artifacts,
    fileSystem: globals.fs,
    logger: globals.logger,
    processManager: globals.processManager,
  );
  final Target target = buildMode == BuildMode.debug
    ? const CopyFlutterBundle()
    : const ReleaseCopyFlutterBundle();
  final BuildResult result = await globals.buildSystem.build(target, environment);

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
}

Future<AssetBundle> buildAssets({
  String manifestPath,
  String assetDirPath,
  @required String packagesPath,
  bool includeDefaultFonts = true,
  bool reportLicensedPackages = false,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  packagesPath ??= globals.fs.path.absolute(packagesPath);

  // Build the asset bundle.
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    assetDirPath: assetDirPath,
    packagesPath: packagesPath,
    includeDefaultFonts: includeDefaultFonts,
    reportLicensedPackages: reportLicensedPackages,
  );
  if (result != 0) {
    return null;
  }

  return assetBundle;
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, DevFSContent> assetEntries,
  { Logger loggerOverride }
) async {
  loggerOverride ??= globals.logger;
  if (bundleDir.existsSync()) {
    try {
      bundleDir.deleteSync(recursive: true);
    } on FileSystemException catch (err) {
      loggerOverride.printError(
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
