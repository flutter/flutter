// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

/// Creates a package: URI.
Uri pkg(String packageName, String packagePath) {
  var path =
      "$packageName${packagePath.startsWith('/') ? "" : "/"}$packagePath";
  return Uri(scheme: 'package', path: path);
}

// Remove if not used.
String configFromPackages(List<List<String>> packages) => """
{
  "configVersion": 2,
  "packages": [
${packages.map((nu) => """
    {
      "name": "${nu[0]}",
      "rootUri": "${nu[1]}"
    }""").join(",\n")}
  ]
}
""";

/// Mimics a directory structure of [description] and runs [fileTest].
///
/// Description is a map, each key is a file entry. If the value is a map,
/// it's a subdirectory, otherwise it's a file and the value is the content
/// as a string.
void loaderTest(
  String name,
  Map<String, Object> description,
  void Function(Uri root, Future<Uint8List?> Function(Uri) loader) loaderTest,
) {
  var root = Uri(scheme: 'test', path: '/');
  Future<Uint8List?> loader(Uri uri) async {
    var path = uri.path;
    if (!uri.isScheme('test') || !path.startsWith('/')) return null;
    var parts = path.split('/');
    Object? value = description;
    for (var i = 1; i < parts.length; i++) {
      if (value is! Map<String, Object?>) return null;
      value = value[parts[i]];
    }
    // ignore: unnecessary_cast
    if (value is String) return utf8.encode(value) as Uint8List;
    return null;
  }

  test(name, () => loaderTest(root, loader));
}
