// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'artifacts.dart';

const String _kFlutterManifestPath = 'flutter.yaml';

dynamic _loadYamlFile(String path) {
  if (!FileSystemEntity.isFileSync(path))
    return null;
  String manifestString = new File(path).readAsStringSync();
  return loadYaml(manifestString);
}

/// Loads all services specified in `flutter.yaml`. Parses each service config file,
/// storing metadata in [services] and the list of jar files in [jars].
Future parseServiceConfigs(
  List<Map<String, String>> services, { List<File> jars, String androidSdk }
) async {
  if (!ArtifactStore.isPackageRootValid)
    return;

  dynamic manifest = _loadYamlFile(_kFlutterManifestPath);
  if (manifest['services'] == null)
    return;

  for (String service in manifest['services']) {
    String serviceRoot = '${ArtifactStore.packageRoot}/$service';
    dynamic serviceConfig = _loadYamlFile('$serviceRoot/config.yaml');
    if (serviceConfig == null)
      continue;

    for (Map<String, String> service in serviceConfig['services']) {
      services.add({
        'root': serviceRoot,
        'name': service['name'],
        'android-class': service['android-class'],
        'ios-framework': service['ios-framework']
      });
    }

    if (jars != null) {
      for (String jar in serviceConfig['jars'])
        jars.add(new File(await getServiceFromUrl(jar, serviceRoot, service, androidSdk: androidSdk, unzip: false)));
    }
  }
}

Future<String> getServiceFromUrl(
  String url, String rootDir, String serviceName, { String androidSdk, bool unzip: false }
) async {
  if (url.startsWith("android-sdk:")) {
    // It's something shipped in the standard android SDK.
    return url.replaceAll('android-sdk:', '$androidSdk/');
  } else if (url.startsWith("http")) {
    // It's a regular file to download.
    return await ArtifactStore.getThirdPartyFile(url, serviceName, unzip);
  } else {
    // Assume url is a path relative to the service's root dir.
    return path.join(rootDir, url);
  }
}

/// Outputs a services.json file for the flutter engine to read. Format:
/// {
///   services: [
///     { name: string, framework: string },
///     ...
///   ]
/// }
File generateServiceDefinitions(
  String dir, List<Map<String, String>> servicesIn, { bool ios }
) {
  assert(ios != null);

  String keyOut = ios ? 'framework' : 'class';
  String keyIn = ios ? 'framework-path' : 'android-class';
  // TODO(mpcomplete): we should use the same filename for consistency.
  String filename = ios ? 'ServiceDefinitions.json' : 'services.json';
  List<Map<String, String>> services =
      servicesIn.map((Map<String, String> service) => {
        'name': service['name'],
        keyOut: service[keyIn]
      }).toList();

  Map<String, dynamic> json = { 'services': services };
  File servicesFile = new File(path.join(dir, filename));
  servicesFile.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
  return servicesFile;
}
