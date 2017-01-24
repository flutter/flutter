// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'android/android_sdk.dart';
import 'globals.dart';

const String _kFlutterManifestPath = 'pubspec.yaml';
const String _kFlutterServicesManifestPath = 'flutter_services.yaml';

dynamic _loadYamlFile(String path) {
  printTrace("Looking for YAML at '$path'");
  if (!fs.isFileSync(path))
    return null;
  String manifestString = fs.file(path).readAsStringSync();
  return loadYaml(manifestString);
}

/// Loads all services specified in `pubspec.yaml`. Parses each service config file,
/// storing meta data in [services] and the list of jar files in [jars].
Future<Null> parseServiceConfigs(
  List<Map<String, String>> services, { List<File> jars }
) async {
  Map<String, Uri> packageMap;
  try {
    packageMap = new PackageMap(PackageMap.globalPackagesPath).map;
  } on FormatException catch(e) {
    printTrace('Invalid ".packages" file while parsing service configs:\n$e');
    return;
  }

  dynamic manifest;
  try {
    manifest = _loadYamlFile(_kFlutterManifestPath);
    manifest = manifest['flutter'];
  } catch (e) {
    printStatus('Error detected in pubspec.yaml:', emphasis: true);
    printError(e);
    return;
  }
  if (manifest == null || manifest['services'] == null) {
    printTrace('No services specified in the manifest');
    return;
  }

  for (String service in manifest['services']) {
    String serviceRoot = packageMap[service].path;
    dynamic serviceConfig = _loadYamlFile('$serviceRoot/$_kFlutterServicesManifestPath');
    if (serviceConfig == null) {
      printStatus('No $_kFlutterServicesManifestPath found for service "$serviceRoot"; skipping.');
      continue;
    }

    for (Map<String, String> service in serviceConfig['services']) {
      services.add(<String, String>{
        'root': serviceRoot,
        'name': service['name'],
        'android-class': service['android-class'],
        'ios-framework': service['ios-framework']
      });
    }

    if (jars != null && serviceConfig['jars'] is Iterable) {
      for (String jar in serviceConfig['jars'])
        jars.add(fs.file(await getServiceFromUrl(jar, serviceRoot, service, unzip: false)));
    }
  }
}

Future<String> getServiceFromUrl(
  String url, String rootDir, String serviceName, { bool unzip: false }
) async {
  if (url.startsWith("android-sdk:") && androidSdk != null) {
    // It's something shipped in the standard android SDK.
    return url.replaceAll('android-sdk:', '${androidSdk.directory}/');
  } else if (url.startsWith("http")) {
    // It's a regular file to download.
    return await cache.getThirdPartyFile(url, serviceName, unzip: unzip);
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
  String dir, List<Map<String, String>> servicesIn
) {
  List<Map<String, String>> services =
      servicesIn.map((Map<String, String> service) => <String, String>{
        'name': service['name'],
        'class': service['android-class']
      }).toList();

  Map<String, dynamic> json = <String, dynamic>{ 'services': services };
  File servicesFile = fs.file(path.join(dir, 'services.json'));
  servicesFile.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
  return servicesFile;
}
