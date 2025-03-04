// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:file/file.dart';

/// Writes a `.dart_tool/package_config.json` file at [directory].
///
/// If directory is not specified, it will be `globals.fs.currentDirectory`;
///
/// It will contain a package entry for [mainLibName] with `rootUri` at
/// [directory].
///
/// [otherLibs] maps other package names to their `rootUri` relative to `directory`.
///
/// Returns the `File` Object representing the package config.
File writePackageConfigFile({
  required Directory directory,
  required String mainLibName,
  Map<String, String> packages = const <String, String>{},
  Map<String, String> languageVersions = const <String, String>{},
  List<String> devDependencies = const <String>[],
}) {
  directory.childDirectory('.dart_tool').childFile('package_graph.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      json.encode(<String, Object?>{
        'roots': <Object?>[mainLibName],
        'packages': <Object>[
          <String, Object?>{
            'name': mainLibName,
            'dependencies': packages.keys.toList().whereNot(devDependencies.contains).toList(),
            'devDependencies': devDependencies,
          },
          ...packages.entries.map(
            (MapEntry<String, String> entry) => <String, Object?>{
              'name': entry.key,
              'dependencies': <String>[],
            },
          ),
        ],
        'configVersion': 1,
      }),
    );
  return directory.childDirectory('.dart_tool').childFile('package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      json.encode(<String, Object?>{
        'packages': <Object>[
          <String, Object?>{
            'name': mainLibName,
            'rootUri': '../',
            'packageUri': 'lib/',
            'languageVersion': languageVersions[mainLibName] ?? '3.7',
          },
          ...packages.entries.map(
            (MapEntry<String, String> entry) => <String, Object?>{
              'name': entry.key,
              'rootUri': Uri.parse('../').resolve(entry.value).toString(),
              'packageUri': 'lib/',
              'languageVersion': languageVersions[entry.key] ?? '3.7',
            },
          ),
        ],
        'configVersion': 2,
      }),
    );
}
