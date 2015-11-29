// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'build_configuration.dart';
import 'base/os.dart';
import 'base/process.dart';
import 'base/logging.dart';

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
  // In the fullness of time, we'll have a consistent URL pattern for all of
  // our artifacts, but, for the time being, Mac OS X artifacts are stored in a
  // different cloud storage bucket.
  String bucket = (platform == 'darwin-x64') ? "mojo_infra" : "mojo";
  return 'https://storage.googleapis.com/$bucket/flutter/$revision/$platform/';
}

enum ArtifactType {
  snapshot,
  shell,
  mojo,
  androidClassesDex,
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
      fileName: 'classes.dex',
      type: ArtifactType.androidClassesDex,
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
      stderr.writeln(message);
      throw new ProcessExit(2);
    }
  }

  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      ensurePackageRootIsValid();
      File revisionFile = new File(path.join(packageRoot, 'sky_engine', 'REVISION'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync();
    }
    return _engineRevision;
  }

  static String getCloudStorageBaseUrl(String platform) {
    return _getCloudStorageBaseUrl(
      platform: platform,
      revision: engineRevision
    );
  }

  /// Download the artifacts.zip archive for the given platform from GCS
  /// and extract it to the local cache.
  static Future _doDownloadArtifactsFromZip(String platform) async {
    String url = getCloudStorageBaseUrl(platform) + 'artifacts.zip';
    logging.info('Downloading $url.');

    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    logging.fine('Received response statusCode=${response.statusCode}');
    if (response.statusCode != 200)
      throw new Exception(response.reasonPhrase);

    BytesBuilder responseBody = new BytesBuilder(copy: false);
    await for (List<int> chunk in response) {
      responseBody.add(chunk);
    }

    Archive archive = new ZipDecoder().decodeBytes(responseBody.takeBytes());
    Directory cacheDir = _getCacheDirForPlatform(platform);
    for (ArchiveFile archiveFile in archive) {
      File cacheFile = new File(path.join(cacheDir.path, archiveFile.name));
      IOSink sink = cacheFile.openWrite();
      sink.add(archiveFile.content);
      await sink.close();
    }

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
    print('Downloading $platform artifacts from the cloud, one moment please...');
    Future future = _doDownloadArtifactsFromZip(platform);
    _pendingZipDownloads[platform] = future;
    return future.then((_) => _pendingZipDownloads.remove(platform));
  }

  static final Map<String, Future> _pendingZipDownloads = new Map<String, Future>();

  static Directory _getBaseCacheDir() {
    if (flutterRoot == null) {
      logging.severe('FLUTTER_ROOT not specified. Cannot find artifact cache.');
      throw new ProcessExit(2);
    }
    Directory cacheDir = new Directory(path.join(flutterRoot, 'bin', 'cache', 'artifacts'));
    if (!cacheDir.existsSync())
      cacheDir.createSync(recursive: true);
    return cacheDir;
  }

  static Directory _getCacheDirForPlatform(String platform) {
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
        logging.severe('File not found in the platform artifacts: ${cachedFile.path}');
        throw new ProcessExit(2);
      }
    }
    return cachedFile.path;
  }

  static void clear() {
    Directory cacheDir = _getBaseCacheDir();
    logging.fine('Clearing cache directory ${cacheDir.path}');
    cacheDir.deleteSync(recursive: true);
  }

  static Future populate() {
    return Future.wait(knownArtifacts.map((artifact) => getPath(artifact)));
  }
}
