// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_config/package_config.dart';

/// Adds methods to convert to a package map on [PackageConfig].
extension PackageMap on PackageConfig {
  /// A package map exactly matching the current package config
  Map<String, Uri> toPackageMap() =>
      {for (var package in packages) package.name: package.packageUriRoot};

  /// A package map with all the current packages but where the uris are all
  /// of the form 'packages/${package.name}'.
  Map<String, Uri> toPackagesDirPackageMap() => {
        for (var package in packages)
          package.name: Uri.parse('packages/${package.name}')
      };
}
