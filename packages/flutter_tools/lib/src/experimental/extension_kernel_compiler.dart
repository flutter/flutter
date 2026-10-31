// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
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
  });

  /// Environment variable overriding the shared Dart data directory.
  static const String kDartDataHomeEnv = 'DART_DATA_HOME';

  /// Environment variable overriding the Pub cache directory.
  static const String kPubCacheEnv = 'PUB_CACHE';

  final Artifacts _artifacts;
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

    final File dillFile = resolveDillFile(extension);
    final File depFile = _fileSystem.file('${dillFile.path}.d');
    final bool isImmutableCache = isPubCacheExtension(extension);

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
        final String dartExecutable = _resolveDartExecutable();
        final command = <String>[
          dartExecutable,
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
          _tryDeleteFile(tempDillFile);
          _tryDeleteFile(tempDepFile);
          throw ExtensionCompileException(
            'Failed to compile extension "${extension.name}" to kernel '
            '(exit code ${result.exitCode}):\n${result.stderr}',
          );
        }

        if (!tempDillFile.existsSync()) {
          _tryDeleteFile(tempDepFile);
          throw ExtensionCompileException(
            'Failed to compile extension "${extension.name}" to kernel: '
            'compiler exited 0 but did not produce "${tempDillFile.path}".',
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

  static void _tryDeleteFile(File file) {
    if (!file.existsSync()) {
      return;
    }
    try {
      file.deleteSync();
    } on FileSystemException {
      // Best-effort cleanup of incomplete kernel output.
    }
  }

  /// Determines whether [extension]'s package root resides inside `$PUB_CACHE`
  /// (checking [kPubCacheEnv] first, then standard `.pub-cache` and Windows
  /// `Pub/Cache` directory segments).
  @visibleForTesting
  bool isPubCacheExtension(DiscoveredProjectExtension extension) {
    final String rootPath = _fileSystem.path.normalize(
      _fileSystem.directory(extension.rootUri).absolute.path,
    );
    final String? pubCacheEnv = _nonEmptyEnv(kPubCacheEnv);
    if (pubCacheEnv != null) {
      final String normalizedPubCache = _fileSystem.path.normalize(
        _fileSystem.directory(pubCacheEnv).absolute.path,
      );
      if (_fileSystem.path.isWithin(normalizedPubCache, rootPath) ||
          _fileSystem.path.equals(normalizedPubCache, rootPath)) {
        return true;
      }
    }
    final List<String> segments = _fileSystem.path.split(rootPath);
    if (segments.contains('.pub-cache')) {
      return true;
    }
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'Pub' && segments[i + 1] == 'Cache') {
        return true;
      }
    }
    return false;
  }

  /// Resolves the target `.dill` cache [File] for [extension].
  @visibleForTesting
  File resolveDillFile(DiscoveredProjectExtension extension) {
    if (isPubCacheExtension(extension)) {
      if (_resolveSharedCacheDirectory() case final Directory cacheDir) {
        final String sdkKey = _computeSdkAndPackageKey(extension);
        return cacheDir.childFile('${extension.name}-$sdkKey.dill');
      }
    }
    return _fileSystem
        .directory(extension.workspaceRootPath)
        .childDirectory('.dart_tool')
        .childDirectory('flutter_tools')
        .childDirectory('extensions')
        .childDirectory(extension.name)
        .childFile('extension.dill');
  }

  Directory? _resolveSharedCacheDirectory() {
    if (_nonEmptyEnv(kDartDataHomeEnv) case final String dartDataHome) {
      return _fileSystem
          .directory(dartDataHome)
          .childDirectory('flutter_tool_extensions')
          .childDirectory('cache');
    }
    if (_platform.isWindows) {
      final String? localAppData = _nonEmptyEnv('LOCALAPPDATA') ?? _nonEmptyEnv('APPDATA');
      if (localAppData != null) {
        return _fileSystem
            .directory(localAppData)
            .childDirectory('flutter_tool_extensions')
            .childDirectory('cache');
      }
    }
    final String? home = _nonEmptyEnv('HOME') ?? _nonEmptyEnv('USERPROFILE');
    if (home != null) {
      return _fileSystem
          .directory(home)
          .childDirectory('.flutter_tool_extensions')
          .childDirectory('cache');
    }
    return null;
  }

  String? _nonEmptyEnv(String key) {
    final String? value = _platform.environment[key]?.trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  String _computeSdkAndPackageKey(DiscoveredProjectExtension extension) {
    final File versionFile = _resolveDartSdkVersionFile();
    final String sdkVersion = versionFile.existsSync()
        ? versionFile.readAsStringSync().trim()
        : 'unknown';
    final String rootPath = _fileSystem.directory(extension.rootUri).absolute.path;
    final int combinedHash = _fnv1a32('$sdkVersion|$rootPath');
    final String sanitizedVersion = sdkVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$sanitizedVersion-${combinedHash.toRadixString(16).padLeft(8, '0')}';
  }

  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final int unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  bool _needsRecompilation({
    required File depFile,
    required File dillFile,
    required File entrypointFile,
    required File packageConfigFile,
  }) {
    if (!dillFile.existsSync() || !depFile.existsSync()) {
      return true;
    }

    final DateTime dillModified = dillFile.lastModifiedSync();

    if (packageConfigFile.existsSync() &&
        packageConfigFile.lastModifiedSync().isAfter(dillModified)) {
      return true;
    }

    if (entrypointFile.existsSync() && entrypointFile.lastModifiedSync().isAfter(dillModified)) {
      return true;
    }

    final File sdkVersionFile = _resolveDartSdkVersionFile();
    if (sdkVersionFile.existsSync() && sdkVersionFile.lastModifiedSync().isAfter(dillModified)) {
      return true;
    }

    final List<String> dependencies = parseDepfileDependencies(depFile.readAsStringSync());
    if (dependencies.isEmpty) {
      return true;
    }

    for (final depPath in dependencies) {
      final File sourceFile = _fileSystem.file(depPath);
      if (!sourceFile.existsSync() || sourceFile.lastModifiedSync().isAfter(dillModified)) {
        return true;
      }
    }

    return false;
  }

  /// Parses dependency file paths from a Makefile-style `.d` depfile emitted by
  /// `dart compile kernel --depfile`.
  @visibleForTesting
  static List<String> parseDepfileDependencies(String content) {
    // Strip line continuations.
    final String normalized = content.replaceAll('\\\r\n', ' ').replaceAll('\\\n', ' ');
    // Locate the target separator ': ' (avoiding Windows drive letters like 'C:\').
    var colonIndex = -1;
    for (var i = 0; i < normalized.length; i++) {
      if (normalized[i] == ':') {
        final bool isNextWhitespaceOrEnd =
            i + 1 == normalized.length ||
            normalized[i + 1] == ' ' ||
            normalized[i + 1] == '\t' ||
            normalized[i + 1] == '\n' ||
            normalized[i + 1] == '\r';
        if (isNextWhitespaceOrEnd) {
          colonIndex = i;
          break;
        }
      }
    }
    if (colonIndex < 0 || colonIndex + 1 >= normalized.length) {
      return const <String>[];
    }

    final String rhs = normalized.substring(colonIndex + 1);
    final results = <String>[];
    final current = StringBuffer();
    var i = 0;
    while (i < rhs.length) {
      final String ch = rhs[i];
      if (ch == r'\' && i + 1 < rhs.length && rhs[i + 1] == ' ') {
        current.write(' ');
        i += 2;
        continue;
      }
      if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
        if (current.isNotEmpty) {
          results.add(current.toString());
          current.clear();
        }
        i++;
        continue;
      }
      current.write(ch);
      i++;
    }
    if (current.isNotEmpty) {
      results.add(current.toString());
    }
    return results;
  }

  File _resolveDartSdkVersionFile() {
    return _flutterRoot
        .childDirectory('bin')
        .childDirectory('cache')
        .childDirectory('dart-sdk')
        .childFile('version');
  }

  String _resolveDartExecutable() => _artifacts.getArtifactPath(Artifact.engineDartBinary);
}
