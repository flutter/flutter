// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/time.dart';
import '../build_system/depfile.dart';
import '../convert.dart';
import 'project_extension_finder.dart';

/// Result of compiling or reusing a workspace-local extension `.dill` Kernel.
///
/// Pass `buildToken` to [ExtensionKernelCompiler.writeCachedCapabilities] so
/// capabilities are persisted only when the on-disk `.dill` still matches the
/// snapshot spawned by the caller.
typedef CompiledExtensionKernel = ({String buildToken, Uri dillUri});

typedef _StampData = ({
  String buildToken,
  ToolExtensionCapabilities? capabilities,
  DateTime compiledAt,
  String packageConfigHash,
  String sdkRevision,
});

typedef _CachedDillValidation = ({bool isValid, _StampData? stamp});

/// Exception thrown when compiling a tool extension entrypoint to a `.dill` Kernel fails.
class ExtensionCompileException implements Exception {
  const ExtensionCompileException(this.message);

  /// Description of the compilation failure.
  final String message;

  @override
  String toString() => 'ExtensionCompileException: $message';
}

/// Compiles discovered tool extension entrypoints to workspace-local `.dill`
/// Kernel files and manages incremental cache invalidation and capability
/// persistence.
class ExtensionKernelCompiler {
  ExtensionKernelCompiler({
    required this._artifacts,
    required this._fileSystem,
    required this._flutterRoot,
    required this._logger,
    required this._processManager,
    this._clock = const SystemClock(),
  }) : _depfileService = DepfileService(fileSystem: _fileSystem, logger: _logger);

  static const String _kDotDartToolDirectoryName = '.dart_tool';
  static const String _kFlutterToolsDirectoryName = 'flutter_tools';
  static const String _kExtensionsDirectoryName = 'extensions';
  static const String _kLocalDillFileName = 'extension.dill';
  static const String _kBuildTokenStampKey = 'buildToken';
  static const String _kCompiledAtStampKey = 'compiledAt';
  static const String _kPackageConfigHashStampKey = 'packageConfigHash';
  static const String _kSdkRevisionStampKey = 'sdkRevision';
  static const String _kCapabilitiesStampKey = 'capabilities';
  static const String _kStampFileSuffix = '.stamp';
  static const String _kDepfileSuffix = '.d';
  static const String _kLockFileSuffix = '.lock';
  static const String _kTempFileSuffix = '.tmp';
  static const int _kBuildTokenByteLength = 16;

  final Artifacts _artifacts;
  final SystemClock _clock;
  final DepfileService _depfileService;
  final FileSystem _fileSystem;
  final Directory _flutterRoot;
  final Logger _logger;
  final ProcessManager _processManager;
  final Random _random = Random.secure();

  /// Compiles [extension] to a workspace-local `.dill` file (or returns the
  /// cached `.dill` URI and `buildToken` if up to date).
  ///
  /// Throws an [ExtensionCompileException] if compilation fails.
  Future<CompiledExtensionKernel> compile(DiscoveredProjectExtension extension) async {
    try {
      final File entrypointFile = _fileSystem.file(extension.entrypointUri);
      final bool entrypointExists = ErrorHandlingFileSystem.noExitOnFailure(
        entrypointFile.existsSync,
      );
      if (!entrypointExists) {
        throw ExtensionCompileException(
          'Extension "${extension.name}" entrypoint not found at "${entrypointFile.path}".',
        );
      }

      final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
      final bool packageConfigExists = ErrorHandlingFileSystem.noExitOnFailure(
        packageConfigFile.existsSync,
      );
      if (!packageConfigExists) {
        throw ExtensionCompileException(
          'Cannot compile extension "${extension.name}" without a resolved '
          '.dart_tool/package_config.json at "${packageConfigFile.path}".',
        );
      }

      final File dillFile = resolveDillFile(extension);
      final File depFile = _fileSystem.file('${dillFile.path}$_kDepfileSuffix');
      final File stampFile = _fileSystem.file('${dillFile.path}$_kStampFileSuffix');

      if (_tryReuseCachedDill(
            extension,
            depFile: depFile,
            dillFile: dillFile,
            entrypointFile: entrypointFile,
            packageConfigFile: packageConfigFile,
            stampFile: stampFile,
          )
          case final CompiledExtensionKernel cachedKernel) {
        return cachedKernel;
      }

      _ensureCacheDirectoryWritable(dillFile);

      return await _fileSystem.runLocked<CompiledExtensionKernel>(
        lockPath: '${dillFile.path}$_kLockFileSuffix',
        logger: _logger,
        scope: () async {
          if (_tryReuseCachedDill(
                extension,
                depFile: depFile,
                dillFile: dillFile,
                entrypointFile: entrypointFile,
                packageConfigFile: packageConfigFile,
                stampFile: stampFile,
              )
              case final CompiledExtensionKernel cachedKernel) {
            return cachedKernel;
          }

          // Capture compilation start time truncated down to whole seconds
          // before hashing inputs or invoking `dart compile kernel`. Comparing
          // `!input.lastModifiedSync().isBefore(compiledAt)` closes both the
          // mid-compile edit window and coarse (millisecond / 1-second) OS
          // filesystem timestamp truncation.
          final DateTime compiledAt = _truncateToSeconds(_clock.now());
          final String sdkRevision = _dartSdkRevision(extension);
          final String packageConfigHash = _hashFile(packageConfigFile);

          final File tempDillFile = _fileSystem.file('${dillFile.path}$_kTempFileSuffix');
          final File tempDepFile = _fileSystem.file('${depFile.path}$_kTempFileSuffix');
          final File tempStampFile = _fileSystem.file('${stampFile.path}$_kTempFileSuffix');
          try {
            final command = <String>[
              // TODO(bkonyi): Resolve the Dart binary from _flutterRoot/bin/cache/dart-sdk
              // instead of Artifact.engineDartBinary so --local-engine runs match the host
              // VM used by Isolate.spawnUri and _resolveDartSdkRevisionFile().
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
              throw ExtensionCompileException(
                'Failed to compile extension "${extension.name}" to kernel '
                '(exit code ${result.exitCode}):\n${result.stderr}',
              );
            }

            final CompiledExtensionKernel compiled = ErrorHandlingFileSystem.noExitOnFailure(() {
              if (!tempDillFile.existsSync() || tempDillFile.lengthSync() == 0) {
                throw ExtensionCompileException(
                  'Failed to compile extension "${extension.name}" to kernel: '
                  'compiler exited 0 but did not produce a non-empty "${tempDillFile.path}".',
                );
              }

              final String buildToken = _generateBuildToken();

              // Commit `.d` first, then `.dill`, and finally `.stamp` last so
              // the stamp acts as the linearizable commit point: an unlocked
              // reader never observes the new `buildToken` before `dillFile` is
              // replaced, and any reader observing the new `.dill` alongside the
              // previous stamp rejects it because the changed inputs fail the
              // previous stamp's freshness check.
              if (tempDepFile.existsSync()) {
                tempDepFile.renameSync(depFile.path);
              } else {
                ErrorHandlingFileSystem.deleteIfExists(depFile);
              }

              tempDillFile.renameSync(dillFile.path);

              tempStampFile
                ..writeAsStringSync(
                  jsonEncode(
                    _encodeStamp(
                      buildToken: buildToken,
                      compiledAt: compiledAt,
                      packageConfigHash: packageConfigHash,
                      sdkRevision: sdkRevision,
                    ),
                  ),
                )
                ..renameSync(stampFile.path);

              return (buildToken: buildToken, dillUri: dillFile.absolute.uri);
            });
            return compiled;
          } finally {
            _cleanupTempFiles(<File>[tempDillFile, tempDepFile, tempStampFile]);
          }
        },
      );
    } on ProcessException catch (error) {
      throw ExtensionCompileException(
        'Failed to compile extension "${extension.name}" to kernel: $error',
      );
    } on FileSystemException catch (error) {
      throw ExtensionCompileException(
        'Failed to compile extension "${extension.name}" to kernel: $error',
      );
    }
  }

  /// Reads the cached [ToolExtensionCapabilities] for [extension] if its
  /// compiled `.dill` Kernel and all dependency inputs are still up to date.
  ///
  /// Returns `null` if the `.dill` or cached capabilities do not exist, are
  /// malformed, or have been invalidated by a source, dependency, or SDK
  /// change.
  ToolExtensionCapabilities? readCachedCapabilities(DiscoveredProjectExtension extension) {
    final File entrypointFile = _fileSystem.file(extension.entrypointUri);
    final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
    try {
      final bool inputsExist = ErrorHandlingFileSystem.noExitOnFailure(
        () => entrypointFile.existsSync() && packageConfigFile.existsSync(),
      );
      if (!inputsExist) {
        return null;
      }
      final File dillFile = resolveDillFile(extension);
      final _CachedDillValidation validation = _validateCachedDill(
        extension,
        depFile: _fileSystem.file('${dillFile.path}$_kDepfileSuffix'),
        dillFile: dillFile,
        entrypointFile: entrypointFile,
        packageConfigFile: packageConfigFile,
        stampFile: _fileSystem.file('${dillFile.path}$_kStampFileSuffix'),
      );
      return validation.isValid ? validation.stamp?.capabilities : null;
    } on ExtensionCompileException {
      return null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Persists [capabilities] into the cache stamp alongside [extension]'s
  /// compiled `.dill` Kernel if the on-disk `.dill` still matches [buildToken]
  /// and all dependency inputs are up to date.
  ///
  /// Cache write failures (such as read-only file systems) are logged at trace
  /// level and ignored so that active commands are not interrupted.
  Future<void> writeCachedCapabilities(
    DiscoveredProjectExtension extension,
    ToolExtensionCapabilities capabilities, {
    required String buildToken,
  }) async {
    if (buildToken.isEmpty) {
      return;
    }
    try {
      final File entrypointFile = _fileSystem.file(extension.entrypointUri);
      final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
      final bool inputsExist = ErrorHandlingFileSystem.noExitOnFailure(
        () => entrypointFile.existsSync() && packageConfigFile.existsSync(),
      );
      if (!inputsExist) {
        return;
      }

      final File dillFile = resolveDillFile(extension);
      final File depFile = _fileSystem.file('${dillFile.path}$_kDepfileSuffix');
      final File stampFile = _fileSystem.file('${dillFile.path}$_kStampFileSuffix');
      final _CachedDillValidation preLockValidation = _validateCachedDill(
        extension,
        depFile: depFile,
        dillFile: dillFile,
        entrypointFile: entrypointFile,
        packageConfigFile: packageConfigFile,
        stampFile: stampFile,
      );
      if (!preLockValidation.isValid || preLockValidation.stamp?.buildToken != buildToken) {
        return;
      }

      _ensureCacheDirectoryWritable(dillFile);
      await _fileSystem.runLocked<void>(
        lockPath: '${dillFile.path}$_kLockFileSuffix',
        logger: _logger,
        scope: () async {
          ErrorHandlingFileSystem.noExitOnFailure(() {
            final _CachedDillValidation validation = _validateCachedDill(
              extension,
              depFile: depFile,
              dillFile: dillFile,
              entrypointFile: entrypointFile,
              packageConfigFile: packageConfigFile,
              stampFile: stampFile,
            );
            final _StampData? stamp = validation.stamp;
            if (!validation.isValid || stamp == null || stamp.buildToken != buildToken) {
              return;
            }
            final File tempStampFile = _fileSystem.file('${stampFile.path}$_kTempFileSuffix');
            try {
              tempStampFile
                ..writeAsStringSync(
                  jsonEncode(
                    _encodeStamp(
                      buildToken: stamp.buildToken,
                      capabilities: capabilities,
                      compiledAt: stamp.compiledAt,
                      packageConfigHash: stamp.packageConfigHash,
                      sdkRevision: stamp.sdkRevision,
                    ),
                  ),
                )
                ..renameSync(stampFile.path);
            } finally {
              _cleanupTempFiles(<File>[tempStampFile]);
            }
          });
        },
      );
    } on ExtensionCompileException catch (error) {
      _logger.printTrace(
        'ExtensionKernelCompiler: skipping capability cache write for "${extension.name}": $error',
      );
    } on FileSystemException catch (error) {
      _logger.printTrace(
        'ExtensionKernelCompiler: failed to write capability cache for "${extension.name}": $error',
      );
    }
  }

  /// Resolves the workspace-local `.dill` cache [File] for [extension].
  @visibleForTesting
  File resolveDillFile(DiscoveredProjectExtension extension) => _fileSystem
      .directory(extension.workspaceRootUri)
      .childDirectory(_kDotDartToolDirectoryName)
      .childDirectory(_kFlutterToolsDirectoryName)
      .childDirectory(_kExtensionsDirectoryName)
      .childDirectory(extension.name)
      .childFile(_kLocalDillFileName)
      .absolute;

  void _ensureCacheDirectoryWritable(File dillFile) {
    ErrorHandlingFileSystem.noExitOnFailure(() {
      dillFile.parent.createSync(recursive: true);
      final File probeLockFile = _fileSystem.file('${dillFile.path}$_kLockFileSuffix');
      probeLockFile.openSync(mode: FileMode.append).closeSync();
    });
  }

  static void _cleanupTempFiles(List<File> tempFiles) {
    ErrorHandlingFileSystem.noExitOnFailure(() {
      for (final file in tempFiles) {
        try {
          ErrorHandlingFileSystem.deleteIfExists(file);
        } on FileSystemException {
          // Best-effort cleanup of temporary artifacts on failure.
        }
      }
    });
  }

  static DateTime _truncateToSeconds(DateTime time) {
    final DateTime utc = time.toUtc();
    return DateTime.fromMillisecondsSinceEpoch(
      (utc.millisecondsSinceEpoch ~/ 1000) * 1000,
      isUtc: true,
    );
  }

  String _generateBuildToken() =>
      hex.encode(List<int>.generate(_kBuildTokenByteLength, (_) => _random.nextInt(256)));

  CompiledExtensionKernel? _tryReuseCachedDill(
    DiscoveredProjectExtension extension, {
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required File packageConfigFile,
    required File stampFile,
  }) {
    final String sdkRevision = _dartSdkRevision(extension);
    final _CachedDillValidation validation = _validateCachedDill(
      extension,
      depFile: depFile,
      dillFile: dillFile,
      entrypointFile: entrypointFile,
      packageConfigFile: packageConfigFile,
      sdkRevision: sdkRevision,
      stampFile: stampFile,
    );
    if (validation case (isValid: true, stamp: final _StampData stamp)) {
      _logger.printTrace(
        'ExtensionKernelCompiler: reusing up-to-date local kernel "${dillFile.path}".',
      );
      return (buildToken: stamp.buildToken, dillUri: dillFile.absolute.uri);
    }
    return null;
  }

  _CachedDillValidation _validateCachedDill(
    DiscoveredProjectExtension extension, {
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required File packageConfigFile,
    required File stampFile,
    String? sdkRevision,
  }) {
    const _CachedDillValidation invalid = (isValid: false, stamp: null);
    try {
      final String resolvedSdkRevision = sdkRevision ?? _dartSdkRevision(extension);
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        if (!dillFile.existsSync() ||
            !depFile.existsSync() ||
            !entrypointFile.existsSync() ||
            !packageConfigFile.existsSync() ||
            dillFile.lengthSync() == 0) {
          return invalid;
        }
        final _StampData? stamp = _readStamp(stampFile);
        if (stamp == null ||
            stamp.sdkRevision != resolvedSdkRevision ||
            _hashFile(packageConfigFile) != stamp.packageConfigHash) {
          return invalid;
        }
        final Depfile depfile = _depfileService.parse(depFile);
        if (depfile.inputs.isEmpty) {
          return invalid;
        }
        for (final File input in depfile.inputs) {
          if (_isPackageConfigInput(input, packageConfigFile)) {
            continue;
          }
          if (!input.existsSync() || !input.lastModifiedSync().isBefore(stamp.compiledAt)) {
            return invalid;
          }
        }
        return (isValid: true, stamp: stamp);
      });
    } on FileSystemException {
      return invalid;
    } on FormatException {
      return invalid;
    }
  }

  bool _isPackageConfigInput(File input, File packageConfigFile) =>
      _fileSystem.path.equals(input.absolute.path, packageConfigFile.absolute.path);

  static String _hashFile(File file) => ErrorHandlingFileSystem.noExitOnFailure(
    () => sha256.convert(file.readAsBytesSync()).toString(),
  );

  String _dartSdkRevision(DiscoveredProjectExtension extension) {
    final File revisionFile = _resolveDartSdkRevisionFile();
    final String? revision = _readNonEmptyTrimmed(revisionFile);
    if (revision == null) {
      throw ExtensionCompileException(
        'Cannot compile extension "${extension.name}": no Dart SDK revision at '
        '"${revisionFile.path}".',
      );
    }
    return revision;
  }

  static String? _readNonEmptyTrimmed(File file) {
    return ErrorHandlingFileSystem.noExitOnFailure(() {
      if (!file.existsSync()) {
        return null;
      }
      final String value = file.readAsStringSync().trim();
      return value.isNotEmpty ? value : null;
    });
  }

  _StampData? _readStamp(File stampFile) {
    try {
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        if (!stampFile.existsSync()) {
          return null;
        }
        final Object? decoded = jsonDecode(stampFile.readAsStringSync());
        if (decoded is! Map<String, Object?>) {
          return null;
        }
        final Object? buildToken = decoded[_kBuildTokenStampKey];
        final Object? compiledAtRaw = decoded[_kCompiledAtStampKey];
        final Object? packageConfigHash = decoded[_kPackageConfigHashStampKey];
        final Object? sdkRevision = decoded[_kSdkRevisionStampKey];
        if (buildToken is! String ||
            buildToken.isEmpty ||
            compiledAtRaw is! String ||
            compiledAtRaw.isEmpty ||
            packageConfigHash is! String ||
            packageConfigHash.isEmpty ||
            sdkRevision is! String ||
            sdkRevision.isEmpty) {
          return null;
        }
        final DateTime? parsedCompiledAt = DateTime.tryParse(compiledAtRaw);
        if (parsedCompiledAt == null) {
          return null;
        }
        ToolExtensionCapabilities? capabilities;
        if (decoded[_kCapabilitiesStampKey] case final Map<String, Object?> rawCapabilities) {
          capabilities = _tryParseCapabilitiesMap(rawCapabilities);
        }
        return (
          buildToken: buildToken,
          capabilities: capabilities,
          compiledAt: parsedCompiledAt.toUtc(),
          packageConfigHash: packageConfigHash,
          sdkRevision: sdkRevision,
        );
      });
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  static ToolExtensionCapabilities? _tryParseCapabilitiesMap(Map<String, Object?> map) {
    if (!map.containsKey(ToolExtensionCapabilities.servicesKey)) {
      return null;
    }
    try {
      return ToolExtensionCapabilities.fromJson(map);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> _encodeStamp({
    required String buildToken,
    required DateTime compiledAt,
    required String packageConfigHash,
    required String sdkRevision,
    ToolExtensionCapabilities? capabilities,
  }) => <String, Object?>{
    _kBuildTokenStampKey: buildToken,
    _kCompiledAtStampKey: compiledAt.toUtc().toIso8601String(),
    _kPackageConfigHashStampKey: packageConfigHash,
    _kSdkRevisionStampKey: sdkRevision,
    if (capabilities != null) _kCapabilitiesStampKey: capabilities.toMap(),
  };

  File _resolveDartSdkRevisionFile() => _flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk')
      .childFile('revision');
}
