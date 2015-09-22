// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.artifacts;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

final Logger _logging = new Logger('sky_tools.artifacts');

enum Artifact { FlutterCompiler, SkyViewerMojo, }

class ArtifactStore {
  String _engineRevision;
  final String packageRoot;

  ArtifactStore(this.packageRoot) {
    _engineRevision = new File(path.join(packageRoot, 'sky_engine', 'REVISION')).readAsStringSync();
  }

  String get engineRevision => _engineRevision;

  // Keep in sync with https://github.com/flutter/engine/blob/master/sky/tools/big_red_button.py#L50
  String googleStorageUrl(String category, String platform) {
    return 'https://storage.googleapis.com/mojo/sky/${category}/${platform}/${engineRevision}/';
  }

  Future _downloadFile(String url, File file) async {
    _logging.fine('Downloading $url to ${file.path}');
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

  Future<Directory> _cacheDir() async {
    Directory cacheDir = new Directory(path.join(packageRoot, 'sky_tools', 'cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<Directory> _engineSpecificCacheDir() async {
    Directory cacheDir = await _cacheDir();
    Directory engineSpecificDir = new Directory(path.join(cacheDir.path, 'sky_engine', engineRevision));

    if (!await engineSpecificDir.exists()) {
      await engineSpecificDir.create(recursive: true);
    }
    return engineSpecificDir;
  }

  // Whether the artifact needs to be marked as executable on disk.
  bool _needsToBeExecutable(Artifact artifact) {
    return artifact == Artifact.FlutterCompiler;
  }

  Future<String> getPath(Artifact artifact) async {
    Directory cacheDir = await _engineSpecificCacheDir();

    String category, name;

    switch (artifact) {
      case Artifact.FlutterCompiler:
        category = 'shell';
        name = 'sky_snapshot';
        break;
      case Artifact.SkyViewerMojo:
        category = 'viewer';
        name = 'sky_viewer.mojo';
        break;
    }

    File cachedFile = new File(path.join(cacheDir.path, name));
    if (!await cachedFile.exists()) {
      _logging.info('Downloading ${name} from the cloud, one moment please...');
      String url = googleStorageUrl(category, 'linux-x64') + name;
      await _downloadFile(url, cachedFile);
      if (_needsToBeExecutable(artifact)) {
        ProcessResult result = await Process.run('chmod', ['u+x', cachedFile.path]);
        if (result.exitCode != 0) throw new Exception(result.stderr);
      }
    }
    return cachedFile.path;
  }

  Future clear() async {
    Directory cacheDir = await _cacheDir();
    _logging.fine('Clearing cache directory ${cacheDir.path}');
    await cacheDir.delete(recursive: true);
  }

  Future populate() async {
    for (Artifact artifact in Artifact.values) {
      _logging.fine('Populating cache with $artifact');
      await getPath(artifact);
    }
  }
}
