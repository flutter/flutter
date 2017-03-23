// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'dart/package_map.dart';
import 'globals.dart';

dynamic _loadYamlFile(String path) {
  if (!fs.isFileSync(path))
    return null;
  final String manifestString = fs.file(path).readAsStringSync();
  return loadYaml(manifestString);
}

String _generatePluginManifest() {
  Map<String, Uri> packages;
  try {
    packages = new PackageMap(PackageMap.globalPackagesPath).map;
  } on FormatException catch(e) {
    printTrace('Invalid .packages file: $e');
    return '';
  }
  final List<String> plugins = <String>[];
  packages.forEach((String name, Uri uri) {
    final Uri packageRoot = uri.resolve('..');
    final dynamic packageConfig = _loadYamlFile(packageRoot.resolve('pubspec.yaml').path);
    if (packageConfig != null) {
      final dynamic flutterConfig = packageConfig['flutter'];
      if (flutterConfig != null && flutterConfig.containsKey('plugin')) {
        printTrace('Found plugin $name at ${packageRoot.path}');
        plugins.add('$name=${packageRoot.path}');
      }
    }
  });
  return plugins.join('\n');
}

void writeFlutterPluginsList() {
  final File pluginsProperties = fs.file('.flutter-plugins');

  final String pluginManifest = _generatePluginManifest();
  if (pluginManifest.isNotEmpty) {
    pluginsProperties.writeAsStringSync('$pluginManifest\n');
  } else {
    if (pluginsProperties.existsSync()) {
      pluginsProperties.deleteSync();
    }
  }
}
