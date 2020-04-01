// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String kPackagesFileName = '.packages';

class PackageMap {
  PackageMap();

  static String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

  static set globalPackagesPath(String value) {
    _globalPackagesPath = value;
  }

  static bool get isUsingCustomPackagesPath => _globalPackagesPath != null;

  static String _globalPackagesPath;
}
