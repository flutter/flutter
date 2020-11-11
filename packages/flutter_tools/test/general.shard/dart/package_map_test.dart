// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:package_config/package_config_types.dart';

import '../../src/common.dart';


const String packageConfigSource = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "web_socket_channel",
      "rootUri": "file:///C:/Users/Jonah/AppData/Roaming/Pub/Cache/hosted/pub.dartlang.org/web_socket_channel-1.1.0",
      "packageUri": "lib/",
      "languageVersion": "2.0"
    },
    {
      "name": "yaml",
      "rootUri": "file:///C:/Users/Jonah/AppData/Roaming/Pub/Cache/hosted/pub.dartlang.org/yaml-2.2.1",
      "packageUri": "lib/",
      "languageVersion": "2.4"
    },
    {
      "name": "flutter_tools",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    }
  ],
  "generated": "2020-11-11T20:41:09.595907Z",
  "generator": "pub",
  "generatorVersion": "2.12.0-31.0.dev"
}
''';

void main() {
  testWithoutContext('Can parse a package map', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(packageConfigSource);
    final PackageConfig packageConfig = createPackageConfig(file);

    expect(packageConfig.packages, hasLength(3));
    expect(packageConfig['flutter_tools'].languageVersion, LanguageVersion(2, 7));
    expect(packageConfig['flutter_tools'].packageUriRoot, Uri.parse('file:///foo/lib/'));
    expect(packageConfig['yaml'].packageUriRoot, Uri.parse('file:///C:/Users/Jonah/AppData/Roaming/Pub/Cache/hosted/pub.dartlang.org/yaml-2.2.1/lib/'));
    expect(packageConfig['yaml'].languageVersion, LanguageVersion(2, 4));
  });

  testWithoutContext('Returns empty package map on parse failure', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{');
    expect(createPackageConfig(file), PackageConfig.empty);
  });

  testWithoutContext('rethrows if fatal is true', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{');
    expect(() => createPackageConfig(file, fatal: true), throwsA(isA<Exception>()));
  });
}
