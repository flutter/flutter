// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mojo/core.dart';
import 'package:flutter/services.dart';
import 'package:sky_services/updater/update_service.mojom.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'version.dart';
import 'pipe_to_file.dart';

const String kManifestFile = 'sky.yaml';
const String kBundleFile = 'app.skyx';

UpdateServiceProxy _initUpdateService() {
  UpdateServiceProxy updateService = new UpdateServiceProxy.unbound();
  shell.requestService(null, updateService);
  return updateService;
}

final UpdateServiceProxy _updateService = _initUpdateService();

String cachedDataDir = null;
Future<String> getDataDir() async {
  if (cachedDataDir == null)
    cachedDataDir = await getAppDataDir();
  return cachedDataDir;
}

class UpdateTask {
  UpdateTask() {}

  run() async {
    try {
      await _runImpl();
    } catch(e) {
      print('Update failed: $e');
    } finally {
      _updateService.ptr.notifyUpdateCheckComplete();
    }
  }

  _runImpl() async {
    _dataDir = await getDataDir();

    await _readLocalManifest();
    yaml.YamlMap remoteManifest = await _fetchManifest();
    if (!_shouldUpdate(remoteManifest)) {
      print('Update skipped. No new version.');
      return;
    }
    MojoResult result = await _fetchBundle();
    if (!result.isOk) {
      print('Update failed while fetching new skyx bundle.');
      return;
    }
    await _replaceBundle();
    print('Update success.');
  }

  yaml.YamlMap _currentManifest;
  String _dataDir;
  String _tempPath;

  _readLocalManifest() async {
    String manifestPath = path.join(_dataDir, kManifestFile);
    String manifestData = await new File(manifestPath).readAsString();
    _currentManifest = yaml.loadYaml(manifestData, sourceUrl: manifestPath);
  }

  Future<yaml.YamlMap> _fetchManifest() async {
    String manifestUrl = _currentManifest['update_url'] + '/' + kManifestFile;
    String manifestData = await fetchString(manifestUrl);
    return yaml.loadYaml(manifestData, sourceUrl: manifestUrl);
  }

  bool _shouldUpdate(yaml.YamlMap remoteManifest) {
    Version currentVersion = new Version(_currentManifest['version']);
    Version remoteVersion = new Version(remoteManifest['version']);
    return (currentVersion < remoteVersion);
  }

  Future<MojoResult> _fetchBundle() async {
    // TODO(mpcomplete): Use the cache dir. We need an equivalent of mkstemp().
    _tempPath = path.join(_dataDir, 'tmp.skyx');
    String bundleUrl = _currentManifest['update_url'] + '/' + kBundleFile;
    UrlResponse response = await fetchUrl(bundleUrl);
    return PipeToFile.copyToFile(response.body, _tempPath);
  }

  _replaceBundle() async {
    String bundlePath = path.join(_dataDir, kBundleFile);
    await new File(_tempPath).rename(bundlePath);
  }
}

void main() {
  var task = new UpdateTask();
  task.run();
}
