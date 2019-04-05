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
import 'globals.dart';

/// A tag for a set of development artifacts that need to be cached.
enum DevelopmentArtifact {
  /// Artifacts required for Android development.
  android,

  /// Artifacts required for iOS development.
  iOS,

  /// Artifacts required for web development,
  web,

  /// Artifacts required for desktop macOS.
  macOS,

  /// Artifacts required for desktop Windows.
  windows,

  /// Artifacts required for desktop linux.
  linux,

  /// Artifacts required by all developments.
  universal,
}

/// A wrapper around the `bin/cache/` directory.
class Cache {
  /// [rootOverride] is configurable for testing.
  /// [artifacts] is configurable for testing.
  Cache({ Directory rootOverride, List<CachedArtifact> artifacts }) : _rootOverride = rootOverride {
    if (artifacts == null) {
      _artifacts.add(MaterialFonts(this));
      _artifacts.add(AndroidEngineArtifacts(this));
      _artifacts.add(IOSEngineArtifacts(this));
      _artifacts.add(GradleWrapper(this));
      _artifacts.add(FlutterWebSdk(this));
      _artifacts.add(FlutterSdk(this));
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

  /// The web sdk has to be co-located with the dart-sdk so that they can share source
  /// code.
  Directory getWebSdkDirectory() {
    return getRoot().childDirectory('flutter_web_sdk');
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

  bool isUpToDate() => _artifacts.every((CachedArtifact artifact) => artifact.isUpToDate());

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

  /// Update the cache to contain all `requiredArtifacts`.
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts) async {
    if (!_lockEnabled) {
      return;
    }
    try {
      for (CachedArtifact artifact in _artifacts) {
        if (!artifact.isUpToDate()) {
          await artifact.update(requiredArtifacts);
        }
      }
    } on SocketException catch (e) {
      if (_hostsBlockedInChina.contains(e.address?.host)) {
        printError(
          'Failed to retrieve Flutter tool dependencies: ${e.message}.\n'
          'If you\'re in China, please see this page: '
          'https://flutter.dev/community/china',
          emphasis: true,
        );
      }
      rethrow;
    }
  }

  Future<bool> areRemoteArtifactsAvailable({
    String engineVersion,
    bool includeAllPlatforms = true,
  }) async {
    final bool includeAllPlatformsState = cache.includeAllPlatforms;
    bool allAvailible = true;
    cache.includeAllPlatforms = includeAllPlatforms;
    for (CachedArtifact cachedArtifact in _artifacts) {
      if (cachedArtifact is EngineCachedArtifact) {
        allAvailible &= await cachedArtifact.checkForArtifacts(engineVersion);
      }
    }
    cache.includeAllPlatforms = includeAllPlatformsState;
    return allAvailible;
  }
}

/// An artifact managed by the cache.
abstract class CachedArtifact {
  CachedArtifact(this.name, this.cache, this.developmentArtifacts);

  final String name;
  final Cache cache;

  // The name of the stamp file. Defaults to the same as the
  // artifact name.
  String get stampName => name;

  /// All development artifacts this cache provides.
  final Set<DevelopmentArtifact> developmentArtifacts;

  Directory get location => cache.getArtifactDirectory(name);
  String get version => cache.getVersionFor(name);

  /// Keep track of the files we've downloaded for this execution so we
  /// can delete them after completion. We don't delete them right after
  /// extraction in case [update] is interrupted, so we can restart without
  /// starting from scratch.
  final List<File> _downloadedFiles = <File>[];

  bool isUpToDate() {
    if (!location.existsSync()) {
      return false;
    }
    if (version != cache.getStampFor(stampName)) {
      return false;
    }
    return isUpToDateInner();
  }

  Future<void> update(Set<DevelopmentArtifact> requiredArtifacts) async {
    // If the set of required artifacts does not include any from this cache,
    // then we can claim we are up to date to skip downloading.
    if (!requiredArtifacts.any(developmentArtifacts.contains)) {
      printTrace('Artifact $this is not required, skipping update.');
      return;
    }
    if (!location.existsSync()) {
      location.createSync(recursive: true);
    }
    await updateInner();
    cache.setStampFor(stampName, version);
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
  bool isUpToDateInner() => true;

  /// Template method to perform artifact update.
  Future<void> updateInner();

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
        final Status status = logger.startProgress(message, timeout: timeoutConfiguration.slowOperation);
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
  MaterialFonts(Cache cache) : super(
    'material_fonts',
    cache,
    const <DevelopmentArtifact>{ DevelopmentArtifact.universal },
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
    const <DevelopmentArtifact>{ DevelopmentArtifact.web },
  );

  @override
  Directory get location => cache.getWebSdkDirectory();

  @override
  String get version => cache.getVersionFor('engine');

  @override
  Future<void> updateInner() async {
    String platformName = 'flutter-web-sdk-';
    if (platform.isMacOS) {
      platformName += 'darwin-x64';
    } else if (platform.isLinux) {
      platformName += 'linux-x64';
    } else if (platform.isWindows) {
      platformName += 'windows-x64';
    }
    final Uri url = Uri.parse('$_storageBaseUrl/flutter_infra/flutter/$version/$platformName.zip');
    await _downloadZipArchive('Downloading Web SDK...', url, location);
    // This is a temporary work-around for not being able to safely download into a shared directory.
    for (FileSystemEntity entity in location.listSync(recursive: true)) {
      if (entity is File) {
        final List<String> segments = fs.path.split(entity.path);
        segments.remove('flutter_web_sdk');
        final String newPath = fs.path.joinAll(segments);
        final File newFile = fs.file(newPath);
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
    Set<DevelopmentArtifact> requiredArtifacts,
  ) : super('engine', cache, requiredArtifacts);

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
    for (String pkgName in getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      if (!fs.directory(pkgPath).existsSync()) {
        return false;
      }
    }

    for (List<String> toolsDir in getBinaryDirs()) {
      final Directory dir = fs.directory(fs.path.join(location.path, toolsDir[0]));
      if (!dir.existsSync()) {
        return false;
      }
    }

    for (String licenseDir in getLicenseDirs()) {
      final File file = fs.file(fs.path.join(location.path, licenseDir, 'LICENSE'));
      if (!file.existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner() async {
    final String url = '$_storageBaseUrl/flutter_infra/flutter/$version/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in getPackageDirs()) {
      await _downloadZipArchive('Downloading package $pkgName...', Uri.parse(url + pkgName + '.zip'), pkgDir);
    }

    for (List<String> toolsDir in getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = fs.directory(fs.path.join(location.path, cacheDir));
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
    for (String licenseDir in getLicenseDirs()) {
      final String licenseDestinationPath = fs.path.join(location.path, licenseDir, 'LICENSE');
      await licenseSource.copy(licenseDestinationPath);
    }
  }

  Future<bool> checkForArtifacts(String engineVersion) async {
    engineVersion ??= version;
    final String url = '$_storageBaseUrl/flutter_infra/flutter/$engineVersion/';

    bool exists = false;
    for (String pkgName in getPackageDirs()) {
      exists = await _doesRemoteExist('Checking package $pkgName is available...',
          Uri.parse(url + pkgName + '.zip'));
      if (!exists) {
        return false;
      }
    }

    for (List<String> toolsDir in getBinaryDirs()) {
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


/// A cached artifact containing the dart:ui source code.
class FlutterSdk extends EngineCachedArtifact {
  FlutterSdk(Cache cache) : super(
    'flutter_sdk',
    cache,
    const <DevelopmentArtifact>{ DevelopmentArtifact.universal },
  );

  @override
  List<String> getPackageDirs() => const <String>['sky_engine'];

  @override
  List<List<String>> getBinaryDirs() {
    final List<List<String>> binaryDirs = <List<String>>[
      <String>['common', 'flutter_patched_sdk.zip'],
    ];
    if (cache.includeAllPlatforms) {
      binaryDirs.addAll(<List<String>>[
        <String>['windows-x64', 'windows-x64/artifacts.zip'],
        <String>['linux-x64', 'linux-x64/artifacts.zip'],
        <String>['darwin-x64', 'darwin-x64/artifacts.zip'],
      ]);
    } else if (platform.isWindows) {
      binaryDirs.addAll(<List<String>>[
        <String>['windows-x64', 'windows-x64/artifacts.zip'],
      ]);
    } else if (platform.isMacOS) {
      binaryDirs.addAll(<List<String>>[
        <String>['darwin-x64', 'darwin-x64/artifacts.zip'],
      ]);
    } else if (platform.isLinux) {
      binaryDirs.addAll(<List<String>>[
        <String>['linux-x64', 'linux-x64/artifacts.zip'],
      ]);
    }
    return binaryDirs;
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

class AndroidEngineArtifacts extends EngineCachedArtifact {
  AndroidEngineArtifacts(Cache cache) : super(
    'android-sdk',
    cache,
    const <DevelopmentArtifact>{ DevelopmentArtifact.android },
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    final List<List<String>> binaryDirs = <List<String>>[];
    if (cache.includeAllPlatforms) {
      binaryDirs
        ..addAll(_osxBinaryDirs)
        ..addAll(_linuxBinaryDirs)
        ..addAll(_windowsBinaryDirs)
        ..addAll(_androidBinaryDirs)
        ..addAll(_dartSdks);
    } else if (platform.isWindows) {
      binaryDirs
        ..addAll(_windowsBinaryDirs)
        ..addAll(_androidBinaryDirs);
    } else if (platform.isMacOS) {
      binaryDirs
        ..addAll(_osxBinaryDirs)
        ..addAll(_androidBinaryDirs);
    } else if (platform.isLinux) {
      binaryDirs
        ..addAll(_linuxBinaryDirs)
        ..addAll(_androidBinaryDirs);
    }
    return binaryDirs;
  }

  @override
  List<String> getLicenseDirs() { return <String>[]; }
}

class IOSEngineArtifacts extends EngineCachedArtifact {
  IOSEngineArtifacts(Cache cache) : super(
    'ios-sdk',
    cache,
    <DevelopmentArtifact>{ DevelopmentArtifact.iOS },
  );

  @override
  List<List<String>> getBinaryDirs() {
    final List<List<String>> binaryDirs = <List<String>>[];
    if (platform.isMacOS || cache.includeAllPlatforms) {
      binaryDirs.addAll(_iosBinaryDirs);
    }
    return binaryDirs;
  }

  @override
  List<String> getLicenseDirs() {
    if (cache.includeAllPlatforms || platform.isMacOS) {
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
class GradleWrapper extends CachedArtifact {
  GradleWrapper(Cache cache) : super(
    'gradle_wrapper',
    cache,
    const <DevelopmentArtifact>{ DevelopmentArtifact.android },
  );

  List<String> get _gradleScripts => <String>['gradlew', 'gradlew.bat'];

  String get _gradleWrapper => fs.path.join('gradle', 'wrapper', 'gradle-wrapper.jar');

  @override
  Future<void> updateInner() {
    final Uri archiveUri = _toStorageUri(version);
    return _downloadZippedTarball('Downloading Gradle Wrapper...', archiveUri, location).then<void>((_) {
      // Delete property file, allowing templates to provide it.
      fs.file(fs.path.join(location.path, 'gradle', 'wrapper', 'gradle-wrapper.properties')).deleteSync();
      // Remove NOTICE file. Should not be part of the template.
      fs.file(fs.path.join(location.path, 'NOTICE')).deleteSync();
    });
  }

  @override
  bool isUpToDateInner() {
    final Directory wrapperDir = cache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'));
    if (!fs.directory(wrapperDir).existsSync()) {
      return false;
    }
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
  r'?'.codeUnitAt(0): '@ques@'.codeUnits,
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
  final Status status = logger.startProgress(message, timeout: timeoutConfiguration.slowOperation);
  final bool exists = await doesRemoteFileExist(url);
  status.stop();
  return exists;
}

/// Create the given [directory] and parents, as necessary.
void _ensureExists(Directory directory) {
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
}

const List<List<String>> _osxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/darwin-x64', 'android-arm-profile/darwin-x64.zip'],
  <String>['android-arm-release/darwin-x64', 'android-arm-release/darwin-x64.zip'],
  <String>['android-arm64-profile/darwin-x64', 'android-arm64-profile/darwin-x64.zip'],
  <String>['android-arm64-release/darwin-x64', 'android-arm64-release/darwin-x64.zip'],
  <String>['android-arm-dynamic-profile/darwin-x64', 'android-arm-dynamic-profile/darwin-x64.zip'],
  <String>['android-arm-dynamic-release/darwin-x64', 'android-arm-dynamic-release/darwin-x64.zip'],
  <String>['android-arm64-dynamic-profile/darwin-x64', 'android-arm64-dynamic-profile/darwin-x64.zip'],
  <String>['android-arm64-dynamic-release/darwin-x64', 'android-arm64-dynamic-release/darwin-x64.zip'],
];

const List<List<String>> _linuxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/linux-x64', 'android-arm-profile/linux-x64.zip'],
  <String>['android-arm-release/linux-x64', 'android-arm-release/linux-x64.zip'],
  <String>['android-arm64-profile/linux-x64', 'android-arm64-profile/linux-x64.zip'],
  <String>['android-arm64-release/linux-x64', 'android-arm64-release/linux-x64.zip'],
  <String>['android-arm-dynamic-profile/linux-x64', 'android-arm-dynamic-profile/linux-x64.zip'],
  <String>['android-arm-dynamic-release/linux-x64', 'android-arm-dynamic-release/linux-x64.zip'],
  <String>['android-arm64-dynamic-profile/linux-x64', 'android-arm64-dynamic-profile/linux-x64.zip'],
  <String>['android-arm64-dynamic-release/linux-x64', 'android-arm64-dynamic-release/linux-x64.zip'],
];

const List<List<String>> _windowsBinaryDirs = <List<String>>[
  <String>['android-arm-profile/windows-x64', 'android-arm-profile/windows-x64.zip'],
  <String>['android-arm-release/windows-x64', 'android-arm-release/windows-x64.zip'],
  <String>['android-arm64-profile/windows-x64', 'android-arm64-profile/windows-x64.zip'],
  <String>['android-arm64-release/windows-x64', 'android-arm64-release/windows-x64.zip'],
  <String>['android-arm-dynamic-profile/windows-x64', 'android-arm-dynamic-profile/windows-x64.zip'],
  <String>['android-arm-dynamic-release/windows-x64', 'android-arm-dynamic-release/windows-x64.zip'],
  <String>['android-arm64-dynamic-profile/windows-x64', 'android-arm64-dynamic-profile/windows-x64.zip'],
  <String>['android-arm64-dynamic-release/windows-x64', 'android-arm64-dynamic-release/windows-x64.zip'],
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
  <String>['android-arm-dynamic-profile', 'android-arm-dynamic-profile/artifacts.zip'],
  <String>['android-arm-dynamic-release', 'android-arm-dynamic-release/artifacts.zip'],
  <String>['android-arm64-dynamic-profile', 'android-arm64-dynamic-profile/artifacts.zip'],
  <String>['android-arm64-dynamic-release', 'android-arm64-dynamic-release/artifacts.zip'],
];

const List<List<String>> _iosBinaryDirs = <List<String>>[
  <String>['ios', 'ios/artifacts.zip'],
  <String>['ios-profile', 'ios-profile/artifacts.zip'],
  <String>['ios-release', 'ios-release/artifacts.zip'],
];

const List<List<String>> _dartSdks = <List<String>> [
  <String>['darwin-x64', 'dart-sdk-darwin-x64.zip'],
  <String>['linux-x64', 'dart-sdk-linux-x64.zip'],
  <String>['windows-x64', 'dart-sdk-windows-x64.zip'],
];
