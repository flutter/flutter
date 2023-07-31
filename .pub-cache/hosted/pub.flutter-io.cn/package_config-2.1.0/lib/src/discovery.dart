// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package_config_io.dart';

import 'errors.dart';
import 'package_config_impl.dart';
import 'package_config_json.dart';
import 'packages_file.dart' as packages_file;
import 'util_io.dart' show defaultLoader, pathJoin;

final Uri packageConfigJsonPath = Uri(path: '.dart_tool/package_config.json');
final Uri dotPackagesPath = Uri(path: '.packages');
final Uri currentPath = Uri(path: '.');
final Uri parentPath = Uri(path: '..');

/// Discover the package configuration for a Dart script.
///
/// The [baseDirectory] points to the directory of the Dart script.
/// A package resolution strategy is found by going through the following steps,
/// and stopping when something is found.
///
/// * Check if a `.dart_tool/package_config.json` file exists in the directory.
/// * Check if a `.packages` file exists in the directory
///   (if `minVersion <= 1`).
/// * Repeat these checks for the parent directories until reaching the
///   root directory if [recursive] is true.
///
/// If any of these tests succeed, a `PackageConfig` class is returned.
/// Returns `null` if no configuration was found. If a configuration
/// is needed, then the caller can supply [PackageConfig.empty].
///
/// If [minVersion] is greated than 1, `.packages` files are ignored.
/// If [minVersion] is greater than the version read from the
/// `package_config.json` file, it too is ignored.
Future<PackageConfig?> findPackageConfig(Directory baseDirectory,
    int minVersion, bool recursive, void Function(Object error) onError) async {
  var directory = baseDirectory;
  if (!directory.isAbsolute) directory = directory.absolute;
  if (!await directory.exists()) {
    return null;
  }
  do {
    // Check for $cwd/.packages
    var packageConfig =
        await findPackagConfigInDirectory(directory, minVersion, onError);
    if (packageConfig != null) return packageConfig;
    if (!recursive) break;
    // Check in parent directories.
    var parentDirectory = directory.parent;
    if (parentDirectory.path == directory.path) break;
    directory = parentDirectory;
  } while (true);
  return null;
}

/// Similar to [findPackageConfig] but based on a URI.
Future<PackageConfig?> findPackageConfigUri(
    Uri location,
    int minVersion,
    Future<Uint8List?> Function(Uri uri)? loader,
    void Function(Object error) onError,
    bool recursive) async {
  if (location.isScheme('package')) {
    onError(PackageConfigArgumentError(
        location, 'location', 'Must not be a package: URI'));
    return null;
  }
  if (loader == null) {
    if (location.isScheme('file')) {
      return findPackageConfig(
          Directory.fromUri(location.resolveUri(currentPath)),
          minVersion,
          recursive,
          onError);
    }
    loader = defaultLoader;
  }
  if (!location.path.endsWith('/')) location = location.resolveUri(currentPath);
  while (true) {
    var file = location.resolveUri(packageConfigJsonPath);
    var bytes = await loader(file);
    if (bytes != null) {
      var config = parsePackageConfigBytes(bytes, file, onError);
      if (config.version >= minVersion) return config;
    }
    if (minVersion <= 1) {
      file = location.resolveUri(dotPackagesPath);
      bytes = await loader(file);
      if (bytes != null) {
        return packages_file.parse(bytes, file, onError);
      }
    }
    if (!recursive) break;
    var parent = location.resolveUri(parentPath);
    if (parent == location) break;
    location = parent;
  }
  return null;
}

/// Finds a `.packages` or `.dart_tool/package_config.json` file in [directory].
///
/// Loads the file, if it is there, and returns the resulting [PackageConfig].
/// Returns `null` if the file isn't there.
/// Reports a [FormatException] if a file is there but the content is not valid.
/// If the file exists, but fails to be read, the file system error is reported.
///
/// If [onError] is supplied, parsing errors are reported using that, and
/// a best-effort attempt is made to return a package configuration.
/// This may be the empty package configuration.
///
/// If [minVersion] is greated than 1, `.packages` files are ignored.
/// If [minVersion] is greater than the version read from the
/// `package_config.json` file, it too is ignored.
Future<PackageConfig?> findPackagConfigInDirectory(Directory directory,
    int minVersion, void Function(Object error) onError) async {
  var packageConfigFile = await checkForPackageConfigJsonFile(directory);
  if (packageConfigFile != null) {
    var config = await readPackageConfigJsonFile(packageConfigFile, onError);
    if (config.version < minVersion) return null;
    return config;
  }
  if (minVersion <= 1) {
    packageConfigFile = await checkForDotPackagesFile(directory);
    if (packageConfigFile != null) {
      return await readDotPackagesFile(packageConfigFile, onError);
    }
  }
  return null;
}

Future<File?> checkForPackageConfigJsonFile(Directory directory) async {
  assert(directory.isAbsolute);
  var file =
      File(pathJoin(directory.path, '.dart_tool', 'package_config.json'));
  if (await file.exists()) return file;
  return null;
}

Future<File?> checkForDotPackagesFile(Directory directory) async {
  var file = File(pathJoin(directory.path, '.packages'));
  if (await file.exists()) return file;
  return null;
}
