// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:package_config/package_config_types.dart';
import 'package:pub_semver/pub_semver.dart';

/// Find [Packages] starting from the given [start] resource.
///
/// Looks for `.dart_tool/package_config.json` in the given and parent
/// directories.
Packages findPackagesFrom(ResourceProvider provider, Resource start) {
  var startFolder = start is Folder ? start : start.parent;
  for (var current in startFolder.withAncestors) {
    var jsonFile = current
        .getChildAssumingFolder('.dart_tool')
        .getChildAssumingFile('package_config.json');
    if (jsonFile.exists) {
      return parsePackageConfigJsonFile(provider, jsonFile);
    }
  }
  return Packages.empty;
}

/// Parse the [file] as a `package_config.json` file.
Packages parsePackageConfigJsonFile(ResourceProvider provider, File file) {
  PackageConfig jsonConfig;
  try {
    var uri = file.toUri();
    var content = file.readAsStringSync();
    jsonConfig = PackageConfig.parseString(content, uri);
  } catch (e) {
    return Packages.empty;
  }

  var map = <String, Package>{};
  for (var jsonPackage in jsonConfig.packages) {
    var name = jsonPackage.name;

    var rootPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.root,
    );

    var libPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.packageUriRoot,
    );

    Version? languageVersion;
    var jsonLanguageVersion = jsonPackage.languageVersion;
    if (jsonLanguageVersion != null) {
      languageVersion = Version(
        jsonLanguageVersion.major,
        jsonLanguageVersion.minor,
        0,
      );
    }

    map[name] = Package(
      name: name,
      rootFolder: provider.getFolder(rootPath),
      libFolder: provider.getFolder(libPath),
      languageVersion: languageVersion,
    );
  }

  return Packages(map);
}

class Package {
  final String name;
  final Folder rootFolder;
  final Folder libFolder;

  /// The language version for this package, `null` not specified explicitly.
  final Version? languageVersion;

  Package({
    required this.name,
    required this.rootFolder,
    required this.libFolder,
    required this.languageVersion,
  });
}

class Packages {
  static final empty = Packages({});

  final Map<String, Package> _map;

  Packages(Map<String, Package> map) : _map = map;

  Iterable<Package> get packages => _map.values;

  /// Return the [Package] with the given [name], or `null`.
  Package? operator [](String name) => _map[name];

  /// Return the inner-most [Package] that contains  the [path], `null` if none.
  Package? packageForPath(String path) {
    Package? result;
    int resultPathLength = 1 << 20;
    for (var package in packages) {
      if (package.rootFolder.contains(path)) {
        var packagePathLength = package.rootFolder.path.length;
        if (result == null || resultPathLength < packagePathLength) {
          result = package;
          resultPathLength = packagePathLength;
        }
      }
    }
    return result;
  }
}
