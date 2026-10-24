// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('bundle_path is optional', () {
    final (AssetsEntry? entry, String? error) = AssetsEntry.parseFromYamlSafe('config.json');
    expect(error, isNull);
    expect(entry!.bundleUri, isNull);
    expect(entry.descriptor, 'config.json');
  });

  testWithoutContext('bundle_path round trips literal special characters', () {
    final (AssetsEntry? entry, String? error) = AssetsEntry.parseFromYamlSafe(
      YamlMap.wrap(<String, Object?>{
        'path': 'configs/dev.json',
        'flavors': <String>['dev'],
        'bundle_path': 'assets/config #1%.json',
      }),
    );
    expect(error, isNull);
    expect(entry!.bundleUri!.toFilePath(windows: false), 'assets/config #1%.json');
    final (AssetsEntry? restored, String? restoredError) = AssetsEntry.parseFromYamlSafe(
      YamlMap.wrap(entry.descriptor! as Map<Object?, Object?>),
    );
    expect(restoredError, isNull);
    expect(restored, entry);
    expect(restored.hashCode, entry.hashCode);
    expect(
      AssetsEntry(uri: entry.uri, bundleUri: Uri.parse('other.json'), flavors: entry.flavors),
      isNot(entry),
    );
  });

  for (final destination in <Object?>[
    null,
    '',
    42,
    '/absolute.json',
    '../outside.json',
    './config.json',
    'assets//config.json',
    'assets/',
    r'assets\config.json',
    'C:/config.json',
    'assets/\nconfig.json',
    'packages/example/config.json',
  ]) {
    testWithoutContext('rejects invalid bundle_path $destination', () {
      final (AssetsEntry? entry, String? error) = AssetsEntry.parseFromYamlSafe(
        YamlMap.wrap(<String, Object?>{
          'path': 'config.json',
          'flavors': <String>['dev'],
          'bundle_path': destination,
        }),
      );
      expect(entry, isNull);
      expect(error, contains('bundle_path'));
    });
  }

  for (final overrides in <Map<String, Object?>>[
    <String, Object?>{'path': 'configs/'},
    <String, Object?>{'path': 'packages/example/config.json'},
    <String, Object?>{'path': '../config.json'},
    <String, Object?>{'flavors': <String>[]},
    <String, Object?>{'flavors': null},
    <String, Object?>{
      'transformers': <Map<String, Object?>>[
        <String, Object?>{'package': 'transformer'},
      ],
    },
    <String, Object?>{
      'platforms': <String>['android'],
    },
  ]) {
    testWithoutContext('rejects unsupported configuration declaration $overrides', () {
      final (AssetsEntry? entry, String? error) = AssetsEntry.parseFromYamlSafe(
        YamlMap.wrap(<String, Object?>{
          'path': 'config.json',
          'flavors': <String>['dev'],
          'bundle_path': 'assets/config.json',
          ...overrides,
        }),
      );
      expect(entry, isNull);
      expect(error, contains('bundle_path'));
    });
  }
}
