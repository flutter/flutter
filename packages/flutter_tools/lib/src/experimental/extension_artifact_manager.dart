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

/// A resolved tool extension artifact on the host filesystem.
@immutable
final class ResolvedExtensionArtifact {
  const ResolvedExtensionArtifact({required this.path, this.stampFile});

  /// Normalized local filesystem path to the cached or local artifact file or
  /// directory, passed to the extension in `resolvedArtifacts`.
  final String path;

  /// Optional stamp [File] used by `flutter assemble` to track staleness for
  /// directory-based artifacts without walking the entire directory tree (the
  /// `.sha256` completion marker for extracted remote `.zip` archives, or
  /// [LocalArtifactDependency.stampUri] when provided).
  final File? stampFile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResolvedExtensionArtifact &&
          other.path == path &&
          other.stampFile?.path == stampFile?.path);

  @override
  int get hashCode => Object.hash(path, stampFile?.path);

  @override
  String toString() => 'ResolvedExtensionArtifact(path: $path, stampFile: ${stampFile?.path})';
}

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

  /// Tracks in-flight download futures keyed by destination path
  /// (`<cacheDir>/<extensionName>/<sha256>/<artifactName>`) to deduplicate
  /// concurrent artifact requests within the same process.
  final _inFlightDownloads = <String, Future<ResolvedExtensionArtifact>>{};

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
  /// artifacts for the current engine version, host platform, optional
  /// [targetPlatforms], and optional [artifactNames] filter are resolved on
  /// disk or downloaded and verified in the shared cache.
  ///
  /// When [artifactNames] is non-null, only artifacts whose
  /// [ArtifactDependency.name] is in [artifactNames] are resolved or downloaded
  /// (returning an empty map immediately without querying extensions when
  /// [artifactNames] is empty). When [targetPlatforms] is `null`, artifacts for
  /// all target platforms supported by each queried extension are requested.
  ///
  /// Returns a map from each resolved artifact's [ArtifactDependency.name] to
  /// its [ResolvedExtensionArtifact], or an empty map when tool extensions are
  /// disabled, [artifactNames] is empty, extension initialization fails, or no
  /// matching active extension implements [ArtifactService].
  ///
  /// When [force] is `true`, existing cached remote artifacts are re-downloaded.
  Future<Map<String, ResolvedExtensionArtifact>> ensureArtifactsDownloaded({
    Set<String>? artifactNames,
    String? extensionName,
    bool force = false,
    Set<String>? targetPlatforms,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled ||
        (artifactNames != null && artifactNames.isEmpty)) {
      return const <String, ResolvedExtensionArtifact>{};
    }
    final ToolContext(:Logger logger, :OperatingSystemUtils os) = _toolContext;

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      logger.printTrace('Failed to initialize extension manager for artifacts: $e');
      return const <String, ResolvedExtensionArtifact>{};
    }

    final artifactExtensions = <ExtensionConnection>[
      for (final ext in _extensionManager.connections)
        if (ext.capabilities.services.contains(ArtifactService.serviceNamespace) &&
            (extensionName == null || ext.extensionName == extensionName))
          ext,
    ];

    if (artifactExtensions.isEmpty) {
      return const <String, ResolvedExtensionArtifact>{};
    }

    final HostPlatform currentHostPlatform = os.hostPlatform;
    final String engineVersion = _engineVersion;

    final resolvedArtifacts = <String, ResolvedExtensionArtifact>{};
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

      final seenForExtension = <String>{};
      for (final dep in dependencies) {
        if (!dep.matchesPlatforms(
          currentHostPlatform: currentHostPlatform,
          targetPlatforms: targetPlatforms,
        )) {
          continue;
        }
        if (!seenForExtension.add(dep.name)) {
          logger.printWarning(
            'Extension "${ext.extensionName}" declared duplicate artifact "${dep.name}"; '
            'keeping the first declaration.',
          );
          continue;
        }
        if (artifactNames != null && !artifactNames.contains(dep.name)) {
          continue;
        }
        final ResolvedExtensionArtifact resolved = switch (dep) {
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
        resolvedArtifacts.putIfAbsent(dep.name, () => resolved);
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
  ResolvedExtensionArtifact _resolveLocalArtifact(
    String extensionName,
    LocalArtifactDependency dep,
  ) {
    final FileSystem fs = _toolContext.fs;
    File? stampFile;
    if (dep.stampUri case final Uri stampUri) {
      final File resolvedStamp = fs.file(stampUri);
      if (!resolvedStamp.existsSync()) {
        throwToolExit(
          'Stamp file for local artifact "${dep.name}" for extension "$extensionName" was not found at "${fs.path.fromUri(stampUri)}".',
        );
      }
      stampFile = resolvedStamp;
    }
    final File file = fs.file(dep.localUri);
    if (file.existsSync()) {
      return ResolvedExtensionArtifact(path: fs.path.normalize(file.path), stampFile: stampFile);
    }
    final Directory dir = fs.directory(dep.localUri);
    if (dir.existsSync()) {
      return ResolvedExtensionArtifact(path: fs.path.normalize(dir.path), stampFile: stampFile);
    }
    throwToolExit(
      'Local artifact "${dep.name}" for extension "$extensionName" was not found at "${fs.path.fromUri(dep.localUri)}".',
    );
  }

  /// Ensures [dep] is present and verified in the local cache under
  /// `<cacheDir>/<extensionName>/<sha256>/<dep.name>`, deduplicating
  /// concurrent in-process requests per destination via [_inFlightDownloads].
  Future<ResolvedExtensionArtifact> _ensureRemoteArtifactCached(
    String extensionName,
    RemoteArtifactDependency dep, {
    required bool force,
  }) async {
    final Directory destDir = artifactDirectory(extensionName: extensionName, sha256: dep.sha256);
    final String destinationPath = destDir.fileSystem.path.join(destDir.path, dep.name);
    if (_inFlightDownloads[destinationPath] case final Future<ResolvedExtensionArtifact> existing) {
      return existing;
    }

    final Future<ResolvedExtensionArtifact> downloadFuture = _downloadAndVerifyArtifact(
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
  /// (`<cacheDir>/<extensionName>/<sha256>`), returning the
  /// [ResolvedExtensionArtifact] for the cached file or extracted directory.
  ///
  /// Because [destDir] is keyed by [RemoteArtifactDependency.sha256], single-file
  /// artifacts are complete once atomically renamed into [destDir], while
  /// extracted `.zip` archives also write a `.sha256` completion stamp file.
  Future<ResolvedExtensionArtifact> _downloadAndVerifyArtifact({
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
    final resolved = ResolvedExtensionArtifact(
      path: isZip ? artifactDir.path : artifactFile.path,
      stampFile: isZip ? stampFile : null,
    );

    if (!force &&
        _isArtifactCached(
          artifactDir: artifactDir,
          artifactFile: artifactFile,
          artifactName: dep.name,
          extensionName: extensionName,
          isZip: isZip,
          logger: logger,
          stampFile: stampFile,
        )) {
      return resolved;
    }

    destDir.createSync(recursive: true);
    await fs.runLocked<void>(
      lockPath: lockFile.path,
      logger: logger,
      scope: () async {
        if (!force &&
            _isArtifactCached(
              artifactDir: artifactDir,
              artifactFile: artifactFile,
              artifactName: dep.name,
              extensionName: extensionName,
              isZip: isZip,
              logger: logger,
              stampFile: stampFile,
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
    return resolved;
  }

  bool _isArtifactCached({
    required Directory artifactDir,
    required File artifactFile,
    required String artifactName,
    required String extensionName,
    required bool isZip,
    required Logger logger,
    required File stampFile,
  }) {
    final bool cached = isZip
        ? artifactDir.existsSync() && stampFile.existsSync()
        : artifactFile.existsSync();
    if (cached) {
      logger.printTrace('Artifact "$artifactName" for extension "$extensionName" already cached.');
    }
    return cached;
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
  /// ([artifactDir] with [stampFile] when [isZip] is `true`, or [artifactFile]
  /// otherwise) and applies declared POSIX executable permissions.
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
    if (isZip) {
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
      final File stagingStamp = stagingDir.childFile(_sha256StampSuffix)
        ..writeAsStringSync(expectedSha);
      stagingStamp.renameSync(stampFile.path);
    } else {
      if (dep.isExecutable) {
        os.makeExecutable(stagingFile);
      }
      if (artifactFile.existsSync()) {
        artifactFile.deleteSync();
      }
      stagingFile.renameSync(artifactFile.path);
    }
  }

  /// Validates every entry in [RemoteArtifactDependency.executables] within
  /// [extractedDir] (rejecting missing files and symbolic links along any
  /// directory or file segment) and marks each file executable.
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
      os.makeExecutable(execFile);
    }
  }
}
