// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.artifacts;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final Logger _logging = new Logger('sky_tools.artifacts');

enum Artifact {
  flutterCompiler,
  flutterShell,
  skyViewerMojo,
}

class ArtifactStore {
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

  // Keep in sync with https://github.com/flutter/engine/blob/master/sky/tools/big_red_button.py#L50
  static String googleStorageUrl(String category, String platform) {
    return 'https://storage.googleapis.com/mojo/sky/${category}/${platform}/${engineRevision}/';
  }

  static Future _downloadFile(String url, File file) async {
    print('Downloading $url to ${file.path}.');
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    _logging.fine('Received response');
    if (response.statusCode != 200) throw new Exception(response.reasonPhrase);
    IOSink sink = file.openWrite();
    await sink.addStream(response);
    await sink.close();
    _logging.fine('Wrote file');
  }

  static Future<Directory> _cacheDir() async {
    Directory cacheDir = new Directory(path.join(packageRoot, 'sky_tools', 'cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static Future<Directory> _engineSpecificCacheDir() async {
    Directory cacheDir = await _cacheDir();
    // For now, all downloaded artifacts are release mode host binaries so use
    // a path that mirrors a local release build.
    // TODO(jamesr): Add support for more configurations.
    String config = 'Release';
    Directory engineSpecificDir = new Directory(path.join(cacheDir.path, 'sky_engine', engineRevision, config));

    if (!await engineSpecificDir.exists()) {
      await engineSpecificDir.create(recursive: true);
    }
    return engineSpecificDir;
  }

  // Whether the artifact needs to be marked as executable on disk.
  static bool _needsToBeExecutable(Artifact artifact) {
    return artifact == Artifact.flutterCompiler;
  }

  static Future<String> getPath(Artifact artifact) async {
    Directory cacheDir = await _engineSpecificCacheDir();

    String category;
    String platform;
    String name;

    switch (artifact) {
      case Artifact.flutterCompiler:
        category = 'shell';
        name = 'sky_snapshot';
        break;
      case Artifact.flutterShell:
        category = 'shell';
        platform = 'android-arm';
        name = 'SkyShell.apk';
        break;
      case Artifact.skyViewerMojo:
        category = 'viewer';
        name = 'sky_viewer.mojo';
        break;
    }

    File cachedFile = new File(path.join(cacheDir.path, name));
    if (!await cachedFile.exists()) {
      _logging.info('Downloading ${name} from the cloud, one moment please...');
      if (platform == null) {
        if (!Platform.isLinux)
          throw new Exception('Platform unsupported.');
        platform = 'linux-x64';
      }
      String url = googleStorageUrl(category, platform) + name;
      await _downloadFile(url, cachedFile);
      if (_needsToBeExecutable(artifact)) {
        ProcessResult result = await Process.run('chmod', ['u+x', cachedFile.path]);
        if (result.exitCode != 0) throw new Exception(result.stderr);
      }
    }
    return cachedFile.path;
  }

  static Future clear() async {
    Directory cacheDir = await _cacheDir();
    _logging.fine('Clearing cache directory ${cacheDir.path}');
    await cacheDir.delete(recursive: true);
  }

  static Future populate() async {
    for (Artifact artifact in Artifact.values) {
      _logging.fine('Populating cache with $artifact');
      await getPath(artifact);
    }
  }
}
