// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'android/android_sdk.dart';
import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'globals.dart';

const String _kFlutterManifestPath = 'pubspec.yaml';
const String _kFlutterServicesManifestPath = 'flutter_services.yaml';

dynamic _loadYamlFile(String path) {
  printTrace("Looking for YAML at '$path'");
  if (!fs.isFileSync(path))
    return null;
  final String manifestString = fs.file(path).readAsStringSync();
  return loadYaml(manifestString);
}

/// Loads all services specified in `pubspec.yaml`. Parses each service config file,
/// storing meta data in [services] and the list of jar files in [jars].
Future<void> parseServiceConfigs(
  List<Map<String, String>> services, { List<File> jars }
) async {
  Map<String, Uri> packageMap;
  try {
    packageMap = PackageMap(PackageMap.globalPackagesPath).map;
  } on FormatException catch (error) {
    printTrace('Invalid ".packages" file while parsing service configs:\n$error');
    return;
  }

  dynamic manifest;
  try {
    manifest = _loadYamlFile(_kFlutterManifestPath);
    manifest = manifest['flutter'];
  } catch (error) {
    printStatus('Error detected in pubspec.yaml:', emphasis: true);
    printError('$error');
    return;
  }
  if (manifest == null || manifest['services'] == null) {
    printTrace('No services specified in the manifest');
    return;
  }

  for (String service in manifest['services']) {
    final String serviceRoot = packageMap[service].path;
    final dynamic serviceConfig = _loadYamlFile('$serviceRoot/$_kFlutterServicesManifestPath');
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
        jars.add(fs.file(await getServiceFromUrl(jar, serviceRoot, service)));
    }
  }
}

Future<String> getServiceFromUrl(String url, String rootDir, String serviceName) async {
  if (url.startsWith('android-sdk:') && androidSdk != null) {
    // It's something shipped in the standard android SDK.
    return url.replaceAll('android-sdk:', '${androidSdk.directory}/');
  } else if (url.startsWith('http:') || url.startsWith('https:')) {
    // It's a regular file to download.
    return await cache.getThirdPartyFile(url, serviceName);
  } else {
    // Assume url is a path relative to the service's root dir.
    return fs.path.join(rootDir, url);
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
  final List<Map<String, String>> services =
      servicesIn.map<Map<String, String>>((Map<String, String> service) => <String, String>{
        'name': service['name'],
        'class': service['android-class']
      }).toList();

  final Map<String, dynamic> jsonObject = <String, dynamic>{ 'services': services };
  final File servicesFile = fs.file(fs.path.join(dir, 'services.json'));
  servicesFile.writeAsStringSync(json.encode(jsonObject), mode: FileMode.write, flush: true);
  return servicesFile;
}
