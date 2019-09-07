// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import 'artifacts.dart';
import 'asset.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/targets/assets.dart';
import 'build_system/targets/dart.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'globals.dart';
import 'project.dart';

String get defaultMainPath => fs.path.join('lib', 'main.dart');
const String defaultAssetBasePath = '.';
const String defaultManifestPath = 'pubspec.yaml';
String get defaultDepfilePath => fs.path.join(getBuildDirectory(), 'snapshot_blob.bin.d');

String getDefaultApplicationKernelPath({ @required bool trackWidgetCreation }) {
  return getKernelPathForTransformerOptions(
    fs.path.join(getBuildDirectory(), 'app.dill'),
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

const String _kKernelKey = 'kernel_blob.bin';
const String _kVMSnapshotData = 'vm_snapshot_data';
const String _kIsolateSnapshotData = 'isolate_snapshot_data';

/// Provides a `build` method that builds the bundle.
class BundleBuilder {
  /// Builds the bundle for the given target platform.
  ///
  /// The default `mainPath` is `lib/main.dart`.
  /// The default  `manifestPath` is `pubspec.yaml`
  Future<void> build({
    TargetPlatform platform,
    BuildMode buildMode,
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
    bool shouldBuildWithAssemble = false,
  }) async {
    mainPath ??= defaultMainPath;
    depfilePath ??= defaultDepfilePath;
    assetDirPath ??= getAssetBuildDirectory();
    packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);
    applicationKernelFilePath ??= getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation);
    final FlutterProject flutterProject = FlutterProject.current();

    if (shouldBuildWithAssemble) {
      await buildWithAssemble(
        buildMode: buildMode ?? BuildMode.debug,
        targetPlatform: platform,
        mainPath: mainPath,
        flutterProject: flutterProject,
        outputDir: assetDirPath,
      );
      return;
    }

    DevFSContent kernelContent;
    if (!precompiledSnapshot) {
      if ((extraFrontEndOptions != null) && extraFrontEndOptions.isNotEmpty)
        printTrace('Extra front-end options: $extraFrontEndOptions');
      ensureDirectoryExists(applicationKernelFilePath);
      final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(flutterProject);
      final CompilerOutput compilerOutput = await kernelCompiler.compile(
        sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath, mode: buildMode),
        mainPath: fs.file(mainPath).absolute.path,
        outputFilePath: applicationKernelFilePath,
        depFilePath: depfilePath,
        trackWidgetCreation: trackWidgetCreation,
        extraFrontEndOptions: extraFrontEndOptions,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        packagesPath: packagesPath,
      );
      if (compilerOutput?.outputFilename == null) {
        throwToolExit('Compiler failed on $mainPath');
      }
      kernelContent = DevFSFileContent(fs.file(compilerOutput.outputFilename));

      fs.directory(getBuildDirectory()).childFile('frontend_server.d')
          .writeAsStringSync('frontend_server.d: ${artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk)}\n');
    }

    final AssetBundle assets = await buildAssets(
      manifestPath: manifestPath,
      assetDirPath: assetDirPath,
      packagesPath: packagesPath,
      reportLicensedPackages: reportLicensedPackages,
    );
    if (assets == null)
      throwToolExit('Error building assets', exitCode: 1);

    await assemble(
      buildMode: buildMode,
      assetBundle: assets,
      kernelContent: kernelContent,
      privateKeyPath: privateKeyPath,
      assetDirPath: assetDirPath,
    );
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
}) async {
  final Environment environment = Environment(
    projectDir: flutterProject.directory,
    buildDir: flutterProject.dartTool.childDirectory('flutter_build'),
    defines: <String, String>{
      kTargetFile: mainPath,
      kBuildMode: getNameForBuildMode(buildMode),
      kTargetPlatform: getNameForTargetPlatform(targetPlatform),
    }
  );
  final BuildResult result = await buildSystem.build(const _BundleTarget(), environment);

  if (!result.success) {
    for (ExceptionMeasurement measurement in result.exceptions.values) {
      printError(measurement.exception.toString());
      printError(measurement.stackTrace.toString());
    }
    throwToolExit('Failed to build bundle.');
  }
  // Hack, we know where the cached version is so copy into expected output directory.
  if (outputDir != null) {
    final Directory outputDirectory = fs.directory(outputDir)..createSync(recursive: true);
    final Directory assetInputDir = environment.buildDir.childDirectory('flutter_assets');
    final File snapshotDepfile = environment.buildDir.childFile('snapshot_blob.bin.d');
    snapshotDepfile.copySync(outputDirectory.childFile('snapshot_blob.bin.d').path);
    copyDirectorySync(assetInputDir, outputDirectory);
    if (buildMode == BuildMode.debug) {
      final File copiedDill = environment.buildDir.childFile('app.dill');
      final File isolateSnapshotData = environment.buildDir.childFile('isolate_snapshot_data');
      final File vmSnapshotData = environment.buildDir.childFile('vm_snapshot_data');
      copiedDill.copySync(outputDirectory.childFile('kernel_blob.bin').path);
      isolateSnapshotData.copySync(outputDirectory.childFile('isolate_snapshot_data').path);
      vmSnapshotData.copySync(outputDirectory.childFile('vm_snapshot_data').path);
    }
  }
}

Future<AssetBundle> buildAssets({
  String manifestPath,
  String assetDirPath,
  String packagesPath,
  bool includeDefaultFonts = true,
  bool reportLicensedPackages = false,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  packagesPath ??= fs.path.absolute(PackageMap.globalPackagesPath);

  // Build the asset bundle.
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  final int result = await assetBundle.build(
    manifestPath: manifestPath,
    assetDirPath: assetDirPath,
    packagesPath: packagesPath,
    includeDefaultFonts: includeDefaultFonts,
    reportLicensedPackages: reportLicensedPackages,
  );
  if (result != 0)
    return null;

  return assetBundle;
}

Future<void> assemble({
  BuildMode buildMode,
  AssetBundle assetBundle,
  DevFSContent kernelContent,
  String privateKeyPath = defaultPrivateKeyPath,
  String assetDirPath,
}) async {
  assetDirPath ??= getAssetBuildDirectory();
  printTrace('Building bundle');

  final Map<String, DevFSContent> assetEntries = Map<String, DevFSContent>.from(assetBundle.entries);
  if (kernelContent != null) {
    final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: buildMode);
    final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: buildMode);
    assetEntries[_kKernelKey] = kernelContent;
    assetEntries[_kVMSnapshotData] = DevFSFileContent(fs.file(vmSnapshotData));
    assetEntries[_kIsolateSnapshotData] = DevFSFileContent(fs.file(isolateSnapshotData));
  }

  printTrace('Writing asset files to $assetDirPath');
  ensureDirectoryExists(assetDirPath);

  await writeBundle(fs.directory(assetDirPath), assetEntries);
  printTrace('Wrote $assetDirPath');
}

Future<void> writeBundle(
  Directory bundleDir,
  Map<String, DevFSContent> assetEntries,
) async {
  if (bundleDir.existsSync())
    bundleDir.deleteSync(recursive: true);
  bundleDir.createSync(recursive: true);

  // Limit number of open files to avoid running out of file descriptors.
  final Pool pool = Pool(64);
  await Future.wait<void>(
    assetEntries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      } finally {
        resource.release();
      }
    }));
}

// Synthetic target to combine copy assets and dill.
class _BundleTarget extends Target {
  const _BundleTarget();

  @override
  Future<void> build(List<File> inputFiles, Environment environment) async { }

  @override
  List<Target> get dependencies => const <Target>[
    CopyAssets(),
    KernelSnapshot(),
    CopyPrecompiledRuntime(),
  ];

  @override
  List<Source> get inputs => <Source>[];

  @override
  String get name => '_bundle_target';

  @override
  List<Source> get outputs => <Source>[];
}
