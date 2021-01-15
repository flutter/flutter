// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart' hide userMessages;
import '../dart/package_map.dart';
import 'flutter_command_runner.dart';

/// A strategy for locating the out/ directory of a local engine build.
///
/// The flutter tool can be run with the output files of one or more engine builds
/// replacing the cached artifacts. Typically this is done by setting the
/// `--local-engine` command line flag to the name of the desired engine variant
/// (e.g. "host_debug_unopt").  Provided that the `flutter/` and `engine/` directories
/// are located adjacent to one another, the output folder will be located
/// automatically.
///
/// For scenarios where the engine is not adjacent to flutter, the
/// `--local-engine-src-path` can be provided to give an exact path.
///
/// For more information on local engines, see CONTRIBUTING.md.
class LocalEngineLocator {
  LocalEngineLocator({
    @required Platform platform,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required String flutterRoot,
    @required UserMessages userMessages,
  }) : _platform = platform,
       _logger = logger,
       _fileSystem = fileSystem,
       _flutterRoot = flutterRoot,
        _userMessages = userMessages;

  final Platform _platform;
  final Logger _logger;
  final FileSystem _fileSystem;
  final String _flutterRoot;
  final UserMessages _userMessages;

  /// Returns the engine build path of a local engine if one is located, otherwise `null`.
  Future<EngineBuildPaths> findEnginePath(String engineSourcePath, String localEngine, String packagePath) async {
    engineSourcePath ??= _platform.environment[kFlutterEngineEnvironmentVariableName];

    if (engineSourcePath == null && localEngine != null) {
      try {
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          _fileSystem.file(
            // TODO(jonahwilliams): update to package_config
            packagePath ?? _fileSystem.path.join('.packages'),
          ),
          logger: _logger,
          throwOnError: false,
        );
        // Skip if sky_engine is the version in bin/cache.
        Uri engineUri = packageConfig[kFlutterEnginePackageName]?.packageUriRoot;
        final String cachedPath = _fileSystem.path.join(_flutterRoot, 'bin', 'cache', 'pkg', kFlutterEnginePackageName, 'lib');
        if (engineUri != null && _fileSystem.identicalSync(cachedPath, engineUri.path)) {
          engineUri = null;
        }
        // If sky_engine is specified and the engineSourcePath not set, try to
        // determine the engineSourcePath by sky_engine setting. A typical engine Uri
        // looks like:
        // file://flutter-engine-local-path/src/out/host_debug_unopt/gen/dart-pkg/sky_engine/lib/
        if (engineUri?.path != null) {
          engineSourcePath = _fileSystem.directory(engineUri.path)
            ?.parent
            ?.parent
            ?.parent
            ?.parent
            ?.parent
            ?.parent
            ?.path;
          if (engineSourcePath != null && (engineSourcePath == _fileSystem.path.dirname(engineSourcePath) || engineSourcePath.isEmpty)) {
            engineSourcePath = null;
            throwToolExit(
              _userMessages.runnerNoEngineSrcDir(
                kFlutterEnginePackageName,
                kFlutterEngineEnvironmentVariableName,
              ),
              exitCode: 2,
            );
          }
        }
      } on FileSystemException {
        engineSourcePath = null;
      }
      // If engineSourcePath is still not set, try to determine it by flutter root.
      engineSourcePath ??= _tryEnginePath(
        _fileSystem.path.join(_fileSystem.directory(_flutterRoot).parent.path, 'engine', 'src'),
      );
    }

    if (engineSourcePath != null && _tryEnginePath(engineSourcePath) == null) {
      throwToolExit(
        _userMessages.runnerNoEngineBuildDirInPath(engineSourcePath),
        exitCode: 2,
      );
    }

    if (engineSourcePath != null) {
      return _findEngineBuildPath(localEngine, engineSourcePath);
    }
    return null;
  }

  // Determine the host engine directory associated with the local engine:
  // Strip '_sim_' since there are no host simulator builds.
  String _getHostEngineBasename(String localEngineBasename) {
    String tmpBasename = localEngineBasename.replaceFirst('_sim_', '_');
    tmpBasename = tmpBasename.substring(tmpBasename.indexOf('_') + 1);
    // Strip suffix for various archs.
    const List<String> suffixes = <String>['_arm', '_arm64', '_x86', '_x64'];
    for (final String suffix in suffixes) {
      tmpBasename = tmpBasename.replaceFirst(RegExp('$suffix\$'), '');
    }
    return 'host_' + tmpBasename;
  }

  EngineBuildPaths _findEngineBuildPath(String localEngine, String enginePath) {
    if (localEngine == null) {
      throwToolExit(_userMessages.runnerLocalEngineRequired, exitCode: 2);
    }

    final String engineBuildPath = _fileSystem.path.normalize(_fileSystem.path.join(enginePath, 'out', localEngine));
    if (!_fileSystem.isDirectorySync(engineBuildPath)) {
      throwToolExit(_userMessages.runnerNoEngineBuild(engineBuildPath), exitCode: 2);
    }

    final String basename = _fileSystem.path.basename(engineBuildPath);
    final String hostBasename = _getHostEngineBasename(basename);
    final String engineHostBuildPath = _fileSystem.path.normalize(
      _fileSystem.path.join(_fileSystem.path.dirname(engineBuildPath), hostBasename),
    );
    if (!_fileSystem.isDirectorySync(engineHostBuildPath)) {
      throwToolExit(_userMessages.runnerNoEngineBuild(engineHostBuildPath), exitCode: 2);
    }

    return EngineBuildPaths(targetEngine: engineBuildPath, hostEngine: engineHostBuildPath);
  }

  String _tryEnginePath(String enginePath) {
    if (_fileSystem.isDirectorySync(_fileSystem.path.join(enginePath, 'out'))) {
      return enginePath;
    }
    return null;
  }
}
