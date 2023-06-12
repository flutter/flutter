// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A package configuration is a way to assign file paths to package URIs,
/// and vice-versa.
///
/// This package provides functionality to find, read and write package
/// configurations in the [specified format](https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/package-config-file-v2.md).
library package_config.package_config;

import 'dart:io' show File, Directory;
import 'dart:typed_data' show Uint8List;

import 'src/discovery.dart' as discover;
import 'src/errors.dart' show throwError;
import 'src/package_config.dart';
import 'src/package_config_io.dart';

export 'package_config_types.dart';

/// Reads a specific package configuration file.
///
/// The file must exist and be readable.
/// It must be either a valid `package_config.json` file
/// or a valid `.packages` file.
/// It is considered a `package_config.json` file if its first character
/// is a `{`.
///
/// If the file is a `.packages` file (the file name is `.packages`)
/// and [preferNewest] is true, the default, also checks if there is
/// a `.dart_tool/package_config.json` file next
/// to the original file, and if so, loads that instead.
/// If [preferNewest] is set to false, a directly specified `.packages` file
/// is loaded even if there is an available `package_config.json` file.
/// The caller can determine this from the [PackageConfig.version]
/// being 1 and look for a `package_config.json` file themselves.
///
/// If [onError] is provided, the configuration file parsing will report errors
/// by calling that function, and then try to recover.
/// The returned package configuration is a *best effort* attempt to create
/// a valid configuration from the invalid configuration file.
/// If no [onError] is provided, errors are thrown immediately.
Future<PackageConfig> loadPackageConfig(File file,
        {bool preferNewest = true, void Function(Object error)? onError}) =>
    readAnyConfigFile(file, preferNewest, onError ?? throwError);

/// Reads a specific package configuration URI.
///
/// The file of the URI must exist and be readable.
/// It must be either a valid `package_config.json` file
/// or a valid `.packages` file.
/// It is considered a `package_config.json` file if its first
/// non-whitespace character is a `{`.
///
/// If [preferNewest] is true, the default, and the file is a `.packages` file,
/// as determined by its file name being `.packages`,
/// first checks if there is a `.dart_tool/package_config.json` file
/// next to the original file, and if so, loads that instead.
/// The [file] *must not* be a `package:` URI.
/// If [preferNewest] is set to false, a directly specified `.packages` file
/// is loaded even if there is an available `package_config.json` file.
/// The caller can determine this from the [PackageConfig.version]
/// being 1 and look for a `package_config.json` file themselves.
///
/// If [loader] is provided, URIs are loaded using that function.
/// The future returned by the loader must complete with a [Uint8List]
/// containing the entire file content encoded as UTF-8,
/// or with `null` if the file does not exist.
/// The loader may throw at its own discretion, for situations where
/// it determines that an error might be need user attention,
/// but it is always allowed to return `null`.
/// This function makes no attempt to catch such errors.
/// As such, it may throw any error that [loader] throws.
///
/// If no [loader] is supplied, a default loader is used which
/// only accepts `file:`,  `http:` and `https:` URIs,
/// and which uses the platform file system and HTTP requests to
/// fetch file content. The default loader never throws because
/// of an I/O issue, as long as the location URIs are valid.
/// As such, it does not distinguish between a file not existing,
/// and it being temporarily locked or unreachable.
///
/// If [onError] is provided, the configuration file parsing will report errors
/// by calling that function, and then try to recover.
/// The returned package configuration is a *best effort* attempt to create
/// a valid configuration from the invalid configuration file.
/// If no [onError] is provided, errors are thrown immediately.
Future<PackageConfig> loadPackageConfigUri(Uri file,
        {Future<Uint8List?> Function(Uri uri)? loader,
        bool preferNewest = true,
        void Function(Object error)? onError}) =>
    readAnyConfigFileUri(file, loader, onError ?? throwError, preferNewest);

/// Finds a package configuration relative to [directory].
///
/// If [directory] contains a package configuration,
/// either a `.dart_tool/package_config.json` file or,
/// if not, a `.packages`, then that file is loaded.
///
/// If no file is found in the current directory,
/// then the parent directories are checked recursively,
/// all the way to the root directory, to check if those contains
/// a package configuration.
/// If [recurse] is set to [false], this parent directory check is not
/// performed.
///
/// If [onError] is provided, the configuration file parsing will report errors
/// by calling that function, and then try to recover.
/// The returned package configuration is a *best effort* attempt to create
/// a valid configuration from the invalid configuration file.
/// If no [onError] is provided, errors are thrown immediately.
///
/// If [minVersion] is set to something greater than its default,
/// any lower-version configuration files are ignored in the search.
///
/// Returns `null` if no configuration file is found.
Future<PackageConfig?> findPackageConfig(Directory directory,
    {bool recurse = true,
    void Function(Object error)? onError,
    int minVersion = 1}) {
  if (minVersion > PackageConfig.maxVersion) {
    throw ArgumentError.value(minVersion, 'minVersion',
        'Maximum known version is ${PackageConfig.maxVersion}');
  }
  return discover.findPackageConfig(
      directory, minVersion, recurse, onError ?? throwError);
}

/// Finds a package configuration relative to [location].
///
/// If [location] contains a package configuration,
/// either a `.dart_tool/package_config.json` file or,
/// if not, a `.packages`, then that file is loaded.
/// The [location] URI *must not* be a `package:` URI.
/// It should be a hierarchical URI which is supported
/// by [loader].
///
/// If no file is found in the current directory,
/// then the parent directories are checked recursively,
/// all the way to the root directory, to check if those contains
/// a package configuration.
/// If [recurse] is set to [false], this parent directory check is not
/// performed.
///
/// If [loader] is provided, URIs are loaded using that function.
/// The future returned by the loader must complete with a [Uint8List]
/// containing the entire file content,
/// or with `null` if the file does not exist.
/// The loader may throw at its own discretion, for situations where
/// it determines that an error might be need user attention,
/// but it is always allowed to return `null`.
/// This function makes no attempt to catch such errors.
///
/// If no [loader] is supplied, a default loader is used which
/// only accepts `file:`,  `http:` and `https:` URIs,
/// and which uses the platform file system and HTTP requests to
/// fetch file content. The default loader never throws because
/// of an I/O issue, as long as the location URIs are valid.
/// As such, it does not distinguish between a file not existing,
/// and it being temporarily locked or unreachable.
///
/// If [onError] is provided, the configuration file parsing will report errors
/// by calling that function, and then try to recover.
/// The returned package configuration is a *best effort* attempt to create
/// a valid configuration from the invalid configuration file.
/// If no [onError] is provided, errors are thrown immediately.
///
/// If [minVersion] is set to something greater than its default,
/// any lower-version configuration files are ignored in the search.
///
/// Returns `null` if no configuration file is found.
Future<PackageConfig?> findPackageConfigUri(Uri location,
    {bool recurse = true,
    int minVersion = 1,
    Future<Uint8List?> Function(Uri uri)? loader,
    void Function(Object error)? onError}) {
  if (minVersion > PackageConfig.maxVersion) {
    throw ArgumentError.value(minVersion, 'minVersion',
        'Maximum known version is ${PackageConfig.maxVersion}');
  }
  return discover.findPackageConfigUri(
      location, minVersion, loader, onError ?? throwError, recurse);
}

/// Writes a package configuration to the provided directory.
///
/// Writes `.dart_tool/package_config.json` relative to [directory].
/// If the `.dart_tool/` directory does not exist, it is created.
/// If it cannot be created, this operation fails.
///
/// Also writes a `.packages` file in [directory].
/// This will stop happening eventually as the `.packages` file becomes
/// discontinued.
/// A comment is generated if `[PackageConfig.extraData]` contains a
/// `"generator"` entry.
Future<void> savePackageConfig(
        PackageConfig configuration, Directory directory) =>
    writePackageConfigJsonFile(configuration, directory);
