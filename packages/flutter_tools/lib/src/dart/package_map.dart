// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/packages_file.dart' as packages_file;
import 'package:path/path.dart' as path;

import '../base/file_system.dart';

const String kPackagesFileName = '.packages';

Map<String, Uri> _parse(String packagesPath) {
  List<int> source = fs.file(packagesPath).readAsBytesSync();
  return packages_file.parse(source, new Uri.file(packagesPath));
}

class PackageMap {
  PackageMap(this.packagesPath);

  static String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

  static set globalPackagesPath(String value) {
    _globalPackagesPath = value;
  }

  static bool get isUsingCustomPackagesPath => _globalPackagesPath != null;

  static String _globalPackagesPath;

  final String packagesPath;

  /// Load and parses the .packages file.
  void load() {
    _map ??= _parse(packagesPath);
  }

  Map<String, Uri> get map {
    load();
    return _map;
  }
  Map<String, Uri> _map;

  /// Returns the path to [packageUri].
  String pathForPackage(Uri packageUri) {
    assert(packageUri.scheme == 'package');
    List<String> pathSegments = packageUri.pathSegments.toList();
    String packageName = pathSegments.removeAt(0);
    Uri packageBase = map[packageName];
    String packageRelativePath = path.joinAll(pathSegments);
    return packageBase.resolve(packageRelativePath).path;
  }

  String checkValid() {
    if (fs.isFileSync(packagesPath))
      return null;
    String message = '$packagesPath does not exist.';
    String pubspecPath = path.absolute(path.dirname(packagesPath), 'pubspec.yaml');
    if (fs.isFileSync(pubspecPath))
      message += '\nDid you run "flutter packages get" in this directory?';
    else
      message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
    return message;
  }
}
