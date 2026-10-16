// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying, downloading, and verifying custom artifacts required by
/// tool extensions in a shared content-addressed cache.
class ExtensionArtifactManager {
  ExtensionArtifactManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._fileSystem,
    required this._logger,
    required this._osUtils,
    required this._platform,
    this._cacheDir,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Logger _logger;
  final OperatingSystemUtils _osUtils;
  final Platform _platform;
  final Directory? _cacheDir;
  final HttpClient _httpClient;

  final _inFlightDownloads = <String, Future<void>>{};

  /// Returns the root shared content-addressed cache directory for tool extension artifacts.
  ///
  /// Resolution order:
  /// 1. Explicit `cacheDir` constructor override (used for hermetic testing).
  /// 2. `$DART_DATA_HOME/flutter_tool_extensions/artifacts` when `DART_DATA_HOME` is set.
  /// 3. `%LOCALAPPDATA%\flutter_tool_extensions\artifacts` (or
  ///    `%USERPROFILE%\.flutter_tool_extensions\artifacts`) on Windows, or
  ///    `$HOME/.flutter_tool_extensions/artifacts` on POSIX platforms.
  /// 4. `<systemTempDirectory>/.flutter_tool_extensions/artifacts` if no home
  ///    environment variable is set.
  Directory get artifactsCacheDirectory {
    if (_cacheDir case final Directory dir) {
      return dir;
    }
    final String? dartDataHome = _platform.environment['DART_DATA_HOME'];
    if (dartDataHome != null && dartDataHome.trim().isNotEmpty) {
      return _fileSystem.directory(
        _fileSystem.path.join(dartDataHome.trim(), 'flutter_tool_extensions', 'artifacts'),
      );
    }
    if (_platform.isWindows) {
      final String? localAppData = _platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        return _fileSystem.directory(
          _fileSystem.path.join(localAppData.trim(), 'flutter_tool_extensions', 'artifacts'),
        );
      }
      final String? userProfile = _platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        return _fileSystem.directory(
          _fileSystem.path.join(userProfile.trim(), '.flutter_tool_extensions', 'artifacts'),
        );
      }
    }
    final String? home = _platform.environment['HOME'];
    if (home != null && home.trim().isNotEmpty) {
      return _fileSystem.directory(
        _fileSystem.path.join(home.trim(), '.flutter_tool_extensions', 'artifacts'),
      );
    }
    return _fileSystem.systemTempDirectory
        .childDirectory('.flutter_tool_extensions')
        .childDirectory('artifacts');
  }

  /// Returns the content-addressed directory `<cacheDir>/<extensionName>/<sha256>`
  /// for the given [extensionName] and [sha256].
  Directory artifactShaDirectory({required String extensionName, required String sha256}) {
    return artifactsCacheDirectory
        .childDirectory(extensionName)
        .childDirectory(sha256.toLowerCase());
  }

  /// Queries all active extensions implementing [ArtifactService] and ensures
  /// required artifacts for the current host platform and optional [targetPlatforms]
  /// are downloaded and verified in the shared content-addressed cache.
  Future<void> ensureArtifactsDownloaded({Set<String>? targetPlatforms}) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return;
    }

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager for artifacts: $e');
      return;
    }

    final artifactExtensions = <ExtensionConnection>[
      for (final ext in _extensionManager.connections)
        if (ext.capabilities.services.contains(ArtifactService.serviceNamespace)) ext,
    ];

    if (artifactExtensions.isEmpty) {
      return;
    }

    final HostPlatform currentHostPlatform = _osUtils.hostPlatform;

    for (final ext in artifactExtensions) {
      final List<ArtifactDependency> dependencies;
      try {
        final Object? result = await ext.sendRequest(
          ArtifactService.downloadArtifactsMethod,
          params: <String, Object?>{
            ArtifactService.hostPlatformParam: currentHostPlatform.cliName,
            if (targetPlatforms?.length == 1)
              ArtifactService.targetPlatformParam: targetPlatforms!.single,
          },
          timeout: null,
        );
        dependencies = ArtifactDependency.listFromJson(result);
      } on Object catch (e) {
        _logger.printTrace('Failed to query artifacts from extension "${ext.extensionName}": $e');
        continue;
      }

      final filteredDeps = <ArtifactDependency>[
        for (final dep in dependencies)
          if (_matchesPlatforms(
            dep,
            currentHostPlatform: currentHostPlatform,
            targetPlatforms: targetPlatforms,
          ))
            dep,
      ];

      for (final dep in filteredDeps) {
        await _ensureArtifactCached(ext.extensionName, dep);
      }
    }
  }

  bool _matchesPlatforms(
    ArtifactDependency dep, {
    required HostPlatform currentHostPlatform,
    required Set<String>? targetPlatforms,
  }) {
    if (dep.hostPlatform != null && dep.hostPlatform != currentHostPlatform) {
      return false;
    }
    if (targetPlatforms != null && dep.targetPlatform != null) {
      final String depTarget = dep.targetPlatform!;
      final bool matched =
          targetPlatforms.contains(depTarget) ||
          targetPlatforms.any((String p) => depTarget.startsWith('$p-'));
      if (!matched) {
        return false;
      }
    }
    return true;
  }

  Future<void> _ensureArtifactCached(String extensionName, ArtifactDependency dep) async {
    final String expectedSha = dep.sha256.toLowerCase();
    final cacheKey = '$extensionName/$expectedSha/${dep.name}';
    if (_inFlightDownloads[cacheKey] case final Future<void> existing) {
      await existing;
      return;
    }

    final Future<void> downloadFuture = _downloadAndVerifyArtifact(extensionName, dep, expectedSha);
    _inFlightDownloads[cacheKey] = downloadFuture;
    try {
      await downloadFuture;
    } finally {
      unawaited(_inFlightDownloads.remove(cacheKey));
    }
  }

  Future<void> _downloadAndVerifyArtifact(
    String extensionName,
    ArtifactDependency dep,
    String expectedSha,
  ) async {
    final Directory shaDir = artifactShaDirectory(
      extensionName: extensionName,
      sha256: expectedSha,
    );
    final File artifactFile = shaDir.childFile(dep.name);
    final Directory artifactDirAsDir = shaDir.childDirectory(dep.name);
    final File stampFile = shaDir.childFile('.${dep.name}.sha256');

    // Verify existing file or unzipped directory in the content-addressed cache.
    if (artifactFile.existsSync()) {
      final Digest existingDigest = await sha256.bind(artifactFile.openRead()).first;
      if (existingDigest.toString().toLowerCase() == expectedSha) {
        _logger.printTrace(
          'Artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
        );
        return;
      }
      _logger.printTrace(
        'Cached artifact "${dep.name}" failed SHA-256 verification; re-downloading.',
      );
      artifactFile.deleteSync();
    } else if (stampFile.existsSync() && artifactDirAsDir.existsSync()) {
      final String existingSha = stampFile.readAsStringSync().trim().toLowerCase();
      if (existingSha == expectedSha) {
        _logger.printTrace(
          'Unzipped artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
        );
        return;
      }
      _logger.printTrace(
        'Cached unzipped artifact "${dep.name}" failed SHA-256 verification; re-downloading.',
      );
      artifactDirAsDir.deleteSync(recursive: true);
      stampFile.deleteSync();
    }

    shaDir.createSync(recursive: true);
    final Directory stagingDir = shaDir.createTempSync('.tmp_${dep.name}_');
    final File stagingFile = stagingDir.childFile(dep.name);

    final Status status = _logger.startProgress(
      'Downloading artifact "${dep.name}" for extension "$extensionName"...',
    );
    try {
      final HttpClientRequest request = await _httpClient.getUrl(dep.url);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throwToolExit(
          'Failed to download artifact "${dep.name}" from ${dep.url}: '
          'HTTP ${response.statusCode}',
        );
      }

      final IOSink sink = stagingFile.openWrite();
      final digestSink = _AccumulatorSink<Digest>();
      final ByteConversionSink hashSink = sha256.startChunkedConversion(digestSink);

      await for (final List<int> chunk in response) {
        sink.add(chunk);
        hashSink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      hashSink.close();

      final Digest actualDigest = digestSink.events.single;
      if (actualDigest.toString().toLowerCase() != expectedSha) {
        throwToolExit(
          'SHA-256 checksum mismatch for artifact "${dep.name}" from ${dep.url}.\n'
          'Expected: ${dep.sha256}\n'
          'Actual:   $actualDigest',
        );
      }

      if (dep.url.path.endsWith('.zip')) {
        final Directory extractedDir = stagingDir.childDirectory('extracted')
          ..createSync(recursive: true);
        _osUtils.unzip(stagingFile, extractedDir);
        if (artifactDirAsDir.existsSync()) {
          artifactDirAsDir.deleteSync(recursive: true);
        }
        extractedDir.renameSync(artifactDirAsDir.path);
        stampFile.writeAsStringSync(expectedSha);
      } else {
        if (artifactFile.existsSync()) {
          artifactFile.deleteSync();
        }
        stagingFile.renameSync(artifactFile.path);
      }
    } finally {
      status.stop();
      if (stagingDir.existsSync()) {
        stagingDir.deleteSync(recursive: true);
      }
    }
  }
}

class _AccumulatorSink<T> implements Sink<T> {
  final events = <T>[];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
