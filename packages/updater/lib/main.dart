// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mojo/core.dart';
import 'package:flutter/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flx/bundle.dart';
import 'package:sky_services/updater/update_service.mojom.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'pipe_to_file.dart';
import 'version.dart';

const String kManifestFile = 'flutter.yaml';
const String kBundleFile = 'app.flx';

UpdateServiceProxy _initUpdateService() {
  UpdateServiceProxy updateService = new UpdateServiceProxy.unbound();
  shell.connectToService(null, updateService);
  return updateService;
}

final UpdateServiceProxy _updateService = _initUpdateService();

String cachedDataDir = null;
Future<String> getDataDir() async {
  if (cachedDataDir == null)
    cachedDataDir = await getAppDataDir();
  return cachedDataDir;
}

class UpdateFailure extends Error {
  UpdateFailure(this._message);
  String _message;
  String toString() => _message;
}

class UpdateTask {
  UpdateTask();

  Future run() async {
    try {
      await _runImpl();
    } on UpdateFailure catch (e) {
      print('Update failed: $e');
    } catch (e, stackTrace) {
      print('Update failed: $e');
      print('Stack: $stackTrace');
    } finally {
      _updateService.ptr.notifyUpdateCheckComplete();
    }
  }

  Future _runImpl() async {
    _dataDir = await getDataDir();

    await _readLocalManifest();
    yaml.YamlMap remoteManifest = await _fetchManifest();
    if (!_shouldUpdate(remoteManifest)) {
      print('Update skipped. No new version.');
      return;
    }
    await _fetchBundle();
    await _validateBundle();
    await _replaceBundle();
    print('Update success.');
  }

  Map _currentManifest;
  String _dataDir;
  String _tempPath;

  Future _readLocalManifest() async {
    String bundlePath = path.join(_dataDir, kBundleFile);
    Bundle bundle = await Bundle.readHeader(bundlePath);
    _currentManifest = bundle.manifest;
  }

  Future<yaml.YamlMap> _fetchManifest() async {
    String manifestUrl = _currentManifest['update-url'] + '/' + kManifestFile;
    String manifestData = (await http.get(manifestUrl)).body;
    return yaml.loadYaml(manifestData, sourceUrl: manifestUrl);
  }

  bool _shouldUpdate(yaml.YamlMap remoteManifest) {
    Version currentVersion = new Version(_currentManifest['version']);
    Version remoteVersion = new Version(remoteManifest['version']);
    return (currentVersion < remoteVersion);
  }

  Future _fetchBundle() async {
    // TODO(mpcomplete): Use the cache dir. We need an equivalent of mkstemp().
    _tempPath = path.join(_dataDir, 'tmp.skyx');
    String bundleUrl = _currentManifest['update-url'] + '/' + kBundleFile;
    UrlResponse response = await fetchUrl(bundleUrl);
    int result = await PipeToFile.copyToFile(response.body, _tempPath);
    if (result != MojoResult.kOk)
      throw new UpdateFailure('Failure fetching new package: ${response.statusLine}');
  }

  Future _validateBundle() async {
    Bundle bundle = await Bundle.readHeader(_tempPath);

    if (bundle == null)
      throw new UpdateFailure('Remote package not a valid FLX file.');
    if (bundle.manifest['key'] != _currentManifest['key'])
      throw new UpdateFailure('Remote package key does not match.');
    if (!await bundle.verifyContent())
      throw new UpdateFailure('Invalid package signature or hash. This package has been tampered with.');
  }

  Future _replaceBundle() async {
    String bundlePath = path.join(_dataDir, kBundleFile);
    await new File(_tempPath).rename(bundlePath);
  }
}

void main() {
  UpdateTask task = new UpdateTask();
  task.run();
}
