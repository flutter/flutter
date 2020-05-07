// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
// TODO(bkonyi): remove deprecated member usage, https://github.com/flutter/flutter/issues/51951
// ignore: deprecated_member_use
import 'package:package_config/packages_file.dart' as packages_file;

import '../base/file_system.dart';
import '../globals.dart' as globals hide fs;

const String kPackagesFileName = '.packages';

Map<String, Uri> _parse(String packagesPath, FileSystem fileSystem) {
  final List<int> source = fileSystem.file(packagesPath).readAsBytesSync();
  return packages_file.parse(source,
      Uri.file(packagesPath, windows: globals.platform.isWindows));
}

class PackageMap {
  PackageMap(this.packagesPath, {
    @required FileSystem fileSystem,
  }) : _fileSystem = fileSystem;

  /// Create a [PackageMap] for testing.
  PackageMap.test(Map<String, Uri> input, {
    @required FileSystem fileSystem,
  }) : packagesPath = '.packages',
       _map = input,
       _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  static String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

  static set globalPackagesPath(String value) {
    _globalPackagesPath = value;
  }

  static bool get isUsingCustomPackagesPath => _globalPackagesPath != null;

  static String _globalPackagesPath;

  final String packagesPath;

  /// Load and parses the .packages file.
  void load() {
    _map ??= _parse(packagesPath, _fileSystem);
  }

  Map<String, Uri> get map {
    load();
    return _map;
  }
  Map<String, Uri> _map;

  /// Returns the path to [packageUri].
  String pathForPackage(Uri packageUri) => uriForPackage(packageUri).path;

  /// Returns the path to [packageUri] as URL.
  Uri uriForPackage(Uri packageUri) {
    assert(packageUri.scheme == 'package');
    final List<String> pathSegments = packageUri.pathSegments.toList();
    final String packageName = pathSegments.removeAt(0);
    final Uri packageBase = map[packageName];
    if (packageBase == null) {
      return null;
    }
    final String packageRelativePath = _fileSystem.path.joinAll(pathSegments);
    return packageBase.resolveUri(_fileSystem.path.toUri(packageRelativePath));
  }

  String checkValid() {
    if (_fileSystem.isFileSync(packagesPath)) {
      return null;
    }
    String message = '$packagesPath does not exist.';
    final String pubspecPath = _fileSystem.path.absolute(_fileSystem.path.dirname(packagesPath), 'pubspec.yaml');
    if (_fileSystem.isFileSync(pubspecPath)) {
      message += '\nDid you run "flutter pub get" in this directory?';
    } else {
      message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
    }
    return message;
  }
}
