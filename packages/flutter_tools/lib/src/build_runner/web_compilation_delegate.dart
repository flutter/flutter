// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:io' as io; // ignore: dart_io_import

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../compile.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../web/compile.dart';
import 'build_script.dart';

/// A build_runner specific implementation of the [WebCompilationProxy].
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  core.PackageGraph _packageGraph;
  BuildImpl _builder;
  PackageUriMapper _packageUriMapper;

  @override
  Future<bool> initialize({
    Directory projectDirectory,
    String testOutputDir,
    BuildMode mode,
  }) async {
    // Create the .dart_tool directory if it doesn't exist.
    projectDirectory.childDirectory('.dart_tool').createSync();
    final Directory generatedDirectory = projectDirectory
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('generated');

    // Override the generated output directory so this does not conflict with
    // other build_runner output.
    core.overrideGeneratedOutputDirectory('flutter_web');
    _packageUriMapper = PackageUriMapper(
        path.absolute('lib/main.dart'), PackageMap.globalPackagesPath, null, null);
    _packageGraph = core.PackageGraph.forPath(projectDirectory.path);

    final core.BuildEnvironment buildEnvironment = core.OverrideableEnvironment(
        core.IOEnvironment(_packageGraph), onLog: (LogRecord record) {
      if (record.level == Level.SEVERE || record.level == Level.SHOUT) {
        printError(record.message);
      } else {
        printTrace(record.message);
      }
    }, reader: MultirootFileBasedAssetReader(_packageGraph, generatedDirectory));
    final LogSubscription logSubscription = LogSubscription(
      buildEnvironment,
      verbose: false,
      logLevel: Level.FINE,
    );
    final BuildOptions buildOptions = await BuildOptions.create(
      logSubscription,
      packageGraph: _packageGraph,
      skipBuildScriptCheck: true,
      trackPerformance: false,
      deleteFilesByDefault: true,
      enableLowResourcesMode: platform.environment['FLUTTER_LOW_RESOURCE_MODE']?.toLowerCase() == 'true',
    );
    final Set<core.BuildDirectory> buildDirs = <core.BuildDirectory>{
      if (testOutputDir != null)
        core.BuildDirectory(
          'test',
          outputLocation: core.OutputLocation(
            testOutputDir,
            useSymlinks: !platform.isWindows,
          ),
      ),
    };
    core.BuildResult result;
    try {
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        mode,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
    } on core.BuildConfigChangedException {
      await _cleanAssets(projectDirectory);
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        mode,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
    } on core.BuildScriptChangedException {
      await _cleanAssets(projectDirectory);
      result = await _runBuilder(
        buildEnvironment,
        buildOptions,
        mode,
        buildDirs,
      );
      return result.status == core.BuildStatus.success;
    }
  }

  @override
  Future<bool> invalidate({@required List<Uri> inputs}) async {
    final Status status =
        logger.startProgress('Recompiling sources...', timeout: null);
    final Map<AssetId, ChangeType> updates = <AssetId, ChangeType>{};
    for (Uri input in inputs) {
      final AssetId assetId = AssetId.resolve(_packageUriMapper.map(input.toFilePath()).toString());
      updates[assetId] = ChangeType.MODIFY;
    }
    core.BuildResult result;
    try {
      result = await _builder.run(updates);
    } finally {
      status.cancel();
    }
    return result.status == core.BuildStatus.success;
  }

  Future<core.BuildResult> _runBuilder(core.BuildEnvironment buildEnvironment, BuildOptions buildOptions, BuildMode buildMode, Set<core.BuildDirectory> buildDirs) async {
    _builder = await BuildImpl.create(
      buildOptions,
      buildEnvironment,
      builders,
      <String, Map<String, dynamic>>{
        'flutter_tools:ddc': <String, dynamic>{
          'flutterWebSdk': artifacts.getArtifactPath(Artifact.flutterWebSdk),
        },
        'flutter_tools:entrypoint': <String, dynamic>{
          'release': buildMode == BuildMode.release,
          'flutterWebSdk': artifacts.getArtifactPath(Artifact.flutterWebSdk),
          'profile': buildMode == BuildMode.profile,
        },
        'flutter_tools:test_entrypoint': <String, dynamic>{
          'release': buildMode == BuildMode.release,
          'profile': buildMode == BuildMode.profile,
        },
      },
      isReleaseBuild: false,
    );
    return _builder.run(
      const <AssetId, ChangeType>{},
      buildDirs: buildDirs,
    );
  }

  Future<void> _cleanAssets(Directory projectDirectory) async {
    final File assetGraphFile = fs.file(core.assetGraphPath);
    AssetGraph assetGraph;
    try {
      assetGraph = AssetGraph.deserialize(await assetGraphFile.readAsBytes());
    } catch (_) {
      printTrace('Failed to clean up asset graph.');
    }
    final core.PackageGraph packageGraph = core.PackageGraph.forThisPackage();
    await _cleanUpSourceOutputs(assetGraph, packageGraph);
    final Directory cacheDirectory = fs.directory(fs.path.join(
      projectDirectory.path,
      '.dart_tool',
      'build',
      'flutter_web',
    ));
    if (assetGraphFile.existsSync()) {
      assetGraphFile.deleteSync();
    }
    if (cacheDirectory.existsSync()) {
      cacheDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> _cleanUpSourceOutputs(AssetGraph assetGraph, core.PackageGraph packageGraph) async {
    final core.FileBasedAssetWriter writer = core.FileBasedAssetWriter(packageGraph);
    if (assetGraph?.outputs == null) {
      return;
    }
    for (AssetId id in assetGraph.outputs) {
      if (id.package != packageGraph.root.name) {
        continue;
      }
      final GeneratedAssetNode node = assetGraph.get(id);
      if (node.wasOutput) {
        // Note that this does a file.exists check in the root package and
        // only tries to delete the file if it exists. This way we only
        // actually delete to_source outputs, without reading in the build
        // actions.
        await writer.delete(id);
      }
    }
  }
}

/// Handles mapping a single root file scheme to a multiroot scheme.
///
/// This allows one build_runner build to read the output from a previous
/// isolated build.
class MultirootFileBasedAssetReader extends core.FileBasedAssetReader {
  MultirootFileBasedAssetReader(
    core.PackageGraph packageGraph,
    this.generatedDirectory,
  ) : super(packageGraph);

  final Directory generatedDirectory;

  @override
  Future<bool> canRead(AssetId id) {
    if (packageGraph[id.package] == packageGraph.root && _missingSource(id)) {
      return _generatedFile(id).exists();
    }
    return super.canRead(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    if (packageGraph[id.package] == packageGraph.root && _missingSource(id)) {
      return _generatedFile(id).readAsBytes();
    }
    return super.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) {
    if (packageGraph[id.package] == packageGraph.root && _missingSource(id)) {
      return _generatedFile(id).readAsString();
    }
    return super.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) async* {
    if (package == null || packageGraph.root.name == package) {
      await for (io.FileSystemEntity entity in glob.list(followLinks: true, root: packageGraph.root.path)) {
        if (entity is io.File && _isNotHidden(entity)) {
          yield _fileToAssetId(entity, packageGraph.root);
        }
      }
      final String generatedRoot = fs.path.join(
        generatedDirectory.path, packageGraph.root.name
      );
      if (!fs.isDirectorySync(generatedRoot)) {
        return;
      }
      await for (io.FileSystemEntity entity in glob.list(followLinks: true, root: generatedRoot)) {
        if (entity is io.File && _isNotHidden(entity)) {
          yield _fileToAssetId(entity, packageGraph.root, generatedRoot);
        }
      }
      return;
    }
    yield* super.findAssets(glob, package: package);
  }

  bool _isNotHidden(io.FileSystemEntity entity) {
    return !path.basename(entity.path).startsWith('._');
  }

  bool _missingSource(AssetId id) {
    return !fs.file(path.joinAll(<String>[packageGraph.root.path, ...id.pathSegments])).existsSync();
  }

  File _generatedFile(AssetId id) {
    return fs.file(
      path.joinAll(<String>[generatedDirectory.path, packageGraph.root.name, ...id.pathSegments])
    );
  }

  /// Creates an [AssetId] for [file], which is a part of [packageNode].
  AssetId _fileToAssetId(io.File file, core.PackageNode packageNode, [String root]) {
    final String filePath = path.normalize(file.absolute.path);
    final String relativePath = path.relative(filePath, from: root ?? packageNode.path);
    return AssetId(packageNode.name, relativePath);
  }
}
