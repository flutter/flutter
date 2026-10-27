// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

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
    @visibleForTesting this._cacheDir,
    @visibleForTesting HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  static const String _dartDataHomeEnvKey = 'DART_DATA_HOME';
  static const String _localAppDataEnvKey = 'LOCALAPPDATA';
  static const String _userProfileEnvKey = 'USERPROFILE';
  static const String _homeEnvKey = 'HOME';
  static const String _extensionsCacheDirName = 'flutter_tool_extensions';
  static const String _hiddenExtensionsCacheDirName = '.flutter_tool_extensions';
  static const String _artifactsCacheSubdirName = 'artifacts';
  static const String _defaultEngineVersion = 'unknown';
  static const String _extractedDirName = 'extracted';
  static const String _sha256StampSuffix = '.sha256';
  static const String _lockFileSuffix = '.lock';

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;
  final Directory? _cacheDir;
  final HttpClient _httpClient;

  /// Tracks in-flight download futures keyed by `<extensionName>/<engineVersion>/<artifactName>`
  /// to deduplicate concurrent artifact requests within the same process.
  final _inFlightDownloads = <String, Future<String>>{};

  /// The current Flutter engine revision from the tool cache, or
  /// [_defaultEngineVersion] (`'unknown'`) when the revision is empty.
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
  /// When [targetPlatforms] is `null`, artifacts for all target platforms
  /// supported by each active extension are requested.
  ///
  /// Returns a map from each downloaded artifact's [ArtifactDependency.name] to
  /// its local filesystem path, or an empty map when tool extensions are
  /// disabled, extension initialization fails, or no active extension implements
  /// [ArtifactService].
  ///
  /// RPC failures when querying an extension's artifact list log a warning and
  /// skip that extension, whereas download, extraction, or SHA-256 verification
  /// failures throw a [ToolExit].
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
        if (resolvedArtifacts.containsKey(dep.name)) {
          logger.printWarning(
            'Artifact "${dep.name}" from extension "${ext.extensionName}" conflicts with an '
            'artifact of the same name from another extension and will be ignored.',
          );
          continue;
        }
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

  /// Queries [ext] over JSON-RPC via [ArtifactService.downloadArtifactsMethod]
  /// for the list of [ArtifactDependency] descriptors required for the given
  /// [engineVersion], [currentHostPlatform], and optional [targetPlatforms].
  ///
  /// Logs a warning and returns an empty list if the RPC fails or returns
  /// malformed data so a single failing extension does not abort artifact
  /// resolution for other extensions.
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

  /// Ensures [dep] is present and verified in the local cache under
  /// `<cacheDir>/<extensionName>/<engineVersion>/<dep.name>`, deduplicating
  /// concurrent in-process requests via [_inFlightDownloads].
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

  /// Downloads, verifies, and installs [dep] into the `<extensionName>/<engineVersion>`
  /// cache directory, returning the local filesystem path to the cached file or
  /// extracted directory.
  ///
  /// Uses a fast unlocked check first (`_isArtifactCachedAndVerified`) when
  /// [force] is `false`. If a download is needed, acquires a cross-process file
  /// lock (`.${dep.name}.lock` via `fs.runLocked`), re-checks the cache
  /// inside the lock, downloads to a temporary staging directory, verifies the
  /// SHA-256 checksum, and installs the artifact followed by its `.sha256`
  /// stamp file.
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
    final bool isZip = dep.isZipArchive;
    final String resolvedPath = isZip ? artifactDir.path : artifactFile.path;

    if (!force &&
        _isArtifactCachedAndVerified(
          engineDir,
          dep,
          deleteStaleOnMismatch: false,
          extensionName: extensionName,
          logger: logger,
        )) {
      return resolvedPath;
    }

    engineDir.createSync(recursive: true);
    await fs.runLocked<void>(
      lockPath: lockFile.path,
      logger: logger,
      scope: () async {
        if (!force &&
            _isArtifactCachedAndVerified(
              engineDir,
              dep,
              deleteStaleOnMismatch: true,
              extensionName: extensionName,
              logger: logger,
            )) {
          return;
        }

        final Directory stagingDir = engineDir.createTempSync('.tmp_${dep.name}_');
        final File stagingFile = stagingDir.childFile(dep.name);

        final Status status = logger.startProgress(
          'Downloading artifact "${dep.name}" for extension "$extensionName"...',
        );
        try {
          final String expectedSha = dep.sha256.toLowerCase();
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

  /// Checks whether [dep] is already cached in [versionDir] and its `.sha256`
  /// stamp file matches [ArtifactDependency.sha256].
  ///
  /// When [deleteStaleOnMismatch] is `true` (inside the cross-process lock),
  /// deletes any stale cached file/directory and stamp file if the stamp does
  /// not match [ArtifactDependency.sha256].
  bool _isArtifactCachedAndVerified(
    Directory versionDir,
    ArtifactDependency dep, {
    required bool deleteStaleOnMismatch,
    required String extensionName,
    required Logger logger,
  }) {
    final bool isZip = dep.isZipArchive;
    final FileSystemEntity target = isZip
        ? versionDir.childDirectory(dep.name)
        : versionDir.childFile(dep.name);
    final File stampFile = versionDir.childFile('.${dep.name}$_sha256StampSuffix');
    if (!target.existsSync() || !stampFile.existsSync()) {
      return false;
    }
    try {
      final String recordedSha = stampFile.readAsStringSync().trim().toLowerCase();
      if (recordedSha == dep.sha256.toLowerCase()) {
        logger.printTrace(
          'Artifact "${dep.name}" for extension "$extensionName" already cached and verified.',
        );
        return true;
      }
    } on FileSystemException {
      // Fall through to re-download.
    }
    if (deleteStaleOnMismatch) {
      logger.printTrace(
        'Cached artifact "${dep.name}" failed SHA-256 verification; re-downloading.',
      );
      try {
        if (target.existsSync()) {
          target.deleteSync(recursive: isZip);
        }
        if (stampFile.existsSync()) {
          stampFile.deleteSync();
        }
      } on FileSystemException {
        // Ignore cleanup errors; _installStagedArtifact will overwrite.
      }
    }
    return false;
  }

  /// Streams the artifact from [ArtifactDependency.url] into [stagingFile] while
  /// computing its SHA-256 digest incrementally.
  ///
  /// Throws a [ToolExit] if the HTTP request fails or the computed digest does
  /// not match [expectedSha].
  Future<void> _downloadAndVerifyToStagingFile({
    required ArtifactDependency dep,
    required String expectedSha,
    required File stagingFile,
  }) async {
    final digestSink = AccumulatorSink<Digest>();
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

  /// Installs a verified [stagingFile] into its final cache destination
  /// ([artifactDir] when [isZip] is `true`, or [artifactFile] otherwise) and
  /// writes [expectedSha] to [stampFile] last via renames from [stagingDir].
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
