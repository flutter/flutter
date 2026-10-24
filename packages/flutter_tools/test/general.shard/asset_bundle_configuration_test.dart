// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';
import '../src/package_config.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late ManifestAssetBundle bundle;

  void writeFile(String path, [String contents = 'configuration']) {
    fileSystem.file(fileSystem.path.fromUri(Uri(path: path)))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  void writeManifest(String assets, {String extra = ''}) {
    writeFile('pubspec.yaml', 'name: example\nflutter:\n  assets:\n$assets\n$extra');
  }

  Future<int> build({String? flavor = 'dev', TargetPlatform target = TargetPlatform.tester}) =>
      bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        targetPlatform: target,
        flavor: flavor,
      );

  Future<String> contents(String key) async =>
      utf8.decode(await bundle.entries[key]!.contentsAsBytes());

  Future<Map<Object?, Object?>> manifest() async =>
      const StandardMessageCodec().decodeMessage(
            ByteData.sublistView(
              Uint8List.fromList(await bundle.entries['AssetManifest.bin']!.contentsAsBytes()),
            ),
          )!
          as Map<Object?, Object?>;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
    bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      flutterRoot: '/flutter',
      splitDeferredAssets: true,
    );
  });

  const configurations = '''
    - path: configs/dev.json
      flavors: [dev]
      bundle_path: assets/branch-config.json
    - path: configs/prod.json
      flavors: [prod]
      bundle_path: assets/branch-config.json''';

  for (final flavor in <String?>['dev', 'prod', null, 'other']) {
    testWithoutContext('selects the configuration for flavor $flavor', () async {
      writeManifest(configurations);
      // Unselected configuration files do not need to exist.
      if (flavor == 'dev' || flavor == 'prod') {
        writeFile('configs/$flavor.json', flavor!);
      }
      expect(await build(flavor: flavor), 0);
      expect(bundle.entries.keys, isNot(contains(startsWith('configs/'))));
      if (flavor == 'dev' || flavor == 'prod') {
        expect(await contents('assets/branch-config.json'), flavor);
        expect(await manifest(), <Object?, Object?>{
          'assets/branch-config.json': <Object?>[
            <Object?, Object?>{'asset': 'assets/branch-config.json'},
          ],
        });
        expect(bundle.inputFiles.map((File file) => file.path), contains('/configs/$flavor.json'));
      } else {
        expect(bundle.entries, isNot(contains('assets/branch-config.json')));
        expect(await manifest(), isEmpty);
      }
    });
  }

  testWithoutContext('updates the source on flavor changes and removes deselected keys', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json', 'dev');
    writeFile('configs/prod.json', 'prod');
    expect(await build(), 0);
    final AssetBundleEntry first = bundle.entries['assets/branch-config.json']!;
    expect(await build(), 0);
    expect(bundle.entries['assets/branch-config.json'], same(first));
    expect(await build(flavor: 'prod'), 0);
    expect(await contents('assets/branch-config.json'), 'prod');
    writeFile('configs/prod.json', 'updated');
    expect(await build(flavor: 'prod'), 0);
    expect(await contents('assets/branch-config.json'), 'updated');
    expect(fileSystem.file('configs/dev.json').readAsStringSync(), 'dev');
    expect(await build(flavor: null), 0);
    expect(bundle.entries, isNot(contains('assets/branch-config.json')));
    expect(await manifest(), isEmpty);
  });

  testWithoutContext('removes a configuration when its declaration is removed', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json');
    expect(await build(), 0);
    writeManifest('    - ordinary.json');
    writeFile('ordinary.json');
    expect(await build(), 0);
    expect(bundle.entries, isNot(contains('assets/branch-config.json')));
  });

  testWithoutContext('removes a configuration when the manifest becomes empty', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json');
    expect(await build(), 0);
    writeFile('pubspec.yaml', 'name: example\n');
    expect(await build(), 0);
    expect(bundle.entries, isNot(contains('assets/branch-config.json')));
  });

  testWithoutContext('uses portable bundle keys on Windows', () async {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    fileSystem.currentDirectory = fileSystem.systemTempDirectory.createTempSync('configuration.');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
    bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(operatingSystem: 'windows'),
      flutterRoot: r'C:\flutter',
    );
    writeManifest(configurations);
    writeFile('configs/dev.json');
    expect(await build(target: TargetPlatform.windows_x64), 0, reason: logger.errorText);
    expect(await contents('assets/branch-config.json'), 'configuration');
  });

  testWithoutContext('rejects mappings declared by dependencies', () async {
    writeManifest('    - ordinary.json');
    writeFile('ordinary.json');
    writePackageConfigFiles(
      directory: fileSystem.currentDirectory,
      mainLibName: 'example',
      packages: <String, String>{'dependency': 'dependency/'},
    );
    writeFile('dependency/pubspec.yaml', '''
name: dependency
flutter:
  assets:
    - path: config.json
      flavors: [dev]
      bundle_path: config.json
''');
    await expectLater(build(), throwsToolExit(message: 'only supported in application assets'));
  });

  testWithoutContext('keeps a destination that becomes an ordinary asset', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json', 'mapped');
    expect(await build(), 0);
    writeManifest('    - assets/branch-config.json');
    writeFile('assets/branch-config.json', 'ordinary');
    expect(await build(), 0);
    expect(await contents('assets/branch-config.json'), 'ordinary');
  });

  testWithoutContext('has the same configuration on multiple target platforms', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json');
    for (final target in <TargetPlatform>[
      TargetPlatform.android_arm64,
      TargetPlatform.ios,
      TargetPlatform.tester,
    ]) {
      expect(await build(target: target), 0);
      expect(await contents('assets/branch-config.json'), 'configuration');
    }
  });

  testWithoutContext('fails when the selected source is missing', () async {
    writeManifest(configurations);
    expect(await build(), 1);
    expect(logger.errorText, contains('No file or variants found'));
  });

  for (final destination in <String>[
    'assets/branch-config.json',
    'assets/branch-config.json/child',
    'assets',
    'AssetManifest.bin',
    'FontManifest.json',
    'NOTICES.Z',
    'kernel_blob.bin',
  ]) {
    testWithoutContext('rejects conflicting or reserved destination $destination', () async {
      writeManifest('''
    - assets/branch-config.json
    - path: configs/dev.json
      flavors: [dev]
      bundle_path: $destination''');
      writeFile('assets/branch-config.json');
      writeFile('configs/dev.json');
      await expectLater(build(), throwsToolExit(message: 'conflicts with'));
    });
  }

  testWithoutContext('rejects two configurations selected for the same destination', () async {
    writeManifest('''
$configurations
    - path: other.json
      flavors: [dev]
      bundle_path: assets/branch-config.json''');
    writeFile('configs/dev.json');
    writeFile('other.json');
    await expectLater(build(), throwsToolExit(message: 'conflicts with'));
  });

  testWithoutContext('rejects collisions with image variants', () async {
    writeManifest('''
    - images/logo.png
    - path: configs/dev.json
      flavors: [dev]
      bundle_path: images/2.0x/logo.png''');
    writeFile('images/logo.png');
    writeFile('images/2.0x/logo.png');
    writeFile('configs/dev.json');
    await expectLater(build(), throwsToolExit(message: 'conflicts with'));
  });

  testWithoutContext('normalizes ordinary paths when checking destination conflicts', () async {
    writeManifest('''
$configurations
    - assets/../assets/branch-config.json''');
    writeFile('configs/dev.json');
    writeFile('assets/branch-config.json');
    await expectLater(build(), throwsToolExit(message: 'conflicts with'));
  });

  testWithoutContext('rejects collisions with fonts', () async {
    writeManifest(
      configurations,
      extra: '''
  fonts:
    - family: Example
      fonts:
        - asset: assets/branch-config.json''',
    );
    writeFile('assets/branch-config.json');
    writeFile('configs/dev.json');
    await expectLater(build(), throwsToolExit(message: 'conflicts with'));
  });

  testWithoutContext('rejects mapping files with resolution variants', () async {
    writeManifest(configurations);
    writeFile('configs/dev.json');
    writeFile('configs/2.0x/dev.json');
    await expectLater(
      build(),
      throwsToolExit(message: 'does not support image resolution variants'),
    );
  });

  for (final section in <String>['shaders', 'deferred-components']) {
    testWithoutContext('rejects mappings in $section', () async {
      final extra = section == 'shaders'
          ? '''
  shaders:
    - path: shader.frag
      flavors: [dev]
      bundle_path: mapped.frag'''
          : '''
  deferred-components:
    - name: component
      assets:
        - path: config.json
          flavors: [dev]
          bundle_path: mapped.json''';
      writeManifest('    - ordinary.json', extra: extra);
      writeFile('ordinary.json');
      await expectLater(build(), throwsToolExit(message: 'not supported in'));
    });
  }
}
