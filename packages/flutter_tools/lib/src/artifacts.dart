// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'base/process.dart';
import 'build_configuration.dart';
import 'globals.dart';

String _getNameForHostPlatform(HostPlatform platform) {
  switch (platform) {
    case HostPlatform.linux:
      return 'linux-x64';
    case HostPlatform.mac:
      return 'darwin-x64';
  }
}

String getNameForTargetPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
      return 'android-arm';
    case TargetPlatform.ios:
      return 'ios';
    case TargetPlatform.darwin_x64:
      return 'darwin-x64';
    case TargetPlatform.linux_x64:
      return 'linux-x64';
  }
}

enum ArtifactType {
  snapshot,
  shell,
  mojo,
  androidClassesJar,
  androidIcuData,
  androidKeystore,
  androidLibSkyShell,
  iosXcodeProject,
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
      return getNameForTargetPlatform(targetPlatform);
    if (hostPlatform != null)
      return _getNameForHostPlatform(hostPlatform);
    assert(false);
    return null;
  }
}

class ArtifactStore {
  static const List<Artifact> knownArtifacts = const <Artifact>[
    const Artifact._(
      name: 'Flutter Tester',
      fileName: 'sky_shell',
      type: ArtifactType.shell,
      targetPlatform: TargetPlatform.linux_x64
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
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Flutter for Mojo',
      fileName: 'flutter.mojo',
      type: ArtifactType.mojo,
      targetPlatform: TargetPlatform.linux_x64
    ),
    const Artifact._(
      name: 'Compiled Java code',
      fileName: 'classes.dex.jar',
      type: ArtifactType.androidClassesJar,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'ICU data table',
      fileName: 'icudtl.dat',
      type: ArtifactType.androidIcuData,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Key Store',
      fileName: 'chromium-debug.keystore',
      type: ArtifactType.androidKeystore,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Compiled C++ code',
      fileName: 'libsky_shell.so',
      type: ArtifactType.androidLibSkyShell,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'iOS Runner (Xcode Project)',
      fileName: 'FlutterXcode.zip',
      type: ArtifactType.iosXcodeProject,
      targetPlatform: TargetPlatform.ios
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

  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      File revisionFile = new File(path.join(flutterRoot, 'bin', 'cache', 'engine.version'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync().trim();
    }
    return _engineRevision;
  }

  static Directory getBaseCacheDir() {
    if (flutterRoot == null) {
      printError('FLUTTER_ROOT not specified. Cannot find artifact cache.');
      throw new ProcessExit(2);
    }
    Directory cacheDir = new Directory(path.join(flutterRoot, 'bin', 'cache', 'artifacts'));
    if (!cacheDir.existsSync()) {
      printError('${cacheDir.path} does not exist. Cannot find artifact cache.');
      throw new ProcessExit(2);
    }
    return cacheDir;
  }

  static Future<String> getPath(Artifact artifact) async {
    File cachedFile = new File(path.join(
        getBaseCacheDir().path, 'engine', artifact.platform, artifact.fileName
    ));
    if (!cachedFile.existsSync()) {
      printError('File not found in the platform artifacts: ${cachedFile.path}');
      throw new ProcessExit(2);
    }
    return cachedFile.path;
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
    await for (List<int> chunk in response)
      responseBody.add(chunk);

    return responseBody.takeBytes();
  }

  /// Download a file from the given url and write it to the cache.
  /// If [unzip] is true, treat the url as a zip file, and unzip it to the
  /// directory given.
  static Future<Null> _downloadFileToCache(Uri url, FileSystemEntity cachedFile, bool unzip) async {
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

  static Future<String> getThirdPartyFile(String urlStr, String cacheSubdir, bool unzip) async {
    Uri url = Uri.parse(urlStr);
    Directory baseDir = getBaseCacheDir();
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
}
