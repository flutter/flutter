// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'globals.dart';

import 'base/file_system.dart';
import 'dart/dependencies.dart';
import 'dart/package_map.dart';
import 'asset.dart';

import 'package:path/path.dart' as pathos;

class DependencyChecker {
  final DartDependencySetBuilder builder;
  final Set<String> _dependencies = new Set<String>();
  final AssetBundle assets;
  DependencyChecker(this.builder, this.assets);

  /// Returns [true] if any components have been modified after [threshold] or
  /// if it cannot be determined.
  bool check(DateTime threshold) {
    _dependencies.clear();
    PackageMap packageMap;
    // Parse the package map.
    try {
      packageMap = new PackageMap(builder.packagesFilePath)..load();
      _dependencies.add(builder.packagesFilePath);
    } catch (e, st) {
      printTrace('DependencyChecker: could not parse .packages file:\n$e\n$st');
      return true;
    }
    // Build the set of Dart dependencies.
    try {
      Set<String> dependencies = builder.build();
      for (String path in dependencies) {
        // Ensure all paths are absolute.
        if (path.startsWith('package:')) {
          path = packageMap.pathForPackage(Uri.parse(path));
        } else {
          path = pathos.join(builder.projectRootPath, path);
        }
        _dependencies.add(path);
      }
    } catch (e, st) {
      printTrace('DependencyChecker: error determining .dart dependencies:\n$e\n$st');
      return true;
    }
    // TODO(johnmccutchan): Extract dependencies from the AssetBundle too.

    // Check all dependency modification times.
    for (String path in _dependencies) {
      File file = fs.file(path);
      FileStat stat = file.statSync();
      if (stat.type == FileSystemEntityType.NOT_FOUND) {
        printTrace('DependencyChecker: Error stating $path.');
        return true;
      }
      if (stat.modified.isAfter(threshold)) {
        printTrace('DependencyChecker: $path is newer than $threshold');
        return true;
      }
    }
    printTrace('DependencyChecker: nothing is modified after $threshold.');
    return false;
  }
}
