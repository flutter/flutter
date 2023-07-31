// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// Given a package map, check in each package's lib directory for the existence
/// of an `_embedder.yaml` file. If the file contains a top level YamlMap, it
/// will be added to the [embedderYamls] map.
class EmbedderYamlLocator {
  /// The name of the embedder files being searched for.
  static const String _embedderFileName = '_embedder.yaml';

  /// A mapping from a package's library directory to the parsed YamlMap.
  final Map<Folder, YamlMap> embedderYamls = HashMap<Folder, YamlMap>();

  /// Initialize a newly created locator by processing the packages in the given
  /// [packageMap].
  EmbedderYamlLocator(Map<String, List<Folder>>? packageMap) {
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /// Initialize with the given [libFolder] of `sky_engine` package.
  EmbedderYamlLocator.forLibFolder(Folder libFolder) {
    _processPackage([libFolder]);
  }

  /// Programmatically add an `_embedder.yaml` mapping.
  void addEmbedderYaml(Folder libDir, String embedderYaml) {
    _processEmbedderYaml(libDir, embedderYaml);
  }

  /// Refresh the map of located files to those found by processing the given
  /// [packageMap].
  void refresh(Map<String, List<Folder>>? packageMap) {
    // Clear existing.
    embedderYamls.clear();
    if (packageMap != null) {
      _processPackageMap(packageMap);
    }
  }

  /// Given the yaml for an embedder ([embedderYaml]) and a folder ([libDir]),
  /// setup the uri mapping.
  void _processEmbedderYaml(Folder libDir, String embedderYaml) {
    try {
      var yaml = loadYaml(embedderYaml);
      if (yaml is YamlMap) {
        embedderYamls[libDir] = yaml;
      }
    } catch (_) {
      // Ignored
    }
  }

  /// Given a package list of folders ([libDirs]), process any
  /// `_embedder.yaml` files that are found in any of the folders.
  void _processPackage(List<Folder> libDirs) {
    for (Folder libDir in libDirs) {
      String? embedderYaml = _readEmbedderYaml(libDir);
      if (embedderYaml != null) {
        _processEmbedderYaml(libDir, embedderYaml);
      }
    }
  }

  /// Process each of the entries in the [packageMap].
  void _processPackageMap(Map<String, List<Folder>> packageMap) {
    packageMap.values.forEach(_processPackage);
  }

  /// Read and return the contents of [libDir]/[_embedderFileName], or `null`
  /// if the file doesn't exist.
  String? _readEmbedderYaml(Folder libDir) {
    var file = libDir.getChildAssumingFile(_embedderFileName);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}
