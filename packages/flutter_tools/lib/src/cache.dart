// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'base/context.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/process.dart';
import 'globals.dart';

class Cache {
  static Cache get instance => context[Cache] ?? (context[Cache] = new Cache());

  /// Return the top-level directory in the cache; this is `bin/cache`.
  Directory getRoot() => new Directory(path.join(ArtifactStore.flutterRoot, 'bin', 'cache'));

  /// Return a directory in the cache dir. For `pkg`, this will return `bin/cache/pkg`.
  Directory getCacheDir(String name) {
    Directory dir = new Directory(path.join(getRoot().path, name));
    if (!dir.existsSync())
      dir.createSync();
    return dir;
  }

  /// Return the top-level mutable directory in the cache; this is `bin/cache/artifacts`.
  Directory getCacheArtifacts() => getCacheDir('artifacts');

  /// Get a named directory from with the cache's artifact directory; for example,
  /// `material_fonts` would return `bin/cache/artifacts/material_fonts`.
  Directory getArtifactDirectory(String name) {
    return new Directory(path.join(getCacheArtifacts().path, name));
  }

  String getVersionFor(String kArtifactName) {
    File versionFile = new File(path.join(getRoot().path, '$kArtifactName.version'));
    return versionFile.existsSync() ? versionFile.readAsStringSync().trim() : null;
  }

  String getStampFor(String kArtifactName) {
    File stampFile = new File(path.join(getRoot().path, '$kArtifactName.stamp'));
    return stampFile.existsSync() ? stampFile.readAsStringSync().trim() : null;
  }

  void setStampFor(String kArtifactName, String version) {
    File stampFile = new File(path.join(getRoot().path, '$kArtifactName.stamp'));
    stampFile.writeAsStringSync(version);
  }

  Future<Null> updateAll() async {
    MaterialFonts materialFonts = new MaterialFonts(cache);
    if (!materialFonts.isUpToDate())
      await materialFonts.download();

    FlutterEngine engine = new FlutterEngine(cache);
    if (!engine.isUpToDate())
      await engine.download();
  }

  /// Download a file from the given URL and return the bytes.
  static Future<List<int>> _downloadFile(Uri url) async {
    printTrace('Downloading $url.');

    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(url);
    HttpClientResponse response = await request.close();

    printTrace('Received response statusCode=${response.statusCode}');
    if (response.statusCode != 200)
      throw new Exception(response.reasonPhrase);

    BytesBuilder responseBody = new BytesBuilder(copy: false);
    await for (List<int> chunk in response)
      responseBody.add(chunk);

    return responseBody.takeBytes();
  }

  /// Download a file from the given url and write it to the cache.
  /// If [unzip] is true, treat the url as a zip file, and unzip it to the
  /// directory given.
  static Future<Null> _downloadFileToCache(Uri url, FileSystemEntity location, bool unzip) async {
    if (!location.parent.existsSync())
      location.parent.createSync(recursive: true);

    List<int> fileBytes = await _downloadFile(url);
    if (unzip) {
      if (location is Directory && !location.existsSync())
        location.createSync(recursive: true);

      File tempFile = new File(path.join(Directory.systemTemp.path, '${url.toString().hashCode}.zip'));
      tempFile.writeAsBytesSync(fileBytes, flush: true);
      // unzip -o -q zipfile -d dest
      runSync(<String>['unzip', '-o', '-q', tempFile.path, '-d', location.path]);
      tempFile.deleteSync();
    } else {
      (location as File).writeAsBytesSync(fileBytes, flush: true);
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
    Status status = logger.startProgress('Downloading Material fonts...');

    return Cache._downloadFileToCache(
      Uri.parse(cache.getVersionFor(kName)),
      cache.getArtifactDirectory(kName),
      true
    ).then((_) {
      cache.setStampFor(kName, cache.getVersionFor(kName));
      status.stop(showElapsedTime: true);
    }).whenComplete(() {
      status.cancel();
    });
  }
}

// TODO(devoncarew): Move the services download to here.
// gs://flutter_infra/flutter/ed3014b3d337d025393bd894ffa2897e05d43e91/firebase/
// gs://flutter_infra/flutter/ed3014b3d337d025393bd894ffa2897e05d43e91/gcm/

class FlutterEngine {
  FlutterEngine(this.cache);

  static const String kName = 'engine';

  final Cache cache;

  List<String> _getEngineDirs() {
    List<String> dirs = <String>['android-arm', 'android-x64'];

    if (Platform.isMacOS)
      dirs.addAll(<String>['ios', 'darwin-x64']);
    else if (Platform.isLinux)
      dirs.add('linux-x64');

    return dirs;
  }

  List<String> _getPackageDirs() => <String>['sky_engine', 'sky_services'];

  bool isUpToDate() {
    Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      Directory dir = new Directory(path.join(pkgDir.path, pkgName));
      if (!dir.existsSync())
        return false;
    }

    Directory engineDir = cache.getArtifactDirectory(kName);
    for (String dirName in _getEngineDirs()) {
      Directory dir = new Directory(path.join(engineDir.path, dirName));
      if (!dir.existsSync())
        return false;
    }

    return cache.getVersionFor(kName) == cache.getStampFor(kName);
  }

  Future<Null> download() async {
    String engineVersion = cache.getVersionFor(kName);
    String url = 'https://storage.googleapis.com/flutter_infra/flutter/$engineVersion/';

    bool allDirty = engineVersion != cache.getStampFor(kName);

    Directory pkgDir = cache.getCacheDir('pkg');
    for (String pkgName in _getPackageDirs()) {
      Directory dir = new Directory(path.join(pkgDir.path, pkgName));
      if (!dir.existsSync() || allDirty) {
        await _downloadItem('Downloading engine package $pkgName...',
          url + pkgName + '.zip', pkgDir);
      }
    }

    Directory engineDir = cache.getArtifactDirectory(kName);
    for (String dirName in _getEngineDirs()) {
      Directory dir = new Directory(path.join(engineDir.path, dirName));
      if (!dir.existsSync() || allDirty) {
        await _downloadItem('Downloading engine artifacts $dirName...',
          url + dirName + '/artifacts.zip', dir);
        _makeFilesExecutable(dir);
      }
    }

    cache.setStampFor(kName, cache.getVersionFor(kName));
  }

  void _makeFilesExecutable(Directory dir) {
    for (FileSystemEntity entity in dir.listSync()) {
      if (entity is File) {
        String name = path.basename(entity.path);
        if (name == 'sky_snapshot' || name == 'sky_shell')
          os.makeExecutable(entity);
      }
    }
  }

  Future<Null> _downloadItem(String message, String url, Directory dest) {
    Status status = logger.startProgress(message);
    return Cache._downloadFileToCache(Uri.parse(url), dest, true).then((_) {
      status.stop(showElapsedTime: true);
    }).whenComplete(() {
      status.cancel();
    });
  }
}
