// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/multi_root_file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';

// assumption: tests have a timeout less than 100 days
final DateTime inFuture = DateTime.now().add(const Duration(days: 100));

void main() {
  for (final bool asyncScanning in <bool>[true, false]) {
    testWithoutContext('No last compile, asyncScanning: $asyncScanning', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: fileSystem,
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );
      fileSystem.file('.packages').writeAsStringSync('\n');

      expect(
        (await projectFileInvalidator.findInvalidated(
          lastCompiled: null,
          urisToMonitor: <Uri>[],
          packagesPath: '.packages',
          asyncScanning: asyncScanning,
          packageConfig: PackageConfig.empty,
        )).uris,
        isEmpty,
      );
    });

    testWithoutContext('Empty project, asyncScanning: $asyncScanning', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: fileSystem,
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );
      fileSystem.file('.packages').writeAsStringSync('\n');

      expect(
        (await projectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[],
          packagesPath: '.packages',
          asyncScanning: asyncScanning,
          packageConfig: PackageConfig.empty,
        )).uris,
        isEmpty,
      );
    });

    testWithoutContext('Non-existent files are ignored, asyncScanning: $asyncScanning', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: MemoryFileSystem.test(),
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );
      fileSystem.file('.packages').writeAsStringSync('\n');

      expect(
        (await projectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[Uri.parse('/not-there-anymore'),],
          packagesPath: '.packages',
          asyncScanning: asyncScanning,
          packageConfig: PackageConfig.empty,
        )).uris,
        isEmpty,
      );
    });

    testWithoutContext('Picks up changes to the .packages file and updates package_config.json, asyncScanning: $asyncScanning', () async {
      final DateTime past = DateTime.now().subtract(const Duration(seconds: 1));
      final FileSystem fileSystem = MemoryFileSystem.test();
      const PackageConfig packageConfig = PackageConfig.empty;
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: fileSystem,
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );
      fileSystem.file('.packages')
        .writeAsStringSync('\n');
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(json.encode(<String, Object>{
            'configVersion': 2,
            'packages': <Object>[],
        }));

      final InvalidationResult invalidationResult = await projectFileInvalidator.findInvalidated(
        lastCompiled: null,
        urisToMonitor: <Uri>[],
        packagesPath: '.packages',
        asyncScanning: asyncScanning,
        packageConfig: packageConfig,
      );
      expect(invalidationResult.uris, isEmpty);
      fileSystem.file('.packages').setLastModifiedSync(DateTime.now());

      final InvalidationResult secondInvalidation = await projectFileInvalidator.findInvalidated(
        lastCompiled: past,
        urisToMonitor: <Uri>[],
        packagesPath: '.packages',
        asyncScanning: asyncScanning,
        packageConfig: packageConfig,
      );
      expect(secondInvalidation.uris, unorderedEquals(<Uri>[
        Uri.parse('.packages'),
        Uri.parse('.dart_tool/package_config.json'),
      ]));
    });

    testWithoutContext('Picks up changes to the .packages file and updates PackageConfig, asyncScanning: $asyncScanning', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      const PackageConfig packageConfig = PackageConfig.empty;
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: fileSystem,
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );
      fileSystem.file('.packages')
        .writeAsStringSync('\n');

      final InvalidationResult invalidationResult = await projectFileInvalidator.findInvalidated(
        lastCompiled: null,
        urisToMonitor: <Uri>[],
        packagesPath: '.packages',
        asyncScanning: asyncScanning,
        packageConfig: packageConfig,
      );

      // Initial package config is re-used.
      expect(invalidationResult.packageConfig, packageConfig);

      fileSystem.file('.packages')
        .writeAsStringSync('foo:lib/\n');
      final DateTime packagesUpdated = fileSystem.statSync('.packages')
        .modified;

      final InvalidationResult nextInvalidationResult = await projectFileInvalidator
        .findInvalidated(
          lastCompiled: packagesUpdated.subtract(const Duration(seconds: 1)),
          urisToMonitor: <Uri>[],
          packagesPath: '.packages',
          asyncScanning: asyncScanning,
          packageConfig: PackageConfig.empty,
        );

      expect(nextInvalidationResult.uris, contains(Uri.parse('.packages')));
      // The PackageConfig should have been recreated too
      expect(nextInvalidationResult.packageConfig,
        isNot(invalidationResult.packageConfig));
    });

    testWithoutContext('Works with MultiRootFileSystem uris, asyncScanning: $asyncScanning', () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final FileSystem multiRootFileSystem = MultiRootFileSystem(
        delegate: fileSystem,
        scheme: 'scheme',
        roots: <String>[
          '/root',
        ],
      );
      final ProjectFileInvalidator projectFileInvalidator = ProjectFileInvalidator(
        fileSystem: multiRootFileSystem,
        platform: FakePlatform(),
        logger: BufferLogger.test(),
      );

      expect(
        (await projectFileInvalidator.findInvalidated(
          lastCompiled: inFuture,
          urisToMonitor: <Uri>[
            Uri.parse('file1'),
            Uri.parse('file:///file2'),
            Uri.parse('scheme:///file3'),
          ],
          packagesPath: '.packages',
          asyncScanning: asyncScanning,
          packageConfig: PackageConfig.empty,
        )).uris,
        isEmpty,
      );
    });
  }
}
