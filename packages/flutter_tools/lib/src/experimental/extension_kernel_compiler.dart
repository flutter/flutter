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
import '../cache.dart';
import 'project_extension_finder.dart';

/// Signature for compiling a [DiscoveredProjectExtension] to a runnable Kernel (`.dill`) URI.
typedef ExtensionKernelCompileFn = Future<Uri> Function(DiscoveredProjectExtension extension);

/// Compiles discovered tool extension entrypoints to `.dill` Kernel files and
/// manages caching across `$PUB_CACHE` and local workspace packages.
class ExtensionKernelCompiler {
  ExtensionKernelCompiler({
    required this._artifacts,
    required this._fileSystem,
    required this._logger,
    required this._platform,
    required this._processManager,
    this._flutterRoot,
  });

  /// Environment variable overriding the shared Dart data directory.
  static const String kDartDataHomeEnv = 'DART_DATA_HOME';

  /// Environment variable overriding the Pub cache directory.
  static const String kPubCacheEnv = 'PUB_CACHE';

  final Artifacts _artifacts;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final String? _flutterRoot;

  /// Compiles [extension] to a `.dill` file (or returns the cached `.dill` URI
  /// if up to date).
  Future<Uri> compile(DiscoveredProjectExtension extension) async {
    final File entrypointFile = _fileSystem.file(extension.entrypointUri);
    if (!entrypointFile.existsSync()) {
      throw StateError(
        'Extension "${extension.name}" entrypoint not found at "${entrypointFile.path}".',
      );
    }

    final File packageConfigFile = _fileSystem.file(extension.packageConfigUri);
    if (!packageConfigFile.existsSync()) {
      throw StateError(
        'Cannot compile extension "${extension.name}" without a resolved '
        '.dart_tool/package_config.json at "${packageConfigFile.path}".',
      );
    }

    final File dillFile = resolveDillFile(extension);
    final File depFile = _fileSystem.file('${dillFile.path}.d');
    final bool isImmutableCache = isPubCacheExtension(extension);

    if (isImmutableCache) {
      if (dillFile.existsSync() && dillFile.lengthSync() > 0) {
        _logger.printTrace(
          'ExtensionKernelCompiler: reusing cached pub-cache kernel "${dillFile.path}".',
        );
        return dillFile.absolute.uri;
      }
    } else if (!_needsRecompilation(
      dillFile: dillFile,
      depFile: depFile,
      packageConfigFile: packageConfigFile,
      entrypointFile: entrypointFile,
    )) {
      _logger.printTrace(
        'ExtensionKernelCompiler: reusing up-to-date local kernel "${dillFile.path}".',
      );
      return dillFile.absolute.uri;
    }

    dillFile.parent.createSync(recursive: true);
    return _fileSystem.runLocked<Uri>(
      lockPath: '${dillFile.path}.lock',
      logger: _logger,
      scope: () async {
        if (isImmutableCache) {
          if (dillFile.existsSync() && dillFile.lengthSync() > 0) {
            _logger.printTrace(
              'ExtensionKernelCompiler: reusing cached pub-cache kernel "${dillFile.path}".',
            );
            return dillFile.absolute.uri;
          }
        } else if (!_needsRecompilation(
          dillFile: dillFile,
          depFile: depFile,
          packageConfigFile: packageConfigFile,
          entrypointFile: entrypointFile,
        )) {
          _logger.printTrace(
            'ExtensionKernelCompiler: reusing up-to-date local kernel "${dillFile.path}".',
          );
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
          throw StateError(
            'Failed to compile extension "${extension.name}" to kernel '
            '(exit code ${result.exitCode}):\n${result.stderr}',
          );
        }

        if (tempDepFile.existsSync()) {
          tempDepFile.renameSync(depFile.path);
        }
        if (tempDillFile.existsSync()) {
          tempDillFile.renameSync(dillFile.path);
        }
        return dillFile.absolute.uri;
      },
    );
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

  /// Determines whether [extension]'s package root resides inside `$PUB_CACHE`.
  @visibleForTesting
  bool isPubCacheExtension(DiscoveredProjectExtension extension) {
    final String rootPath = _fileSystem.path.normalize(
      _fileSystem.directory(extension.rootUri).absolute.path,
    );
    final String? pubCacheEnv = _platform.environment[kPubCacheEnv]?.trim();
    if (pubCacheEnv != null && pubCacheEnv.isNotEmpty) {
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
      final Directory cacheDir = _resolveSharedCacheDirectory();
      final String sdkKey = _computeSdkAndPackageKey(extension);
      return cacheDir.childFile('${extension.name}-$sdkKey.dill');
    }
    return _fileSystem
        .directory(extension.workspaceRootPath)
        .childDirectory('.dart_tool')
        .childDirectory('flutter_tools')
        .childDirectory('extensions')
        .childDirectory(extension.name)
        .childFile('extension.dill');
  }

  Directory _resolveSharedCacheDirectory() {
    final String? dartDataHome = _platform.environment[kDartDataHomeEnv]?.trim();
    if (dartDataHome != null && dartDataHome.isNotEmpty) {
      return _fileSystem
          .directory(dartDataHome)
          .childDirectory('flutter_tool_extensions')
          .childDirectory('cache');
    }
    if (_platform.isWindows) {
      final String? localAppData =
          _platform.environment['LOCALAPPDATA']?.trim() ?? _platform.environment['APPDATA']?.trim();
      if (localAppData != null && localAppData.isNotEmpty) {
        return _fileSystem
            .directory(localAppData)
            .childDirectory('flutter_tool_extensions')
            .childDirectory('cache');
      }
    }
    final String? home =
        _platform.environment['HOME']?.trim() ?? _platform.environment['USERPROFILE']?.trim();
    if (home != null && home.isNotEmpty) {
      return _fileSystem
          .directory(home)
          .childDirectory('.flutter_tool_extensions')
          .childDirectory('cache');
    }
    return _fileSystem.systemTempDirectory
        .childDirectory('flutter_tool_extensions')
        .childDirectory('cache');
  }

  String _computeSdkAndPackageKey(DiscoveredProjectExtension extension) {
    final File? versionFile = _resolveDartSdkVersionFile();
    final String sdkVersion = versionFile != null && versionFile.existsSync()
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

    final File? sdkVersionFile = _resolveDartSdkVersionFile();
    if (sdkVersionFile != null &&
        sdkVersionFile.existsSync() &&
        sdkVersionFile.lastModifiedSync().isAfter(dillModified)) {
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

  File? _resolveDartSdkVersionFile() {
    final String? flutterRoot = _flutterRoot ?? Cache.flutterRoot;
    if (flutterRoot == null || flutterRoot.isEmpty) {
      return null;
    }
    return _fileSystem.file(
      _fileSystem.path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'version'),
    );
  }

  String _resolveDartExecutable() => _artifacts.getArtifactPath(Artifact.engineDartBinary);
}
