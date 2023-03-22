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
    String name = '';
    String version = '';
    String source = '';
    List<dynamic> dependencies = <dynamic>[];

    if (packageInfo is LinkedHashMap) {
      final LinkedHashMap<String, dynamic> info = packageInfo as LinkedHashMap<String, dynamic>;
      if (info.containsKey('name')) {
        name = info['name'] as String;
      }
      if (info.containsKey('version')) {
        version = info['version'] as String;
      }
      if (info.containsKey('source')) {
        source = info['source'] as String;
      }
      if (info.containsKey('dependencies')) {
        dependencies = info['dependencies'] as List<dynamic>;
      }
    }
    return DartDependencyPackage(
      name: name,
      version: version,
      source: source,
      dependencies: dependencies.map((dynamic e) => e.toString()).toList(),
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
