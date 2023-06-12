// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'dart:io' show Directory;

void main() async {
  var packageConfig = await findPackageConfig(Directory.current);
  if (packageConfig == null) {
    print('Failed to locate or read package config.');
  } else {
    print('This package depends on ${packageConfig.packages.length} packages:');
    for (var package in packageConfig.packages) {
      print('- ${package.name}');
    }
  }
}
