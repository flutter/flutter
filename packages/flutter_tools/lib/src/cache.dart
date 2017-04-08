// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  Cache({ Directory rootOverride }) : _rootOverride = rootOverride;

  final Directory _rootOverride;

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
  static void disableLocking() {
    _lockEnabled = false;
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
    _lock = fs.file(fs.path.join(flutterRoot, 'bin', 'cache', 'lockfile')).openSync(mode: FileMode.WRITE);
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
    if (_lockEnabled && _lock == null) {
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

  bool isUpToDate() {
    final MaterialFonts materialFonts = new MaterialFonts(cache);
    final FlutterEngine engine = new FlutterEngine(cache);

    return materialFonts.isUpToDate() && engine.isUpToDate();
  }

  Future<String> getThirdPartyFile(String urlStr, String serviceName, {
    bool unzip: false
  }) async {
    final Uri url = Uri.parse(urlStr);
    final Directory thirdPartyDir = getArtifactDirectory('third_party');

    final Directory serviceDir = fs.directory(fs.path.join(thirdPartyDir.path, serviceName));
    if (!serviceDir.existsSync())
      serviceDir.createSync(recursive: true);

    final File cachedFile = fs.file(fs.path.join(serviceDir.path, url.pathSegments.last));
    if (!cachedFile.existsSync()) {
      try {
        await _downloadFileToCache(url, cachedFile, unzip);
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
    final MaterialFonts materialFonts = new MaterialFonts(cache);
    if (!materialFonts.isUpToDate())
      await materialFonts.download();

    final FlutterEngine engine = new FlutterEngine(cache);
    if (!engine.isUpToDate())
      await engine.download();
  }

  /// Download a file from the given url and write it to the cache.
  /// If [unzip] is true, treat the url as a zip file, and unzip it to the
  /// directory given.
  static Future<Null> _downloadFileToCache(Uri url, FileSystemEntity location, bool unzip) async {
    if (!location.parent.existsSync())
      location.parent.createSync(recursive: true);

    final List<int> fileBytes = await fetchUrl(url);
    if (unzip) {
      if (location is Directory && !location.existsSync())
        location.createSync(recursive: true);

      final File tempFile = fs.file(fs.path.join(fs.systemTempDirectory.path, '${url.toString().hashCode}.zip'));
      tempFile.writeAsBytesSync(fileBytes, flush: true);
      os.unzip(tempFile, location);
      tempFile.deleteSync();
    } else {
      final File file = location;
      file.writeAsBytesSync(fileBytes, flush: true);
    }
  }
}

class MaterialFonts {
  MaterialFonts(this.cache);

  static const String kName = 'material_fonts';

  final Cache cache;

  bool isUpToDate() {
    if (!cache.getArtifactDirectory(kName).existsSync())
      return false;
    return cache.getVersionFor(kName) == cache.getStampFor(kName);
  }

  Future<Null> download() {
    final Status status = logger.startProgress('Downloading Material fonts...', expectSlowOperation: true);

    final Directory fontsDir = cache.getArtifactDirectory(kName);
    if (fontsDir.existsSync())
      fontsDir.deleteSync(recursive: true);

    return Cache._downloadFileToCache(
      Uri.parse(cache.getVersionFor(kName)), fontsDir, true
    ).then<Null>((Null value) {
      cache.setStampFor(kName, cache.getVersionFor(kName));
      status.stop();
    }).whenComplete(status.cancel);
  }
}

class FlutterEngine {

  FlutterEngine(this.cache);

  static const String kName = 'engine';
  static const String kSkyEngine = 'sky_engine';

  final Cache cache;

  List<String> _getPackageDirs() => const <String>[kSkyEngine];

  // Return a list of (cache directory path, download URL path) tuples.
  List<List<String>> _getBinaryDirs() {
    final List<List<String>> binaryDirs = <List<String>>[];

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
    <String>['android-arm-profile/darwin-x64', 'android-arm-profile/darwin-x64.zip'],
    <String>['android-arm-release/darwin-x64', 'android-arm-release/darwin-x64.zip'],
  ];

  List<List<String>> get _linuxBinaryDirs => <List<String>>[
    <String>['linux-x64', 'linux-x64/artifacts.zip'],
    <String>['android-arm-profile/linux-x64', 'android-arm-profile/linux-x64.zip'],
    <String>['android-arm-release/linux-x64', 'android-arm-release/linux-x64.zip'],
  ];

  List<List<String>> get _windowsBinaryDirs => <List<String>>[
    <String>['windows-x64', 'windows-x64/artifacts.zip'],
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

  bool isUpToDate() {
    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      if (!fs.directory(pkgPath).existsSync())
        return false;
    }

    final Directory engineDir = cache.getArtifactDirectory(kName);
    for (List<String> toolsDir in _getBinaryDirs()) {
      final Directory dir = fs.directory(fs.path.join(engineDir.path, toolsDir[0]));
      if (!dir.existsSync())
        return false;
    }

    return cache.getVersionFor(kName) == cache.getStampFor(kName);
  }

  Future<Null> download() async {
    final String engineVersion = cache.getVersionFor(kName);
    final String url = 'https://storage.googleapis.com/flutter_infra/flutter/$engineVersion/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      final String pkgPath = fs.path.join(pkgDir.path, pkgName);
      final Directory dir = fs.directory(pkgPath);
      if (dir.existsSync())
        dir.deleteSync(recursive: true);
      await _downloadItem('Downloading package $pkgName...', url + pkgName + '.zip', pkgDir);
    }

    final Directory engineDir = cache.getArtifactDirectory(kName);
    if (engineDir.existsSync())
      engineDir.deleteSync(recursive: true);

    for (List<String> toolsDir in _getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = fs.directory(fs.path.join(engineDir.path, cacheDir));
      await _downloadItem('Downloading $cacheDir tools...', url + urlPath, dir);

      _makeFilesExecutable(dir);

      final File frameworkZip = fs.file(fs.path.join(dir.path, 'Flutter.framework.zip'));
      if (frameworkZip.existsSync()) {
        final Directory framework = fs.directory(fs.path.join(dir.path, 'Flutter.framework'));
        framework.createSync();
        os.unzip(frameworkZip, framework);
      }
    }

    cache.setStampFor(kName, cache.getVersionFor(kName));
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
    return Cache._downloadFileToCache(Uri.parse(url), dest, true).then<Null>((Null value) {
      status.stop();
    }).whenComplete(status.cancel);
  }
}
