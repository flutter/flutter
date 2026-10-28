// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../cache.dart';
import '../dart/package_map.dart';

/// A strategy for locating the `out/` directory of a local engine build.
///
/// The flutter tool can be run with the output files of one or more engine builds
/// replacing the cached artifacts. Typically this is done by setting the
/// `--local-engine` command line flag to the name of the desired engine variant
/// (e.g. "host_debug_unopt"). The `--local-engine-src-path` can be provided to
/// give an exact path to the engine subtree. If it is not specified, the `engine`
/// subfolder in this repository is used.
///
/// For more information on local engines, see README.md.
class LocalEngineLocator {
  LocalEngineLocator({
    required this._platform,
    required this._logger,
    required this._fileSystem,
    required this._flutterRoot,
    required this._userMessages,
  });

  final Platform _platform;
  final Logger _logger;
  final FileSystem _fileSystem;
  final String _flutterRoot;
  final UserMessages _userMessages;

  String _runnerNoEngineBuild(String engineBuildPath) =>
      'No Flutter engine build found at $engineBuildPath, and no Bazel build directory under '
      '${_fileSystem.path.join(_fileSystem.path.dirname(engineBuildPath), 'bazel-out')} '
      'whose ${LocalEngineLayout.manifestFileName} names it.';

  String _runnerSeveralBazelBuilds(String name, List<String> directories) =>
      '$name is the name of several Bazel build directories:\n'
      '${directories.map((String d) => '  $d').join('\n')}\n'
      'Pass the directory you mean as --local-engine or --local-engine-host.';

  String get _runnerHostEngineRequiresLocalEngine =>
      'You must specify --local-engine if you are using --local-engine-host.';

  String _runnerNoWebSdk(String webSdkPath) => 'No Flutter web sdk found at $webSdkPath.';

  String get _runnerLocalEngineRequiresHostEngine =>
      'You are using a locally built engine (--local-engine) but have not specified --local-engine-host.\n'
      'You may be building with a different engine than the one you are running with. '
      'See https://github.com/flutter/flutter/issues/132245 for details.';

  String _runnerNoEngineBuildDirInPath(String engineSourcePath) =>
      'No Flutter engine build directory found at: $engineSourcePath.\n'
      '\n'
      'To fix this:\n'
      "1. Ensure '$engineSourcePath' is a valid Flutter engine 'src' directory.\n"
      "2. Verify the engine is compiled in that directory, which should produce an 'out' directory.\n"
      '\n'
      'Alternatively, specify a different engine source path using the '
      '--local-engine-src-path flag or the FLUTTER_ENGINE environment variable.';

  String get _runnerLocalEngineOrWebSdkRequired =>
      'You must specify --local-engine or --local-web-sdk if you are using a locally built engine or web sdk.';

  /// Returns the engine build path of a local engine if one is located, otherwise `null`.
  Future<EngineBuildPaths?> findEnginePath({
    String? engineSourcePath,
    String? localEngine,
    String? localHostEngine,
    String? localWebSdk,
    String? packagePath,
  }) async {
    if (localHostEngine != null && localEngine == null) {
      throwToolExit(_runnerHostEngineRequiresLocalEngine, exitCode: 2);
    }

    engineSourcePath ??= _platform.environment[kFlutterEngineEnvironmentVariableName];
    if (engineSourcePath == null &&
        localEngine == null &&
        localWebSdk == null &&
        packagePath == null) {
      return null;
    }

    if (engineSourcePath == null) {
      try {
        if (localEngine != null) {
          engineSourcePath = _findEngineSourceByBuildPath(localEngine);
        }
        if (localWebSdk != null) {
          engineSourcePath ??= _findEngineSourceByBuildPath(localWebSdk);
        }
        engineSourcePath ??= await _findEngineSourceByPackageConfig(packagePath);
      } on FileSystemException catch (e) {
        _logger.printTrace('Local engine auto-detection file exception: $e');
        engineSourcePath = null;
      }

      // If engineSourcePath is still not set, try to determine it by flutter root.
      engineSourcePath ??= _tryEnginePath(
        _fileSystem.path.join(_fileSystem.directory(_flutterRoot).path, 'engine', 'src'),
      );
    }

    if (engineSourcePath != null && _tryEnginePath(engineSourcePath) == null) {
      throwToolExit(_runnerNoEngineBuildDirInPath(engineSourcePath), exitCode: 2);
    }

    if (engineSourcePath != null) {
      _logger.printTrace('Local engine source at $engineSourcePath');
      return _findEngineBuildPath(
        engineSourcePath: engineSourcePath,
        localEngine: localEngine,
        localWebSdk: localWebSdk,
        localHostEngine: localHostEngine,
      );
    }
    if (localEngine != null || localWebSdk != null) {
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

  String? _findEngineSourceByBuildPath(String buildPath) {
    // When the local engine is an absolute path to a variant inside the
    // out directory, parse the engine source.
    // --local-engine /path/to/cache/builder/src/out/host_debug_unopt
    if (_fileSystem.path.isAbsolute(buildPath)) {
      final Directory buildDirectory = _fileSystem.directory(buildPath);
      final Directory outDirectory = buildDirectory.parent;
      final Directory srcDirectory = outDirectory.parent;
      if (buildDirectory.existsSync() &&
          outDirectory.basename == 'out' &&
          srcDirectory.basename == 'src') {
        _logger.printTrace('Parsed engine source from local engine as ${srcDirectory.path}.');
        return srcDirectory.path;
      }
    }
    return null;
  }

  Future<String?> _findEngineSourceByPackageConfig(String? packagePath) async {
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      _fileSystem.file(packagePath ?? findPackageConfigFileOrDefault(_fileSystem.currentDirectory)),
      logger: _logger,
      throwOnError: false,
    );
    // Skip if sky_engine is the version in bin/cache.
    Uri? engineUri = packageConfig[kFlutterEnginePackageName]?.packageUriRoot;
    final String cachedPath = _fileSystem.path.join(
      _flutterRoot,
      'bin',
      'cache',
      'pkg',
      kFlutterEnginePackageName,
      'lib',
    );
    if (engineUri != null && _fileSystem.identicalSync(cachedPath, engineUri.path)) {
      _logger.printTrace(
        'Local engine auto-detection sky_engine in $packagePath is the same version in bin/cache.',
      );
      engineUri = null;
    }
    // If sky_engine is specified and the engineSourcePath not set, try to
    // determine the engineSourcePath by sky_engine setting. A typical engine Uri
    // looks like:
    // file://flutter-engine-local-path/src/out/host_debug_unopt/gen/dart-pkg/sky_engine/lib/
    String? engineSourcePath;
    final String? engineUriPath = engineUri?.path;
    if (engineUriPath != null) {
      engineSourcePath = _fileSystem
          .directory(engineUriPath)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
      if (engineSourcePath == _fileSystem.path.dirname(engineSourcePath) ||
          engineSourcePath.isEmpty) {
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

  EngineBuildPaths _findEngineBuildPath({
    required String engineSourcePath,
    String? localEngine,
    String? localWebSdk,
    String? localHostEngine,
  }) {
    if (localEngine == null && localWebSdk == null) {
      throwToolExit(_runnerLocalEngineOrWebSdkRequired, exitCode: 2);
    }

    String? engineBuildPath;
    String? engineHostBuildPath;
    if (localEngine != null) {
      engineBuildPath = _engineBuildDirectory(
        _fileSystem.path.join(engineSourcePath, 'out'),
        localEngine,
      );

      if (localHostEngine == null) {
        throwToolExit(_runnerLocalEngineRequiresHostEngine);
      }
      // The host build beside the target's: in the target's out directory
      // when the target is GN's `out/<name>` (another checkout's, maybe),
      // else -- a Bazel directory's parent is no out directory -- the
      // source's, where the Bazel directories are.
      final String targetOut = _fileSystem.path.dirname(engineBuildPath);
      final String outDirectory = _fileSystem.path.basename(targetOut) == 'out'
          ? targetOut
          : _fileSystem.path.join(engineSourcePath, 'out');
      engineHostBuildPath = _engineBuildDirectory(outDirectory, localHostEngine);
    }

    String? webSdkPath;
    if (localWebSdk != null) {
      webSdkPath = _fileSystem.path.normalize(
        _fileSystem.path.join(engineSourcePath, 'out', localWebSdk),
      );
      if (!_fileSystem.isDirectorySync(webSdkPath)) {
        throwToolExit(_runnerNoWebSdk(webSdkPath), exitCode: 2);
      }
    }

    return EngineBuildPaths(
      targetEngine: engineBuildPath,
      webSdk: webSdkPath,
      hostEngine: engineHostBuildPath,
    );
  }

  /// The engine build directory [nameOrPath] names: a directory under GN's
  /// [outDirectory] (or an absolute path, a Bazel build directory's among
  /// them), or else the Bazel build directory of that name -- the one under
  /// `<out>/bazel-out/<configuration>/bin/engine/src/flutter` whose
  /// local_engine.json names it (`host_debug_unopt`, GN's name for the
  /// configuration's build directory; LocalEngineLayout), so that
  /// `--local-engine=host_debug_unopt` finds a Bazel build as it finds GN's.
  String _engineBuildDirectory(String outDirectory, String nameOrPath) {
    final String path = _fileSystem.path.normalize(_fileSystem.path.join(outDirectory, nameOrPath));
    if (_fileSystem.isDirectorySync(path)) {
      return path;
    }
    final List<String> bazel = _bazelBuildDirectories(outDirectory, nameOrPath);
    if (bazel.length == 1) {
      _logger.printTrace('Local engine $nameOrPath is the Bazel build directory ${bazel.single}.');
      return bazel.single;
    }
    if (bazel.length > 1) {
      throwToolExit(_runnerSeveralBazelBuilds(nameOrPath, bazel), exitCode: 2);
    }
    throwToolExit(_runnerNoEngineBuild(path), exitCode: 2);
  }

  /// The Bazel build directories under [outDirectory]'s bazel-out whose
  /// manifest names the build [name], each once (bazel-bin is a link to one
  /// of them, and is not read).
  List<String> _bazelBuildDirectories(String outDirectory, String name) {
    final Directory bazelOut = _fileSystem.directory(
      _fileSystem.path.join(outDirectory, 'bazel-out'),
    );
    if (!bazelOut.existsSync()) {
      return const <String>[];
    }
    final found = <String>[];
    final List<Directory> configurations = bazelOut.listSync().whereType<Directory>().toList()
      ..sort((Directory a, Directory b) => a.path.compareTo(b.path));
    for (final configuration in configurations) {
      final String directory = _fileSystem.path.join(
        configuration.path,
        'bin',
        'engine',
        'src',
        'flutter',
      );
      if (!_fileSystem
          .file(_fileSystem.path.join(directory, LocalEngineLayout.manifestFileName))
          .existsSync()) {
        continue;
      }
      final layout = LocalEngineLayout.of(directory, fileSystem: _fileSystem);
      if (layout.name == name) {
        found.add(directory);
      }
    }
    return found;
  }

  String? _tryEnginePath(String enginePath) {
    if (_fileSystem.isDirectorySync(_fileSystem.path.join(enginePath, 'out'))) {
      return enginePath;
    }
    return null;
  }
}
