// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/context.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'globals.dart';

/// A wrapper around the `bin/cache/` directory.
class Cache {
  /// [rootOverride] is configurable for testing.
  /// [artifacts] is configurable for testing.
  Cache({ Directory rootOverride, List<CachedArtifact> artifacts }) : _rootOverride = rootOverride {
    if (artifacts == null) {
      _artifacts.add(new MaterialFonts(this));
      _artifacts.add(new FlutterEngine(this));
      _artifacts.add(new GradleWrapper(this));
    } else {
      _artifacts.addAll(artifacts);
    }
  }

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
  static Future<Null> lock() async {
    if (!_lockEnabled)
      return null;
    assert(_lock == null);
    _lock = await fs.file(fs.path.join(flutterRoot, 'bin', 'cache', 'lockfile')).open(mode: FileMode.WRITE);
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
        await new Future<Null>.delayed(const Duration(milliseconds: 50));
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
      throw new StateError(
        'The current process does not own the lock for the cache directory. This is a bug in Flutter CLI tools.',
      );
    }
  }

  static String _dartSdkVersion;

  static String get dartSdkVersion => _dartSdkVersion ??= platform.version;

  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      final File revisionFile = fs.file(fs.path.join(flutterRoot, 'bin', 'internal', 'engine.version'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync().trim();
    }
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

  /// Return the top-level mutable directory in the cache; this is `bin/cache/artifacts`.
  Directory getCacheArtifacts() => getCacheDir('artifacts');

  /// Get a named directory from with the cache's artifact directory; for example,
  /// `material_fonts` would return `bin/cache/artifacts/material_fonts`.
  Directory getArtifactDirectory(String name) {
    return fs.directory(fs.path.join(getCacheArtifacts().path, name));
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

  Future<Null> updateAll() async {
    if (!_lockEnabled)
      return null;
    for (CachedArtifact artifact in _artifacts) {
      if (!artifact.isUpToDate())
        await artifact.update();
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

  bool isUpToDate() {
    if (!location.existsSync())
      return false;
    if (version != cache.getStampFor(name))
      return false;
    return isUpToDateInner();
  }

  Future<Null> update() async {
    if (location.existsSync())
      location.deleteSync(recursive: true);
    location.createSync(recursive: true);
    return updateInner().then<Null>((_) {
      cache.setStampFor(name, version);
    });
  }

  /// Hook method for extra checks for being up-to-date.
  bool isUpToDateInner() => true;

  /// Template method to perform artifact update.
  Future<Null> updateInner();
}

/// A cached artifact containing fonts used for Material Design.
class MaterialFonts extends CachedArtifact {
  MaterialFonts(Cache cache): super('material_fonts', cache);

  @override
  Future<Null> updateInner() {
    final Status status = logger.startProgress('Downloading Material fonts...', expectSlowOperation: true);
    return _downloadZipArchive(Uri.parse(version), location).then<Null>((_) {
      status.stop();
    }).whenComplete(status.cancel);
  }
}

/// A cached artifact containing the Flutter engine binaries.
class FlutterEngine extends CachedArtifact {
  FlutterEngine(Cache cache): super('engine', cache);

  List<String> _getPackageDirs() => const <String>['sky_engine'];

  // Return a list of (cache directory path, download URL path) tuples.
  List<List<String>> _getBinaryDirs() {
    final List<List<String>> binaryDirs = <List<String>>[];

    binaryDirs.add(<String>['common', 'flutter_patched_sdk.zip']);

    if (cache.includeAllPlatforms)
      binaryDirs
        ..addAll(_osxBinaryDirs)
        ..addAll(_linuxBinaryDirs)
        ..addAll(_windowsBinaryDirs)
        ..addAll(_androidBinaryDirs)
        ..addAll(_iosBinaryDirs);
    else if (platform.isLinux)
      binaryDirs
        ..addAll(_linuxBinaryDirs)
        ..addAll(_androidBinaryDirs);
    else if (platform.isMacOS)
      binaryDirs
        ..addAll(_osxBinaryDirs)
        ..addAll(_androidBinaryDirs)
        ..addAll(_iosBinaryDirs);
    else if (platform.isWindows)
      binaryDirs
        ..addAll(_windowsBinaryDirs)
        ..addAll(_androidBinaryDirs);

    return binaryDirs;
  }

  List<List<String>> get _osxBinaryDirs => <List<String>>[
    <String>['darwin-x64', 'darwin-x64/artifacts.zip'],
    <String>['darwin-x64', 'dart-sdk-darwin-x64.zip'],
    <String>['android-arm-profile/darwin-x64', 'android-arm-profile/darwin-x64.zip'],
    <String>['android-arm-release/darwin-x64', 'android-arm-release/darwin-x64.zip'],
  ];

  List<List<String>> get _linuxBinaryDirs => <List<String>>[
    <String>['linux-x64', 'linux-x64/artifacts.zip'],
    <String>['linux-x64', 'dart-sdk-linux-x64.zip'],
    <String>['android-arm-profile/linux-x64', 'android-arm-profile/linux-x64.zip'],
    <String>['android-arm-release/linux-x64', 'android-arm-release/linux-x64.zip'],
  ];

  List<List<String>> get _windowsBinaryDirs => <List<String>>[
    <String>['windows-x64', 'windows-x64/artifacts.zip'],
    <String>['windows-x64', 'dart-sdk-windows-x64.zip'],
    <String>['android-arm-profile/windows-x64', 'android-arm-profile/windows-x64.zip'],
    <String>['android-arm-release/windows-x64', 'android-arm-release/windows-x64.zip'],
  ];

  List<List<String>> get _androidBinaryDirs => <List<String>>[
    <String>['android-x86', 'android-x86/artifacts.zip'],
    <String>['android-x64', 'android-x64/artifacts.zip'],
    <String>['android-arm', 'android-arm/artifacts.zip'],
    <String>['android-arm-profile', 'android-arm-profile/artifacts.zip'],
    <String>['android-arm-release', 'android-arm-release/artifacts.zip'],
  ];

  List<List<String>> get _iosBinaryDirs => <List<String>>[
    <String>['ios', 'ios/artifacts.zip'],
    <String>['ios-profile', 'ios-profile/artifacts.zip'],
    <String>['ios-release', 'ios-release/artifacts.zip'],
  ];

  @override
  bool isUpToDateInner() {
    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      if (!fs.directory(pkgPath).existsSync())
        return false;
    }

    for (List<String> toolsDir in _getBinaryDirs()) {
      final Directory dir = fs.directory(fs.path.join(location.path, toolsDir[0]));
      if (!dir.existsSync())
        return false;
    }
    return true;
  }

  @override
  Future<Null> updateInner() async {
    final String url = 'https://storage.googleapis.com/flutter_infra/flutter/$version/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      final Directory dir = fs.directory(pkgPath);
      if (dir.existsSync())
        dir.deleteSync(recursive: true);
      await _downloadItem('Downloading package $pkgName...', url + pkgName + '.zip', pkgDir);
    }

    for (List<String> toolsDir in _getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = fs.directory(fs.path.join(location.path, cacheDir));
      await _downloadItem('Downloading $cacheDir tools...', url + urlPath, dir);

      _makeFilesExecutable(dir);

      final File frameworkZip = fs.file(fs.path.join(dir.path, 'Flutter.framework.zip'));
      if (frameworkZip.existsSync()) {
        final Directory framework = fs.directory(fs.path.join(dir.path, 'Flutter.framework'));
        framework.createSync();
        os.unzip(frameworkZip, framework);
      }
    }
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

  Future<Null> _downloadItem(String message, String url, Directory dest) {
    final Status status = logger.startProgress(message, expectSlowOperation: true);
    return _downloadZipArchive(Uri.parse(url), dest).then<Null>((_) {
      status.stop();
    }).whenComplete(status.cancel);
  }
}

/// A cached artifact containing Gradle Wrapper scripts and binaries.
class GradleWrapper extends CachedArtifact {
  GradleWrapper(Cache cache): super('gradle_wrapper', cache);

  @override
  Future<Null> updateInner() async {
    final Status status = logger.startProgress('Downloading Gradle Wrapper...', expectSlowOperation: true);

    final String url = 'https://android.googlesource.com'
        '/platform/tools/base/+archive/$version/templates/gradle/wrapper.tgz';
    await _downloadZippedTarball(Uri.parse(url), location).then<Null>((_) {
      // Delete property file, allowing templates to provide it.
      fs.file(fs.path.join(location.path, 'gradle', 'wrapper', 'gradle-wrapper.properties')).deleteSync();
      status.stop();
    }).whenComplete(status.cancel);
  }
}

/// Download a file from the given [url] and write it to [location].
Future<Null> _downloadFile(Uri url, File location) async {
  _ensureExists(location.parent);
  final List<int> fileBytes = await fetchUrl(url);
  location.writeAsBytesSync(fileBytes, flush: true);
}

/// Download a zip archive from the given [url] and unzip it to [location].
Future<Null> _downloadZipArchive(Uri url, Directory location) {
  return _withTemporaryFile('download.zip', (File tempFile) async {
    await _downloadFile(url, tempFile);
    _ensureExists(location);
    os.unzip(tempFile, location);
  });
}

/// Download a gzipped tarball from the given [url] and unpack it to [location].
Future<Null> _downloadZippedTarball(Uri url, Directory location) {
  return _withTemporaryFile('download.tgz', (File tempFile) async {
    await _downloadFile(url, tempFile);
    _ensureExists(location);
    os.unpack(tempFile, location);
  });
}

/// Create a file with the given name in a new temporary directory, invoke
/// [onTemporaryFile] with the file as argument, then delete the temporary
/// directory.
Future<Null> _withTemporaryFile(String name, Future<Null> onTemporaryFile(File file)) async {
  final Directory tempDir = fs.systemTempDirectory.createTempSync();
  final File tempFile = fs.file(fs.path.join(tempDir.path, name));
  await onTemporaryFile(tempFile).whenComplete(() {
    tempDir.delete(recursive: true);
  });
}

/// Create the given [directory] and parents, as necessary.
void _ensureExists(Directory directory) {
  if (!directory.existsSync())
    directory.createSync(recursive: true);
}
