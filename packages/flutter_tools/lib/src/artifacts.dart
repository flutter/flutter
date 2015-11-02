// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'build_configuration.dart';
import 'os_utils.dart';

final Logger _logging = new Logger('sky_tools.artifacts');

const String _kShellCategory = 'shell';
const String _kViewerCategory = 'viewer';

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
    case TargetPlatform.linux:
      return 'linux-x64';
  }
}

// Keep in sync with https://github.com/flutter/engine/blob/master/sky/tools/big_red_button.py#L50
String _getCloudStorageBaseUrl({String category, String platform, String revision}) {
  if (platform == 'darwin-x64') {
    // In the fullness of time, we'll have a consistent URL pattern for all of
    // our artifacts, but, for the time being, darwin artifacts are stored in a
    // different cloud storage bucket.
    return 'https://storage.googleapis.com/mojo_infra/flutter/${platform}/${revision}/';
  }
  return 'https://storage.googleapis.com/mojo/sky/${category}/${platform}/${revision}/';
}

enum ArtifactType {
  snapshot,
  shell,
  viewer,
}

class Artifact {
  const Artifact._({
    this.name,
    this.fileName,
    this.category,
    this.type,
    this.hostPlatform,
    this.targetPlatform
  });

  final String name;
  final String fileName;
  final String category; // TODO(abarth): Remove categories.
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

  String getUrl(String revision) {
    return _getCloudStorageBaseUrl(
      category: category,
      platform: platform,
      revision: revision
    ) + fileName;
  }

  // Whether the artifact needs to be marked as executable on disk.
  bool get executable => type == ArtifactType.snapshot;
}

class ArtifactStore {
  static const List<Artifact> knownArtifacts = const <Artifact>[
    const Artifact._(
      name: 'Sky Shell',
      fileName: 'SkyShell.apk',
      category: _kShellCategory,
      type: ArtifactType.shell,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      category: _kShellCategory,
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.linux
    ),
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      category: _kShellCategory,
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.mac
    ),
    const Artifact._(
      name: 'Sky Viewer',
      fileName: 'sky_viewer.mojo',
      category: _kViewerCategory,
      type: ArtifactType.viewer,
      targetPlatform: TargetPlatform.android
    ),
    const Artifact._(
      name: 'Sky Viewer',
      fileName: 'sky_viewer.mojo',
      category: _kViewerCategory,
      type: ArtifactType.viewer,
      targetPlatform: TargetPlatform.linux
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

  static String packageRoot;
  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      File revisionFile = new File(path.join(packageRoot, 'sky_engine', 'REVISION'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync();
    }
    return _engineRevision;
  }

  static String getCloudStorageBaseUrl(String category, String platform) {
    return _getCloudStorageBaseUrl(
      category: category,
      platform: platform,
      revision: engineRevision
    );
  }

  static Future _downloadFile(String url, File file) async {
    _logging.info('Downloading $url to ${file.path}.');
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    _logging.fine('Received response statusCode=${response.statusCode}');
    if (response.statusCode != 200)
      throw new Exception(response.reasonPhrase);
    IOSink sink = file.openWrite();
    await sink.addStream(response);
    await sink.close();
    _logging.fine('Wrote file');
  }

  static Directory _getBaseCacheDir() {
    Directory cacheDir = new Directory(path.join(packageRoot, 'sky_tools', 'cache'));
    if (!cacheDir.existsSync())
      cacheDir.createSync(recursive: true);
    return cacheDir;
  }

  static Directory _getCacheDirForArtifact(Artifact artifact) {
    Directory baseDir = _getBaseCacheDir();
    // For now, all downloaded artifacts are release mode host binaries so use
    // a path that mirrors a local release build.
    // TODO(jamesr): Add support for more configurations.
    String config = 'Release';
    Directory artifactSpecificDir = new Directory(path.join(
        baseDir.path, 'sky_engine', engineRevision, config, artifact.platform));
    if (!artifactSpecificDir.existsSync())
      artifactSpecificDir.createSync(recursive: true);
    return artifactSpecificDir;
  }

  static Future<String> getPath(Artifact artifact) async {
    Directory cacheDir = _getCacheDirForArtifact(artifact);
    File cachedFile = new File(path.join(cacheDir.path, artifact.fileName));
    if (!cachedFile.existsSync()) {
      print('Downloading ${artifact.name} from the cloud, one moment please...');
      await _downloadFile(artifact.getUrl(engineRevision), cachedFile);
      if (artifact.executable) {
        ProcessResult result = osUtils.makeExecutable(cachedFile);
        if (result.exitCode != 0)
          throw new Exception(result.stderr);
      }
    }
    return cachedFile.path;
  }

  static void clear() {
    Directory cacheDir = _getBaseCacheDir();
    _logging.fine('Clearing cache directory ${cacheDir.path}');
    cacheDir.deleteSync(recursive: true);
  }

  static Future populate() {
    return Future.wait(knownArtifacts.map((artifact) => getPath(artifact)));
  }
}
