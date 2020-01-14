// Copyright 2014 The Flutter Authors. All rights reserved.
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
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../web/compile.dart';
import 'web_fs.dart';

/// A build_runner specific implementation of the [WebCompilationProxy].
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  @override
  Future<bool> initialize({
    Directory projectDirectory,
    String testOutputDir,
    List<String> testFiles,
    BuildMode mode,
    String projectName,
    bool initializePlatform,
  }) async {
    // Create the .dart_tool directory if it doesn't exist.
    projectDirectory
      .childDirectory('.dart_tool')
      .createSync();
    final FlutterProject flutterProject = FlutterProject.fromDirectory(projectDirectory);
    final bool hasWebPlugins = findPlugins(flutterProject)
        .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
    final BuildDaemonClient client = await buildDaemonCreator.startBuildDaemon(
      projectDirectory.path,
      release: mode == BuildMode.release,
      profile: mode == BuildMode.profile,
      hasPlugins: hasWebPlugins,
      initializePlatform: initializePlatform,
      testTargets: WebTestTargetManifest(
        testFiles
          .map<String>((String absolutePath) {
            final String relativePath = path.relative(absolutePath, from: projectDirectory.path);
            return '${path.withoutExtension(relativePath)}.*';
          })
          .toList(),
      ),
    );
    client.startBuild();
    bool success = true;
    await for (final BuildResults results in client.buildResults) {
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
      for (final Directory childDirectory in childDirectories) {
        final String path = globals.fs.path.join(
          testOutputDir,
          'packages',
          globals.fs.path.basename(childDirectory.path),
        );
        fsUtils.copyDirectorySync(
          childDirectory.childDirectory('lib'),
          globals.fs.directory(path),
        );
      }
      final Directory outputDirectory = rootDirectory
        .childDirectory(projectName)
        .childDirectory('test');
      fsUtils.copyDirectorySync(
        outputDirectory,
        globals.fs.directory(globals.fs.path.join(testOutputDir)),
      );
    }
    return success;
  }
}

/// Handles mapping a single root file scheme to a multi-root scheme.
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
      final String generatedRoot = globals.fs.path.join(generatedDirectory.path, packageGraph.root.name);
      await for (final io.FileSystemEntity entity in glob.list(followLinks: true, root: packageGraph.root.path)) {
        if (entity is io.File && _isNotHidden(entity) && !globals.fs.path.isWithin(generatedRoot, entity.path)) {
          yield _fileToAssetId(entity, packageGraph.root);
        }
      }
      if (!globals.fs.isDirectorySync(generatedRoot)) {
        return;
      }
      await for (final io.FileSystemEntity entity in glob.list(followLinks: true, root: generatedRoot)) {
        if (entity is io.File && _isNotHidden(entity)) {
          yield _fileToAssetId(entity, packageGraph.root, globals.fs.path.relative(generatedRoot), true);
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
    return !globals.fs.file(path.joinAll(<String>[packageGraph.root.path, ...id.pathSegments])).existsSync();
  }

  File _generatedFile(AssetId id) {
    return globals.fs.file(
      path.joinAll(<String>[generatedDirectory.path, packageGraph.root.name, ...id.pathSegments])
    );
  }

  /// Creates an [AssetId] for [file], which is a part of [packageNode].
  AssetId _fileToAssetId(io.File file, core.PackageNode packageNode, [String root, bool generated = false]) {
    final String filePath = path.normalize(file.absolute.path);
    String relativePath;
    if (generated) {
      relativePath = filePath.substring(root.length + 2);
    } else {
      relativePath = path.relative(filePath, from: packageNode.path);
    }
    return AssetId(packageNode.name, relativePath);
  }
}
