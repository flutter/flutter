// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:package_config/package_config.dart';

/// The [PackageConfig] parsed from the current isolates package config file.
final Future<PackageConfig> currentPackageConfig = () async {
  return loadPackageConfigUri(await packageConfigUri);
}();

final Future<Uri> packageConfigUri = () async {
  var uri = await Isolate.packageConfig;
  if (uri == null) {
    throw StateError('Unable to find a package config');
  }
  return uri;
}();
