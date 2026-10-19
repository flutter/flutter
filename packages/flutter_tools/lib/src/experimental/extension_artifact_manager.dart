// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying, downloading, and verifying custom artifacts required by
/// tool extensions in a shared content-addressed cache.
class ExtensionArtifactManager {
  ExtensionArtifactManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._toolContext,
    this._cacheDir,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  static const String _dartDataHomeEnvKey = 'DART_DATA_HOME';
  static const String _localAppDataEnvKey = 'LOCALAPPDATA';
  static const String _userProfileEnvKey = 'USERPROFILE';
  static const String _homeEnvKey = 'HOME';
  static const String _extensionsCacheDirName = 'flutter_tool_extensions';
  static const String _hiddenExtensionsCacheDirName = '.flutter_tool_extensions';
  static const String _artifactsCacheSubdirName = 'artifacts';
  static const String _zipExtension = '.zip';
  static const String _extractedDirName = 'extracted';
  static const String _sha256StampSuffix = '.sha256';
  static const String _lockFileSuffix = '.lock';

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;
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
    final ToolContext(:FileSystem fs, :Platform platform) = _toolContext;
    final String? dartDataHome = platform.environment[_dartDataHomeEnvKey];
    if (dartDataHome != null && dartDataHome.trim().isNotEmpty) {
      return fs.directory(
        fs.path.join(dartDataHome.trim(), _extensionsCacheDirName, _artifactsCacheSubdirName),
      );
    }
    if (platform.isWindows) {
      final String? localAppData = platform.environment[_localAppDataEnvKey];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        return fs.directory(
          fs.path.join(localAppData.trim(), _extensionsCacheDirName, _artifactsCacheSubdirName),
        );
      }
      final String? userProfile = platform.environment[_userProfileEnvKey];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        return fs.directory(
          fs.path.join(
            userProfile.trim(),
            _hiddenExtensionsCacheDirName,
            _artifactsCacheSubdirName,
          ),
        );
      }
    }
    final String? home = platform.environment[_homeEnvKey];
    if (home != null && home.trim().isNotEmpty) {
      return fs.directory(
        fs.path.join(home.trim(), _hiddenExtensionsCacheDirName, _artifactsCacheSubdirName),
      );
    }
    return fs.systemTempDirectory
        .childDirectory(_hiddenExtensionsCacheDirName)
        .childDirectory(_artifactsCacheSubdirName);
  }

  /// Returns the content-addressed directory `<cacheDir>/<extensionName>/<sha256>`
  /// for the given [extensionName] and [sha256].
  ///
  /// Throws an [ArgumentError] if [extensionName] or [sha256] is not a valid
  /// single path segment.
  Directory artifactShaDirectory({required String extensionName, required String sha256}) {
    if (!ArtifactDependency.isValidSinglePathSegment(extensionName)) {
      throw ArgumentError.value(
        extensionName,
        'extensionName',
        'Must be a valid single path segment.',
      );
    }
    if (!ArtifactDependency.isValidSinglePathSegment(sha256)) {
      throw ArgumentError.value(sha256, 'sha256', 'Must be a valid single path segment.');
    }
    return artifactsCacheDirectory
        .childDirectory(extensionName)
        .childDirectory(sha256.toLowerCase());
  }

  /// Queries all active extensions implementing [ArtifactService] and ensures
  /// required artifacts for the current host platform and optional [targetPlatforms]
  /// are downloaded and verified in the shared content-addressed cache.
  ///
  /// When [force] is `true`, existing cached artifacts are re-downloaded.
  Future<void> ensureArtifactsDownloaded({Set<String>? targetPlatforms, bool force = false}) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return;
    }
    final ToolContext(:Logger logger, :OperatingSystemUtils os) = _toolContext;

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      logger.printTrace('Failed to initialize extension manager for artifacts: $e');
      return;
    }

    final artifactExtensions = <ExtensionConnection>[
      for (final ext in _extensionManager.connections)
        if (ext.capabilities.services.contains(ArtifactService.serviceNamespace)) ext,
    ];

    if (artifactExtensions.isEmpty) {
      return;
    }

    final HostPlatform currentHostPlatform = os.hostPlatform;

    for (final ext in artifactExtensions) {
      if (!ArtifactDependency.isValidSinglePathSegment(ext.extensionName)) {
        logger.printWarning(
          'Skipping artifacts from extension with invalid name "${ext.extensionName}".',
        );
        continue;
      }
      final List<ArtifactDependency> dependencies = await _queryExtensionArtifacts(
        ext,
        currentHostPlatform: currentHostPlatform,
        logger: logger,
        targetPlatforms: targetPlatforms,
      );

      final filteredDeps = <ArtifactDependency>[
        for (final dep in dependencies)
          if (dep.matchesPlatforms(
            currentHostPlatform: currentHostPlatform,
            targetPlatforms: targetPlatforms,
          ))
            dep,
      ];

      for (final dep in filteredDeps) {
        await _ensureArtifactCached(ext.extensionName, dep, force: force);
      }
    }
  }

  Future<List<ArtifactDependency>> _queryExtensionArtifacts(
    ExtensionConnection ext, {
    required HostPlatform currentHostPlatform,
    required Logger logger,
    required Set<String>? targetPlatforms,
  }) async {
    try {
      final Object? result = await ext.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.hostPlatformParam: currentHostPlatform.cliName,
          if (targetPlatforms != null)
            ArtifactService.targetPlatformsParam: targetPlatforms.toList(),
        },
      );
      return ArtifactDependency.listFromJson(result);
    } on Object catch (e) {
      logger.printWarning('Failed to query artifacts from extension "${ext.extensionName}": $e');
      return const <ArtifactDependency>[];
    }
  }

  Future<void> _ensureArtifactCached(
    String extensionName,
    ArtifactDependency dep, {
    required bool force,
  }) async {
    final String expectedSha = dep.sha256.toLowerCase();
    final cacheKey = '$extensionName/$expectedSha/${dep.name}';
    if (_inFlightDownloads[cacheKey] case final Future<void> existing) {
      await existing;
      return;
    }

    final Future<void> downloadFuture = _downloadAndVerifyArtifact(
      extensionName,
      dep,
      expectedSha,
      force: force,
    );
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
    String expectedSha, {
    required bool force,
  }) async {
    final ToolContext(:FileSystem fs, :Logger logger, :OperatingSystemUtils os) = _toolContext;
    final Directory shaDir = artifactShaDirectory(
      extensionName: extensionName,
      sha256: expectedSha,
    );
    final File artifactFile = shaDir.childFile(dep.name);
    final Directory artifactDir = shaDir.childDirectory(dep.name);
    final File stampFile = shaDir.childFile('.${dep.name}$_sha256StampSuffix');
    final File lockFile = shaDir.childFile('.${dep.name}$_lockFileSuffix');

    if (!force &&
        await _isArtifactCachedAndVerified(
          artifactDir: artifactDir,
          artifactFile: artifactFile,
          dep: dep,
          expectedSha: expectedSha,
          extensionName: extensionName,
          logger: logger,
          stampFile: stampFile,
        )) {
      return;
    }

    shaDir.createSync(recursive: true);
    await fs.runLocked<void>(
      lockPath: lockFile.path,
      logger: logger,
      scope: () async {
        if (!force &&
            await _isArtifactCachedAndVerified(
              artifactDir: artifactDir,
              artifactFile: artifactFile,
              dep: dep,
              expectedSha: expectedSha,
              extensionName: extensionName,
              logger: logger,
              stampFile: stampFile,
            )) {
          return;
        }

        final Directory stagingDir = shaDir.createTempSync('.tmp_${dep.name}_');
        final File stagingFile = stagingDir.childFile(dep.name);

        final Status status = logger.startProgress(
          'Downloading artifact "${dep.name}" for extension "$extensionName"...',
        );
        try {
          await _downloadAndVerifyToStagingFile(
            dep: dep,
            expectedSha: expectedSha,
            stagingFile: stagingFile,
          );
          _installStagedArtifact(
            artifactDir: artifactDir,
            artifactFile: artifactFile,
            dep: dep,
            expectedSha: expectedSha,
            os: os,
            stagingDir: stagingDir,
            stagingFile: stagingFile,
            stampFile: stampFile,
          );
        } finally {
          status.stop();
          if (stagingDir.existsSync()) {
            stagingDir.deleteSync(recursive: true);
          }
        }
      },
    );
  }

  Future<bool> _isArtifactCachedAndVerified({
    required Directory artifactDir,
    required File artifactFile,
    required ArtifactDependency dep,
    required String expectedSha,
    required String extensionName,
    required Logger logger,
    required File stampFile,
  }) async {
    if (artifactFile.existsSync()) {
      return _verifyCachedFile(
        artifactFile: artifactFile,
        dep: dep,
        expectedSha: expectedSha,
        extensionName: extensionName,
        logger: logger,
      );
    }
    if (stampFile.existsSync() && artifactDir.existsSync()) {
      return _verifyCachedDirectory(
        artifactDir: artifactDir,
        dep: dep,
        expectedSha: expectedSha,
        extensionName: extensionName,
        logger: logger,
        stampFile: stampFile,
      );
    }
    return false;
  }

  Future<bool> _verifyCachedFile({
    required File artifactFile,
    required ArtifactDependency dep,
    required String expectedSha,
    required String extensionName,
    required Logger logger,
  }) async {
    final Digest existingDigest = await sha256.bind(artifactFile.openRead()).first;
    if (existingDigest.toString().toLowerCase() == expectedSha) {
      logger.printTrace(
        'Artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
      );
      return true;
    }
    logger.printTrace('Cached artifact "${dep.name}" failed SHA-256 verification; re-downloading.');
    artifactFile.deleteSync();
    return false;
  }

  bool _verifyCachedDirectory({
    required Directory artifactDir,
    required ArtifactDependency dep,
    required String expectedSha,
    required String extensionName,
    required Logger logger,
    required File stampFile,
  }) {
    final String existingSha = stampFile.readAsStringSync().trim().toLowerCase();
    if (existingSha == expectedSha) {
      logger.printTrace(
        'Unzipped artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
      );
      return true;
    }
    logger.printTrace(
      'Cached unzipped artifact "${dep.name}" failed SHA-256 verification; re-downloading.',
    );
    artifactDir.deleteSync(recursive: true);
    stampFile.deleteSync();
    return false;
  }

  Future<void> _downloadAndVerifyToStagingFile({
    required ArtifactDependency dep,
    required String expectedSha,
    required File stagingFile,
  }) async {
    final digestSink = _AccumulatorSink<Digest>();
    try {
      final HttpClientRequest request = await _httpClient.getUrl(dep.url);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throwToolExit(
          'Failed to download artifact "${dep.name}" from ${dep.url}: '
          'HTTP ${response.statusCode}',
        );
      }

      final IOSink sink = stagingFile.openWrite();
      final ByteConversionSink hashSink = sha256.startChunkedConversion(digestSink);
      try {
        await for (final List<int> chunk in response) {
          sink.add(chunk);
          hashSink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
        hashSink.close();
      }
    } on IOException catch (e) {
      throwToolExit('Failed to download artifact "${dep.name}" from ${dep.url}: $e');
    } on OSError catch (e) {
      throwToolExit('Failed to download artifact "${dep.name}" from ${dep.url}: $e');
    }

    final Digest actualDigest = digestSink.events.single;
    if (actualDigest.toString().toLowerCase() != expectedSha) {
      throwToolExit('''
SHA-256 checksum mismatch for artifact "${dep.name}" from ${dep.url}.
Expected: ${dep.sha256}
Actual:   $actualDigest''');
    }
  }

  void _installStagedArtifact({
    required Directory artifactDir,
    required File artifactFile,
    required ArtifactDependency dep,
    required String expectedSha,
    required OperatingSystemUtils os,
    required Directory stagingDir,
    required File stagingFile,
    required File stampFile,
  }) {
    if (dep.url.path.endsWith(_zipExtension)) {
      if (stampFile.existsSync()) {
        stampFile.deleteSync();
      }
      final Directory extractedDir = stagingDir.childDirectory(_extractedDirName)
        ..createSync(recursive: true);
      try {
        os.unzip(stagingFile, extractedDir);
      } on Object catch (e) {
        throwToolExit('Failed to extract artifact "${dep.name}" from ${dep.url}: $e');
      }
      if (artifactDir.existsSync()) {
        artifactDir.deleteSync(recursive: true);
      }
      extractedDir.renameSync(artifactDir.path);
      final File stagingStamp = stagingDir.childFile(_sha256StampSuffix)
        ..writeAsStringSync(expectedSha);
      stagingStamp.renameSync(stampFile.path);
    } else {
      if (artifactFile.existsSync()) {
        artifactFile.deleteSync();
      }
      stagingFile.renameSync(artifactFile.path);
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
