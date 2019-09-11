// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:io' as io; // ignore: dart_io_import

import 'package:build/build.dart';
import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_runner_core/build_runner_core.dart' as core;
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import '../base/file_system.dart';
import '../build_info.dart';
import '../convert.dart';
import '../web/compile.dart';
import 'web_fs.dart';

/// A build_runner specific implementation of the [WebCompilationProxy].
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  @override
  Future<bool> initialize({
    Directory projectDirectory,
    String testOutputDir,
    BuildMode mode,
    String projectName
  }) async {
    // Create the .dart_tool directory if it doesn't exist.
    projectDirectory
      .childDirectory('.dart_tool')
      .createSync();
    final BuildDaemonClient client = await buildDaemonCreator.startBuildDaemon(
      projectDirectory.path,
      release: mode == BuildMode.release,
      profile: mode == BuildMode.profile,
      hasPlugins: false,
      includeTests: true,
    );
    client.startBuild();
    bool success = true;
    await for (BuildResults results in client.buildResults) {
      final BuildResult result = results.results.firstWhere((BuildResult result) {
        return result.target == 'web';
      });
      if (result.status == BuildStatus.failed) {
        success = false;
        break;
      }
      if (result.status == BuildStatus.succeeded) {
        break;
      }
    }
    if (success && testOutputDir != null) {
      final Directory rootDirectory = projectDirectory
        .childDirectory('.dart_tool')
        .childDirectory('build')
        .childDirectory('flutter_web');

      final Iterable<Directory> childDirectories = rootDirectory
        .listSync()
        .whereType<Directory>();
      for (Directory childDirectory in childDirectories) {
        final String path = fs.path.join(testOutputDir, 'packages',
            fs.path.basename(childDirectory.path));
        copyDirectorySync(childDirectory.childDirectory('lib'), fs.directory(path));
      }
      final Directory outputDirectory = rootDirectory
          .childDirectory(projectName)
          .childDirectory('test');
      copyDirectorySync(outputDirectory, fs.directory(fs.path.join(testOutputDir)));
    }
    return success;
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
