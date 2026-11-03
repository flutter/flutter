// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:dart_data_home/dart_data_home.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_system/depfile.dart';
import '../convert.dart';
import 'project_extension_finder.dart';

/// Signature for compiling a [DiscoveredProjectExtension] to a runnable Kernel (`.dill`) URI.
typedef ExtensionKernelCompileFn = Future<Uri> Function(DiscoveredProjectExtension extension);

/// Exception thrown when compiling a tool extension entrypoint to a `.dill` Kernel fails.
class ExtensionCompileException implements Exception {
  const ExtensionCompileException(this.message);

  /// Description of the compilation failure.
  final String message;

  @override
  String toString() => 'ExtensionCompileException: $message';
}

/// Compiles discovered tool extension entrypoints to `.dill` Kernel files and
/// manages caching across `$PUB_CACHE` and local workspace packages.
class ExtensionKernelCompiler {
  ExtensionKernelCompiler({
    required this._artifacts,
    required this._fileSystem,
    required this._flutterRoot,
    required this._logger,
    required this._platform,
    required this._processManager,
  }) : _depfileService = DepfileService(fileSystem: _fileSystem, logger: _logger);

  /// Environment variable overriding the Pub cache directory.
  static const String kPubCacheEnv = 'PUB_CACHE';

  static const String _kLocalAppDataEnv = 'LOCALAPPDATA';
  static const String _kHomeEnv = 'HOME';
  static const String _kExtensionsDataDirectoryName = 'flutter_tool_extensions';
  static const String _kCacheSubdirectoryName = 'cache';
  static const String _kPubDirectoryName = 'Pub';
  static const String _kPubCacheSubdirectoryName = 'Cache';
  static const String _kPosixPubCacheDirectoryName = '.pub-cache';
  static const String _kUnknownSdkVersion = 'unknown';

  final Artifacts _artifacts;
  final DepfileService _depfileService;
  final FileSystem _fileSystem;
  final Directory _flutterRoot;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;

  /// Compiles [extension] to a `.dill` file (or returns the cached `.dill` URI
  /// if up to date).
  Future<Uri> compile(DiscoveredProjectExtension extension) async {
    final File entrypointFile = _fileSystem.file(extension.entrypointUri);
    if (!entrypointFile.existsSync()) {
      throw ExtensionCompileException(
        'Extension "${extension.name}" entrypoint not found at "${entrypointFile.path}".',
      );
    }

    final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
    if (!packageConfigFile.existsSync()) {
      throw ExtensionCompileException(
        'Cannot compile extension "${extension.name}" without a resolved '
        '.dart_tool/package_config.json at "${packageConfigFile.path}".',
      );
    }

    final (File dillFile, bool isImmutableCache) = _resolveDillTarget(extension);
    final File depFile = _fileSystem.file('${dillFile.path}.d');

    if (_isCachedDillValid(
      depFile: depFile,
      dillFile: dillFile,
      entrypointFile: entrypointFile,
      isImmutableCache: isImmutableCache,
      packageConfigFile: packageConfigFile,
    )) {
      return dillFile.absolute.uri;
    }

    dillFile.parent.createSync(recursive: true);
    return _fileSystem.runLocked<Uri>(
      lockPath: '${dillFile.path}.lock',
      logger: _logger,
      scope: () async {
        if (_isCachedDillValid(
          depFile: depFile,
          dillFile: dillFile,
          entrypointFile: entrypointFile,
          isImmutableCache: isImmutableCache,
          packageConfigFile: packageConfigFile,
        )) {
          return dillFile.absolute.uri;
        }

        final File tempDillFile = _fileSystem.file('${dillFile.path}.tmp');
        final File tempDepFile = _fileSystem.file('${depFile.path}.tmp');
        final command = <String>[
          _artifacts.getArtifactPath(Artifact.engineDartBinary),
          'compile',
          'kernel',
          '--packages=${packageConfigFile.path}',
          '--output=${tempDillFile.path}',
          '--depfile=${tempDepFile.path}',
          entrypointFile.path,
        ];

        _logger.printTrace(
          'ExtensionKernelCompiler: compiling "${extension.name}" with: ${command.join(' ')}',
        );
        final ProcessResult result = await _processManager.run(command);
        if (result.exitCode != 0) {
          ErrorHandlingFileSystem.deleteIfExists(tempDillFile);
          ErrorHandlingFileSystem.deleteIfExists(tempDepFile);
          throw ExtensionCompileException(
            'Failed to compile extension "${extension.name}" to kernel '
            '(exit code ${result.exitCode}):\n${result.stderr}',
          );
        }

        if (!tempDillFile.existsSync() || tempDillFile.lengthSync() == 0) {
          ErrorHandlingFileSystem.deleteIfExists(tempDillFile);
          ErrorHandlingFileSystem.deleteIfExists(tempDepFile);
          throw ExtensionCompileException(
            'Failed to compile extension "${extension.name}" to kernel: '
            'compiler exited 0 but did not produce a non-empty "${tempDillFile.path}".',
          );
        }

        if (tempDepFile.existsSync()) {
          tempDepFile.renameSync(depFile.path);
        }
        tempDillFile.renameSync(dillFile.path);
        return dillFile.absolute.uri;
      },
    );
  }

  bool _isCachedDillValid({
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required bool isImmutableCache,
    required File packageConfigFile,
  }) {
    if (isImmutableCache) {
      if (dillFile.existsSync() && dillFile.lengthSync() > 0) {
        _logger.printTrace(
          'ExtensionKernelCompiler: reusing cached pub-cache kernel "${dillFile.path}".',
        );
        return true;
      }
      return false;
    }
    if (!_needsRecompilation(
      dillFile: dillFile,
      depFile: depFile,
      packageConfigFile: packageConfigFile,
      entrypointFile: entrypointFile,
    )) {
      _logger.printTrace(
        'ExtensionKernelCompiler: reusing up-to-date local kernel "${dillFile.path}".',
      );
      return true;
    }
    return false;
  }

  /// Determines whether [extension]'s package root resides inside `$PUB_CACHE`
  /// (checking [kPubCacheEnv] first, then the platform default Pub cache path).
  @visibleForTesting
  bool isPubCacheExtension(DiscoveredProjectExtension extension) {
    final Directory? pubCacheDir = _resolvePubCacheDirectory();
    if (pubCacheDir == null) {
      return false;
    }
    final String rootPath = _fileSystem.path.normalize(
      _fileSystem.directory(extension.rootUri).absolute.path,
    );
    final String normalizedPubCache = _fileSystem.path.normalize(pubCacheDir.absolute.path);
    return _fileSystem.path.isWithin(normalizedPubCache, rootPath) ||
        _fileSystem.path.equals(normalizedPubCache, rootPath);
  }

  /// Resolves the Pub cache directory following `SystemCache.defaultDir` in
  /// `package:pub` (`PUB_CACHE`, `%LOCALAPPDATA%\Pub\Cache` on Windows, or
  /// `$HOME/.pub-cache` on POSIX).
  Directory? _resolvePubCacheDirectory() {
    if (_nonEmptyEnv(kPubCacheEnv) case final String pubCacheEnv) {
      return _fileSystem.directory(pubCacheEnv);
    }
    if (_platform.isWindows) {
      if (_nonEmptyEnv(_kLocalAppDataEnv) case final String localAppData) {
        return _fileSystem
            .directory(localAppData)
            .childDirectory(_kPubDirectoryName)
            .childDirectory(_kPubCacheSubdirectoryName);
      }
    } else if (_nonEmptyEnv(_kHomeEnv) case final String home) {
      return _fileSystem.directory(home).childDirectory(_kPosixPubCacheDirectoryName);
    }
    return null;
  }

  /// Resolves the target `.dill` cache [File] for [extension].
  @visibleForTesting
  File resolveDillFile(DiscoveredProjectExtension extension) {
    final (File dillFile, _) = _resolveDillTarget(extension);
    return dillFile;
  }

  (File dillFile, bool isImmutableCache) _resolveDillTarget(DiscoveredProjectExtension extension) {
    if (isPubCacheExtension(extension)) {
      final Directory cacheDir = _resolveSharedCacheDirectory();
      final String sdkKey = _computeSdkAndPackageKey(extension);
      return (cacheDir.childFile('${extension.name}-$sdkKey.dill'), true);
    }
    final File localDill = _fileSystem
        .directory(extension.workspaceRootPath)
        .childDirectory('.dart_tool')
        .childDirectory('flutter_tools')
        .childDirectory('extensions')
        .childDirectory(extension.name)
        .childFile('extension.dill');
    return (localDill, false);
  }

  /// Resolves the shared cache directory for compiled `.dill` files via
  /// [getDartDataHome] from `package:dart_data_home`, falling back to
  /// `<flutterRoot>/bin/cache/flutter_tool_extensions/cache` if the required OS
  /// environment variables are unset.
  Directory _resolveSharedCacheDirectory() {
    final environment = <String, String>{
      for (final MapEntry(:String key, :String value) in _platform.environment.entries)
        if (value.trim().isNotEmpty) key: value.trim(),
    };
    try {
      final String dataHomePath = getDartDataHome(
        _kExtensionsDataDirectoryName,
        environment: environment,
      );
      return _fileSystem.directory(dataHomePath).childDirectory(_kCacheSubdirectoryName);
    } on Exception {
      return _flutterRoot
          .childDirectory('bin')
          .childDirectory('cache')
          .childDirectory(_kExtensionsDataDirectoryName)
          .childDirectory(_kCacheSubdirectoryName);
    }
  }

  String? _nonEmptyEnv(String key) {
    final String? value = _platform.environment[key]?.trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  String _computeSdkAndPackageKey(DiscoveredProjectExtension extension) {
    final File versionFile = _resolveDartSdkVersionFile();
    final String sdkVersion = versionFile.existsSync()
        ? versionFile.readAsStringSync().trim()
        : _kUnknownSdkVersion;
    final String rootPath = _fileSystem.directory(extension.rootUri).absolute.path;
    final combinedHash = sha256.convert(utf8.encode('$sdkVersion|$rootPath')).toString();
    final String sanitizedVersion = sdkVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$sanitizedVersion-$combinedHash';
  }

  bool _needsRecompilation({
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required File packageConfigFile,
  }) {
    if (!dillFile.existsSync() || !depFile.existsSync() || dillFile.lengthSync() == 0) {
      return true;
    }
    final Depfile depfile = _depfileService.parse(depFile);
    if (depfile.inputs.isEmpty) {
      return true;
    }
    final DateTime dillModified = dillFile.lastModifiedSync();
    for (final file in <File>[packageConfigFile, entrypointFile, _resolveDartSdkVersionFile()]) {
      if (file.existsSync() && file.lastModifiedSync().isAfter(dillModified)) {
        return true;
      }
    }
    return depfile.inputs.any(
      (File input) => !input.existsSync() || input.lastModifiedSync().isAfter(dillModified),
    );
  }

  File _resolveDartSdkVersionFile() => _flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk')
      .childFile('version');
}
