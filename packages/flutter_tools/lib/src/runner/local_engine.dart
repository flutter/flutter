// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart' hide userMessages;
import '../cache.dart';
import '../dart/package_map.dart';

/// A strategy for locating the out/ directory of a local engine build.
///
/// The flutter tool can be run with the output files of one or more engine builds
/// replacing the cached artifacts. Typically this is done by setting the
/// `--local-engine` command line flag to the name of the desired engine variant
/// (e.g. "host_debug_unopt"). Provided that the `flutter/` and `engine/` directories
/// are located adjacent to one another, the output folder will be located
/// automatically.
///
/// For scenarios where the engine is not adjacent to flutter, the
/// `--local-engine-src-path` can be provided to give an exact path.
///
/// For more information on local engines, see CONTRIBUTING.md.
class LocalEngineLocator {
  LocalEngineLocator({
    required Platform platform,
    required Logger logger,
    required FileSystem fileSystem,
    required String flutterRoot,
    required UserMessages userMessages,
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
  Future<EngineBuildPaths?> findEnginePath(String? engineSourcePath, String? localEngine, String? packagePath) async {
    engineSourcePath ??= _platform.environment[kFlutterEngineEnvironmentVariableName];

    if (engineSourcePath == null && localEngine != null) {
      try {
        engineSourcePath = _findEngineSourceByLocalEngine(localEngine);
        engineSourcePath ??= await _findEngineSourceByPackageConfig(packagePath);
      } on FileSystemException catch (e) {
        _logger.printTrace('Local engine auto-detection file exception: $e');
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
      _logger.printTrace('Local engine source at $engineSourcePath');
      return _findEngineBuildPath(localEngine, engineSourcePath);
    }
    if (localEngine != null) {
      throwToolExit(
        _userMessages.runnerNoEngineSrcDir(
          kFlutterEnginePackageName,
          kFlutterEngineEnvironmentVariableName,
        ),
        exitCode: 2,
      );
    }
    return null;
  }

  String? _findEngineSourceByLocalEngine(String localEngine) {
    // When the local engine is an absolute path to a variant inside the
    // out directory, parse the engine source.
    // --local-engine /path/to/cache/builder/src/out/host_debug_unopt
    if (_fileSystem.path.isAbsolute(localEngine)) {
      final Directory localEngineDirectory = _fileSystem.directory(localEngine);
      final Directory outDirectory = localEngineDirectory.parent;
      final Directory srcDirectory = outDirectory.parent;
      if (localEngineDirectory.existsSync() && outDirectory.basename == 'out' && srcDirectory.basename == 'src') {
        _logger.printTrace('Parsed engine source from local engine as ${srcDirectory.path}.');
        return srcDirectory.path;
      }
    }
    return null;
  }

  Future<String?> _findEngineSourceByPackageConfig(String? packagePath) async {
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      _fileSystem.file(
        // TODO(zanderso): update to package_config
        packagePath ?? _fileSystem.path.join('.packages'),
      ),
      logger: _logger,
      throwOnError: false,
    );
    // Skip if sky_engine is the version in bin/cache.
    Uri? engineUri = packageConfig[kFlutterEnginePackageName]?.packageUriRoot;
    final String cachedPath = _fileSystem.path.join(_flutterRoot, 'bin', 'cache', 'pkg', kFlutterEnginePackageName, 'lib');
    if (engineUri != null && _fileSystem.identicalSync(cachedPath, engineUri.path)) {
      _logger.printTrace('Local engine auto-detection sky_engine in $packagePath is the same version in bin/cache.');
      engineUri = null;
    }
    // If sky_engine is specified and the engineSourcePath not set, try to
    // determine the engineSourcePath by sky_engine setting. A typical engine Uri
    // looks like:
    // file://flutter-engine-local-path/src/out/host_debug_unopt/gen/dart-pkg/sky_engine/lib/
    String? engineSourcePath;
    final String? engineUriPath = engineUri?.path;
    if (engineUriPath != null) {
      engineSourcePath = _fileSystem.directory(engineUriPath)
        .parent
        .parent
        .parent
        .parent
        .parent
        .parent
        .path;
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
    return engineSourcePath;
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
    return 'host_$tmpBasename';
  }

  EngineBuildPaths _findEngineBuildPath(String? localEngine, String enginePath) {
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

  String? _tryEnginePath(String enginePath) {
    if (_fileSystem.isDirectorySync(_fileSystem.path.join(enginePath, 'out'))) {
      return enginePath;
    }
    return null;
  }
}
