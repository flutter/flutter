// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:dart_data_home/dart_data_home.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';
import 'package:yaml/yaml.dart';

import '../artifacts.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_system/depfile.dart';
import '../convert.dart';
import '../package_graph.dart';
import 'project_extension_finder.dart';

typedef _LockPackageInfo = ({String? resolvedRef, String source, String version});

typedef _LocalStampData = ({
  ToolExtensionCapabilities? capabilities,
  String closureHash,
  String sdkRevision,
  String sdkVersion,
});

typedef _SharedCacheClosureEvaluation = ({
  List<Package> closurePackages,
  _LockPackageInfo extensionLockInfo,
  Map<String, _LockPackageInfo> lockPackages,
});

typedef _CachedDillValidation = ({bool isValid, _LocalStampData? localStamp});

typedef _CachedWorkspaceMetadata = ({
  PackageConfig packageConfig,
  String packageConfigRaw,
  PackageGraph? packageGraph,
  String? packageGraphRaw,
  Map<String, _LockPackageInfo>? pubspecLock,
  String? pubspecLockRaw,
});

sealed class _DillTarget {
  const _DillTarget({required this.dillFile});

  final File dillFile;
}

final class _SharedDillTarget extends _DillTarget {
  const _SharedDillTarget({
    required this.capabilitiesFile,
    required super.dillFile,
    required this.localFallback,
  });

  final File capabilitiesFile;
  final _LocalDillTarget localFallback;
}

final class _LocalDillTarget extends _DillTarget {
  const _LocalDillTarget({
    required this.closureHash,
    required super.dillFile,
    required this.sdkRevision,
    required this.sdkVersion,
    required this.stampFile,
  });

  final String closureHash;
  final String sdkRevision;
  final String sdkVersion;
  final File stampFile;
}

/// Exception thrown when compiling a tool extension entrypoint to a `.dill` Kernel fails.
class ExtensionCompileException implements Exception {
  const ExtensionCompileException(this.message);

  /// Description of the compilation failure.
  final String message;

  @override
  String toString() => 'ExtensionCompileException: $message';
}

/// Compiles discovered tool extension entrypoints to `.dill` Kernel files and
/// manages caching across shared immutable packages and local workspace packages.
class ExtensionKernelCompiler {
  ExtensionKernelCompiler({
    required this._artifacts,
    required this._fileSystem,
    required this._flutterRoot,
    required this._logger,
    required this._platform,
    required this._processManager,
  }) : _depfileService = DepfileService(fileSystem: _fileSystem, logger: _logger);

  static const String _kExtensionsDataDirectoryName = 'flutter_tool_extensions';
  static const String _kCacheSubdirectoryName = 'cache';
  static const String _kPackageGraphFileName = 'package_graph.json';
  static const String _kPackageConfigFileName = 'package_config.json';
  static const String _kPubspecLockFileName = 'pubspec.lock';
  static const String _kDotDartToolDirectoryName = '.dart_tool';
  static const String _kFlutterToolsDirectoryName = 'flutter_tools';
  static const String _kExtensionsDirectoryName = 'extensions';
  static const String _kLocalDillFileName = 'extension.dill';
  static const String _kPackagesLockKey = 'packages';
  static const String _kSourceLockKey = 'source';
  static const String _kVersionLockKey = 'version';
  static const String _kDescriptionLockKey = 'description';
  static const String _kResolvedRefLockKey = 'resolved-ref';
  static const String _kHostedSource = 'hosted';
  static const String _kGitSource = 'git';
  static const String _kSdkRevisionStampKey = 'sdkRevision';
  static const String _kSdkVersionStampKey = 'sdkVersion';
  static const String _kClosureHashStampKey = 'closureHash';
  static const String _kCapabilitiesStampKey = 'capabilities';
  static const String _kCapabilitiesFileSuffix = '.capabilities.json';
  static const String _kStampFileSuffix = '.stamp';
  static const String _kDepfileSuffix = '.d';
  static const String _kLockFileSuffix = '.lock';
  static const String _kTempFileSuffix = '.tmp';
  static const _kImmutableLockSources = <String>{_kHostedSource, _kGitSource};
  static final _kUnsupportedLabelChars = RegExp(r'[^a-zA-Z0-9._+-]');

  final Artifacts _artifacts;
  final DepfileService _depfileService;
  final FileSystem _fileSystem;
  final Directory _flutterRoot;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final _workspaceMetadataCache = <String, _CachedWorkspaceMetadata>{};

  /// Compiles [extension] to a `.dill` file (or returns the cached `.dill` URI
  /// if up to date).
  ///
  /// Throws an [ExtensionCompileException] if compilation fails.
  Future<Uri> compile(DiscoveredProjectExtension extension) async {
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

      final _DillTarget target = ErrorHandlingFileSystem.noExitOnFailure(
        () => _resolveDillTarget(extension),
      );
      if (_isCachedDillValid(
        entrypointFile: entrypointFile,
        packageConfigFile: packageConfigFile,
        target: target,
      )) {
        return target.dillFile.absolute.uri;
      }
      if (target case _SharedDillTarget(:final _LocalDillTarget localFallback)) {
        if (_isCachedDillValid(
          entrypointFile: entrypointFile,
          packageConfigFile: packageConfigFile,
          target: localFallback,
        )) {
          return localFallback.dillFile.absolute.uri;
        }
      }

      switch (target) {
        case _SharedDillTarget(:final _LocalDillTarget localFallback):
          try {
            return await _compileTarget(
              extension,
              entrypointFile: entrypointFile,
              packageConfigFile: packageConfigFile,
              target: target,
            );
          } on FileSystemException catch (error) {
            _logger.printTrace(
              'ExtensionKernelCompiler: shared cache unavailable ($error); '
              'falling back to workspace-local cache.',
            );
            return await _compileTarget(
              extension,
              entrypointFile: entrypointFile,
              packageConfigFile: packageConfigFile,
              target: localFallback,
            );
          }
        case _LocalDillTarget():
          return await _compileTarget(
            extension,
            entrypointFile: entrypointFile,
            packageConfigFile: packageConfigFile,
            target: target,
          );
      }
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

  Future<Uri> _compileTarget(
    DiscoveredProjectExtension extension, {
    required File entrypointFile,
    required File packageConfigFile,
    required _DillTarget target,
  }) async {
    final File dillFile = target.dillFile;
    final File depFile = _fileSystem.file('${dillFile.path}$_kDepfileSuffix');
    _ensureCacheDirectoryWritable(dillFile);

    return _fileSystem.runLocked<Uri>(
      lockPath: '${dillFile.path}$_kLockFileSuffix',
      logger: _logger,
      scope: () async {
        if (_isCachedDillValid(
          entrypointFile: entrypointFile,
          packageConfigFile: packageConfigFile,
          target: target,
        )) {
          return dillFile.absolute.uri;
        }

        final File tempDillFile = _fileSystem.file('${dillFile.path}$_kTempFileSuffix');
        final File tempDepFile = _fileSystem.file('${depFile.path}$_kTempFileSuffix');
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

          final Uri compiledUri = ErrorHandlingFileSystem.noExitOnFailure(() {
            if (!tempDillFile.existsSync() || tempDillFile.lengthSync() == 0) {
              throw ExtensionCompileException(
                'Failed to compile extension "${extension.name}" to kernel: '
                'compiler exited 0 but did not produce a non-empty "${tempDillFile.path}".',
              );
            }

            // Clear or update cached capabilities BEFORE renaming tempDillFile
            // onto dillFile.path so unlocked concurrent readers never observe
            // a fresh .dill alongside stale capabilities from a prior build.
            switch (target) {
              case _SharedDillTarget(:final File capabilitiesFile):
                ErrorHandlingFileSystem.deleteIfExists(capabilitiesFile);
              case _LocalDillTarget(
                :final String closureHash,
                :final String sdkRevision,
                :final String sdkVersion,
                :final File stampFile,
              ):
                ErrorHandlingFileSystem.deleteIfExists(dillFile);
                _fileSystem.file('${stampFile.path}$_kTempFileSuffix')
                  ..writeAsStringSync(
                    jsonEncode(
                      _encodeStamp(
                        closureHash: closureHash,
                        sdkRevision: sdkRevision,
                        sdkVersion: sdkVersion,
                      ),
                    ),
                  )
                  ..renameSync(stampFile.path);
            }

            if (tempDepFile.existsSync()) {
              tempDepFile.renameSync(depFile.path);
            } else {
              ErrorHandlingFileSystem.deleteIfExists(depFile);
            }

            tempDillFile.renameSync(dillFile.path);
            return dillFile.absolute.uri;
          });
          return compiledUri;
        } finally {
          _cleanupTempFiles(<File>[
            tempDillFile,
            tempDepFile,
            if (target case _LocalDillTarget(:final File stampFile))
              _fileSystem.file('${stampFile.path}$_kTempFileSuffix'),
          ]);
        }
      },
    );
  }

  void _ensureCacheDirectoryWritable(File dillFile) {
    ErrorHandlingFileSystem.noExitOnFailure(() {
      dillFile.parent.createSync(recursive: true);
      final File probeLockFile = _fileSystem.file('${dillFile.path}$_kLockFileSuffix');
      probeLockFile.openSync(mode: FileMode.append).closeSync();
    });
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
      final _DillTarget target = ErrorHandlingFileSystem.noExitOnFailure(
        () => _resolveDillTarget(extension),
      );
      final _CachedDillValidation validation = _validateCachedDill(
        entrypointFile: entrypointFile,
        packageConfigFile: packageConfigFile,
        target: target,
      );
      switch (target) {
        case _SharedDillTarget(:final File capabilitiesFile, :final _LocalDillTarget localFallback):
          if (validation.isValid) {
            return _readCapabilitiesFile(capabilitiesFile);
          }
          final _CachedDillValidation fallbackValidation = _validateCachedDill(
            entrypointFile: entrypointFile,
            packageConfigFile: packageConfigFile,
            target: localFallback,
          );
          return fallbackValidation.isValid ? fallbackValidation.localStamp?.capabilities : null;
        case _LocalDillTarget():
          return validation.isValid ? validation.localStamp?.capabilities : null;
      }
    } on ExtensionCompileException {
      return null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Persists [capabilities] into the cache alongside [extension]'s compiled
  /// `.dill` Kernel if the `.dill` is still present and up to date.
  ///
  /// Cache write failures (such as read-only file systems) are logged at trace
  /// level and ignored so that active commands are not interrupted.
  Future<void> writeCachedCapabilities(
    DiscoveredProjectExtension extension,
    ToolExtensionCapabilities capabilities,
  ) async {
    try {
      final File entrypointFile = _fileSystem.file(extension.entrypointUri);
      final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
      final bool inputsExist = ErrorHandlingFileSystem.noExitOnFailure(
        () => entrypointFile.existsSync() && packageConfigFile.existsSync(),
      );
      if (!inputsExist) {
        return;
      }
      final _DillTarget resolvedTarget = ErrorHandlingFileSystem.noExitOnFailure(
        () => _resolveDillTarget(extension),
      );
      final _DillTarget activeTarget;
      if (_validateCachedDill(
        entrypointFile: entrypointFile,
        packageConfigFile: packageConfigFile,
        target: resolvedTarget,
      ).isValid) {
        activeTarget = resolvedTarget;
      } else if (resolvedTarget case _SharedDillTarget(:final _LocalDillTarget localFallback)
          when _validateCachedDill(
            entrypointFile: entrypointFile,
            packageConfigFile: packageConfigFile,
            target: localFallback,
          ).isValid) {
        activeTarget = localFallback;
      } else {
        return;
      }

      _ensureCacheDirectoryWritable(activeTarget.dillFile);
      await _fileSystem.runLocked<void>(
        lockPath: '${activeTarget.dillFile.path}$_kLockFileSuffix',
        logger: _logger,
        scope: () async {
          ErrorHandlingFileSystem.noExitOnFailure(() {
            final _CachedDillValidation validation = _validateCachedDill(
              entrypointFile: entrypointFile,
              packageConfigFile: packageConfigFile,
              target: activeTarget,
            );
            if (!validation.isValid) {
              return;
            }
            switch (activeTarget) {
              case _SharedDillTarget(:final File capabilitiesFile):
                final File tempCapabilitiesFile = _fileSystem.file(
                  '${capabilitiesFile.path}$_kTempFileSuffix',
                );
                try {
                  tempCapabilitiesFile
                    ..writeAsStringSync(jsonEncode(capabilities.toMap()))
                    ..renameSync(capabilitiesFile.path);
                } finally {
                  _cleanupTempFiles(<File>[tempCapabilitiesFile]);
                }
              case _LocalDillTarget(:final File stampFile):
                final _LocalStampData? localStamp = validation.localStamp;
                if (localStamp == null) {
                  return;
                }
                final File tempStampFile = _fileSystem.file('${stampFile.path}$_kTempFileSuffix');
                try {
                  tempStampFile
                    ..writeAsStringSync(
                      jsonEncode(
                        _encodeStamp(
                          capabilities: capabilities,
                          closureHash: localStamp.closureHash,
                          sdkRevision: localStamp.sdkRevision,
                          sdkVersion: localStamp.sdkVersion,
                        ),
                      ),
                    )
                    ..renameSync(stampFile.path);
                } finally {
                  _cleanupTempFiles(<File>[tempStampFile]);
                }
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

  static void _cleanupTempFiles(List<File> tempFiles) {
    for (final file in tempFiles) {
      try {
        ErrorHandlingFileSystem.deleteIfExists(file);
      } on FileSystemException {
        // Best-effort cleanup of temporary artifacts on failure.
      }
    }
  }

  bool _isCachedDillValid({
    required File entrypointFile,
    required File packageConfigFile,
    required _DillTarget target,
  }) {
    if (_validateCachedDill(
      entrypointFile: entrypointFile,
      packageConfigFile: packageConfigFile,
      target: target,
    ).isValid) {
      _logger.printTrace(switch (target) {
        _SharedDillTarget() =>
          'ExtensionKernelCompiler: reusing cached shared kernel "${target.dillFile.path}".',
        _LocalDillTarget() =>
          'ExtensionKernelCompiler: reusing up-to-date local kernel "${target.dillFile.path}".',
      });
      return true;
    }
    return false;
  }

  /// Determines whether [extension] and its resolved dependency closure
  /// consist exclusively of immutable (`hosted` or `git`) packages in
  /// `pubspec.lock` outside the workspace root, making it eligible for the
  /// shared Tier 1 `.dill` cache.
  @visibleForTesting
  bool isSharedCacheExtension(DiscoveredProjectExtension extension) =>
      ErrorHandlingFileSystem.noExitOnFailure(() => _resolveDillTarget(extension))
          is _SharedDillTarget;

  _SharedCacheClosureEvaluation? _evaluateSharedCacheClosure(
    DiscoveredProjectExtension extension, {
    required Set<String>? closureNames,
    required Map<String, _LockPackageInfo>? lockPackages,
    required PackageConfig? packageConfig,
  }) {
    if (packageConfig == null || closureNames == null || lockPackages == null) {
      return null;
    }
    final String normalizedWorkspaceRoot = _fileSystem.path.normalize(
      _fileSystem.directory(extension.workspaceRootUri).absolute.path,
    );
    final String extRootPath = _fileSystem.directory(extension.rootUri).absolute.path;
    if (_isWithinDirectory(extRootPath, normalizedWorkspaceRoot)) {
      return null;
    }
    final _LockPackageInfo? extLockInfo = lockPackages[extension.name];
    if (extLockInfo == null ||
        !_kImmutableLockSources.contains(extLockInfo.source) ||
        extLockInfo.version.trim().isEmpty) {
      return null;
    }
    final closurePackages = <Package>[];
    for (final String name in closureNames) {
      final Package? pkg = packageConfig[name];
      final _LockPackageInfo? depLockInfo = lockPackages[name];
      if (pkg == null ||
          depLockInfo == null ||
          !_kImmutableLockSources.contains(depLockInfo.source) ||
          depLockInfo.version.trim().isEmpty) {
        return null;
      }
      final String pkgRootPath = _fileSystem.directory(pkg.root).absolute.path;
      if (_isWithinDirectory(pkgRootPath, normalizedWorkspaceRoot)) {
        return null;
      }
      closurePackages.add(pkg);
    }
    return (
      closurePackages: closurePackages,
      extensionLockInfo: extLockInfo,
      lockPackages: lockPackages,
    );
  }

  bool _isWithinDirectory(String candidatePath, String normalizedParentPath) {
    final String normalizedCandidate = _fileSystem.path.normalize(candidatePath);
    return _fileSystem.path.isWithin(normalizedParentPath, normalizedCandidate) ||
        _fileSystem.path.equals(normalizedParentPath, normalizedCandidate);
  }

  _CachedWorkspaceMetadata? _loadWorkspaceMetadata(
    File packageConfigFile, {
    required String extensionName,
  }) {
    return ErrorHandlingFileSystem.noExitOnFailure(() {
      if (!packageConfigFile.existsSync()) {
        return null;
      }
      final String cacheKey = _fileSystem.path.normalize(packageConfigFile.absolute.path);
      final String packageConfigRaw;
      try {
        packageConfigRaw = packageConfigFile.readAsStringSync();
      } on FileSystemException catch (error) {
        throw ExtensionCompileException(
          'Failed to read package_config.json for extension "$extensionName" at '
          '"${packageConfigFile.path}": $error',
        );
      }

      final File graphFile = packageConfigFile.parent.childFile(_kPackageGraphFileName);
      final String? packageGraphRaw = _tryReadFileString(graphFile);
      final File lockFile = packageConfigFile.parent.parent.childFile(_kPubspecLockFileName);
      final String? pubspecLockRaw = _tryReadFileString(lockFile);

      final _CachedWorkspaceMetadata? cached = _workspaceMetadataCache[cacheKey];
      if (cached != null &&
          cached.packageConfigRaw == packageConfigRaw &&
          cached.packageGraphRaw == packageGraphRaw &&
          cached.pubspecLockRaw == pubspecLockRaw) {
        return cached;
      }

      final PackageConfig packageConfig;
      if (cached != null && cached.packageConfigRaw == packageConfigRaw) {
        packageConfig = cached.packageConfig;
      } else {
        try {
          packageConfig = PackageConfig.parseString(
            packageConfigRaw,
            packageConfigFile.absolute.uri,
          );
        } on FormatException catch (error) {
          throw ExtensionCompileException(
            'Failed to parse package_config.json for extension "$extensionName" at '
            '"${packageConfigFile.path}": $error',
          );
        }
      }

      final PackageGraph? packageGraph;
      if (cached != null && cached.packageGraphRaw == packageGraphRaw) {
        packageGraph = cached.packageGraph;
      } else {
        packageGraph = _parsePackageGraphRaw(graphFile, packageGraphRaw);
      }

      final Map<String, _LockPackageInfo>? pubspecLock;
      if (cached != null && cached.pubspecLockRaw == pubspecLockRaw) {
        pubspecLock = cached.pubspecLock;
      } else {
        pubspecLock = _parsePubspecLockRaw(pubspecLockRaw);
      }

      final _CachedWorkspaceMetadata updated = (
        packageConfig: packageConfig,
        packageConfigRaw: packageConfigRaw,
        packageGraph: packageGraph,
        packageGraphRaw: packageGraphRaw,
        pubspecLock: pubspecLock,
        pubspecLockRaw: pubspecLockRaw,
      );
      _workspaceMetadataCache[cacheKey] = updated;
      return updated;
    });
  }

  static String? _tryReadFileString(File file) {
    try {
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        if (!file.existsSync()) {
          return null;
        }
        return file.readAsStringSync();
      });
    } on FileSystemException {
      return null;
    }
  }

  static PackageGraph? _parsePackageGraphRaw(File graphFile, String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      return PackageGraph.fromJson(graphFile, jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  static Set<String>? _extensionClosureFromGraph(PackageGraph? graph, String extensionName) {
    if (graph == null || !graph.dependencies.containsKey(extensionName)) {
      return null;
    }
    final closure = <String>{};
    final toVisit = <String>[extensionName];
    while (toVisit.isNotEmpty) {
      final String name = toVisit.removeLast();
      if (closure.add(name)) {
        toVisit.addAll(graph.dependencies[name] ?? const <String>[]);
      }
    }
    return closure;
  }

  static Map<String, _LockPackageInfo>? _parsePubspecLockRaw(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final Object? parsed = loadYaml(raw);
      if (parsed is! YamlMap) {
        return null;
      }
      final Object? packagesNode = parsed[_kPackagesLockKey];
      if (packagesNode is! YamlMap) {
        return null;
      }
      final result = <String, _LockPackageInfo>{};
      for (final MapEntry(:Object? key, :Object? value) in packagesNode.entries) {
        if (key is! String || value is! YamlMap) {
          continue;
        }
        final Object? source = value[_kSourceLockKey];
        final Object? version = value[_kVersionLockKey];
        if (source is! String || version is! String) {
          continue;
        }
        String? resolvedRef;
        if (value[_kDescriptionLockKey] case final YamlMap description) {
          if (description[_kResolvedRefLockKey] case final String ref) {
            resolvedRef = ref;
          }
        }
        result[key] = (resolvedRef: resolvedRef, source: source, version: version);
      }
      return result;
    } on YamlException {
      return null;
    }
  }

  /// Resolves the target `.dill` cache [File] for [extension].
  @visibleForTesting
  File resolveDillFile(DiscoveredProjectExtension extension) =>
      ErrorHandlingFileSystem.noExitOnFailure(() => _resolveDillTarget(extension)).dillFile;

  _DillTarget _resolveDillTarget(DiscoveredProjectExtension extension) {
    final String sdkRevision = _dartSdkRevision(extension);
    final String sdkVersion = _readSdkVersion();
    final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
    final _CachedWorkspaceMetadata? metadata = _loadWorkspaceMetadata(
      packageConfigFile,
      extensionName: extension.name,
    );
    final PackageConfig? packageConfig = metadata?.packageConfig;
    final Set<String>? closureNames = _extensionClosureFromGraph(
      metadata?.packageGraph,
      extension.name,
    );
    final Map<String, _LockPackageInfo>? lockPackages = metadata?.pubspecLock;

    final File localDill = _fileSystem
        .directory(extension.workspaceRootUri)
        .childDirectory(_kDotDartToolDirectoryName)
        .childDirectory(_kFlutterToolsDirectoryName)
        .childDirectory(_kExtensionsDirectoryName)
        .childDirectory(extension.name)
        .childFile(_kLocalDillFileName)
        .absolute;
    final String closureHash = _computeLocalClosureHash(
      extension,
      closureNames: closureNames,
      lockPackages: lockPackages,
      packageConfig: packageConfig,
    );
    final localTarget = _LocalDillTarget(
      closureHash: closureHash,
      dillFile: localDill,
      sdkRevision: sdkRevision,
      sdkVersion: sdkVersion,
      stampFile: _fileSystem.file('${localDill.path}$_kStampFileSuffix'),
    );

    if (_evaluateSharedCacheClosure(
          extension,
          closureNames: closureNames,
          lockPackages: lockPackages,
          packageConfig: packageConfig,
        )
        case final _SharedCacheClosureEvaluation evaluation) {
      final Directory cacheDir = _resolveSharedCacheDirectory();
      final String rawExtVersion = evaluation.extensionLockInfo.version.trim();
      final String sanitizedExtVersion = rawExtVersion.replaceAll(_kUnsupportedLabelChars, '_');
      final String sdkAndDepsHash = _computeSdkAndDepsHash(
        extension,
        closurePackages: evaluation.closurePackages,
        lockPackages: evaluation.lockPackages,
        sdkRevision: sdkRevision,
        sdkVersion: sdkVersion,
      );
      final prefix = '${extension.name}-$sanitizedExtVersion-$sdkAndDepsHash';
      final File dillFile = _fileSystem.file(
        _fileSystem.path.normalize(cacheDir.childFile('$prefix.dill').absolute.path),
      );
      final File capabilitiesFile = _fileSystem.file(
        _fileSystem.path.normalize(
          cacheDir.childFile('$prefix$_kCapabilitiesFileSuffix').absolute.path,
        ),
      );
      return _SharedDillTarget(
        capabilitiesFile: capabilitiesFile,
        dillFile: dillFile,
        localFallback: localTarget,
      );
    }
    return localTarget;
  }

  /// Resolves the shared cache directory for compiled `.dill` files via
  /// [getDartDataHome] from `package:dart_data_home`, falling back to
  /// `<flutterRoot>/bin/cache/flutter_tool_extensions/cache` if the required OS
  /// environment variables are unset.
  Directory _resolveSharedCacheDirectory() {
    // Strip empty or whitespace-only entries because `getDartDataHome` checks
    // `environment['DART_DATA_HOME'] != null` without checking `.isEmpty`, which
    // would otherwise resolve `DART_DATA_HOME=""` relative to the current directory.
    // Note: `getDartDataHome` branches on `dart:io` `Platform.operatingSystem`.
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

  String _computeSdkAndDepsHash(
    DiscoveredProjectExtension extension, {
    required List<Package> closurePackages,
    required Map<String, _LockPackageInfo> lockPackages,
    required String sdkRevision,
    required String sdkVersion,
  }) {
    final String entrypointPath = _fileSystem.path.normalize(
      _fileSystem.file(extension.entrypointUri).absolute.path,
    );
    final packageDescriptors = <String>[
      for (final Package pkg in closurePackages)
        _formatPackageDescriptor(pkg, lockInfo: lockPackages[pkg.name]),
    ]..sort();
    final String payload = <String>[
      'revision=$sdkRevision',
      'sdkVersion=$sdkVersion',
      'entrypoint=$entrypointPath',
      ...packageDescriptors,
    ].join('|');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  String _computeLocalClosureHash(
    DiscoveredProjectExtension extension, {
    required Set<String>? closureNames,
    required Map<String, _LockPackageInfo>? lockPackages,
    required PackageConfig? packageConfig,
  }) {
    final String entrypointPath = _fileSystem.path.normalize(
      _fileSystem.file(extension.entrypointUri).absolute.path,
    );
    if (packageConfig == null) {
      return sha256.convert(utf8.encode('none|entrypoint=$entrypointPath')).toString();
    }
    final List<String> descriptors;
    final String modePrefix;
    if (closureNames != null) {
      modePrefix = 'closure';
      descriptors = <String>[
        for (final String name in closureNames)
          if (packageConfig[name] case final Package pkg)
            _formatPackageDescriptor(pkg, lockInfo: lockPackages?[name])
          else
            '$name:::::',
      ]..sort();
    } else {
      modePrefix = 'all';
      descriptors = <String>[
        for (final Package pkg in packageConfig.packages)
          _formatPackageDescriptor(pkg, lockInfo: lockPackages?[pkg.name]),
      ]..sort();
    }
    final String payload = <String>[
      modePrefix,
      'entrypoint=$entrypointPath',
      ...descriptors,
    ].join('|');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  String _formatPackageDescriptor(Package pkg, {_LockPackageInfo? lockInfo}) {
    final String normalizedRoot = _fileSystem.path.normalize(
      _fileSystem.directory(pkg.root).absolute.path,
    );
    final String normalizedPackageUriRoot = _fileSystem.path.normalize(
      _fileSystem.directory(pkg.packageUriRoot).absolute.path,
    );
    final String source = lockInfo?.source ?? '';
    final String version = lockInfo?.version ?? '';
    final String resolvedRef = lockInfo?.resolvedRef ?? '';
    return '${pkg.name}:$source:$version:$resolvedRef:$normalizedRoot:$normalizedPackageUriRoot';
  }

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

  String _readSdkVersion() =>
      _readNonEmptyTrimmed(_resolveDartSdkVersionFile()) ?? _platform.version.trim();

  static String? _readNonEmptyTrimmed(File file) {
    return ErrorHandlingFileSystem.noExitOnFailure(() {
      if (!file.existsSync()) {
        return null;
      }
      final String value = file.readAsStringSync().trim();
      return value.isNotEmpty ? value : null;
    });
  }

  _CachedDillValidation _validateCachedDill({
    required File entrypointFile,
    required File packageConfigFile,
    required _DillTarget target,
  }) {
    const _CachedDillValidation invalid = (isValid: false, localStamp: null);
    try {
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        final File dillFile = target.dillFile;
        final File depFile = _fileSystem.file('${dillFile.path}$_kDepfileSuffix');
        if (!dillFile.existsSync() || !depFile.existsSync() || dillFile.lengthSync() == 0) {
          return invalid;
        }
        _LocalStampData? localStamp;
        switch (target) {
          case _SharedDillTarget():
            break;
          case _LocalDillTarget(
            :final String closureHash,
            :final String sdkRevision,
            :final String sdkVersion,
            :final File stampFile,
          ):
            localStamp = _readLocalStamp(stampFile);
            if (localStamp == null ||
                localStamp.sdkRevision != sdkRevision ||
                localStamp.sdkVersion != sdkVersion ||
                localStamp.closureHash != closureHash) {
              return invalid;
            }
        }
        final Depfile depfile = _depfileService.parse(depFile);
        if (depfile.inputs.isEmpty) {
          return invalid;
        }
        final DateTime dillModified = dillFile.lastModifiedSync();
        final trackedFiles = <File>[
          if (target is _LocalDillTarget) packageConfigFile,
          entrypointFile,
        ];
        for (final file in trackedFiles) {
          if (file.existsSync() && file.lastModifiedSync().isAfter(dillModified)) {
            return invalid;
          }
        }
        for (final File input in depfile.inputs) {
          if (target is _SharedDillTarget && _isPackageConfigFile(input)) {
            continue;
          }
          if (!input.existsSync() || input.lastModifiedSync().isAfter(dillModified)) {
            return invalid;
          }
        }
        return (isValid: true, localStamp: localStamp);
      });
    } on FileSystemException {
      return invalid;
    } on FormatException {
      return invalid;
    }
  }

  _LocalStampData? _readLocalStamp(File stampFile) {
    try {
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        if (!stampFile.existsSync()) {
          return null;
        }
        final Object? decoded = jsonDecode(stampFile.readAsStringSync());
        if (decoded is! Map<String, Object?>) {
          return null;
        }
        final Object? sdkRevision = decoded[_kSdkRevisionStampKey];
        final Object? sdkVersion = decoded[_kSdkVersionStampKey];
        final Object? closureHash = decoded[_kClosureHashStampKey];
        if (sdkRevision is! String ||
            sdkRevision.isEmpty ||
            sdkVersion is! String ||
            sdkVersion.isEmpty ||
            closureHash is! String ||
            closureHash.isEmpty) {
          return null;
        }
        ToolExtensionCapabilities? capabilities;
        if (decoded[_kCapabilitiesStampKey] case final Map<String, Object?> rawCapabilities) {
          capabilities = _tryParseCapabilitiesMap(rawCapabilities);
        }
        return (
          capabilities: capabilities,
          closureHash: closureHash,
          sdkRevision: sdkRevision,
          sdkVersion: sdkVersion,
        );
      });
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  ToolExtensionCapabilities? _readCapabilitiesFile(File capabilitiesFile) {
    try {
      return ErrorHandlingFileSystem.noExitOnFailure(() {
        if (!capabilitiesFile.existsSync()) {
          return null;
        }
        final Object? decoded = jsonDecode(capabilitiesFile.readAsStringSync());
        if (decoded is! Map<String, Object?>) {
          return null;
        }
        return _tryParseCapabilitiesMap(decoded);
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
    required String closureHash,
    required String sdkRevision,
    required String sdkVersion,
    ToolExtensionCapabilities? capabilities,
  }) => <String, Object?>{
    _kSdkRevisionStampKey: sdkRevision,
    _kSdkVersionStampKey: sdkVersion,
    _kClosureHashStampKey: closureHash,
    if (capabilities != null) _kCapabilitiesStampKey: capabilities.toMap(),
  };

  bool _isPackageConfigFile(File file) =>
      _fileSystem.path.basename(file.path) == _kPackageConfigFileName &&
      _fileSystem.path.basename(file.parent.path) == _kDotDartToolDirectoryName;

  File _resolveDartSdkVersionFile() => _flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk')
      .childFile('version');

  File _resolveDartSdkRevisionFile() => _flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk')
      .childFile('revision');
}
