// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:dart_data_home/dart_data_home.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

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
  static const String _kPackageGraphFileName = 'package_graph.json';
  static const String _kPackageConfigFileName = 'package_config.json';
  static const String _kDotDartToolDirectoryName = '.dart_tool';
  static const String _kPubCacheExtraDataKey = 'pubCache';
  static final _kUnsupportedLabelChars = RegExp(r'[^a-zA-Z0-9._+-]');

  final Artifacts _artifacts;
  final DepfileService _depfileService;
  final FileSystem _fileSystem;
  final Directory _flutterRoot;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;

  /// Compiles [extension] to a `.dill` file (or returns the cached `.dill` URI
  /// if up to date).
  ///
  /// Throws an [ExtensionCompileException] if compilation fails.
  Future<Uri> compile(DiscoveredProjectExtension extension) async {
    try {
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

      final (File dillFile, bool isSharedCache, String sdkRevision) = _resolveDillTarget(extension);
      final File depFile = _fileSystem.file('${dillFile.path}.d');
      final File revisionStampFile = _fileSystem.file('${dillFile.path}.revision');

      if (_isCachedDillValid(
        depFile: depFile,
        dillFile: dillFile,
        entrypointFile: entrypointFile,
        isSharedCache: isSharedCache,
        packageConfigFile: packageConfigFile,
        revisionStampFile: revisionStampFile,
        sdkRevision: sdkRevision,
      )) {
        return dillFile.absolute.uri;
      }

      dillFile.parent.createSync(recursive: true);
      return await _fileSystem.runLocked<Uri>(
        lockPath: '${dillFile.path}.lock',
        logger: _logger,
        scope: () async {
          if (_isCachedDillValid(
            depFile: depFile,
            dillFile: dillFile,
            entrypointFile: entrypointFile,
            isSharedCache: isSharedCache,
            packageConfigFile: packageConfigFile,
            revisionStampFile: revisionStampFile,
            sdkRevision: sdkRevision,
          )) {
            return dillFile.absolute.uri;
          }

          final File tempDillFile = _fileSystem.file('${dillFile.path}.tmp');
          final File tempDepFile = _fileSystem.file('${depFile.path}.tmp');
          final File tempRevisionFile = _fileSystem.file('${revisionStampFile.path}.tmp');
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

            if (!tempDillFile.existsSync() || tempDillFile.lengthSync() == 0) {
              throw ExtensionCompileException(
                'Failed to compile extension "${extension.name}" to kernel: '
                'compiler exited 0 but did not produce a non-empty "${tempDillFile.path}".',
              );
            }

            if (tempDepFile.existsSync()) {
              tempDepFile.renameSync(depFile.path);
            } else {
              ErrorHandlingFileSystem.deleteIfExists(depFile);
            }
            tempDillFile.renameSync(dillFile.path);
            tempRevisionFile
              ..writeAsStringSync(sdkRevision)
              ..renameSync(revisionStampFile.path);
            return dillFile.absolute.uri;
          } finally {
            _cleanupTempFiles(<File>[tempDillFile, tempDepFile, tempRevisionFile]);
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
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required bool isSharedCache,
    required File packageConfigFile,
    required File revisionStampFile,
    required String sdkRevision,
  }) {
    if (!_needsRecompilation(
      depFile: depFile,
      dillFile: dillFile,
      entrypointFile: entrypointFile,
      isSharedCache: isSharedCache,
      packageConfigFile: packageConfigFile,
      revisionStampFile: revisionStampFile,
      sdkRevision: sdkRevision,
    )) {
      _logger.printTrace(
        isSharedCache
            ? 'ExtensionKernelCompiler: reusing cached pub-cache kernel "${dillFile.path}".'
            : 'ExtensionKernelCompiler: reusing up-to-date local kernel "${dillFile.path}".',
      );
      return true;
    }
    return false;
  }

  /// Determines whether [extension]'s package root resides inside `$PUB_CACHE`
  /// and its resolved dependency closure resides inside `$PUB_CACHE` or the
  /// Flutter SDK.
  @visibleForTesting
  bool isPubCacheExtension(DiscoveredProjectExtension extension) {
    final (bool isPubCache, _) = _evaluatePubCacheClosure(extension);
    return isPubCache;
  }

  (bool isPubCache, List<Package> closurePackages) _evaluatePubCacheClosure(
    DiscoveredProjectExtension extension,
  ) {
    final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
    final PackageConfig? packageConfig = packageConfigFile.existsSync()
        ? _parsePackageConfig(packageConfigFile, extensionName: extension.name)
        : null;
    final Directory? pubCacheDir = _resolvePubCacheDirectory(packageConfig);
    if (pubCacheDir == null) {
      return (false, const <Package>[]);
    }
    final String normalizedPubCache = _fileSystem.path.normalize(pubCacheDir.absolute.path);
    final String rootPath = _fileSystem.directory(extension.rootUri).absolute.path;
    if (!_isWithinDirectory(rootPath, normalizedPubCache)) {
      return (false, const <Package>[]);
    }
    if (packageConfig == null) {
      return (false, const <Package>[]);
    }
    final Set<String>? closureNames = _extensionClosure(packageConfigFile, extension.name);
    if (closureNames == null) {
      return (false, const <Package>[]);
    }
    final String normalizedFlutterRoot = _fileSystem.path.normalize(_flutterRoot.absolute.path);
    final closurePackages = <Package>[];
    for (final String name in closureNames) {
      final Package? pkg = packageConfig[name];
      if (pkg == null) {
        return (false, const <Package>[]);
      }
      final String pkgRootPath = _fileSystem.directory(pkg.root).absolute.path;
      if (!_isWithinDirectory(pkgRootPath, normalizedPubCache) &&
          !_isWithinDirectory(pkgRootPath, normalizedFlutterRoot)) {
        return (false, const <Package>[]);
      }
      closurePackages.add(pkg);
    }
    return (true, closurePackages);
  }

  bool _isWithinDirectory(String candidatePath, String normalizedParentPath) {
    final String normalizedCandidate = _fileSystem.path.normalize(candidatePath);
    return _fileSystem.path.isWithin(normalizedParentPath, normalizedCandidate) ||
        _fileSystem.path.equals(normalizedParentPath, normalizedCandidate);
  }

  PackageConfig _parsePackageConfig(File packageConfigFile, {required String extensionName}) {
    try {
      return PackageConfig.parseString(
        packageConfigFile.readAsStringSync(),
        packageConfigFile.absolute.uri,
      );
    } on FormatException catch (error) {
      throw ExtensionCompileException(
        'Failed to parse package_config.json for extension "$extensionName" at '
        '"${packageConfigFile.path}": $error',
      );
    } on FileSystemException catch (error) {
      throw ExtensionCompileException(
        'Failed to read package_config.json for extension "$extensionName" at '
        '"${packageConfigFile.path}": $error',
      );
    }
  }

  Set<String>? _extensionClosure(File packageConfigFile, String extensionName) {
    final File graphFile = packageConfigFile.parent.childFile(_kPackageGraphFileName);
    if (!graphFile.existsSync()) {
      return null;
    }
    final PackageGraph graph;
    try {
      graph = PackageGraph.fromJson(graphFile, jsonDecode(graphFile.readAsStringSync()));
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
    if (!graph.dependencies.containsKey(extensionName)) {
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

  /// Resolves the Pub cache directory from [packageConfig]'s `pubCache` metadata
  /// if present, falling back to `SystemCache.defaultDir` in `package:pub`
  /// (`PUB_CACHE`, `%LOCALAPPDATA%\Pub\Cache` on Windows, or `$HOME/.pub-cache`
  /// on POSIX).
  Directory? _resolvePubCacheDirectory(PackageConfig? packageConfig) {
    if (packageConfig?.extraData case {_kPubCacheExtraDataKey: final String pubCacheUriStr}) {
      if (Uri.tryParse(pubCacheUriStr) case final Uri uri when uri.isScheme('file')) {
        return _fileSystem.directory(uri);
      }
    }
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
    final (File dillFile, _, _) = _resolveDillTarget(extension);
    return dillFile;
  }

  (File dillFile, bool isSharedCache, String sdkRevision) _resolveDillTarget(
    DiscoveredProjectExtension extension,
  ) {
    final String sdkRevision = _dartSdkRevision(extension);
    final (bool isPubCache, List<Package> closurePackages) = _evaluatePubCacheClosure(extension);
    if (isPubCache) {
      final Directory cacheDir = _resolveSharedCacheDirectory();
      final String sdkKey = _computeSdkAndPackageKey(
        extension,
        closurePackages: closurePackages,
        sdkRevision: sdkRevision,
      );
      return (cacheDir.childFile('${extension.name}-$sdkKey.dill'), true, sdkRevision);
    }
    final File localDill = _fileSystem
        .directory(extension.workspaceRootPath)
        .childDirectory(_kDotDartToolDirectoryName)
        .childDirectory('flutter_tools')
        .childDirectory('extensions')
        .childDirectory(extension.name)
        .childFile('extension.dill');
    return (localDill, false, sdkRevision);
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

  String _computeSdkAndPackageKey(
    DiscoveredProjectExtension extension, {
    required List<Package> closurePackages,
    required String sdkRevision,
  }) {
    final String entrypointPath = _fileSystem.path.normalize(
      _fileSystem.file(extension.entrypointUri).absolute.path,
    );
    final packageDescriptors = <String>[
      for (final pkg in closurePackages)
        '${pkg.name}:${_fileSystem.path.normalize(_fileSystem.directory(pkg.root).absolute.path)}:${_fileSystem.path.normalize(_fileSystem.directory(pkg.packageUriRoot).absolute.path)}',
    ]..sort();
    final String payload = <String>[
      'revision=$sdkRevision',
      'entrypoint=$entrypointPath',
      ...packageDescriptors,
    ].join('|');
    final combinedHash = sha256.convert(utf8.encode(payload)).toString();
    final String rawSdkLabel = _readNonEmptyTrimmed(_resolveDartSdkVersionFile()) ?? sdkRevision;
    final String sanitizedVersion = rawSdkLabel.replaceAll(_kUnsupportedLabelChars, '_');
    return '$sanitizedVersion-$combinedHash';
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

  static String? _readNonEmptyTrimmed(File file) {
    if (!file.existsSync()) {
      return null;
    }
    final String value = file.readAsStringSync().trim();
    return value.isNotEmpty ? value : null;
  }

  bool _needsRecompilation({
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required bool isSharedCache,
    required File packageConfigFile,
    required File revisionStampFile,
    required String sdkRevision,
  }) {
    if (!dillFile.existsSync() || !depFile.existsSync() || dillFile.lengthSync() == 0) {
      return true;
    }
    if (_readNonEmptyTrimmed(revisionStampFile) != sdkRevision) {
      return true;
    }
    final Depfile depfile = _depfileService.parse(depFile);
    if (depfile.inputs.isEmpty) {
      return true;
    }
    final DateTime dillModified = dillFile.lastModifiedSync();
    final trackedFiles = <File>[if (!isSharedCache) packageConfigFile, entrypointFile];
    for (final file in trackedFiles) {
      if (file.existsSync() && file.lastModifiedSync().isAfter(dillModified)) {
        return true;
      }
    }
    for (final File input in depfile.inputs) {
      if (isSharedCache && _isPackageConfigFile(input)) {
        continue;
      }
      if (!input.existsSync() || input.lastModifiedSync().isAfter(dillModified)) {
        return true;
      }
    }
    return false;
  }

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
