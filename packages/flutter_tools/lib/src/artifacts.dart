// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.artifacts;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.device');

enum Artifact { FlutterCompiler, SkyViewerMojo, }

class _ArtifactStore {
  _ArtifactStore._();

  // Keep in sync with https://github.com/flutter/engine/blob/master/sky/tools/big_red_button.py#L50
  String googleStorageUrl(String category, String platform, String engineRevision) {
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

  Future<Directory> _cacheDir(String engineRevision, String packageRoot) async {
    String cacheDirPath = '${packageRoot}/sky_tools/cache/sky_engine/${engineRevision}/';
    Directory cacheDir = new Directory(cacheDirPath);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Whether the artifact needs to be marked as executable on disk.
  bool _needsToBeExecutable(Artifact artifact) {
    return artifact == Artifact.FlutterCompiler;
  }


  Future<String> getEngineRevision(String packageRoot) {
    return new File(packageRoot + '/sky_engine/REVISION').readAsString();
  }

  Future<String> getPath(Artifact artifact, String packageRoot) async {
    String engineRevision = await getEngineRevision(packageRoot);
    Directory cacheDir = await _cacheDir(engineRevision, packageRoot);

    String category, name;

    if (artifact == Artifact.FlutterCompiler) {
      category = 'shell';
      name = 'sky_snapshot';
    } else if (artifact == Artifact.SkyViewerMojo) {
      category = 'viewer';
      name = 'sky_viewer.mojo';
    } else {
      // Unknown artifact.
      return '';
    }

    File cachedFile = new File(cacheDir.path + name);
    if (!await cachedFile.exists()) {
      _logging.info('Downloading ${name} from the cloud, one moment please...');
      String url = googleStorageUrl(category, 'linux-x64', engineRevision) + name;
      await _downloadFile(url, cachedFile);
      if (_needsToBeExecutable(artifact)) {
        ProcessResult result = await Process.run('chmod', ['u+x', cachedFile.path]);
        if (result.exitCode != 0) throw new Exception(result.stderr);
      }
    }
    return cachedFile.path;
  }
}

final _ArtifactStore artifactStore = new _ArtifactStore._();
