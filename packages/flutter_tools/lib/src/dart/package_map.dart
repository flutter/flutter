// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:package_config/packages_file.dart' as packages_file;
import 'package:path/path.dart' as path;

const String kPackagesFileName = '.packages';

Map<String, Uri> _parse(String packagesPath) {
  List<int> source = new File(packagesPath).readAsBytesSync();
  return packages_file.parse(source, new Uri.file(packagesPath));
}

class PackageMap {
  PackageMap(this.packagesPath);

  static String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

  static set globalPackagesPath(String value) {
    _globalPackagesPath = value;
  }

  static String _globalPackagesPath;

  final String packagesPath;

  Map<String, Uri> get map {
    _map ??= _parse(packagesPath);
    return _map;
  }
  Map<String, Uri> _map;

  String checkValid() {
    if (FileSystemEntity.isFileSync(packagesPath))
      return null;
    String message = '$packagesPath does not exist.';
    String pubspecPath = path.absolute(path.dirname(packagesPath), 'pubspec.yaml');
    if (FileSystemEntity.isFileSync(pubspecPath))
      message += '\nDid you run `pub get` in this directory?';
    else
      message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
    return message;
  }
}
