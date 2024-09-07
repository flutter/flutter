// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

/// Parsing the output of "dart pub deps --json"
///
/// expected structure: {"name": "package name", "source": "hosted", "dependencies": [...]}
class DartDependencyPackage {
  DartDependencyPackage({
    required this.name,
    required this.version,
    required this.source,
    required this.dependencies,
  });

  factory DartDependencyPackage.fromHashMap(dynamic packageInfo) {
    List<String> dependencies = <String>[];

    if (packageInfo is! LinkedHashMap) {
      return DartDependencyPackage(
        name: '',
        version: '',
        source: '',
        dependencies: dependencies,
      );
    }
    if (packageInfo case {'dependencies': final List<dynamic> list}) {
      dependencies = <String>[for (final dynamic e in list) '$e'];
    }
    return DartDependencyPackage(
      name: packageInfo['name'] as String? ?? '',
      version: packageInfo['version'] as String? ?? '',
      source: packageInfo['source'] as String? ?? '',
      dependencies: dependencies,
    );
  }

  final String name;
  final String version;
  final String source;
  final List<String> dependencies;

}

class DartPubJson {
  DartPubJson(this._json);
  final LinkedHashMap<String, dynamic> _json;
  final List<DartDependencyPackage> _packages = <DartDependencyPackage>[];

  List<DartDependencyPackage> get packages {
    if (_packages.isNotEmpty) {
      return _packages;
    }
    if (_json.containsKey('packages')) {
      final List<dynamic> packagesInfo = _json['packages'] as List<dynamic>;
      for (final dynamic info in packagesInfo) {
        _packages.add(DartDependencyPackage.fromHashMap(info));
      }
    }
    return _packages;
  }
}
