// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The set of constants and utilities to check file paths.
///
/// The recommended import prefix is `file_paths`.
import 'package:path/path.dart' as p;

/// The file name used for analysis options files.
const String analysisOptionsYaml = 'analysis_options.yaml';

/// File name of Android manifest files.
const String androidManifestXml = 'AndroidManifest.xml';

/// File name of Blaze `BUILD` files.
const String blazeBuild = 'BUILD';

/// The path of the file that is the marker of a Blaze workspace, relative
/// to the workspace root.
const String blazeWorkspaceMarker = 'dart/config/ide/flutter.json';

/// File name of GN `BUILD.gn` files.
const String buildGn = 'BUILD.gn';

/// The name of the `.dart_tool` directory.
const String dotDartTool = '.dart_tool';

/// The name of the data file used to specify data-driven fixes.
const String fixDataYaml = 'fix_data.yaml';

/// The name of the package config files.
const String packageConfigJson = 'package_config.json';

/// File name of pubspec files.
const String pubspecYaml = 'pubspec.yaml';

/// Converts the given [path] into absolute and normalized.
String absoluteNormalized(p.Context pathContext, String path) {
  path = path.trim();
  path = pathContext.absolute(path);
  path = pathContext.normalize(path);
  return path;
}

/// Return `true` if [path] is an analysis options file.
bool isAnalysisOptionsYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == analysisOptionsYaml;
}

/// Return `true` if [path] is a `AndroidManifest.xml` file.
bool isAndroidManifestXml(p.Context pathContext, String path) {
  return pathContext.basename(path) == androidManifestXml;
}

/// Return `true` if [path] is a Blaze `BUILD` file.
bool isBlazeBuild(p.Context pathContext, String path) {
  return pathContext.basename(path) == blazeBuild;
}

/// Return `true` if [path] is a Dart file.
bool isDart(p.Context pathContext, String path) {
  return pathContext.extension(path) == '.dart';
}

/// Return `true` if the [path] is a `fix_data.yaml` file.
/// Such files specify data-driven fixes.
bool isFixDataYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == fixDataYaml;
}

/// Return `true` if the given [path] refers to a file that is assumed to be
/// generated.
bool isGenerated(String path) {
  // TODO(brianwilkerson) Generalize this mechanism.
  const List<String> suffixes = <String>[
    '.g.dart',
    '.pb.dart',
    '.pbenum.dart',
    '.pbserver.dart',
    '.pbjson.dart',
    '.template.dart'
  ];
  for (var suffix in suffixes) {
    if (path.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

/// Return `true` if [path] is a `.dart_tool/package_config.json` file.
bool isPackageConfigJson(p.Context pathContext, String path) {
  var components = pathContext.split(path);
  return components.length > 2 &&
      components[components.length - 1] == packageConfigJson &&
      components[components.length - 2] == dotDartTool;
}

/// Return `true` if [path] is a `pubspec.yaml` file.
bool isPubspecYaml(p.Context pathContext, String path) {
  return pathContext.basename(path) == pubspecYaml;
}
