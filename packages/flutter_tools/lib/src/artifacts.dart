// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.artifacts;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final Logger _logging = new Logger('sky_tools.device');

enum Artifact {
  FlutterCompiler,
}

class _ArtifactStore {
  _ArtifactStore._();

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

  Future<String> _getEngineRevision(String packageRoot) {
    return new File(packageRoot + '/sky_engine/REVISION').readAsString();
  }

  Future<Directory> _cacheDir(String engineRevision, String packageRoot) async {
    String cacheDirPath = '${packageRoot}/sky_tools/cache/sky_engine/${engineRevision}/';
    Directory cacheDir = new Directory(cacheDirPath);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<String> getPath(Artifact artifact, String packageRoot) async {
    String engineRevision = await _getEngineRevision(packageRoot);
    Directory cacheDir = await _cacheDir(engineRevision, packageRoot);

    if (artifact == Artifact.FlutterCompiler) {
      File skySnapshotFile = new File(cacheDir.path + 'sky_snapshot');
      if (!await skySnapshotFile.exists()) {
        _logging.info('Downloading sky_snapshot from the cloud, one moment please...');
        String googleStorageUrl = 'https://storage.googleapis.com/mojo/sky/shell/linux-x64/${engineRevision}/sky_snapshot';
        await _downloadFile(googleStorageUrl, skySnapshotFile);
        ProcessResult result = await Process.run('chmod', ['u+x', skySnapshotFile.path]);
        if (result.exitCode != 0) throw new Exception(result.stderr);
      }
      return skySnapshotFile.path;
    }

    return '';
  }
}

final _ArtifactStore artifactStore = new _ArtifactStore._();
