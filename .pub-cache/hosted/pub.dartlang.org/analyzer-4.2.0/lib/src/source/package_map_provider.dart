// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// Data structure output by PackageMapProvider.  This contains both the package
/// map and dependency information.
class PackageMapInfo {
  /// The package map itself.  This is a map from package name to a list of
  /// the folders containing source code for the package.
  ///
  /// `null` if an error occurred.
  Map<String, List<Folder>> packageMap;

  /// Dependency information.  This is a set of the paths which were consulted
  /// in order to generate the package map.  If any of these files is
  /// modified, the package map will need to be regenerated.
  Set<String> dependencies;

  PackageMapInfo(this.packageMap, this.dependencies);
}

/// A PackageMapProvider is an entity capable of determining the mapping from
/// package name to source directory for a given folder.
abstract class PackageMapProvider {
  /// Compute a package map for the given folder, if possible.
  ///
  /// If a package map can't be computed (e.g. because an error occurred), a
  /// [PackageMapInfo] will still be returned, but its packageMap will be null.
  PackageMapInfo computePackageMap(Folder folder);
}
