// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'android/gradle_utils.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart' show SocketException;
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart' show OperatingSystemUtils;
import 'base/process.dart';
import 'features.dart';
import 'globals.dart' as globals;

/// A tag for a set of development artifacts that need to be cached.
class DevelopmentArtifact {

  const DevelopmentArtifact._(this.name, {this.unstable = false, this.feature});

  /// The name of the artifact.
  ///
  /// This should match the flag name in precache.dart
  final String name;

  /// Whether this artifact should be unavailable on master branch only.
  final bool unstable;

  /// A feature to control the visibility of this artifact.
  final Feature feature;

  /// Artifacts required for Android development.
  static const DevelopmentArtifact androidGenSnapshot = DevelopmentArtifact._('android_gen_snapshot');
  static const DevelopmentArtifact androidMaven = DevelopmentArtifact._('android_maven');
  // Artifacts used for internal builds.
  static const DevelopmentArtifact androidInternalBuild = DevelopmentArtifact._('android_internal_build');

  /// Artifacts required for iOS development.
  static const DevelopmentArtifact iOS = DevelopmentArtifact._('ios');

  /// Artifacts required for web development.
  static const DevelopmentArtifact web = DevelopmentArtifact._('web', feature: flutterWebFeature);

  /// Artifacts required for desktop macOS.
  static const DevelopmentArtifact macOS = DevelopmentArtifact._('macos', unstable: true);

  /// Artifacts required for desktop Windows.
  static const DevelopmentArtifact windows = DevelopmentArtifact._('windows', unstable: true);

  /// Artifacts required for desktop Linux.
  static const DevelopmentArtifact linux = DevelopmentArtifact._('linux', unstable: true);

  /// Artifacts required for Fuchsia.
  static const DevelopmentArtifact fuchsia = DevelopmentArtifact._('fuchsia', unstable: true);

  /// Artifacts required for the Flutter Runner.
  static const DevelopmentArtifact flutterRunner = DevelopmentArtifact._('flutter_runner', unstable: true);

  /// Artifacts required for any development platform.
  ///
  /// This does not need to be explicitly returned from requiredArtifacts as
  /// it will always be downloaded.
  static const DevelopmentArtifact universal = DevelopmentArtifact._('universal');

  /// The values of DevelopmentArtifacts.
  static final List<DevelopmentArtifact> values = <DevelopmentArtifact>[
    androidGenSnapshot,
    androidMaven,
    androidInternalBuild,
    iOS,
    web,
    macOS,
    windows,
    linux,
    fuchsia,
    universal,
    flutterRunner,
  ];

  @override
  String toString() => 'Artifact($name, $unstable)';
}

/// A wrapper around the `bin/cache/` directory.
class Cache {
  /// [rootOverride] is configurable for testing.
  /// [artifacts] is configurable for testing.
  Cache({
    Directory rootOverride,
    List<ArtifactSet> artifacts,
    // TODO(jonahwilliams): make required once migrated to context-free.
    Logger logger,
    FileSystem fileSystem,
    Platform platform,
    OperatingSystemUtils osUtils,
  }) : _rootOverride = rootOverride,
       _logger = logger ?? globals.logger,
       _fileSystem = fileSystem ?? globals.fs,
       _platform = platform ?? globals.platform,
       _osUtils = osUtils ?? globals.os {
    // TODO(zra): Move to initializer list once logger and platform parameters
    // are required.
    _net = Net(logger: _logger, platform: _platform);
    _fsUtils = FileSystemUtils(fileSystem: _fileSystem, platform: _platform);
    if (artifacts == null) {
      _artifacts.add(MaterialFonts(this));

      _artifacts.add(GradleWrapper(this));
      _artifacts.add(AndroidMavenArtifacts());
      _artifacts.add(AndroidGenSnapshotArtifacts(this));
      _artifacts.add(AndroidInternalBuildArtifacts(this));

      _artifacts.add(IOSEngineArtifacts(this));
      _artifacts.add(FlutterWebSdk(this));
      _artifacts.add(FlutterSdk(this));
      _artifacts.add(WindowsEngineArtifacts(this));
      _artifacts.add(MacOSEngineArtifacts(this));
      _artifacts.add(LinuxEngineArtifacts(this));
      _artifacts.add(LinuxFuchsiaSDKArtifacts(this));
      _artifacts.add(MacOSFuchsiaSDKArtifacts(this));
      _artifacts.add(FlutterRunnerSDKArtifacts(this));
      _artifacts.add(FlutterRunnerDebugSymbols(this));
      for (final String artifactName in IosUsbArtifacts.artifactNames) {
        _artifacts.add(IosUsbArtifacts(artifactName, this));
      }
      _artifacts.add(FontSubsetArtifacts(this));
    } else {
      _artifacts.addAll(artifacts);
    }
  }

  final Logger _logger;
  final Platform _platform;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _osUtils;

  Net _net;
  FileSystemUtils _fsUtils;

  static const List<String> _hostsBlockedInChina = <String> [
    'storage.googleapis.com',
  ];

  final Directory _rootOverride;
  final List<ArtifactSet> _artifacts = <ArtifactSet>[];

  // Initialized by FlutterCommandRunner on startup.
  static String flutterRoot;

  // Whether to cache artifacts for all platforms. Defaults to only caching
  // artifacts for the current platform.
  bool includeAllPlatforms = false;

  // Whether to cache the unsigned mac binaries. Defaults to caching the signed binaries.
  bool useUnsignedMacBinaries = false;

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
    if (!_lockEnabled) {
      return;
    }
    assert(_lock == null);
    final File lockFile =
        globals.fs.file(globals.fs.path.join(flutterRoot, 'bin', 'cache', 'lockfile'));
    try {
      _lock = lockFile.openSync(mode: FileMode.write);
    } on FileSystemException catch (e) {
      globals.printError('Failed to open or create the artifact cache lockfile: "$e"');
      globals.printError('Please ensure you have permissions to create or open '
                 '${lockFile.path}');
      throwToolExit('Failed to open or create the lockfile');
    }
    bool locked = false;
    bool printed = false;
    while (!locked) {
      try {
        _lock.lockSync();
        locked = true;
      } on FileSystemException {
        if (!printed) {
          globals.printTrace('Waiting to be able to obtain lock of Flutter binary artifacts directory: ${_lock.path}');
          globals.printStatus('Waiting for another flutter command to release the startup lock...');
          printed = true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Releases the lock. This is not necessary unless the process is long-lived.
  static void releaseLockEarly() {
    if (!_lockEnabled || _lock == null) {
      return;
    }
    _lock.closeSync();
    _lock = null;
  }

  /// Checks if the current process owns the lock for the cache directory at
  /// this very moment; throws a [StateError] if it doesn't.
  static void checkLockAcquired() {
    if (_lockEnabled && _lock == null && globals.platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true') {
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
      final String justVersion = _platform.version.split(' ')[0];
      _dartSdkVersion = justVersion.replaceFirstMapped(RegExp(r'(\d+\.\d+\.\d+)(.+)'), (Match match) {
        final String noFlutter = match[2].replaceAll('.flutter-', ' ');
        return '${match[1]} (build ${match[1]}$noFlutter)';
      });
    }
    return _dartSdkVersion;
  }

  /// The current version of the Flutter engine the flutter tool will download.
  String get engineRevision {
    _engineRevision ??= getVersionFor('engine');
    return _engineRevision;
  }
  String _engineRevision;

  String get storageBaseUrl {
    final String overrideUrl = _platform.environment['FLUTTER_STORAGE_BASE_URL'];
    if (overrideUrl == null) {
      return 'https://storage.googleapis.com';
    }
    // verify that this is a valid URI.
    try {
      Uri.parse(overrideUrl);
    } on FormatException catch (err) {
      throwToolExit('"FLUTTER_STORAGE_BASE_URL" contains an invalid URI:\n$err');
    }
    _maybeWarnAboutStorageOverride(overrideUrl);
    return overrideUrl;
  }

  bool _hasWarnedAboutStorageOverride = false;

  void _maybeWarnAboutStorageOverride(String overrideUrl) {
    if (_hasWarnedAboutStorageOverride) {
      return;
    }
    _logger.printStatus(
      'Flutter assets will be downloaded from $overrideUrl. Make sure you trust this source!',
      emphasis: true,
    );
    _hasWarnedAboutStorageOverride = true;
  }

  /// Return the top-level directory in the cache; this is `bin/cache`.
  Directory getRoot() {
    if (_rootOverride != null) {
      return _fileSystem.directory(_fileSystem.path.join(_rootOverride.path, 'bin', 'cache'));
    } else {
      return _fileSystem.directory(_fileSystem.path.join(flutterRoot, 'bin', 'cache'));
    }
  }

  /// Return a directory in the cache dir. For `pkg`, this will return `bin/cache/pkg`.
  Directory getCacheDir(String name) {
    final Directory dir = _fileSystem.directory(_fileSystem.path.join(getRoot().path, name));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      _osUtils.chmod(dir, '755');
    }
    return dir;
  }

  /// Return the top-level directory for artifact downloads.
  Directory getDownloadDir() => getCacheDir('downloads');

  /// Return the top-level mutable directory in the cache; this is `bin/cache/artifacts`.
  Directory getCacheArtifacts() => getCacheDir('artifacts');

  /// Location of LICENSE file.
  File getLicenseFile() => _fileSystem.file(_fileSystem.path.join(flutterRoot, 'LICENSE'));

  /// Get a named directory from with the cache's artifact directory; for example,
  /// `material_fonts` would return `bin/cache/artifacts/material_fonts`.
  Directory getArtifactDirectory(String name) {
    return getCacheArtifacts().childDirectory(name);
  }

  MapEntry<String, String> get dyLdLibEntry {
    if (_dyLdLibEntry != null) {
      return _dyLdLibEntry;
    }
    final List<String> paths = <String>[];
    for (final ArtifactSet artifact in _artifacts) {
      final Map<String, String> env = artifact.environment;
      if (env == null || !env.containsKey('DYLD_LIBRARY_PATH')) {
        continue;
      }
      final String path = env['DYLD_LIBRARY_PATH'];
      if (path.isEmpty) {
        continue;
      }
      paths.add(path);
    }
    _dyLdLibEntry = MapEntry<String, String>('DYLD_LIBRARY_PATH', paths.join(':'));
    return _dyLdLibEntry;
  }
  MapEntry<String, String> _dyLdLibEntry;

  /// The web sdk has to be co-located with the dart-sdk so that they can share source
  /// code.
  Directory getWebSdkDirectory() {
    return getRoot().childDirectory('flutter_web_sdk');
  }

  String getVersionFor(String artifactName) {
    final File versionFile = _fileSystem.file(_fileSystem.path.join(
      _rootOverride?.path ?? flutterRoot,
      'bin',
      'internal',
      '$artifactName.version',
    ));
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
    return _fileSystem.file(_fileSystem.path.join(getRoot().path, '$artifactName.stamp'));
  }

  /// Returns `true` if either [entity] is older than the tools stamp or if
  /// [entity] doesn't exist.
  bool isOlderThanToolsStamp(FileSystemEntity entity) {
    final File flutterToolsStamp = getStampFileFor('flutter_tools');
    return _fsUtils.isOlderThanReference(
      entity: entity,
      referenceFile: flutterToolsStamp,
    );
  }

  bool isUpToDate() => _artifacts.every((ArtifactSet artifact) => artifact.isUpToDate());

  Future<String> getThirdPartyFile(String urlStr, String serviceName) async {
    final Uri url = Uri.parse(urlStr);
    final Directory thirdPartyDir = getArtifactDirectory('third_party');

    final Directory serviceDir = _fileSystem.directory(_fileSystem.path.join(
      thirdPartyDir.path,
      serviceName,
    ));
    if (!serviceDir.existsSync()) {
      serviceDir.createSync(recursive: true);
      _osUtils.chmod(serviceDir, '755');
    }

    final File cachedFile = _fileSystem.file(_fileSystem.path.join(
      serviceDir.path,
      url.pathSegments.last,
    ));
    if (!cachedFile.existsSync()) {
      try {
        await downloadFile(url, cachedFile);
      } on Exception catch (e) {
        throwToolExit('Failed to fetch third-party artifact $url: $e');
      }
    }

    return cachedFile.path;
  }

  /// Update the cache to contain all `requiredArtifacts`.
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts) async {
    if (!_lockEnabled) {
      return;
    }
    for (final ArtifactSet artifact in _artifacts) {
      if (!requiredArtifacts.contains(artifact.developmentArtifact)) {
        _logger.printTrace('Artifact $artifact is not required, skipping update.');
        continue;
      }
      if (artifact.isUpToDate()) {
        continue;
      }
      try {
        await artifact.update();
      } on SocketException catch (e) {
        if (_hostsBlockedInChina.contains(e.address?.host)) {
          _logger.printError(
            'Failed to retrieve Flutter tool dependencies: ${e.message}.\n'
            "If you're in China, please see this page: "
            'https://flutter.dev/community/china',
            emphasis: true,
          );
        }
        rethrow;
      }
    }
  }

  Future<bool> areRemoteArtifactsAvailable({
    String engineVersion,
    bool includeAllPlatforms = true,
  }) async {
    final bool includeAllPlatformsState = this.includeAllPlatforms;
    bool allAvailible = true;
    this.includeAllPlatforms = includeAllPlatforms;
    for (final ArtifactSet cachedArtifact in _artifacts) {
      if (cachedArtifact is EngineCachedArtifact) {
        allAvailible &= await cachedArtifact.checkForArtifacts(engineVersion);
      }
    }
    this.includeAllPlatforms = includeAllPlatformsState;
    return allAvailible;
  }

  /// Download a file from the given [url] and write it to [location].
  Future<void> downloadFile(Uri url, File location) async {
    _ensureExists(location.parent);
    await _net.fetchUrl(url, destFile: location);
  }

  Future<bool> doesRemoteExist(String message, Uri url) async {
    final Status status = _logger.startProgress(
      message,
      timeout: timeoutConfiguration.slowOperation,
    );
    bool exists;
    try {
      exists = await _net.doesRemoteFileExist(url);
    } finally {
      status.stop();
    }
    return exists;
  }
}

/// Representation of a set of artifacts used by the tool.
abstract class ArtifactSet {
  ArtifactSet(this.developmentArtifact) : assert(developmentArtifact != null);

  /// The development artifact.
  final DevelopmentArtifact developmentArtifact;

  /// [true] if the artifact is up to date.
  bool isUpToDate();

  /// The environment variables (if any) required to consume the artifacts.
  Map<String, String> get environment {
    return const <String, String>{};
  }

  /// Updates the artifact.
  Future<void> update();
}

/// An artifact set managed by the cache.
abstract class CachedArtifact extends ArtifactSet {
  CachedArtifact(
    this.name,
    this.cache,
    DevelopmentArtifact developmentArtifact,
  ) : super(developmentArtifact);

  final Cache cache;

  /// The canonical name of the artifact.
  final String name;

  // The name of the stamp file. Defaults to the same as the
  // artifact name.
  String get stampName => name;

  Directory get location => cache.getArtifactDirectory(name);
  String get version => cache.getVersionFor(name);

  /// Keep track of the files we've downloaded for this execution so we
  /// can delete them after completion. We don't delete them right after
  /// extraction in case [update] is interrupted, so we can restart without
  /// starting from scratch.
  @visibleForTesting
  final List<File> downloadedFiles = <File>[];

  @override
  bool isUpToDate() {
    if (!location.existsSync()) {
      return false;
    }
    if (version != cache.getStampFor(stampName)) {
      return false;
    }
    return isUpToDateInner();
  }

  @override
  Future<void> update() async {
    if (!location.existsSync()) {
      try {
        location.createSync(recursive: true);
      } on FileSystemException catch (err) {
        globals.printError(err.toString());
        throwToolExit(
          'Failed to create directory for flutter cache at ${location.path}. '
          'Flutter may be missing permissions in its cache directory.'
        );
      }
    }
    await updateInner();
    try {
      cache.setStampFor(stampName, version);
    } on FileSystemException catch (err) {
      globals.printError(
        'The new artifact "$name" was downloaded, but Flutter failed to update '
        'its stamp file, receiving the error "$err". '
        'Flutter can continue, but the artifact may be re-downloaded on '
        'subsequent invocations until the problem is resolved.',
      );
    }
    _removeDownloadedFiles();
  }

  /// Clear any zip/gzip files downloaded.
  void _removeDownloadedFiles() {
    for (final File f in downloadedFiles) {
      try {
        f.deleteSync();
      } on FileSystemException catch (e) {
        globals.printError('Failed to delete "${f.path}". Please delete manually. $e');
        continue;
      }
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
  bool isUpToDateInner() => true;


  /// Template method to perform artifact update.
  Future<void> updateInner();

  Uri _toStorageUri(String path) => Uri.parse('${cache.storageBaseUrl}/$path');

  /// Download an archive from the given [url] and unzip it to [location].
  Future<void> _downloadArchive(String message, Uri url, Directory location, bool verifier(File f), void extractor(File f, Directory d)) {
    return _withDownloadFile(flattenNameSubdirs(url), (File tempFile) async {
      if (!verifier(tempFile)) {
        final Status status = globals.logger.startProgress(message, timeout: timeoutConfiguration.slowOperation);
        try {
          await cache.downloadFile(url, tempFile);
          status.stop();
        // The exception is rethrown, so don't catch only Exceptions.
        } catch (exception) { // ignore: avoid_catches_without_on_clauses
          status.cancel();
          rethrow;
        }
      } else {
        globals.logger.printTrace('$message (cached)');
      }
      _ensureExists(location);
      extractor(tempFile, location);
    });
  }

  /// Download a zip archive from the given [url] and unzip it to [location].
  Future<void> _downloadZipArchive(String message, Uri url, Directory location) {
    return _downloadArchive(message, url, location, globals.os.verifyZip, globals.os.unzip);
  }

  /// Download a gzipped tarball from the given [url] and unpack it to [location].
  Future<void> _downloadZippedTarball(String message, Uri url, Directory location) {
    return _downloadArchive(message, url, location, globals.os.verifyGzip, globals.os.unpack);
  }

  /// Create a temporary file and invoke [onTemporaryFile] with the file as
  /// argument, then add the temporary file to the [downloadedFiles].
  Future<void> _withDownloadFile(String name, Future<void> onTemporaryFile(File file)) async {
    final File tempFile = globals.fs.file(globals.fs.path.join(cache.getDownloadDir().path, name));
    downloadedFiles.add(tempFile);
    await onTemporaryFile(tempFile);
  }
}

/// A cached artifact containing fonts used for Material Design.
class MaterialFonts extends CachedArtifact {
  MaterialFonts(Cache cache) : super(
    'material_fonts',
    cache,
    DevelopmentArtifact.universal,
  );

  @override
  Future<void> updateInner() {
    final Uri archiveUri = _toStorageUri(version);
    return _downloadZipArchive('Downloading Material fonts...', archiveUri, location);
  }
}

/// A cached artifact containing the web dart:ui sources, platform dill files,
/// and libraries.json.
///
/// This SDK references code within the regular Dart sdk to reduce download size.
class FlutterWebSdk extends CachedArtifact {
  FlutterWebSdk(Cache cache) : super(
    'flutter_web_sdk',
    cache,
    DevelopmentArtifact.web,
  );

  @override
  Directory get location => cache.getWebSdkDirectory();

  @override
  String get version => cache.getVersionFor('engine');

  @override
  Future<void> updateInner() async {
    String platformName = 'flutter-web-sdk-';
    if (globals.platform.isMacOS) {
      platformName += 'darwin-x64';
    } else if (globals.platform.isLinux) {
      platformName += 'linux-x64';
    } else if (globals.platform.isWindows) {
      platformName += 'windows-x64';
    }
    final Uri url = Uri.parse('${cache.storageBaseUrl}/flutter_infra/flutter/$version/$platformName.zip');
    await _downloadZipArchive('Downloading Web SDK...', url, location);
    // This is a temporary work-around for not being able to safely download into a shared directory.
    for (final FileSystemEntity entity in location.listSync(recursive: true)) {
      if (entity is File) {
        final List<String> segments = globals.fs.path.split(entity.path);
        segments.remove('flutter_web_sdk');
        final String newPath = globals.fs.path.joinAll(segments);
        final File newFile = globals.fs.file(newPath);
        if (!newFile.existsSync()) {
          newFile.createSync(recursive: true);
        }
        entity.copySync(newPath);
      }
    }
  }
}

abstract class EngineCachedArtifact extends CachedArtifact {
  EngineCachedArtifact(
    this.stampName,
    Cache cache,
    DevelopmentArtifact developmentArtifact,
  ) : super('engine', cache, developmentArtifact);

  @override
  final String stampName;

  /// Return a list of (directory path, download URL path) tuples.
  List<List<String>> getBinaryDirs();

  /// A list of cache directory paths to which the LICENSE file should be copied.
  List<String> getLicenseDirs();

  /// A list of the dart package directories to download.
  List<String> getPackageDirs();

  @override
  bool isUpToDateInner() {
    final Directory pkgDir = cache.getCacheDir('pkg');
    for (final String pkgName in getPackageDirs()) {
      final String pkgPath = globals.fs.path.join(pkgDir.path, pkgName);
      if (!globals.fs.directory(pkgPath).existsSync()) {
        return false;
      }
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final Directory dir = globals.fs.directory(globals.fs.path.join(location.path, toolsDir[0]));
      if (!dir.existsSync()) {
        return false;
      }
    }

    for (final String licenseDir in getLicenseDirs()) {
      final File file = globals.fs.file(globals.fs.path.join(location.path, licenseDir, 'LICENSE'));
      if (!file.existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner() async {
    final String url = '${cache.storageBaseUrl}/flutter_infra/flutter/$version/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (final String pkgName in getPackageDirs()) {
      await _downloadZipArchive('Downloading package $pkgName...', Uri.parse(url + pkgName + '.zip'), pkgDir);
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = globals.fs.directory(globals.fs.path.join(location.path, cacheDir));

      // Avoid printing things like 'Downloading linux-x64 tools...' multiple times.
      final String friendlyName = urlPath.replaceAll('/artifacts.zip', '').replaceAll('.zip', '');
      await _downloadZipArchive('Downloading $friendlyName tools...', Uri.parse(url + urlPath), dir);

      _makeFilesExecutable(dir);

      const List<String> frameworkNames = <String>['Flutter', 'FlutterMacOS'];
      for (final String frameworkName in frameworkNames) {
        final File frameworkZip = globals.fs.file(globals.fs.path.join(dir.path, '$frameworkName.framework.zip'));
        if (frameworkZip.existsSync()) {
          final Directory framework = globals.fs.directory(globals.fs.path.join(dir.path, '$frameworkName.framework'));
          framework.createSync();
          globals.os.unzip(frameworkZip, framework);
        }
      }
    }

    final File licenseSource = cache.getLicenseFile();
    for (final String licenseDir in getLicenseDirs()) {
      final String licenseDestinationPath = globals.fs.path.join(location.path, licenseDir, 'LICENSE');
      await licenseSource.copy(licenseDestinationPath);
    }
  }

  Future<bool> checkForArtifacts(String engineVersion) async {
    engineVersion ??= version;
    final String url = '${cache.storageBaseUrl}/flutter_infra/flutter/$engineVersion/';

    bool exists = false;
    for (final String pkgName in getPackageDirs()) {
      exists = await cache.doesRemoteExist('Checking package $pkgName is available...',
          Uri.parse(url + pkgName + '.zip'));
      if (!exists) {
        return false;
      }
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      exists = await cache.doesRemoteExist('Checking $cacheDir tools are available...',
          Uri.parse(url + urlPath));
      if (!exists) {
        return false;
      }
    }
    return true;
  }

  void _makeFilesExecutable(Directory dir) {
    globals.os.chmod(dir, 'a+r,a+x');
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final FileStat stat = entity.statSync();
        final bool isUserExecutable = ((stat.mode >> 6) & 0x1) == 1;
        if (entity.basename == 'flutter_tester' || isUserExecutable) {
          // Make the file readable and executable by all users.
          globals.os.chmod(entity, 'a+r,a+x');
        }
      }
    }
  }
}


/// A cached artifact containing the dart:ui source code.
class FlutterSdk extends EngineCachedArtifact {
  FlutterSdk(Cache cache) : super(
    'flutter_sdk',
    cache,
    DevelopmentArtifact.universal,
  );

  @override
  List<String> getPackageDirs() => const <String>['sky_engine'];

  @override
  List<List<String>> getBinaryDirs() {
    return <List<String>>[
      <String>['common', 'flutter_patched_sdk.zip'],
      <String>['common', 'flutter_patched_sdk_product.zip'],
      if (cache.includeAllPlatforms) ...<List<String>>[
        <String>['windows-x64', 'windows-x64/artifacts.zip'],
        <String>['linux-x64', 'linux-x64/artifacts.zip'],
        <String>['darwin-x64', 'darwin-x64/artifacts.zip'],
      ]
      else if (globals.platform.isWindows)
        <String>['windows-x64', 'windows-x64/artifacts.zip']
      else if (globals.platform.isMacOS)
        <String>['darwin-x64', 'darwin-x64/artifacts.zip']
      else if (globals.platform.isLinux)
        <String>['linux-x64', 'linux-x64/artifacts.zip'],
    ];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

class MacOSEngineArtifacts extends EngineCachedArtifact {
  MacOSEngineArtifacts(Cache cache) : super(
    'macos-sdk',
    cache,
    DevelopmentArtifact.macOS,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (globals.platform.isMacOS) {
      return _macOSDesktopBinaryDirs;
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

class WindowsEngineArtifacts extends EngineCachedArtifact {
  WindowsEngineArtifacts(Cache cache) : super(
    'windows-sdk',
    cache,
    DevelopmentArtifact.windows,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (globals.platform.isWindows) {
      return _windowsDesktopBinaryDirs;
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

class LinuxEngineArtifacts extends EngineCachedArtifact {
  LinuxEngineArtifacts(Cache cache) : super(
    'linux-sdk',
    cache,
    DevelopmentArtifact.linux,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (globals.platform.isLinux) {
      return _linuxDesktopBinaryDirs;
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

/// The artifact used to generate snapshots for Android builds.
class AndroidGenSnapshotArtifacts extends EngineCachedArtifact {
  AndroidGenSnapshotArtifacts(Cache cache) : super(
    'android-sdk',
    cache,
    DevelopmentArtifact.androidGenSnapshot,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    return <List<String>>[
      if (cache.includeAllPlatforms) ...<List<String>>[
        ..._osxBinaryDirs,
        ..._linuxBinaryDirs,
        ..._windowsBinaryDirs,
        ..._dartSdks,
      ] else if (globals.platform.isWindows)
        ..._windowsBinaryDirs
      else if (globals.platform.isMacOS)
        ..._osxBinaryDirs
      else if (globals.platform.isLinux)
        ..._linuxBinaryDirs,
    ];
  }

  @override
  List<String> getLicenseDirs() { return <String>[]; }
}

/// Artifacts used for internal builds. The flutter tool builds Android projects
/// using the artifacts cached by [AndroidMavenArtifacts].
class AndroidInternalBuildArtifacts extends EngineCachedArtifact {
  AndroidInternalBuildArtifacts(Cache cache) : super(
    'android-internal-build-artifacts',
    cache,
    DevelopmentArtifact.androidInternalBuild,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    return _androidBinaryDirs;
  }

  @override
  List<String> getLicenseDirs() { return <String>[]; }
}

/// A cached artifact containing the Maven dependencies used to build Android projects.
class AndroidMavenArtifacts extends ArtifactSet {
  AndroidMavenArtifacts() : super(DevelopmentArtifact.androidMaven);

  @override
  Future<void> update() async {
    final Directory tempDir =
        globals.fs.systemTempDirectory.createTempSync('flutter_gradle_wrapper.');
    gradleUtils.injectGradleWrapperIfNeeded(tempDir);

    final Status status = globals.logger.startProgress('Downloading Android Maven dependencies...',
        timeout: timeoutConfiguration.slowOperation);
    final File gradle = tempDir.childFile(
        globals.platform.isWindows ? 'gradlew.bat' : 'gradlew',
      );
    try {
      final String gradleExecutable = gradle.absolute.path;
      final String flutterSdk = globals.fsUtils.escapePath(Cache.flutterRoot);
      final RunResult processResult = await globals.processUtils.run(
        <String>[
          gradleExecutable,
          '-b', globals.fs.path.join(flutterSdk, 'packages', 'flutter_tools', 'gradle', 'resolve_dependencies.gradle'),
          '--project-cache-dir', tempDir.path,
          'resolveDependencies',
        ],
        environment: gradleEnvironment);
      if (processResult.exitCode != 0) {
        globals.printError('Failed to download the Android dependencies');
      }
    } finally {
      status.stop();
      tempDir.deleteSync(recursive: true);
    }
  }

  @override
  bool isUpToDate() {
    // The dependencies are downloaded and cached by Gradle.
    // The tool doesn't know if the dependencies are already cached at this point.
    // Therefore, call Gradle to figure this out.
    return false;
  }
}

class IOSEngineArtifacts extends EngineCachedArtifact {
  IOSEngineArtifacts(Cache cache) : super(
    'ios-sdk',
    cache,
    DevelopmentArtifact.iOS,
  );

  @override
  List<List<String>> getBinaryDirs() {
    return <List<String>>[
      if (globals.platform.isMacOS || cache.includeAllPlatforms)
        ..._iosBinaryDirs,
    ];
  }

  @override
  List<String> getLicenseDirs() {
    if (cache.includeAllPlatforms || globals.platform.isMacOS) {
      return const <String>['ios', 'ios-profile', 'ios-release'];
    }
    return const <String>[];
  }

  @override
  List<String> getPackageDirs() {
    return <String>[];
  }
}

/// A cached artifact containing Gradle Wrapper scripts and binaries.
///
/// While this is only required for Android, we need to always download it due
/// the ensurePlatformSpecificTooling logic.
class GradleWrapper extends CachedArtifact {
  GradleWrapper(Cache cache) : super(
    'gradle_wrapper',
    cache,
    DevelopmentArtifact.universal,
  );

  List<String> get _gradleScripts => <String>['gradlew', 'gradlew.bat'];

  String get _gradleWrapper => globals.fs.path.join('gradle', 'wrapper', 'gradle-wrapper.jar');

  @override
  Future<void> updateInner() {
    final Uri archiveUri = _toStorageUri(version);
    return _downloadZippedTarball('Downloading Gradle Wrapper...', archiveUri, location).then<void>((_) {
      // Delete property file, allowing templates to provide it.
      globals.fs.file(globals.fs.path.join(location.path, 'gradle', 'wrapper', 'gradle-wrapper.properties')).deleteSync();
      // Remove NOTICE file. Should not be part of the template.
      globals.fs.file(globals.fs.path.join(location.path, 'NOTICE')).deleteSync();
    });
  }

  @override
  bool isUpToDateInner() {
    final Directory wrapperDir = cache.getCacheDir(globals.fs.path.join('artifacts', 'gradle_wrapper'));
    if (!globals.fs.directory(wrapperDir).existsSync()) {
      return false;
    }
    for (final String scriptName in _gradleScripts) {
      final File scriptFile = globals.fs.file(globals.fs.path.join(wrapperDir.path, scriptName));
      if (!scriptFile.existsSync()) {
        return false;
      }
    }
    final File gradleWrapperJar = globals.fs.file(globals.fs.path.join(wrapperDir.path, _gradleWrapper));
    if (!gradleWrapperJar.existsSync()) {
      return false;
    }
    return true;
  }
}

 const String _cipdBaseUrl =
    'https://chrome-infra-packages.appspot.com/dl';

/// Common functionality for pulling Fuchsia SDKs.
abstract class _FuchsiaSDKArtifacts extends CachedArtifact {
  _FuchsiaSDKArtifacts(Cache cache, String platform) :
    _path = 'fuchsia/sdk/core/$platform-amd64',
    super(
      'fuchsia-$platform',
      cache,
      DevelopmentArtifact.fuchsia,
    );

  final String _path;

  @override
  Directory get location => cache.getArtifactDirectory('fuchsia');

  Future<void> _doUpdate() {
    final String url = '$_cipdBaseUrl/$_path/+/$version';
    return _downloadZipArchive('Downloading package fuchsia SDK...',
                               Uri.parse(url), location);
  }
}

/// The pre-built flutter runner for Fuchsia development.
class FlutterRunnerSDKArtifacts extends CachedArtifact {
  FlutterRunnerSDKArtifacts(Cache cache) : super(
    'flutter_runner',
    cache,
    DevelopmentArtifact.flutterRunner,
  );

  @override
  Directory get location => cache.getArtifactDirectory('flutter_runner');

  @override
  String get version => cache.getVersionFor('engine');

  @override
  Future<void> updateInner() async {
    if (!globals.platform.isLinux && !globals.platform.isMacOS) {
      return Future<void>.value();
    }
    final String url = '$_cipdBaseUrl/flutter/fuchsia/+/git_revision:$version';
    await _downloadZipArchive('Downloading package flutter runner...',
        Uri.parse(url), location);
  }
}

/// Implementations of this class can resolve URLs for packages that are versioned.
///
/// See also [CipdArchiveResolver].
abstract class VersionedPackageResolver {
  const VersionedPackageResolver();

  /// Returns the URL for the artifact.
  String resolveUrl(String packageName, String version);
}

/// Resolves the CIPD archive URL for a given package and version.
class CipdArchiveResolver extends VersionedPackageResolver {
  const CipdArchiveResolver();

  @override
  String resolveUrl(String packageName, String version) {
    return '$_cipdBaseUrl/flutter/$packageName/+/git_revision:$version';
  }
}

/// The debug symbols for flutter runner for Fuchsia development.
class FlutterRunnerDebugSymbols extends CachedArtifact {
  FlutterRunnerDebugSymbols(Cache cache, {this.packageResolver = const CipdArchiveResolver(), this.dryRun = false})
      : super('flutter_runner_debug_symbols', cache, DevelopmentArtifact.flutterRunner);

  final VersionedPackageResolver packageResolver;

  final bool dryRun;

  @override
  Directory get location => cache.getArtifactDirectory(name);

  @override
  String get version => cache.getVersionFor('engine');

  Future<void> _downloadDebugSymbols(String targetArch) async {
    final String packageName = 'fuchsia-debug-symbols-$targetArch';
    final String url = packageResolver.resolveUrl(packageName, version);
    if (!dryRun) {
      await _downloadZipArchive(
          'Downloading debug symbols for flutter runner - arch:$targetArch...',
          Uri.parse(url),
          location);
    }
  }

  @override
  Future<void> updateInner() async {
    if (!globals.platform.isLinux && !globals.platform.isMacOS) {
      return Future<void>.value();
    }
    await _downloadDebugSymbols('x64');
    await _downloadDebugSymbols('arm64');
  }
}

/// The Fuchsia core SDK for Linux.
class LinuxFuchsiaSDKArtifacts extends _FuchsiaSDKArtifacts {
  LinuxFuchsiaSDKArtifacts(Cache cache) : super(cache, 'linux');

  @override
  Future<void> updateInner() {
    if (!globals.platform.isLinux) {
      return Future<void>.value();
    }
    return _doUpdate();
  }
}

/// The Fuchsia core SDK for MacOS.
class MacOSFuchsiaSDKArtifacts extends _FuchsiaSDKArtifacts {
  MacOSFuchsiaSDKArtifacts(Cache cache) : super(cache, 'mac');

  @override
  Future<void> updateInner() async {
    if (!globals.platform.isMacOS) {
      return Future<void>.value();
    }
    return _doUpdate();
  }
}

/// Cached artifacts for font subsetting.
class FontSubsetArtifacts extends EngineCachedArtifact {
  FontSubsetArtifacts(Cache cache) : super(artifactName, cache, DevelopmentArtifact.universal);

  static const String artifactName = 'font-subset';

  @override
  List<List<String>> getBinaryDirs() {
    const Map<String, List<String>> artifacts = <String, List<String>> {
      'macos': <String>['darwin-x64', 'darwin-x64/$artifactName.zip'],
      'linux': <String>['linux-x64', 'linux-x64/$artifactName.zip'],
      'windows': <String>['windows-x64', 'windows-x64/$artifactName.zip'],
    };
    if (cache.includeAllPlatforms) {
      return artifacts.values.toList();
    } else {
      final List<String> binaryDirs = artifacts[globals.platform.operatingSystem];
      if (binaryDirs == null) {
        throwToolExit('Unsupported operating system: ${globals.platform.operatingSystem}');
      }
      return <List<String>>[binaryDirs];
    }
  }

  @override
  List<String> getLicenseDirs() => const <String>[];

  @override
  List<String> getPackageDirs() => const <String>[];
}

/// Cached iOS/USB binary artifacts.
class IosUsbArtifacts extends CachedArtifact {
  IosUsbArtifacts(String name, Cache cache) : super(
    name,
    cache,
    // This is universal to ensure every command checks for them first
    DevelopmentArtifact.universal,
  );

  static const List<String> artifactNames = <String>[
    'libimobiledevice',
    'usbmuxd',
    'libplist',
    'openssl',
    'ios-deploy',
  ];

  // For unknown reasons, users are getting into bad states where libimobiledevice is
  // downloaded but some executables are missing from the zip. The names here are
  // used for additional download checks below, so we can redownload if they are
  // missing.
  static const Map<String, List<String>> _kExecutables = <String, List<String>>{
    'libimobiledevice': <String>[
      'idevicescreenshot',
      'idevicesyslog',
    ],
    'usbmuxd': <String>[
      'iproxy',
    ],
  };

  @override
  Map<String, String> get environment {
    return <String, String>{
      'DYLD_LIBRARY_PATH': cache.getArtifactDirectory(name).path,
    };
  }

  @override
  bool isUpToDateInner() {
    final List<String> executables =_kExecutables[name];
    if (executables == null) {
      return true;
    }
    for (final String executable in executables) {
      if (!location.childFile(executable).existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner() {
    if (!globals.platform.isMacOS && !cache.includeAllPlatforms) {
      return Future<void>.value();
    }
    if (location.existsSync()) {
      location.deleteSync(recursive: true);
    }
    return _downloadZipArchive('Downloading $name...', archiveUri, location);
  }

  @visibleForTesting
  Uri get archiveUri => Uri.parse('${cache.storageBaseUrl}/flutter_infra/ios-usb-dependencies${cache.useUnsignedMacBinaries ? '/unsigned' : ''}/$name/$version/$name.zip');
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
  r'?'.codeUnitAt(0): '@ques@'.codeUnits,
};

/// Given a name containing slashes, colons, and backslashes, expand it into
/// something that doesn't.
String _flattenNameNoSubdirs(String fileName) {
  final List<int> replacedCodeUnits = <int>[
    for (int codeUnit in fileName.codeUnits)
      ..._flattenNameSubstitutions[codeUnit] ?? <int>[codeUnit],
  ];
  return String.fromCharCodes(replacedCodeUnits);
}

@visibleForTesting
String flattenNameSubdirs(Uri url) {
  final List<String> pieces = <String>[url.host, ...url.pathSegments];
  final Iterable<String> convertedPieces = pieces.map<String>(_flattenNameNoSubdirs);
  return globals.fs.path.joinAll(convertedPieces);
}

/// Create the given [directory] and parents, as necessary.
void _ensureExists(Directory directory) {
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
}

const List<List<String>> _windowsDesktopBinaryDirs = <List<String>>[
  <String>['windows-x64', 'windows-x64/windows-x64-flutter.zip'],
  <String>['windows-x64', 'windows-x64/flutter-cpp-client-wrapper.zip'],
];

const List<List<String>> _linuxDesktopBinaryDirs = <List<String>>[
  <String>['linux-x64', 'linux-x64/linux-x64-flutter-glfw.zip'],
  <String>['linux-x64', 'linux-x64/flutter-cpp-client-wrapper-glfw.zip'],
];

// TODO(jonahwilliams): upload debug desktop artifacts to host-debug and
// remove from existing host folder.
// https://github.com/flutter/flutter/issues/38935
const List<List<String>> _macOSDesktopBinaryDirs = <List<String>>[
  <String>['darwin-x64', 'darwin-x64/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-profile', 'darwin-x64-profile/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-profile', 'darwin-x64-profile/artifacts.zip'],
  <String>['darwin-x64-release', 'darwin-x64-release/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-release', 'darwin-x64-release/artifacts.zip'],
];

const List<List<String>> _osxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/darwin-x64', 'android-arm-profile/darwin-x64.zip'],
  <String>['android-arm-release/darwin-x64', 'android-arm-release/darwin-x64.zip'],
  <String>['android-arm64-profile/darwin-x64', 'android-arm64-profile/darwin-x64.zip'],
  <String>['android-arm64-release/darwin-x64', 'android-arm64-release/darwin-x64.zip'],
  <String>['android-x64-profile/darwin-x64', 'android-x64-profile/darwin-x64.zip'],
  <String>['android-x64-release/darwin-x64', 'android-x64-release/darwin-x64.zip'],
];

const List<List<String>> _linuxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/linux-x64', 'android-arm-profile/linux-x64.zip'],
  <String>['android-arm-release/linux-x64', 'android-arm-release/linux-x64.zip'],
  <String>['android-arm64-profile/linux-x64', 'android-arm64-profile/linux-x64.zip'],
  <String>['android-arm64-release/linux-x64', 'android-arm64-release/linux-x64.zip'],
  <String>['android-x64-profile/linux-x64', 'android-x64-profile/linux-x64.zip'],
  <String>['android-x64-release/linux-x64', 'android-x64-release/linux-x64.zip'],
];

const List<List<String>> _windowsBinaryDirs = <List<String>>[
  <String>['android-arm-profile/windows-x64', 'android-arm-profile/windows-x64.zip'],
  <String>['android-arm-release/windows-x64', 'android-arm-release/windows-x64.zip'],
  <String>['android-arm64-profile/windows-x64', 'android-arm64-profile/windows-x64.zip'],
  <String>['android-arm64-release/windows-x64', 'android-arm64-release/windows-x64.zip'],
  <String>['android-x64-profile/windows-x64', 'android-x64-profile/windows-x64.zip'],
  <String>['android-x64-release/windows-x64', 'android-x64-release/windows-x64.zip'],
];

const List<List<String>> _iosBinaryDirs = <List<String>>[
  <String>['ios', 'ios/artifacts.zip'],
  <String>['ios-profile', 'ios-profile/artifacts.zip'],
  <String>['ios-release', 'ios-release/artifacts.zip'],
];

const List<List<String>> _androidBinaryDirs = <List<String>>[
  <String>['android-x86', 'android-x86/artifacts.zip'],
  <String>['android-x64', 'android-x64/artifacts.zip'],
  <String>['android-arm', 'android-arm/artifacts.zip'],
  <String>['android-arm-profile', 'android-arm-profile/artifacts.zip'],
  <String>['android-arm-release', 'android-arm-release/artifacts.zip'],
  <String>['android-arm64', 'android-arm64/artifacts.zip'],
  <String>['android-arm64-profile', 'android-arm64-profile/artifacts.zip'],
  <String>['android-arm64-release', 'android-arm64-release/artifacts.zip'],
  <String>['android-x64-profile', 'android-x64-profile/artifacts.zip'],
  <String>['android-x64-release', 'android-x64-release/artifacts.zip'],
  <String>['android-x86-jit-release', 'android-x86-jit-release/artifacts.zip'],
];

const List<List<String>> _dartSdks = <List<String>> [
  <String>['darwin-x64', 'dart-sdk-darwin-x64.zip'],
  <String>['linux-x64', 'dart-sdk-linux-x64.zip'],
  <String>['windows-x64', 'dart-sdk-windows-x64.zip'],
];
