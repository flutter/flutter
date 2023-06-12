// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/package_config_json.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:package_config/src/packages_file.dart'
    as package_config_packages_file;
import 'package:pub_semver/pub_semver.dart';

/// Find [Packages] starting from the given [start] resource.
///
/// Looks for `.dart_tool/package_config.json` or `.packages` in the given
/// and parent directories.
Packages findPackagesFrom(ResourceProvider provider, Resource start) {
  var startFolder = start is Folder ? start : start.parent2;
  for (var current in startFolder.withAncestors) {
    try {
      var jsonFile = current
          .getChildAssumingFolder('.dart_tool')
          .getChildAssumingFile('package_config.json');
      if (jsonFile.exists) {
        return parsePackageConfigJsonFile(provider, jsonFile);
      }
    } catch (e) {
      return Packages.empty;
    }

    try {
      var dotFile = current.getChildAssumingFile('.packages');
      if (dotFile.exists) {
        return parseDotPackagesFile(provider, dotFile);
      }
    } catch (e) {
      return Packages.empty;
    }
  }
  return Packages.empty;
}

/// Parse the [file] as a `.packages` file.
Packages parseDotPackagesFile(ResourceProvider provider, File file) {
  var uri = file.toUri();
  var content = file.readAsBytesSync();
  // TODO(srawlins): Replacing these two imports with public imports currently
  // requires a sweeping breaking change, from synchronous code to asynchronous,
  // including in our public APIs. When synchronous public APIs become
  // available, use those.
  // See https://github.com/dart-lang/package_config/issues/95.
  var packageConfig = package_config_packages_file.parse(
      content, uri, (Object error) => throw error);

  var map = <String, Package>{};
  for (var package in packageConfig.packages) {
    var libUri = package.packageUriRoot;
    var libPath = fileUriToNormalizedPath(
      provider.pathContext,
      libUri,
    );
    var libFolder = provider.getFolder(libPath);
    map[package.name] = Package(
      name: package.name,
      rootFolder: libFolder,
      libFolder: libFolder,
      languageVersion: null,
    );
  }

  return Packages(map);
}

/// Parse the [file] as a `package_config.json` file.
Packages parsePackageConfigJsonFile(ResourceProvider provider, File file) {
  var uri = file.toUri();
  var content = file.readAsStringSync();
  var jsonConfig = parsePackageConfigJson(uri, content);

  var map = <String, Package>{};
  for (var jsonPackage in jsonConfig.packages) {
    var name = jsonPackage.name;

    var rootPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.rootUri,
    );

    var libPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.packageUri,
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

/// Check the content of the [file], and parse it as either `.packages` file,
/// or as a `package_config.json` file, depending on its content (not its
/// location).  OTOH, if the file has the `.packages` format, still look
/// for a `.dart_tool/package_config.json` relative to the specified [file].
Packages parsePackagesFile(ResourceProvider provider, File file) {
  try {
    var content = file.readAsStringSync();
    var isJson = content.trimLeft().startsWith('{');
    if (isJson) {
      return parsePackageConfigJsonFile(provider, file);
    } else {
      var relativePackageConfigFile = file.parent2
          .getChildAssumingFolder('.dart_tool')
          .getChildAssumingFile('package_config.json');
      if (relativePackageConfigFile.exists) {
        return parsePackageConfigJsonFile(provider, relativePackageConfigFile);
      }
      return parseDotPackagesFile(provider, file);
    }
  } catch (e) {
    return Packages.empty;
  }
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
