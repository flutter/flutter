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
  static const String _defaultEngineVersion = 'unknown';
  static const String _zipExtension = '.zip';
  static const String _extractedDirName = 'extracted';
  static const String _sha256StampSuffix = '.sha256';
  static const String _lockFileSuffix = '.lock';
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;
  final Directory? _cacheDir;
  final HttpClient _httpClient;

  final _inFlightDownloads = <String, Future<String>>{};

  String get _engineVersion {
    final String revision = _toolContext.cache.engineRevision.trim();
    return revision.isNotEmpty ? revision : _defaultEngineVersion;
  }

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

  /// Returns the cache directory `<cacheDir>/<extensionName>/<engineVersion>`
  /// for the given [extensionName] and [engineVersion].
  ///
  /// Throws an [ArgumentError] if [extensionName] or [engineVersion] is not a
  /// valid single path segment.
  Directory artifactDirectory({required String engineVersion, required String extensionName}) {
    if (!ArtifactDependency.isValidSinglePathSegment(extensionName)) {
      throw ArgumentError.value(
        extensionName,
        'extensionName',
        'Must be a valid single path segment.',
      );
    }
    if (!ArtifactDependency.isValidSinglePathSegment(engineVersion)) {
      throw ArgumentError.value(
        engineVersion,
        'engineVersion',
        'Must be a valid single path segment.',
      );
    }
    return artifactsCacheDirectory.childDirectory(extensionName).childDirectory(engineVersion);
  }

  /// Queries all active extensions implementing [ArtifactService] and ensures
  /// required artifacts for the current engine version, host platform, and
  /// optional [targetPlatforms] are downloaded and verified in the shared cache.
  ///
  /// Returns a map from each downloaded artifact's [ArtifactDependency.name] to
  /// its local filesystem path.
  ///
  /// When [force] is `true`, existing cached artifacts are re-downloaded.
  Future<Map<String, String>> ensureArtifactsDownloaded({
    bool force = false,
    Set<String>? targetPlatforms,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String>{};
    }
    final ToolContext(:Logger logger, :OperatingSystemUtils os) = _toolContext;

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      logger.printTrace('Failed to initialize extension manager for artifacts: $e');
      return const <String, String>{};
    }

    final artifactExtensions = <ExtensionConnection>[
      for (final ext in _extensionManager.connections)
        if (ext.capabilities.services.contains(ArtifactService.serviceNamespace)) ext,
    ];

    if (artifactExtensions.isEmpty) {
      return const <String, String>{};
    }

    final HostPlatform currentHostPlatform = os.hostPlatform;
    final String engineVersion = _engineVersion;
    if (!ArtifactDependency.isValidSinglePathSegment(engineVersion)) {
      logger.printWarning(
        'Skipping extension artifacts due to invalid engine version "$engineVersion".',
      );
      return const <String, String>{};
    }

    final resolvedArtifacts = <String, String>{};
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
        engineVersion: engineVersion,
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
        resolvedArtifacts[dep.name] = await _ensureArtifactCached(
          ext.extensionName,
          engineVersion,
          dep,
          force: force,
        );
      }
    }
    return resolvedArtifacts;
  }

  Future<List<ArtifactDependency>> _queryExtensionArtifacts(
    ExtensionConnection ext, {
    required HostPlatform currentHostPlatform,
    required String engineVersion,
    required Logger logger,
    required Set<String>? targetPlatforms,
  }) async {
    try {
      final Object? result = await ext.sendRequest(
        ArtifactService.downloadArtifactsMethod,
        params: <String, Object?>{
          ArtifactService.engineVersionParam: engineVersion,
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

  Future<String> _ensureArtifactCached(
    String extensionName,
    String engineVersion,
    ArtifactDependency dep, {
    required bool force,
  }) async {
    final cacheKey = '$extensionName/$engineVersion/${dep.name}';
    if (_inFlightDownloads[cacheKey] case final Future<String> existing) {
      return existing;
    }

    final Future<String> downloadFuture = _downloadAndVerifyArtifact(
      extensionName,
      engineVersion,
      dep,
      force: force,
    );
    _inFlightDownloads[cacheKey] = downloadFuture;
    try {
      return await downloadFuture;
    } finally {
      unawaited(_inFlightDownloads.remove(cacheKey));
    }
  }

  Future<String> _downloadAndVerifyArtifact(
    String extensionName,
    String engineVersion,
    ArtifactDependency dep, {
    required bool force,
  }) async {
    final ToolContext(:FileSystem fs, :Logger logger, :OperatingSystemUtils os) = _toolContext;
    final Directory engineDir = artifactDirectory(
      engineVersion: engineVersion,
      extensionName: extensionName,
    );
    final File artifactFile = engineDir.childFile(dep.name);
    final Directory artifactDir = engineDir.childDirectory(dep.name);
    final File stampFile = engineDir.childFile('.${dep.name}$_sha256StampSuffix');
    final File lockFile = engineDir.childFile('.${dep.name}$_lockFileSuffix');
    final bool isZip = dep.url.path.endsWith(_zipExtension);
    final String resolvedPath = isZip ? artifactDir.path : artifactFile.path;

    if (!force &&
        await _isArtifactCachedAndVerified(
          artifactDir: artifactDir,
          artifactFile: artifactFile,
          dep: dep,
          extensionName: extensionName,
          isZip: isZip,
          logger: logger,
          stampFile: stampFile,
        )) {
      return resolvedPath;
    }

    engineDir.createSync(recursive: true);
    await fs.runLocked<void>(
      lockPath: lockFile.path,
      logger: logger,
      scope: () async {
        if (!force &&
            await _isArtifactCachedAndVerified(
              artifactDir: artifactDir,
              artifactFile: artifactFile,
              dep: dep,
              extensionName: extensionName,
              isZip: isZip,
              logger: logger,
              stampFile: stampFile,
            )) {
          return;
        }

        final Directory stagingDir = engineDir.createTempSync('.tmp_${dep.name}_');
        final File stagingFile = stagingDir.childFile(dep.name);

        final Status status = logger.startProgress(
          'Downloading artifact "${dep.name}" for extension "$extensionName"...',
        );
        try {
          final String expectedSha = dep.sha256?.toLowerCase() ?? await _fetchRemoteSha256(dep);
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
            isZip: isZip,
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
    return resolvedPath;
  }

  Future<bool> _isArtifactCachedAndVerified({
    required Directory artifactDir,
    required File artifactFile,
    required ArtifactDependency dep,
    required String extensionName,
    required bool isZip,
    required Logger logger,
    required File stampFile,
  }) async {
    if (dep.sha256 case final String sha) {
      final String expectedSha = sha.toLowerCase();
      if (!isZip && artifactFile.existsSync()) {
        return _verifyCachedFile(
          artifactFile: artifactFile,
          dep: dep,
          expectedSha: expectedSha,
          extensionName: extensionName,
          logger: logger,
          stampFile: stampFile,
        );
      }
      if (isZip && stampFile.existsSync() && artifactDir.existsSync()) {
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

    if (stampFile.existsSync()) {
      final String recordedSha = stampFile.readAsStringSync().trim().toLowerCase();
      if (ArtifactDependency.isValidSha256(recordedSha)) {
        if (isZip && artifactDir.existsSync()) {
          logger.printTrace(
            'Unzipped artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
          );
          return true;
        }
        if (!isZip && artifactFile.existsSync()) {
          return _verifyCachedFile(
            artifactFile: artifactFile,
            dep: dep,
            expectedSha: recordedSha,
            extensionName: extensionName,
            logger: logger,
            stampFile: stampFile,
          );
        }
      }
    }
    return false;
  }

  Future<bool> _verifyCachedFile({
    required File artifactFile,
    required ArtifactDependency dep,
    required String expectedSha,
    required String extensionName,
    required Logger logger,
    required File stampFile,
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
    if (stampFile.existsSync()) {
      stampFile.deleteSync();
    }
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

  Future<String> _fetchRemoteSha256(ArtifactDependency dep) async {
    final Uri sha256Url = dep.sha256Url!;
    final String body;
    try {
      final HttpClientRequest request = await _httpClient.getUrl(sha256Url);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throwToolExit(
          'Failed to download SHA-256 checksum for artifact "${dep.name}" from $sha256Url: '
          'HTTP ${response.statusCode}',
        );
      }
      body = await utf8.decodeStream(response);
    } on IOException catch (e) {
      throwToolExit(
        'Failed to download SHA-256 checksum for artifact "${dep.name}" from $sha256Url: $e',
      );
    } on OSError catch (e) {
      throwToolExit(
        'Failed to download SHA-256 checksum for artifact "${dep.name}" from $sha256Url: $e',
      );
    }
    final String trimmed = body.trim();
    final String token = trimmed.isEmpty
        ? ''
        : trimmed.split(_whitespaceRegExp).first.toLowerCase();
    if (!ArtifactDependency.isValidSha256(token)) {
      throwToolExit(
        'Invalid SHA-256 checksum for artifact "${dep.name}" from $sha256Url: "$trimmed"',
      );
    }
    return token;
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
Expected: $expectedSha
Actual:   $actualDigest''');
    }
  }

  void _installStagedArtifact({
    required Directory artifactDir,
    required File artifactFile,
    required ArtifactDependency dep,
    required String expectedSha,
    required bool isZip,
    required OperatingSystemUtils os,
    required Directory stagingDir,
    required File stagingFile,
    required File stampFile,
  }) {
    if (stampFile.existsSync()) {
      stampFile.deleteSync();
    }
    if (isZip) {
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
    } else {
      if (artifactFile.existsSync()) {
        artifactFile.deleteSync();
      }
      stagingFile.renameSync(artifactFile.path);
    }
    final File stagingStamp = stagingDir.childFile(_sha256StampSuffix)
      ..writeAsStringSync(expectedSha);
    stagingStamp.renameSync(stampFile.path);
  }
}

class _AccumulatorSink<T> implements Sink<T> {
  final events = <T>[];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
