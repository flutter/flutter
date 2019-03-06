// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'asset.dart';
import 'base/file_system.dart';
import 'dart/dependencies.dart';
import 'globals.dart';

class DependencyChecker {
  DependencyChecker(this.builder, this.assets);

  final DartDependencySetBuilder builder;
  final Set<String> _dependencies = Set<String>();
  final AssetBundle assets;

  /// Returns [true] if any components have been modified after [threshold] or
  /// if it cannot be determined.
  bool check(DateTime threshold) {
    _dependencies.clear();
    // Build the set of Dart dependencies.
    try {
      _dependencies.addAll(builder.build());
    } catch (e, st) {
      printTrace('DependencyChecker: error determining .dart dependencies:\n$e\n$st');
      return true;
    }
    // TODO(johnmccutchan): Extract dependencies from the AssetBundle too.

    // Check all dependency modification times.
    for (String path in _dependencies) {
      final File file = fs.file(path);
      final FileStat stat = file.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
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
