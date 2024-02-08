// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';

void main() {

  testWithoutContext('correctly bundles assets given a simple asset manifest with a transformer', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final FakePlatform platform = FakePlatform();

    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('assets', 'hello.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
  - path: assets/hello.txt
    transformers:
      - package: capitalizer
''');

    final ManifestAssetBundle bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      flutterRoot: Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      ),
    );

    await bundle.build(
      packagesPath: '.packages',
      flutterProject: FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      ),
    );


    expect(bundle.entries, contains('assets/hello.txt'));
    expect(
      bundle.entries['assets/hello.txt']!.transformers,
      orderedEquals(
        <AssetTransformerEntry>[
          const AssetTransformerEntry(package: 'capitalizer', args: null),
        ],
      ),
    );
  });

  testWithoutContext('Given an asset declaration with multiple transformers, the transformers are stored in the declaration sequence', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final BufferLogger logger = BufferLogger.test();
    final FakePlatform platform = FakePlatform();

    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('assets', 'hello.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
  - path: assets/hello.txt
    transformers:
      - package: capitalizer
      - package: scrambler
      - package: encoder
''');

    final ManifestAssetBundle bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      flutterRoot: Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      ),
    );

    final int code = await bundle.build(
      packagesPath: '.packages',
      flutterProject: FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      ),
    );

    expect(code, 0);
    expect(bundle.entries, contains('assets/hello.txt'));
    expect(
      bundle.entries['assets/hello.txt']!.transformers,
      orderedEquals(
        <AssetTransformerEntry>[
          const AssetTransformerEntry(package: 'capitalizer', args: null),
          const AssetTransformerEntry(package: 'scrambler', args: null),
          const AssetTransformerEntry(package: 'encoder', args: null),
        ],
      ),
    );
  });

  testWithoutContext('Parses valid transformer declarations with args', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();

    final BufferLogger logger = BufferLogger.test();
    final FakePlatform platform = FakePlatform();

    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('assets', 'hello.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
  - path: assets/hello.txt
    transformers:
      - package: capitalizer
        args: ["-e", "--every-other"]
''');

    final ManifestAssetBundle bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      flutterRoot: Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      ),
    );

    final int code = await bundle.build(
      packagesPath: '.packages',
      flutterProject: FlutterProject.fromDirectoryTest(
        fileSystem.currentDirectory,
      ),
    );

    expect(code, 0);
    expect(bundle.entries, contains('assets/hello.txt'));
    expect(
      bundle.entries['assets/hello.txt']!.transformers,
      unorderedEquals(
        <AssetTransformerEntry>[
          const AssetTransformerEntry(
            package: 'capitalizer',
            args: <String>['-e', '--every-other'],
          ),
        ],
      ),
    );
  });
}
