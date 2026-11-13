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
  static const String _executableChmodMode = 'a+x';

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;
  final Directory? _cacheDir;
  final HttpClient _httpClient;

  /// Tracks in-flight download futures keyed by destination path
  /// (`<cacheDir>/<extensionName>/<sha256>/<artifactName>`) to deduplicate
  /// concurrent artifact requests within the same process.
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
  ///
  /// Throws a [ToolExit] if no cache directory override or home/data
  /// environment variable is available.
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
    throwToolExit(
      'Unable to determine shared cache directory for tool extension artifacts: '
      'none of $_dartDataHomeEnvKey, $_homeEnvKey, $_localAppDataEnvKey, or $_userProfileEnvKey are set.',
    );
  }

  /// Returns the content-addressed cache directory
  /// `<cacheDir>/<extensionName>/<sha256>` for the given [extensionName] and
  /// lowercase [sha256] digest.
  ///
  /// Throws an [ArgumentError] if [extensionName] or [sha256] is not a valid
  /// single path segment.
  Directory artifactDirectory({required String extensionName, required String sha256}) {
    if (!ArtifactDependency.isValidSinglePathSegment(extensionName)) {
      throw ArgumentError.value(
        extensionName,
        'extensionName',
        'Must be a valid single path segment.',
      );
    }
    final String normalizedSha256 = sha256.toLowerCase();
    if (!ArtifactDependency.isValidSinglePathSegment(normalizedSha256)) {
      throw ArgumentError.value(sha256, 'sha256', 'Must be a valid single path segment.');
    }
    return artifactsCacheDirectory.childDirectory(extensionName).childDirectory(normalizedSha256);
  }

  /// Queries active extensions implementing [ArtifactService] (or only the
  /// extension matching [extensionName] when specified) and ensures required
  /// artifacts for the current engine version, host platform, and optional
  /// [targetPlatforms] are resolved on disk or downloaded and verified in the
  /// shared cache.
  ///
  /// When [targetPlatforms] is `null`, artifacts for all target platforms
  /// supported by each queried extension are requested.
  ///
  /// Returns a map from each resolved artifact's [ArtifactDependency.name] to
  /// its local filesystem path, or an empty map when tool extensions are
  /// disabled, extension initialization fails, or no matching active extension
  /// implements [ArtifactService]. When [extensionName] is provided (for
  /// example, during `flutter build` or `ExtensionBackedDevice.startApp`), the
  /// returned map is scoped strictly to that owning extension; when
  /// [extensionName] is `null` (for example, during `flutter precache`), all
  /// extensions' artifacts are downloaded into their isolated
  /// `<cacheDir>/<extensionName>/<sha256>/<name>` directories.
  ///
  /// RPC failures when querying an extension's artifact list log a warning and
  /// skip that extension, whereas missing local artifacts or download,
  /// extraction, executable permission validation, or SHA-256 verification
  /// failures throw a [ToolExit].
  ///
  /// When [force] is `true`, existing cached remote artifacts are re-downloaded.
  Future<Map<String, String>> ensureArtifactsDownloaded({
    String? extensionName,
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
        if (ext.capabilities.services.contains(ArtifactService.serviceNamespace) &&
            (extensionName == null || ext.extensionName == extensionName))
          ext,
    ];

    if (artifactExtensions.isEmpty) {
      return const <String, String>{};
    }

    final HostPlatform currentHostPlatform = os.hostPlatform;
    final String engineVersion = _engineVersion;

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

      final seenForExtension = <String>{};
      for (final dep in filteredDeps) {
        if (!seenForExtension.add(dep.name)) {
          logger.printWarning(
            'Extension "${ext.extensionName}" declared duplicate artifact "${dep.name}"; '
            'keeping the first declaration.',
          );
          continue;
        }
        final String resolvedPath = switch (dep) {
          final LocalArtifactDependency localDep => _resolveLocalArtifact(
            ext.extensionName,
            localDep,
          ),
          final RemoteArtifactDependency remoteDep => await _ensureRemoteArtifactCached(
            ext.extensionName,
            remoteDep,
            force: force,
          ),
        };
        resolvedArtifacts.putIfAbsent(dep.name, () => resolvedPath);
      }
    }
    return resolvedArtifacts;
  }

  /// Queries [ext] over JSON-RPC via [ArtifactService.listRequiredArtifactsMethod]
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
        ArtifactService.listRequiredArtifactsMethod,
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

  /// Resolves a [LocalArtifactDependency] directly to its unpacked local
  /// filesystem path after verifying that [LocalArtifactDependency.localUri]
  /// (and optional [LocalArtifactDependency.stampUri]) exist on disk.
  ///
  /// Throws a [ToolExit] if [LocalArtifactDependency.localUri] or a non-null
  /// [LocalArtifactDependency.stampUri] does not exist on disk.
  String _resolveLocalArtifact(String extensionName, LocalArtifactDependency dep) {
    final FileSystem fs = _toolContext.fs;
    if (dep.stampUri case final Uri stampUri when !fs.file(stampUri).existsSync()) {
      throwToolExit(
        'Stamp file for local artifact "${dep.name}" for extension "$extensionName" was not found at "${fs.path.fromUri(stampUri)}".',
      );
    }
    final File file = fs.file(dep.localUri);
    if (file.existsSync()) {
      return fs.path.normalize(file.path);
    }
    final Directory dir = fs.directory(dep.localUri);
    if (dir.existsSync()) {
      return fs.path.normalize(dir.path);
    }
    throwToolExit(
      'Local artifact "${dep.name}" for extension "$extensionName" was not found at "${fs.path.fromUri(dep.localUri)}".',
    );
  }

  /// Ensures [dep] is present and verified in the local cache under
  /// `<cacheDir>/<extensionName>/<sha256>/<dep.name>`, deduplicating
  /// concurrent in-process requests per destination via [_inFlightDownloads].
  Future<String> _ensureRemoteArtifactCached(
    String extensionName,
    RemoteArtifactDependency dep, {
    required bool force,
  }) async {
    final Directory destDir = artifactDirectory(extensionName: extensionName, sha256: dep.sha256);
    final String destinationPath = destDir.fileSystem.path.join(destDir.path, dep.name);
    if (_inFlightDownloads[destinationPath] case final Future<String> existing) {
      return existing;
    }

    final Future<String> downloadFuture = _downloadAndVerifyArtifact(
      dep: dep,
      destDir: destDir,
      extensionName: extensionName,
      force: force,
    );
    _inFlightDownloads[destinationPath] = downloadFuture;
    try {
      return await downloadFuture;
    } finally {
      unawaited(_inFlightDownloads.remove(destinationPath));
    }
  }

  /// Downloads, verifies, and installs [dep] into [destDir]
  /// (`<cacheDir>/<extensionName>/<sha256>`), returning the local filesystem
  /// path to the cached file or extracted directory.
  ///
  /// Uses a fast unlocked check first (`_isArtifactCachedAndVerified`) when
  /// [force] is `false`. If a download is needed, acquires a cross-process file
  /// lock (`<destDir>.lock` via `fs.runLocked`), re-checks the cache inside the
  /// lock, downloads to a temporary staging directory, verifies the SHA-256
  /// checksum, and installs the artifact followed by its `.sha256` stamp file.
  Future<String> _downloadAndVerifyArtifact({
    required RemoteArtifactDependency dep,
    required Directory destDir,
    required String extensionName,
    required bool force,
  }) async {
    final ToolContext(:FileSystem fs, :Logger logger, :OperatingSystemUtils os) = _toolContext;
    final File artifactFile = destDir.childFile(dep.name);
    final Directory artifactDir = destDir.childDirectory(dep.name);
    final File stampFile = destDir.childFile('.${dep.name}$_sha256StampSuffix');
    final File lockFile = fs.file('${destDir.path}$_lockFileSuffix');
    final bool isZip = dep.isZipArchive;
    final String resolvedPath = isZip ? artifactDir.path : artifactFile.path;

    if (!force &&
        _isArtifactCachedAndVerified(
          destDir,
          dep,
          deleteStaleOnMismatch: false,
          extensionName: extensionName,
          logger: logger,
        )) {
      return resolvedPath;
    }

    destDir.createSync(recursive: true);
    await fs.runLocked<void>(
      lockPath: lockFile.path,
      logger: logger,
      scope: () async {
        if (!force &&
            _isArtifactCachedAndVerified(
              destDir,
              dep,
              deleteStaleOnMismatch: true,
              extensionName: extensionName,
              logger: logger,
            )) {
          return;
        }

        final Directory stagingDir = destDir.createTempSync('.tmp_${dep.name}_');
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
            extensionName: extensionName,
            fs: fs,
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

  /// Checks whether [dep] is already cached in [destDir] and its `.sha256`
  /// stamp file matches [RemoteArtifactDependency.sha256].
  ///
  /// When [deleteStaleOnMismatch] is `true` (inside the cross-process lock),
  /// deletes any stale cached file/directory and stamp file if the stamp does
  /// not match [RemoteArtifactDependency.sha256].
  bool _isArtifactCachedAndVerified(
    Directory destDir,
    RemoteArtifactDependency dep, {
    required bool deleteStaleOnMismatch,
    required String extensionName,
    required Logger logger,
  }) {
    final bool isZip = dep.isZipArchive;
    final FileSystemEntity target = isZip
        ? destDir.childDirectory(dep.name)
        : destDir.childFile(dep.name);
    final File stampFile = destDir.childFile('.${dep.name}$_sha256StampSuffix');
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

  /// Streams the artifact from [RemoteArtifactDependency.url] into [stagingFile]
  /// while computing its SHA-256 digest incrementally.
  ///
  /// Throws a [ToolExit] if the HTTP request fails or the computed digest does
  /// not match [expectedSha].
  Future<void> _downloadAndVerifyToStagingFile({
    required RemoteArtifactDependency dep,
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
  /// ([artifactDir] when [isZip] is `true`, or [artifactFile] otherwise),
  /// applies declared POSIX executable permissions, and writes [expectedSha] to
  /// [stampFile] last via renames from [stagingDir].
  void _installStagedArtifact({
    required Directory artifactDir,
    required File artifactFile,
    required RemoteArtifactDependency dep,
    required String expectedSha,
    required String extensionName,
    required FileSystem fs,
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
      _applyArchiveExecutablePermissions(
        dep: dep,
        extensionName: extensionName,
        extractedDir: extractedDir,
        fs: fs,
        os: os,
      );
      if (artifactDir.existsSync()) {
        artifactDir.deleteSync(recursive: true);
      }
      extractedDir.renameSync(artifactDir.path);
    } else {
      if (dep.isExecutable) {
        os.chmod(stagingFile, _executableChmodMode);
      }
      if (artifactFile.existsSync()) {
        artifactFile.deleteSync();
      }
      stagingFile.renameSync(artifactFile.path);
    }
    final File stagingStamp = stagingDir.childFile(_sha256StampSuffix)
      ..writeAsStringSync(expectedSha);
    stagingStamp.renameSync(stampFile.path);
  }

  /// Validates every entry in [RemoteArtifactDependency.executables] within
  /// [extractedDir] (rejecting out-of-tree paths, missing files, and symbolic
  /// links along any directory or file segment) and applies `chmod a+x`.
  void _applyArchiveExecutablePermissions({
    required RemoteArtifactDependency dep,
    required String extensionName,
    required Directory extractedDir,
    required FileSystem fs,
    required OperatingSystemUtils os,
  }) {
    for (final String relativePath in dep.executables) {
      assert(ArtifactDependency.isValidExecutableSubpath(relativePath));
      final List<String> segments = relativePath.split('/');
      String currentPath = extractedDir.path;
      for (var i = 0; i < segments.length - 1; i++) {
        currentPath = fs.path.join(currentPath, segments[i]);
        if (fs.isLinkSync(currentPath)) {
          throwToolExit(
            'Executable "$relativePath" in artifact "${dep.name}" for extension '
            '"$extensionName" traverses a symbolic link.',
          );
        }
        if (!fs.directory(currentPath).existsSync()) {
          throwToolExit(
            'Executable "$relativePath" declared by artifact "${dep.name}" for extension '
            '"$extensionName" was not found in the extracted archive.',
          );
        }
      }
      final String execPath = fs.path.join(currentPath, segments.last);
      if (fs.isLinkSync(execPath)) {
        throwToolExit(
          'Executable "$relativePath" in artifact "${dep.name}" for extension '
          '"$extensionName" must not be a symbolic link.',
        );
      }
      final File execFile = fs.file(execPath);
      if (!execFile.existsSync()) {
        throwToolExit(
          'Executable "$relativePath" declared by artifact "${dep.name}" for extension '
          '"$extensionName" was not found in the extracted archive.',
        );
      }
      os.chmod(execFile, _executableChmodMode);
    }
  }
}
