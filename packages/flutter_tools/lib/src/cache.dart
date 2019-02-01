// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart' show SocketException;
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'build_info.dart';
import 'globals.dart';

/// A wrapper around the `bin/cache/` directory.
class Cache {
  /// [rootOverride] is configurable for testing.
  /// [artifacts] is configurable for testing.
  Cache({ Directory rootOverride, List<CachedArtifact> artifacts }) : _rootOverride = rootOverride {
    if (artifacts == null) {
      _artifacts.add(MaterialFonts(this));
      _artifacts.add(FlutterEngine(this));
      _artifacts.add(GradleWrapper(this));
    } else {
      _artifacts.addAll(artifacts);
    }
  }

  static const List<String> _hostsBlockedInChina = <String> [
    'storage.googleapis.com',
  ];

  final Directory _rootOverride;
  final List<CachedArtifact> _artifacts = <CachedArtifact>[];

  // Initialized by FlutterCommandRunner on startup.
  static String flutterRoot;

  // Whether to cache artifacts for all platforms. Defaults to only caching
  // artifacts for the current platform.
  bool includeAllPlatforms = false;

  static RandomAccessFile _lock;
  static bool _lockEnabled = true;

  /// Turn off the [lock]/[releaseLockEarly] mechanism.
  ///
  /// This is used by the tests since they run simultaneously and all in one
  /// process and so it would be a mess if they had to use the lock.
  @visibleForTesting
  static void disableLocking() {
    _lockEnabled = false;
  }

  /// Turn on the [lock]/[releaseLockEarly] mechanism.
  ///
  /// This is used by the tests.
  @visibleForTesting
  static void enableLocking() {
    _lockEnabled = true;
  }

  /// Lock the cache directory.
  ///
  /// This happens automatically on startup (see [FlutterCommandRunner.runCommand]).
  ///
  /// Normally the lock will be held until the process exits (this uses normal
  /// POSIX flock semantics). Long-lived commands should release the lock by
  /// calling [Cache.releaseLockEarly] once they are no longer touching the cache.
  static Future<void> lock() async {
    if (!_lockEnabled)
      return;
    assert(_lock == null);
    _lock = await fs.file(fs.path.join(flutterRoot, 'bin', 'cache', 'lockfile')).open(mode: FileMode.write);
    bool locked = false;
    bool printed = false;
    while (!locked) {
      try {
        await _lock.lock();
        locked = true;
      } on FileSystemException {
        if (!printed) {
          printTrace('Waiting to be able to obtain lock of Flutter binary artifacts directory: ${_lock.path}');
          printStatus('Waiting for another flutter command to release the startup lock...');
          printed = true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Releases the lock. This is not necessary unless the process is long-lived.
  static void releaseLockEarly() {
    if (!_lockEnabled || _lock == null)
      return;
    _lock.closeSync();
    _lock = null;
  }

  /// Checks if the current process owns the lock for the cache directory at
  /// this very moment; throws a [StateError] if it doesn't.
  static void checkLockAcquired() {
    if (_lockEnabled && _lock == null && platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true') {
      throw StateError(
        'The current process does not own the lock for the cache directory. This is a bug in Flutter CLI tools.',
      );
    }
  }

  String _dartSdkVersion;

  String get dartSdkVersion {
    if (_dartSdkVersion == null) {
      // Make the version string more customer-friendly.
      // Changes '2.1.0-dev.8.0.flutter-4312ae32' to '2.1.0 (build 2.1.0-dev.8.0 4312ae32)'
      final String justVersion = platform.version.split(' ')[0];
      _dartSdkVersion = justVersion.replaceFirstMapped(RegExp(r'(\d+\.\d+\.\d+)(.+)'), (Match match) {
        final String noFlutter = match[2].replaceAll('.flutter-', ' ');
        return '${match[1]} (build ${match[1]}$noFlutter)';
      });
    }
    return _dartSdkVersion;
  }

  String _engineRevision;

  String get engineRevision {
    _engineRevision ??= getVersionFor('engine');
    return _engineRevision;
  }

  static Cache get instance => context[Cache];

  /// Return the top-level directory in the cache; this is `bin/cache`.
  Directory getRoot() {
    if (_rootOverride != null)
      return fs.directory(fs.path.join(_rootOverride.path, 'bin', 'cache'));
    else
      return fs.directory(fs.path.join(flutterRoot, 'bin', 'cache'));
  }

  /// Return a directory in the cache dir. For `pkg`, this will return `bin/cache/pkg`.
  Directory getCacheDir(String name) {
    final Directory dir = fs.directory(fs.path.join(getRoot().path, name));
    if (!dir.existsSync())
      dir.createSync(recursive: true);
    return dir;
  }

  /// Return the top-level directory for artifact downloads.
  Directory getDownloadDir() => getCacheDir('downloads');

  /// Return the top-level mutable directory in the cache; this is `bin/cache/artifacts`.
  Directory getCacheArtifacts() => getCacheDir('artifacts');

  /// Get a named directory from with the cache's artifact directory; for example,
  /// `material_fonts` would return `bin/cache/artifacts/material_fonts`.
  Directory getArtifactDirectory(String name) {
    return getCacheArtifacts().childDirectory(name);
  }

  String getVersionFor(String artifactName) {
    final File versionFile = fs.file(fs.path.join(_rootOverride?.path ?? flutterRoot, 'bin', 'internal', '$artifactName.version'));
    return versionFile.existsSync() ? versionFile.readAsStringSync().trim() : null;
  }

  String getStampFor(String artifactName) {
    final File stampFile = getStampFileFor(artifactName);
    return stampFile.existsSync() ? stampFile.readAsStringSync().trim() : null;
  }

  void setStampFor(String artifactName, String version) {
    getStampFileFor(artifactName).writeAsStringSync(version);
  }

  File getStampFileFor(String artifactName) {
    return fs.file(fs.path.join(getRoot().path, '$artifactName.stamp'));
  }

  /// Returns `true` if either [entity] is older than the tools stamp or if
  /// [entity] doesn't exist.
  bool isOlderThanToolsStamp(FileSystemEntity entity) {
    final File flutterToolsStamp = getStampFileFor('flutter_tools');
    return isOlderThanReference(entity: entity, referenceFile: flutterToolsStamp);
  }

  bool isUpToDate({
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    bool skipUnknown = true,
  }) => _artifacts.every((CachedArtifact artifact) => artifact.isUpToDate(buildMode: buildMode, targetPlatform: targetPlatform, skipUnknown: skipUnknown));

  Future<String> getThirdPartyFile(String urlStr, String serviceName) async {
    final Uri url = Uri.parse(urlStr);
    final Directory thirdPartyDir = getArtifactDirectory('third_party');

    final Directory serviceDir = fs.directory(fs.path.join(thirdPartyDir.path, serviceName));
    if (!serviceDir.existsSync())
      serviceDir.createSync(recursive: true);

    final File cachedFile = fs.file(fs.path.join(serviceDir.path, url.pathSegments.last));
    if (!cachedFile.existsSync()) {
      try {
        await _downloadFile(url, cachedFile);
      } catch (e) {
        printError('Failed to fetch third-party artifact $url: $e');
        rethrow;
      }
    }

    return cachedFile.path;
  }

  Future<void> updateAll({
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    bool skipUnknown = true,
    bool clobber = false,
  }) async {
    if (!_lockEnabled) {
      return;
    }
    try {
      for (CachedArtifact artifact in _artifacts) {
        if (clobber || !artifact.isUpToDate(buildMode: buildMode, targetPlatform: targetPlatform, skipUnknown: skipUnknown)) {
          await artifact.update(buildMode: buildMode, targetPlatform: targetPlatform, skipUnknown: skipUnknown, clobber: clobber);
        }
      }
    } on SocketException catch (e) {
      if (_hostsBlockedInChina.contains(e.address?.host)) {
        printError(
          'Failed to retrieve Flutter tool dependencies: ${e.message}.\n'
          'If you\'re in China, please see this page: '
          'https://flutter.io/community/china',
          emphasis: true,
        );
      }
      rethrow;
    }
  }
}

/// An artifact managed by the cache.
abstract class CachedArtifact {
  CachedArtifact(this.name, this.cache);

  final String name;
  final Cache cache;

  Directory get location => cache.getArtifactDirectory(name);
  String get version => cache.getVersionFor(name);

  /// Keep track of the files we've downloaded for this execution so we
  /// can delete them after completion. We don't delete them right after
  /// extraction in case [update] is interrupted, so we can restart without
  /// starting from scratch.
  final List<File> _downloadedFiles = <File>[];

  bool isUpToDate({
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    bool skipUnknown = true,
  }) {
    if (!location.existsSync()) {
      return false;
    } if (version != cache.getStampFor(name)) {
      return false;
    }
    return isUpToDateInner(
      buildMode: buildMode,
      targetPlatform: targetPlatform,
      skipUnknown: skipUnknown,
    );
  }

  Future<void> update({
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    bool skipUnknown = true,
    bool clobber = false,
  }) async {
    if (location.existsSync()) {
      location.deleteSync(recursive: true);
    }
    location.createSync(recursive: true);
    await updateInner(
      buildMode: buildMode,
      targetPlatform: targetPlatform,
      skipUnknown: skipUnknown,
      clobber: clobber,
    );
    cache.setStampFor(name, version);
    _removeDownloadedFiles();
  }

  /// Clear any zip/gzip files downloaded.
  void _removeDownloadedFiles() {
    for (File f in _downloadedFiles) {
      f.deleteSync();
      for (Directory d = f.parent; d.absolute.path != cache.getDownloadDir().absolute.path; d = d.parent) {
        if (d.listSync().isEmpty) {
          d.deleteSync();
        } else {
          break;
        }
      }
    }
  }

  /// Hook method for extra checks for being up-to-date.
  bool isUpToDateInner({BuildMode buildMode, TargetPlatform targetPlatform, bool skipUnknown}) => true;

  /// Template method to perform artifact update.
  Future<void> updateInner({
    @required BuildMode buildMode,
    @required TargetPlatform targetPlatform,
    @required bool skipUnknown,
    @required bool clobber,
  });

  String get _storageBaseUrl {
    final String overrideUrl = platform.environment['FLUTTER_STORAGE_BASE_URL'];
    if (overrideUrl == null)
      return 'https://storage.googleapis.com';
    _maybeWarnAboutStorageOverride(overrideUrl);
    return overrideUrl;
  }

  Uri _toStorageUri(String path) => Uri.parse('$_storageBaseUrl/$path');

  /// Download an archive from the given [url] and unzip it to [location].
  Future<void> _downloadArchive(String message, Uri url, Directory location, bool verifier(File f), void extractor(File f, Directory d)) {
    return _withDownloadFile('${flattenNameSubdirs(url)}', (File tempFile) async {
      if (!verifier(tempFile)) {
        final Status status = logger.startProgress(message, timeout: kSlowOperation);
        try {
          await _downloadFile(url, tempFile);
          status.stop();
        } catch (exception) {
          status.cancel();
          rethrow;
        }
      } else {
        logger.printTrace('$message (cached)');
      }
      _ensureExists(location);
      extractor(tempFile, location);
    });
  }

  /// Download a zip archive from the given [url] and unzip it to [location].
  Future<void> _downloadZipArchive(String message, Uri url, Directory location) {
    return _downloadArchive(message, url, location, os.verifyZip, os.unzip);
  }

  /// Download a gzipped tarball from the given [url] and unpack it to [location].
  Future<void> _downloadZippedTarball(String message, Uri url, Directory location) {
    return _downloadArchive(message, url, location, os.verifyGzip, os.unpack);
  }

  /// Create a temporary file and invoke [onTemporaryFile] with the file as
  /// argument, then add the temporary file to the [_downloadedFiles].
  Future<void> _withDownloadFile(String name, Future<void> onTemporaryFile(File file)) async {
    final File tempFile = fs.file(fs.path.join(cache.getDownloadDir().path, name));
    _downloadedFiles.add(tempFile);
    await onTemporaryFile(tempFile);
  }
}

bool _hasWarnedAboutStorageOverride = false;

void _maybeWarnAboutStorageOverride(String overrideUrl) {
  if (_hasWarnedAboutStorageOverride)
    return;
  logger.printStatus(
    'Flutter assets will be downloaded from $overrideUrl. Make sure you trust this source!',
    emphasis: true,
  );
  _hasWarnedAboutStorageOverride = true;
}

/// A cached artifact containing fonts used for Material Design.
class MaterialFonts extends CachedArtifact {
  MaterialFonts(Cache cache) : super('material_fonts', cache);

  @override
  Future<void> updateInner({BuildMode buildMode, TargetPlatform targetPlatform, bool skipUnknown, bool clobber}) async {
    final Uri archiveUri = _toStorageUri(version);
    if (fs.directory(location).listSync().isEmpty || clobber) {
      await _downloadZipArchive('Downloading Material fonts...', archiveUri, location);
    }
  }
}

/// A cached artifact containing the Flutter engine binaries.
class FlutterEngine extends CachedArtifact {
  FlutterEngine(Cache cache) : super('engine', cache);

  List<String> _getPackageDirs() => const <String>['sky_engine'];

  // Return a list of (cache directory path, download URL path) tuples.
  List<List<String>> _getBinaryDirs({
    @required BuildMode buildMode,
    @required TargetPlatform targetPlatform,
    @required bool skipUnknown,
  }) {
    final List<List<String>> binaryDirs = <List<String>>[
      <String>['common', 'flutter_patched_sdk.zip'],
    ];
    TargetPlatform hostPlatform;
    List<EngineBinary> binaries = _binaries;
    if (cache.includeAllPlatforms) {
      hostPlatform = null;
      binaries = _binaries + _dartSdks;
    } if (platform.isMacOS) {
      hostPlatform = TargetPlatform.darwin_x64;
    } else if (platform.isLinux) {
      hostPlatform = TargetPlatform.linux_x64;
    } else if (platform.isWindows) {
      hostPlatform = TargetPlatform.windows_x64;
    }
    for (EngineBinary engineBinary in _reduceEngineBinaries(
      binaries,
      buildMode: buildMode,
      targetPlatform: targetPlatform,
      hostPlatform: hostPlatform,
      skipUnknown: skipUnknown,
    )) {
      binaryDirs.add(engineBinary.toTuple());
    }
    return binaryDirs;
  }

  Iterable<EngineBinary> _reduceEngineBinaries(List<EngineBinary> binaries, {
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    TargetPlatform hostPlatform,
    bool skipUnknown,
  }) sync* {
    for (EngineBinary engineBinary in binaries) {
      if (hostPlatform != null && engineBinary.hostPlatform != null && engineBinary.hostPlatform != hostPlatform) {
        continue;
      }
      if (engineBinary.skipChecks) {
        yield engineBinary;
      }
      // Certain binaries have no restrictions and should always be included.
      if (engineBinary.buildMode == null && engineBinary.targetPlatform == null) {
        yield engineBinary;
      } else if (engineBinary.buildMode == buildMode && engineBinary.targetPlatform == targetPlatform) {
        yield engineBinary;
      } else if (!skipUnknown) {
        // If we don't skip unknown, then assume null matches everything.
        if (targetPlatform == null && buildMode != null && buildMode == engineBinary.buildMode) {
          yield engineBinary;
        } else if (buildMode == null && targetPlatform != null && targetPlatform == engineBinary.targetPlatform) {
          yield engineBinary;
        } else {
          yield engineBinary;
        }
      }
    }
  }
  List<EngineBinary> get _dartSdks => const <EngineBinary>[
    EngineBinary(
      name: 'darwin-x64',
      fileName: 'dart-sdk-darwin-x64.zip',
    ),
    EngineBinary(
      name: 'linux-x64',
      fileName: 'dart-sdk-linux-x64.zip',
    ),
    EngineBinary(
      name: 'windows-x64',
      fileName: 'dart-sdk-windows-x64.zip',
    ),
  ];

  /// A set of all possible engine artifacts to download.
  /// A binary without a buildMode or targetPlatform is downloaded
  /// if the hostPlatform matches.
  List<EngineBinary> get _binaries => const <EngineBinary>[
    EngineBinary(
      name: 'linux-x64',
      fileName: 'linux-x64/artifacts.zip',
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm-profile/linux-x64',
      fileName: 'android-arm-profile/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.profile,
      hostPlatform: TargetPlatform.linux_x64,
      skipChecks: true,
    ),
    EngineBinary(
      name: 'android-arm-release/linux-x64',
      fileName: 'android-arm-release/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.release,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm64-profile/linux-x64',
      fileName: 'android-arm64-profile/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.profile,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm64-release/linux-x64',
      fileName: 'android-arm64-release/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.release,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-profile/linux-x64',
      fileName: 'android-arm-dynamic-profile/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.dynamicProfile,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-release/linux-x64',
      fileName:  'android-arm-dynamic-release/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.dynamicRelease,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-profile/linux-x64',
      fileName: 'android-arm64-dynamic-profile/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.dynamicProfile,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-release/linux-x64',
      fileName: 'android-arm64-dynamic-release/linux-x64.zip',
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.dynamicRelease,
      hostPlatform: TargetPlatform.linux_x64,
    ),
    EngineBinary(
      name: 'windows-x64',
      fileName: 'windows-x64/artifacts.zip',
      hostPlatform: TargetPlatform.windows_x64,
    ),
    EngineBinary(
      name: 'android-arm-profile/windows-x64',
      fileName: 'android-arm-profile/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.profile,
      skipChecks: true
    ),
    EngineBinary(
      name: 'android-arm-release/windows-x64',
      fileName: 'android-arm-release/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.release,
    ),
    EngineBinary(
      name: 'android-arm64-profile/windows-x64',
      fileName: 'android-arm64-profile/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.profile,
    ),
    EngineBinary(
      name: 'android-arm64-release/windows-x64',
      fileName: 'android-arm64-release/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.release,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-profile/windows-x64',
      fileName: 'android-arm-dynamic-profile/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.dynamicProfile,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-release/windows-x64',
      fileName: 'android-arm-dynamic-release/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm,
      buildMode: BuildMode.dynamicRelease,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-profile/windows-x64',
      fileName: 'android-arm64-dynamic-profile/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.dynamicProfile,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-release/windows-x64',
      fileName: 'android-arm64-dynamic-release/windows-x64.zip',
      hostPlatform: TargetPlatform.windows_x64,
      targetPlatform: TargetPlatform.android_arm64,
      buildMode: BuildMode.dynamicRelease,
    ),
    EngineBinary(
      name: 'android-x86',
      fileName: 'android-x86/artifacts.zip',
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_x86,
    ),
    EngineBinary(
      name: 'android-x64',
      fileName: 'android-x64/artifacts.zip',
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_x64,
    ),
    EngineBinary(
      name: 'android-arm',
      fileName: 'android-arm/artifacts.zip',
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm-profile',
      fileName: 'android-arm-profile/artifacts.zip',
      buildMode: BuildMode.profile,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm-release',
      fileName: 'android-arm-release/artifacts.zip',
      buildMode: BuildMode.release,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm64',
      fileName: 'android-arm64/artifacts.zip',
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm64-profile',
      fileName: 'android-arm64-profile/artifacts.zip',
      buildMode: BuildMode.profile,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm64-release',
      fileName: 'android-arm64-release/artifacts.zip',
      buildMode: BuildMode.release,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-profile',
      fileName: 'android-arm-dynamic-profile/artifacts.zip',
      buildMode: BuildMode.dynamicProfile,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-release',
      fileName: 'android-arm-dynamic-release/artifacts.zip',
      buildMode: BuildMode.dynamicRelease,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-profile',
      fileName: 'android-arm64-dynamic-profile/artifacts.zip',
      buildMode: BuildMode.dynamicProfile,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-release',
      fileName: 'android-arm64-dynamic-release/artifacts.zip',
      buildMode: BuildMode.dynamicRelease,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'ios', fileName: 'ios/artifacts.zip',
      buildMode: BuildMode.debug,
      hostPlatform: TargetPlatform.darwin_x64,
      targetPlatform: TargetPlatform.ios,
    ),
    EngineBinary(
      name: 'ios-profile',
      fileName: 'ios-profile/artifacts.zip',
      buildMode: BuildMode.profile,
      hostPlatform: TargetPlatform.darwin_x64,
      targetPlatform: TargetPlatform.ios,
    ),
    EngineBinary(
      name: 'ios-release',
      fileName: 'ios-release/artifacts.zip',
      buildMode: BuildMode.release,
      hostPlatform: TargetPlatform.darwin_x64,
      targetPlatform: TargetPlatform.ios,
    ),
    EngineBinary(
      name: 'darwin-x64',
      fileName: 'darwin-x64/artifacts.zip',
      hostPlatform: TargetPlatform.darwin_x64,
    ),
    EngineBinary(
      name: 'android-arm-profile/darwin-x64',
      fileName: 'android-arm-profile/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.profile,
      targetPlatform: TargetPlatform.android_arm,
      skipChecks: true,
    ),
    EngineBinary(
      name: 'android-arm-release/darwin-x64',
      fileName: 'android-arm-release/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.release,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm64-profile/darwin-x64',
      fileName: 'android-arm64-profile/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.profile,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm64-release/darwin-x64',
      fileName: 'android-arm64-release/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.release,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-profile/darwin-x64',
      fileName: 'android-arm-dynamic-profile/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.dynamicProfile,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm-dynamic-release/darwin-x64',
      fileName: 'android-arm-dynamic-release/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.dynamicRelease,
      targetPlatform: TargetPlatform.android_arm,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-profile/darwin-x64',
      fileName: 'android-arm64-dynamic-profile/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.dynamicProfile,
      targetPlatform: TargetPlatform.android_arm64,
    ),
    EngineBinary(
      name: 'android-arm64-dynamic-release/darwin-x64',
      fileName: 'android-arm64-dynamic-release/darwin-x64.zip',
      hostPlatform: TargetPlatform.darwin_x64,
      buildMode: BuildMode.dynamicRelease,
      targetPlatform: TargetPlatform.android_arm64,
    ),
  ];

  // A list of cache directory paths to which the LICENSE file should be copied.
  List<String> _getLicenseDirs() {
    if (cache.includeAllPlatforms || platform.isMacOS) {
      return const <String>['ios', 'ios-profile', 'ios-release'];
    }
    return const <String>[];
  }

  @override
  bool isUpToDateInner({
    BuildMode buildMode,
    TargetPlatform targetPlatform,
    bool skipUnknown,
  }) {
    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      if (!fs.directory(pkgPath).existsSync())
        return false;
    }

    for (List<String> toolsDir in _getBinaryDirs(buildMode: buildMode, targetPlatform: targetPlatform, skipUnknown: skipUnknown)) {
      final Directory dir = fs.directory(fs.path.join(location.path, toolsDir[0]));
      if (!dir.existsSync())
        return false;
    }

    for (String licenseDir in _getLicenseDirs()) {
      final File file = fs.file(fs.path.join(location.path, licenseDir, 'LICENSE'));
      if (!file.existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner({
    @required BuildMode buildMode,
    @required TargetPlatform targetPlatform,
    @required bool skipUnknown,
    @required bool clobber,
  }) async {
    final String url = '$_storageBaseUrl/flutter_infra/flutter/$version/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      final Directory dir = fs.directory(pkgPath);
      bool exists = dir.existsSync();
      if (exists && clobber) {
        dir.deleteSync(recursive: true);
        exists = false;
      }
      if (!exists) {
        await _downloadZipArchive('Downloading package $pkgName...', Uri.parse(url + pkgName + '.zip'), pkgDir);
      }
    }

    for (List<String> toolsDir in _getBinaryDirs(buildMode: buildMode, targetPlatform: targetPlatform, skipUnknown: skipUnknown)) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = fs.directory(fs.path.join(location.path, cacheDir));
      // Here we assume if a directory exists, all the files are correct.
      if (dir.existsSync() && !clobber) {
        continue;
      }
      await _downloadZipArchive('Downloading $cacheDir tools...', Uri.parse(url + urlPath), dir);

      _makeFilesExecutable(dir);

      final File frameworkZip = fs.file(fs.path.join(dir.path, 'Flutter.framework.zip'));
      if (frameworkZip.existsSync()) {
        final Directory framework = fs.directory(fs.path.join(dir.path, 'Flutter.framework'));
        framework.createSync();
        os.unzip(frameworkZip, framework);
      }
    }

    final File licenseSource = fs.file(fs.path.join(Cache.flutterRoot, 'LICENSE'));
    for (String licenseDir in _getLicenseDirs()) {
      final String licenseDestinationPath = fs.path.join(location.path, licenseDir, 'LICENSE');
      // If the destination does not exist, we did not download the artifact to
      // perform this operation.
      if (!fs.directory(fs.path.join(location.path, licenseDir)).existsSync()) {
        continue;
      }
      await licenseSource.copy(licenseDestinationPath);
    }
  }

  Future<bool> areRemoteArtifactsAvailable({String engineVersion,
                                            bool includeAllPlatforms = true}) async {
    final bool includeAllPlatformsState = cache.includeAllPlatforms;
    cache.includeAllPlatforms = includeAllPlatforms;

    Future<bool> checkForArtifacts(String engineVersion) async {
      engineVersion ??= version;
      final String url = '$_storageBaseUrl/flutter_infra/flutter/$engineVersion/';

      bool exists = false;
      for (String pkgName in _getPackageDirs()) {
        exists = await _doesRemoteExist('Checking package $pkgName is available...',
            Uri.parse(url + pkgName + '.zip'));
        if (!exists) {
          return false;
        }
      }

      for (List<String> toolsDir in _getBinaryDirs(buildMode: null, targetPlatform: null, skipUnknown: false)) {
        final String cacheDir = toolsDir[0];
        final String urlPath = toolsDir[1];
        exists = await _doesRemoteExist('Checking $cacheDir tools are available...',
            Uri.parse(url + urlPath));
        if (!exists) {
          return false;
        }
      }

      return true;
    }

    final bool result = await checkForArtifacts(engineVersion);
    cache.includeAllPlatforms = includeAllPlatformsState;
    return result;
  }


  void _makeFilesExecutable(Directory dir) {
    for (FileSystemEntity entity in dir.listSync()) {
      if (entity is File) {
        final String name = fs.path.basename(entity.path);
        if (name == 'flutter_tester')
          os.makeExecutable(entity);
      }
    }
  }
}

/// A cached artifact containing Gradle Wrapper scripts and binaries.
class GradleWrapper extends CachedArtifact {
  GradleWrapper(Cache cache) : super('gradle_wrapper', cache);

  List<String> get _gradleScripts => <String>['gradlew', 'gradlew.bat'];

  String get _gradleWrapper => fs.path.join('gradle', 'wrapper', 'gradle-wrapper.jar');

  @override
  Future<void> updateInner({BuildMode buildMode, TargetPlatform targetPlatform, bool skipUnknown, bool clobber}) async {
    final Uri archiveUri = _toStorageUri(version);
    if (fs.directory(location).listSync().isEmpty || clobber) {
      await _downloadZippedTarball('Downloading Gradle Wrapper...', archiveUri, location).then<void>((_) {
        // Delete property file, allowing templates to provide it.
        fs.file(fs.path.join(location.path, 'gradle', 'wrapper', 'gradle-wrapper.properties')).deleteSync();
        // Remove NOTICE file. Should not be part of the template.
        fs.file(fs.path.join(location.path, 'NOTICE')).deleteSync();
      });
    }
  }

  @override
  bool isUpToDateInner({BuildMode buildMode, TargetPlatform targetPlatform, bool skipUnknown}) {
    final Directory wrapperDir = cache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'));
    if (!fs.directory(wrapperDir).existsSync())
      return false;
    for (String scriptName in _gradleScripts) {
      final File scriptFile = fs.file(fs.path.join(wrapperDir.path, scriptName));
      if (!scriptFile.existsSync())
        return false;
    }
    final File gradleWrapperJar = fs.file(fs.path.join(wrapperDir.path, _gradleWrapper));
    if (!gradleWrapperJar.existsSync())
      return false;
    return true;
  }
}

// Many characters are problematic in filenames, especially on Windows.
final Map<int, List<int>> _flattenNameSubstitutions = <int, List<int>>{
  r'@'.codeUnitAt(0): '@@'.codeUnits,
  r'/'.codeUnitAt(0): '@s@'.codeUnits,
  r'\'.codeUnitAt(0): '@bs@'.codeUnits,
  r':'.codeUnitAt(0): '@c@'.codeUnits,
  r'%'.codeUnitAt(0): '@per@'.codeUnits,
  r'*'.codeUnitAt(0): '@ast@'.codeUnits,
  r'<'.codeUnitAt(0): '@lt@'.codeUnits,
  r'>'.codeUnitAt(0): '@gt@'.codeUnits,
  r'"'.codeUnitAt(0): '@q@'.codeUnits,
  r'|'.codeUnitAt(0): '@pip@'.codeUnits,
  r'?'.codeUnitAt(0): '@ques@'.codeUnits
};

/// Given a name containing slashes, colons, and backslashes, expand it into
/// something that doesn't.
String _flattenNameNoSubdirs(String fileName) {
  final List<int> replacedCodeUnits = <int>[];
  for (int codeUnit in fileName.codeUnits) {
    replacedCodeUnits.addAll(_flattenNameSubstitutions[codeUnit] ?? <int>[codeUnit]);
  }
  return String.fromCharCodes(replacedCodeUnits);
}

@visibleForTesting
String flattenNameSubdirs(Uri url) {
  final List<String> pieces = <String>[url.host]..addAll(url.pathSegments);
  final Iterable<String> convertedPieces = pieces.map<String>(_flattenNameNoSubdirs);
  return fs.path.joinAll(convertedPieces);
}

/// Download a file from the given [url] and write it to [location].
Future<void> _downloadFile(Uri url, File location) async {
  _ensureExists(location.parent);
  final List<int> fileBytes = await fetchUrl(url);
  location.writeAsBytesSync(fileBytes, flush: true);
}

Future<bool> _doesRemoteExist(String message, Uri url) async {
  final Status status = logger.startProgress(message, timeout: kSlowOperation);
  final bool exists = await doesRemoteFileExist(url);
  status.stop();
  return exists;
}

/// Create the given [directory] and parents, as necessary.
void _ensureExists(Directory directory) {
  if (!directory.existsSync())
    directory.createSync(recursive: true);
}

class EngineBinary {
  const EngineBinary({
    this.targetPlatform,
    this.buildMode,
    @required this.name,
    @required this.fileName,
    this.hostPlatform,
    this.skipChecks = false,
  });

  final TargetPlatform targetPlatform;
  final TargetPlatform hostPlatform;
  final BuildMode buildMode;
  final String name;
  final String fileName;
  final bool skipChecks;

  List<String> toTuple() => <String>[name, fileName];
}
