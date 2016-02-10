// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'base/globals.dart';
import 'base/os.dart';
import 'base/process.dart';
import 'build_configuration.dart';

String _getNameForHostPlatform(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.linux:
      return 'linux-x64';
    case HostPlatform.mac:
      return 'darwin-x64';
  }
}

String _getNameForTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
      return 'android-arm';
    case TargetPlatform.iOS:
      return 'ios-arm';
    case TargetPlatform.iOSSimulator:
      return 'ios-x64';
    case TargetPlatform.mac:
      return 'darwin-x64';
    case TargetPlatform.linux:
      return 'linux-x64';
  }
}

// Keep in sync with https://github.com/flutter/engine/blob/master/sky/tools/release_engine.py
// and https://github.com/flutter/buildbot/blob/master/travis/build.sh
String _getCloudStorageBaseUrl({String platform, String revision}) {
  return 'https://storage.googleapis.com/mojo_infra/flutter/$revision/$platform/';
}

enum ArtifactType {
  snapshot,
  shell,
  mojo,
  androidClassesJar,
  androidIcuData,
  androidKeystore,
  androidLibSkyShell,
}

class Artifact {
  const Artifact._({
    this.name,
    this.fileName,
    this.type,
    this.hostPlatform,
    this.targetPlatform
  });

  final String name;
  final String fileName;
  final ArtifactType type;
  final HostPlatform hostPlatform;
  final TargetPlatform targetPlatform;

  String get platform {
    if (targetPlatform != null)
      return _getNameForTargetPlatform(targetPlatform);
    if (hostPlatform != null)
      return _getNameForHostPlatform(hostPlatform);
    assert(false);
    return null;
  }

  // Whether the artifact needs to be marked as executable on disk.
  bool get executable {
    return type == ArtifactType.snapshot ||
      (type == ArtifactType.shell && targetPlatform == TargetPlatform.linux);
  }
}

class ArtifactStore {
  static const List<Artifact> knownArtifacts = const <Artifact>[
    const Artifact._(
      name: 'Sky Shell',
      fileName: 'SkyShell.apk',
      type: ArtifactType.shell,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Sky Shell',
      fileName: 'sky_shell',
      type: ArtifactType.shell,
      targetPlatform: TargetPlatform.linux
    ),
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.linux
    ),
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.mac
    ),
    const Artifact._(
      name: 'Flutter for Mojo',
      fileName: 'flutter.mojo',
      type: ArtifactType.mojo,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Flutter for Mojo',
      fileName: 'flutter.mojo',
      type: ArtifactType.mojo,
      targetPlatform: TargetPlatform.linux
    ),
    const Artifact._(
      name: 'Compiled Java code',
      fileName: 'classes.dex.jar',
      type: ArtifactType.androidClassesJar,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'ICU data table',
      fileName: 'icudtl.dat',
      type: ArtifactType.androidIcuData,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Key Store',
      fileName: 'chromium-debug.keystore',
      type: ArtifactType.androidKeystore,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Compiled C++ code',
      fileName: 'libsky_shell.so',
      type: ArtifactType.androidLibSkyShell,
      targetPlatform: TargetPlatform.android
    ),
  ];

  static Artifact getArtifact({
    ArtifactType type,
    HostPlatform hostPlatform,
    TargetPlatform targetPlatform
  }) {
    for (Artifact artifact in ArtifactStore.knownArtifacts) {
      if (type != null &&
          type != artifact.type)
        continue;
      if (hostPlatform != null &&
          artifact.hostPlatform != null &&
          hostPlatform != artifact.hostPlatform)
        continue;
      if (targetPlatform != null &&
          artifact.targetPlatform != null &&
          targetPlatform != artifact.targetPlatform)
        continue;
      return artifact;
    }
    return null;
  }

  // These values are initialized by FlutterCommandRunner on startup.
  static String flutterRoot;
  static String packageRoot = 'packages';

  static bool get isPackageRootValid {
    return FileSystemEntity.isDirectorySync(packageRoot);
  }

  static void ensurePackageRootIsValid() {
    if (!isPackageRootValid) {
      String message = '$packageRoot is not a valid directory.';
      if (packageRoot == 'packages') {
        if (FileSystemEntity.isFileSync('pubspec.yaml'))
          message += '\nDid you run `pub get` in this directory?';
        else
          message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
      }
      printError(message);
      throw new ProcessExit(2);
    }
  }

  static void validateSkyEnginePackage() {
    if (engineRevision == null) {
      printError("Cannot locate the sky_engine package; did you include 'flutter' in your pubspec.yaml file?");
      throw new ProcessExit(2);
    }
    if (engineRevision != expectedEngineRevision) {
      printError("Error: incompatible sky_engine package; please run 'pub get' to get the correct one.\n");
      throw new ProcessExit(2);
    }
  }

  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      File revisionFile = new File(path.join(packageRoot, 'sky_engine', 'REVISION'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync();
    }
    return _engineRevision;
  }

  static String _expectedEngineRevision;

  static String get expectedEngineRevision {
    if (_expectedEngineRevision == null) {
      // TODO(jackson): Parse the .packages file and use the path from there instead
      File revisionFile = new File(path.join(flutterRoot, 'packages', 'flutter', 'packages', 'sky_engine', 'REVISION'));
      if (revisionFile.existsSync())
        _expectedEngineRevision = revisionFile.readAsStringSync();
    }
    return _expectedEngineRevision;
  }

  static String getCloudStorageBaseUrl(String platform) {
    return _getCloudStorageBaseUrl(
      platform: platform,
      revision: engineRevision
    );
  }

  /// Download a file from the given URL and return the bytes.
  static Future<List<int>> _downloadFile(Uri url) async {
    printStatus('Downloading $url.');

    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(url);
    HttpClientResponse response = await request.close();
    printTrace('Received response statusCode=${response.statusCode}');
    if (response.statusCode != 200)
      throw new Exception(response.reasonPhrase);

    BytesBuilder responseBody = new BytesBuilder(copy: false);
    await for (List<int> chunk in response) {
      responseBody.add(chunk);
    }

    return responseBody.takeBytes();
  }

  /// Download a file from the given url and write it to the cache.
  /// If [unzip] is true, treat the url as a zip file, and unzip it to the
  /// directory given.
  static Future _downloadFileToCache(Uri url, FileSystemEntity cachedFile, bool unzip) async {
    if (!cachedFile.parent.existsSync())
      cachedFile.parent.createSync(recursive: true);

    List<int> fileBytes = await _downloadFile(url);
    if (unzip) {
      if (cachedFile is Directory && !cachedFile.existsSync())
        cachedFile.createSync(recursive: true);

      Archive archive = new ZipDecoder().decodeBytes(fileBytes);
      for (ArchiveFile archiveFile in archive) {
        File subFile = new File(path.join(cachedFile.path, archiveFile.name));
        subFile.writeAsBytesSync(archiveFile.content, flush: true);
      }
    } else {
      File asFile = new File(cachedFile.path);
      asFile.writeAsBytesSync(fileBytes, flush: true);
    }
  }

  /// Download the artifacts.zip archive for the given platform from GCS
  /// and extract it to the local cache.
  static Future _doDownloadArtifactsFromZip(String platform) async {
    String url = getCloudStorageBaseUrl(platform) + 'artifacts.zip';
    Directory cacheDir = _getCacheDirForPlatform(platform);
    await _downloadFileToCache(Uri.parse(url), cacheDir, true);

    for (Artifact artifact in knownArtifacts) {
      if (artifact.platform == platform && artifact.executable) {
        ProcessResult result = os.makeExecutable(
            new File(path.join(cacheDir.path, artifact.fileName)));
        if (result.exitCode != 0)
          throw new Exception(result.stderr);
      }
    }
  }

  /// A wrapper ensuring that a platform's ZIP is not downloaded multiple times
  /// concurrently.
  static Future _downloadArtifactsFromZip(String platform) {
    if (_pendingZipDownloads.containsKey(platform)) {
      return _pendingZipDownloads[platform];
    }
    printStatus('Downloading $platform artifacts from the cloud, one moment please...');
    Future future = _doDownloadArtifactsFromZip(platform);
    _pendingZipDownloads[platform] = future;
    return future.then((_) => _pendingZipDownloads.remove(platform));
  }

  static final Map<String, Future> _pendingZipDownloads = new Map<String, Future>();

  static Directory _getBaseCacheDir() {
    if (flutterRoot == null) {
      printError('FLUTTER_ROOT not specified. Cannot find artifact cache.');
      throw new ProcessExit(2);
    }
    Directory cacheDir = new Directory(path.join(flutterRoot, 'bin', 'cache', 'artifacts'));
    if (!cacheDir.existsSync())
      cacheDir.createSync(recursive: true);
    return cacheDir;
  }

  static Directory _getCacheDirForPlatform(String platform) {
    validateSkyEnginePackage();
    Directory baseDir = _getBaseCacheDir();
    // TODO(jamesr): Add support for more configurations.
    String config = 'Release';
    Directory artifactSpecificDir = new Directory(path.join(
        baseDir.path, 'sky_engine', engineRevision, config, platform));
    if (!artifactSpecificDir.existsSync())
      artifactSpecificDir.createSync(recursive: true);
    return artifactSpecificDir;
  }

  static Future<String> getPath(Artifact artifact) async {
    Directory cacheDir = _getCacheDirForPlatform(artifact.platform);
    File cachedFile = new File(path.join(cacheDir.path, artifact.fileName));
    if (!cachedFile.existsSync()) {
      await _downloadArtifactsFromZip(artifact.platform);
      if (!cachedFile.existsSync()) {
        printError('File not found in the platform artifacts: ${cachedFile.path}');
        throw new ProcessExit(2);
      }
    }
    return cachedFile.path;
  }

  static Future<String> getThirdPartyFile(String urlStr, String cacheSubdir, bool unzip) async {
    Uri url = Uri.parse(urlStr);
    Directory baseDir = _getBaseCacheDir();
    Directory cacheDir = new Directory(path.join(
        baseDir.path, 'third_party', cacheSubdir));
    File cachedFile = new File(
        path.join(cacheDir.path, url.pathSegments[url.pathSegments.length-1]));
    if (!cachedFile.existsSync()) {
      try {
        await _downloadFileToCache(url, cachedFile, unzip);
      } catch (e) {
        printError('Failed to fetch third-party artifact: $url: $e');
        throw new ProcessExit(2);
      }
    }
    return cachedFile.path;
  }

  static void clear() {
    Directory cacheDir = _getBaseCacheDir();
    printTrace('Clearing cache directory ${cacheDir.path}');
    cacheDir.deleteSync(recursive: true);
  }

  static Future populate() {
    return Future.wait(knownArtifacts.map((artifact) => getPath(artifact)));
  }
}
