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
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';
import '../src/package_config.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late ManifestAssetBundle bundle;

  void writeFile(String path, [String contents = 'contents']) {
    fileSystem.file(fileSystem.path.fromUri(Uri(path: path)))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  void writeManifest(String assets, {String extra = ''}) {
    writeFile('pubspec.yaml', 'name: example\nflutter:\n  assets:\n$assets\n$extra');
  }

  Future<int> build({
    String? flavor,
    TargetPlatform platform = TargetPlatform.android_arm64,
    bool deferred = false,
    FlutterHookResult? hooks,
  }) => bundle.build(
    packageConfigPath: '.dart_tool/package_config.json',
    flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
    flavor: flavor,
    targetPlatform: platform,
    deferredComponentsEnabled: deferred,
    flutterHookResult: hooks,
  );

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

  for (final flavor in <String?>['dev', 'prod', null, 'other']) {
    testWithoutContext('selects Branch configuration for flavor $flavor', () async {
      writeManifest('''
    - path: configs/dev/branch-config.json
      flavors: [dev]
      bundle_path: assets/branch-config.json
    - path: configs/prod/branch-config.json
      flavors: [prod]
      bundle_path: assets/branch-config.json''');
      writeFile('configs/dev/branch-config.json', '{"environment":"dev"}');
      writeFile('configs/prod/branch-config.json', '{"environment":"prod"}');
      expect(await build(flavor: flavor), 0);
      expect(bundle.entries.keys, isNot(contains(startsWith('configs/'))));
      if (flavor == 'dev' || flavor == 'prod') {
        expect(
          utf8.decode(await bundle.entries['assets/branch-config.json']!.contentsAsBytes()),
          '{"environment":"$flavor"}',
        );
        expect((await manifest()).keys, contains('assets/branch-config.json'));
        expect(
          bundle.inputFiles.map((File file) => file.path),
          contains('/configs/$flavor/branch-config.json'),
        );
      } else {
        expect(bundle.entries, isNot(contains('assets/branch-config.json')));
      }
    });
  }

  testWithoutContext(
    'updates the source when rebuilding the same bundle for another flavor',
    () async {
      writeManifest('''
    - path: dev.json
      flavors: [dev]
      bundle_path: assets/branch-config.json
    - path: prod.json
      flavors: [prod]
      bundle_path: assets/branch-config.json''');
      writeFile('dev.json', 'dev');
      writeFile('prod.json', 'prod');
      expect(await build(flavor: 'dev'), 0);
      final AssetBundleEntry first = bundle.entries['assets/branch-config.json']!;
      expect(await build(flavor: 'dev'), 0);
      expect(bundle.entries['assets/branch-config.json'], same(first));
      expect(await build(flavor: 'prod'), 0);
      expect(
        utf8.decode(await bundle.entries['assets/branch-config.json']!.contentsAsBytes()),
        'prod',
      );
      writeFile('prod.json', 'updated');
      expect(await build(flavor: 'prod'), 0);
      expect(
        utf8.decode(await bundle.entries['assets/branch-config.json']!.contentsAsBytes()),
        'updated',
      );
      expect(fileSystem.file('dev.json').readAsStringSync(), 'dev');
    },
  );

  testWithoutContext('removes mapped entries when their flavor is no longer selected', () async {
    writeManifest('    - path: dev.json\n      flavors: [dev]\n      bundle_path: config.json');
    writeFile('dev.json');
    expect(await build(flavor: 'dev'), 0);
    expect(bundle.entries, contains('config.json'));
    expect(await build(), 0);
    expect(bundle.entries, isNot(contains('config.json')));
  });

  testWithoutContext('removes the previous destination after a pubspec edit', () async {
    writeManifest('    - path: config.json\n      bundle_path: old.json');
    writeFile('config.json');
    expect(await build(), 0);
    writeManifest('    - path: config.json\n      bundle_path: new.json');
    expect(await build(), 0);
    expect(bundle.entries, contains('new.json'));
    expect(bundle.entries, isNot(contains('old.json')));
  });

  testWithoutContext('keeps duplicate declarations of the same source', () async {
    writeManifest('''
    - path: source.json
      bundle_path: config.json
    - path: source.json
      bundle_path: config.json
''');
    writeFile('source.json');
    expect(await build(), 0);
    expect((await manifest()).keys, <String>['config.json']);
  });

  testWithoutContext('rejects different transformers for the same mapped source', () async {
    writeManifest('''
    - path: source.json
      bundle_path: config.json
      transformers:
        - package: first
    - path: source.json
      bundle_path: config.json
      transformers:
        - package: second
''');
    writeFile('source.json');
    await expectLater(build(), throwsToolExit(message: 'Conflicting assets at bundle path'));
  });

  testWithoutContext('uses portable bundle keys on Windows', () async {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    fileSystem.currentDirectory = fileSystem.systemTempDirectory.createTempSync('bundle_path.');
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
    bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(operatingSystem: 'windows'),
      flutterRoot: r'C:\flutter',
    );
    writeManifest('    - path: source/\n      bundle_path: images/');
    writeFile('source/logo.png');
    writeFile('source/2.0x/logo.png');
    expect(await build(platform: TargetPlatform.windows_x64), 0);
    expect(logger.errorText, isEmpty);
    expect(bundle.entries.keys, containsAll(<String>['images/logo.png', 'images/2.0x/logo.png']));
  });

  testWithoutContext('normalizes legacy destinations when checking conflicts', () async {
    writeManifest('''
    - path: source.json
      bundle_path: config.json
    - assets/../config.json
''');
    writeFile('source.json');
    writeFile('config.json');
    fileSystem.directory('assets').createSync();
    await expectLater(build(), throwsToolExit(message: 'Conflicting assets at bundle path'));
  });

  testWithoutContext('reports missing mapped source files', () async {
    writeManifest('    - path: missing.json\n      bundle_path: config.json');
    expect(await build(), 1);
    expect(logger.errorText, contains('No file or variants found'));
  });

  for (final reverse in <bool>[false, true]) {
    testWithoutContext(
      'rejects file-directory destination collisions (reverse: $reverse)',
      () async {
        final declarations = <String>[
          '    - path: source.json\n      bundle_path: assets',
          '    - assets/config.json',
        ];
        writeManifest((reverse ? declarations.reversed : declarations).join('\n'));
        writeFile('source.json');
        writeFile('assets/config.json');
        await expectLater(
          build(),
          throwsToolExit(message: 'a file cannot also be used as a directory'),
        );
      },
    );
  }

  testWithoutContext('detects a destination collision with hook assets', () async {
    writeManifest('    - path: source.json\n      bundle_path: packages/example/config.json');
    writeFile('source.json');
    writeFile('hook.json');
    final hooks = FlutterHookResult(
      buildStart: DateTime(2026),
      buildEnd: DateTime(2026),
      dependencies: <Uri>[],
      dataAssets: <HookAsset>[
        HookAsset(file: Uri.file('/hook.json'), name: 'config.json', package: 'example'),
      ],
    );
    await expectLater(
      build(hooks: hooks),
      throwsToolExit(message: 'Conflicting assets at bundle path'),
    );
  });

  testWithoutContext('detects a destination collision with fonts', () async {
    writeManifest(
      '    - path: source.ttf\n      bundle_path: fonts/font.ttf',
      extra: '''
  fonts:
    - family: Test
      fonts:
        - asset: fonts/font.ttf
''',
    );
    writeFile('source.ttf');
    writeFile('fonts/font.ttf');
    await expectLater(build(), throwsToolExit(message: 'Conflicting assets at bundle path'));
  });

  testWithoutContext('preserves shader kind and source under a mapped destination', () async {
    writeManifest(
      '    - common.txt',
      extra: '''
  shaders:
    - path: source.frag
      bundle_path: shaders/renamed.frag
''',
    );
    writeFile('common.txt');
    writeFile('source.frag');
    expect(await build(), 0);
    final AssetBundleEntry entry = bundle.entries['shaders/renamed.frag']!;
    expect(entry.kind, AssetKind.shader);
    expect((entry.content as DevFSFileContent).file.path, '/source.frag');
  });

  testWithoutContext('filters platforms before checking destination conflicts', () async {
    writeManifest('''
    - path: android.json
      platforms: [android]
      bundle_path: config.json
    - path: ios.json
      platforms: [ios]
      bundle_path: config.json''');
    writeFile('android.json', 'android');
    writeFile('ios.json', 'ios');
    expect(await build(), 0);
    expect(utf8.decode(await bundle.entries['config.json']!.contentsAsBytes()), 'android');
  });

  for (final second in <String>[
    '    - path: other.json\n      bundle_path: config.json',
    '    - config.json',
    '    - path: other.json\n      flavors: [dev]\n      bundle_path: config.json',
  ]) {
    testWithoutContext('rejects selected destination conflict with $second', () async {
      writeManifest('''
    - path: dev.json
      flavors: [dev]
      bundle_path: config.json
$second''');
      writeFile('dev.json');
      writeFile('other.json');
      writeFile('config.json');
      await expectLater(
        build(flavor: 'dev'),
        throwsToolExit(message: 'Conflicting assets at bundle path "config.json"'),
      );
    });
  }

  for (final key in <String>[
    'AssetManifest.bin',
    'FontManifest.json',
    'NOTICES.Z',
    'kernel_blob.bin',
  ]) {
    testWithoutContext('rejects generated destination $key', () async {
      writeManifest('    - path: source.json\n      bundle_path: $key');
      writeFile('source.json');
      await expectLater(build(), throwsToolExit(message: 'reserved for a generated Flutter asset'));
    });
  }

  testWithoutContext('rewrites directory prefixes and image variants without recursing', () async {
    writeManifest('    - path: source/\n      bundle_path: images/');
    writeFile('source/logo.png');
    writeFile('source/2.0x/logo.png', '2x');
    writeFile('source/nested/ignored.png');
    expect(await build(), 0);
    expect(bundle.entries.keys, containsAll(<String>['images/logo.png', 'images/2.0x/logo.png']));
    expect(bundle.entries.keys, isNot(contains('images/nested/ignored.png')));
    expect((await manifest())['images/logo.png'], <Object?>[
      <String, Object?>{'asset': 'images/logo.png'},
      <String, Object?>{'asset': 'images/2.0x/logo.png', 'dpr': 2.0},
    ]);
  });

  testWithoutContext('renames image variants when the base image is missing', () async {
    writeManifest('    - path: source/logo.png\n      bundle_path: images/brand.png');
    writeFile('source/2.0x/logo.png');
    expect(await build(), 0);
    expect(bundle.entries.keys, contains('images/2.0x/brand.png'));
    expect((await manifest()).keys, contains('images/brand.png'));
  });

  testWithoutContext('detects a collision with an image variant', () async {
    writeManifest('''
    - path: source/logo.png
      bundle_path: images/logo.png
    - images/2.0x/logo.png''');
    writeFile('source/logo.png');
    writeFile('source/2.0x/logo.png');
    writeFile('images/2.0x/logo.png');
    await expectLater(
      build(),
      throwsToolExit(message: 'Conflicting assets at bundle path "images/2.0x/logo.png"'),
    );
  });

  testWithoutContext('preserves package namespaces and transformer configuration', () async {
    writePackageConfigFiles(
      directory: fileSystem.currentDirectory,
      mainLibName: 'example',
      packages: <String, String>{'foo': '/foo/'},
    );
    writeFile('pubspec.yaml', 'name: example\ndependencies:\n  foo:\n    path: foo\n');
    writeFile('foo/pubspec.yaml', '''
name: foo
flutter:
  assets:
    - path: config.json
      bundle_path: assets/config.json
      transformers:
        - package: transformer
          args: [--example]
''');
    writeFile('foo/config.json');
    expect(await build(), 0);
    final AssetBundleEntry entry = bundle.entries['packages/foo/assets/config.json']!;
    expect((entry.content as DevFSFileContent).file.path, '/foo/config.json');
    expect(entry.transformers, <AssetTransformerEntry>[
      const AssetTransformerEntry(package: 'transformer', args: <String>['--example']),
    ]);
  });

  testWithoutContext('resolves explicitly declared package files from their source', () async {
    writePackageConfigFiles(
      directory: fileSystem.currentDirectory,
      mainLibName: 'example',
      packages: <String, String>{'foo': '/foo/'},
    );
    writeManifest('    - path: packages/foo/config.json\n      bundle_path: assets/config.json');
    writeFile('foo/lib/config.json', 'package config');
    expect(await build(), 0);
    expect(
      utf8.decode(await bundle.entries['assets/config.json']!.contentsAsBytes()),
      'package config',
    );
  });

  testWithoutContext('rewrites deferred component assets', () async {
    writeManifest(
      '    - common.txt',
      extra: '''
  deferred-components:
    - name: feature
      assets:
        - path: config.json
          bundle_path: assets/config.json
''',
    );
    writeFile('common.txt');
    writeFile('config.json');
    expect(await build(deferred: true), 0);
    expect(bundle.deferredComponentsEntries['feature'], contains('assets/config.json'));
    expect((await manifest()).keys, contains('assets/config.json'));
  });

  testWithoutContext(
    'encodes special characters for web output and decodes manifest keys',
    () async {
      writeManifest('    - path: source.json\n      bundle_path: "assets/config #1%.json"');
      writeFile('source.json');
      expect(await build(platform: TargetPlatform.web_javascript), 0);
      expect(bundle.entries, contains('assets/config%20%231%25.json'));
      expect((await manifest()).keys, contains('assets/config #1%.json'));
      expect(bundle.entries, contains('AssetManifest.bin.json'));
    },
  );
}
