// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pool/pool.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'artifacts.dart';
import 'asset.dart' hide defaultManifestPath;
import 'base/common.dart';
import 'base/config.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/build_targets.dart';
import 'build_system/depfile.dart';
import 'build_system/tools/asset_transformer.dart';
import 'build_system/tools/shader_compiler.dart';
import 'bundle.dart';
import 'cache.dart';
import 'context/tool_context.dart';
import 'devfs.dart';
import 'device.dart';
import 'project.dart';
import 'version.dart';

/// Provides a `build` method that builds the bundle.
class BundleBuilder {
  BundleBuilder({
    required this._analytics,
    required this._buildSystem,
    required this._buildTargets,
    required this._toolContext,
  });

  final Analytics _analytics;
  final BuildSystem _buildSystem;
  final BuildTargets _buildTargets;
  final ToolContext _toolContext;

  /// Builds the bundle for the given target platform.
  ///
  /// The default `mainPath` is `lib/main.dart`.
  /// The default `manifestPath` is `pubspec.yaml`.
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    BuildSystem? buildSystem,
  }) async {
    final ToolContext(
      :Artifacts artifacts,
      :Cache cache,
      :Config config,
      :FileSystem fs,
      :FlutterProjectFactory projectFactory,
      :FlutterVersion flutterVersion,
      :Logger logger,
      platform: Platform hostPlatform,
      :ProcessManager processManager,
    ) = _toolContext;
    project ??= projectFactory.fromDirectory(fs.currentDirectory);
    mainPath ??= defaultMainPath(fs);
    depfilePath ??= defaultDepfilePath(config: config, fileSystem: fs);
    assetDirPath ??= getAssetBuildDirectory(config, fs);
    buildSystem ??= _buildSystem;

    // If the precompiled flag was not passed, force us into debug mode.
    final environment = Environment(
      projectDir: project.directory,
      packageConfigPath: buildInfo.packageConfigPath,
      outputDir: fs.directory(assetDirPath),
      buildDir: project.dartTool.childDirectory('flutter_build'),
      cacheDir: cache.getRoot(),
      flutterRootDir: fs.directory(Cache.flutterRoot),
      engineVersion: artifacts.usesLocalArtifacts ? null : flutterVersion.engineRevision,
      defines: <String, String>{
        // used by the KernelSnapshot target
        kTargetPlatform: platform.getName(),
        kTargetFile: mainPath,
        kDeferredComponents: 'false',
        ...buildInfo.toBuildSystemEnvironment(),
      },
      artifacts: artifacts,
      fileSystem: fs,
      logger: logger,
      processManager: processManager,
      analytics: _analytics,
      platform: hostPlatform,
      generateDartPluginRegistry: true,
    );
    final Target target = buildInfo.mode == BuildMode.debug
        ? _buildTargets.copyFlutterBundle
        : _buildTargets.releaseCopyFlutterBundle;
    final BuildResult result = await buildSystem.build(target, environment);

    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        logger.printError(
          'Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: (measurement.fatal && measurement.exception is! ToolExit)
              ? measurement.stackTrace
              : null,
        );
      }
      throwToolExit('Failed to build bundle.');
    }
    final depfile = Depfile(result.inputFiles, result.outputFiles);
    final File outputDepfile = fs.file(depfilePath);
    if (!outputDepfile.parent.existsSync()) {
      outputDepfile.parent.createSync(recursive: true);
    }
    environment.depFileService.writeToFile(depfile, outputDepfile);

    // Work around for flutter_tester placing kernel artifacts in odd places.
    if (applicationKernelFilePath != null) {
      final File outputDill = fs.directory(assetDirPath).childFile('kernel_blob.bin');
      if (outputDill.existsSync()) {
        outputDill.copySync(applicationKernelFilePath);
      }
    }
    return;
  }
}

Future<AssetBundle?> buildAssets({
  required String manifestPath,
  required String packageConfigPath,
  required TargetPlatform targetPlatform,
  String? flavor,
}) async {
  // Build the asset bundle.
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    packageConfigPath: packageConfigPath,
    targetPlatform: targetPlatform,
    flavor: flavor,
  );
  if (result != 0) {
    return null;
  }

  return assetBundle;
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, AssetBundleEntry> assetEntries, {
  required BuildMode buildMode,
  required ImpellerStatus impellerStatus,
  required Directory projectDir,
  required TargetPlatform targetPlatform,
  required ToolContext toolContext,
}) async {
  final ToolContext(
    :Artifacts artifacts,
    fs: FileSystem fileSystem,
    :Logger logger,
    :Platform platform,
    :ProcessManager processManager,
  ) = toolContext;
  if (bundleDir.existsSync()) {
    try {
      bundleDir.deleteSync(recursive: true);
    } on FileSystemException catch (err) {
      logger.printWarning(
        'Failed to clean up asset directory ${bundleDir.path}: $err\n'
        'To clean build artifacts, use the command "flutter clean".',
      );
    }
  }
  bundleDir.createSync(recursive: true);

  final shaderCompiler = ShaderCompiler(
    processManager: processManager,
    logger: logger,
    fileSystem: fileSystem,
    artifacts: artifacts,
    platform: platform,
  );

  final assetTransformer = AssetTransformer(
    processManager: processManager,
    fileSystem: fileSystem,
    dartBinaryPath: artifacts.getArtifactPath(Artifact.engineDartBinary),
    buildMode: buildMode,
  );

  // Limit number of open files to avoid running out of file descriptors.
  final pool = Pool(64);
  await Future.wait<void>(
    assetEntries.entries.map<Future<void>>((MapEntry<String, AssetBundleEntry> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`. However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = fileSystem.file(fileSystem.path.join(bundleDir.path, entry.key));
        file.parent.createSync(recursive: true);
        final DevFSContent devFSContent = entry.value.content;
        if (devFSContent is DevFSFileContent) {
          final input = devFSContent.file as File;
          var doCopy = true;
          switch (entry.value.kind) {
            case AssetKind.regular:
              if (entry.value.transformers.isEmpty) {
                break;
              }
              final AssetTransformationResult result = await assetTransformer.transformAsset(
                asset: input,
                outputPath: file.path,
                workingDirectory: projectDir.path,
                transformerEntries: entry.value.transformers,
                logger: logger,
              );
              doCopy = false;
              if (result.failure != null) {
                throwToolExit(
                  'User-defined transformation of asset "${entry.key}" failed.\n'
                  '${result.failure!.message}',
                );
              }
            case AssetKind.font:
              break;
            case AssetKind.shader:
              var inputToCompiler = input;
              if (entry.value.transformers.isNotEmpty) {
                final transformedShaderSourcePath = '${file.path}.transformed';
                final AssetTransformationResult result = await assetTransformer.transformAsset(
                  asset: inputToCompiler,
                  outputPath: transformedShaderSourcePath,
                  workingDirectory: projectDir.path,
                  transformerEntries: entry.value.transformers,
                  logger: logger,
                );
                if (result.failure != null) {
                  throwToolExit(
                    'User-defined transformation of shader "${entry.key}" failed.\n'
                    '${result.failure!.message}',
                  );
                }
                inputToCompiler = fileSystem.file(transformedShaderSourcePath);
              }

              doCopy = !await shaderCompiler.compileShader(
                input: inputToCompiler,
                outputPath: file.path,
                targetPlatform: targetPlatform,
              );
          }
          if (doCopy) {
            input.copySync(file.path);
          }
        } else {
          await file.writeAsBytes(await entry.value.contentsAsBytes());
        }
      } finally {
        resource.release();
      }
    }),
  );
}
