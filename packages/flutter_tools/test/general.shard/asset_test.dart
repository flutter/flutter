// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Assets', () {
    final String dataPath = globals.fs.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'test',
      'data',
      'asset_test',
    );

    setUpAll(() {
      Cache.disableLocking();
    });

    // This test intentionally does not use a memory file system to ensure
    // that AssetBundle with fonts also works on Windows.
    testUsingContext('app font uses local font file', () async {
      final AssetBundle asset = AssetBundleFactory.instance.createBundle();
      final String manifestPath =
          globals.fs.path.join(dataPath, 'main', 'pubspec.yaml');
      final String packagesPath =
          globals.fs.path.join(dataPath, 'main', '.packages');
      await asset.build(
        manifestPath: manifestPath,
        packagesPath: packagesPath,
      );

      expect(asset.entries.containsKey('FontManifest.json'), isTrue);
      expect(
        await getValueAsString('FontManifest.json', asset),
        '[{"family":"packages/font/test_font","fonts":[{"asset":"packages/font/test_font_file"}]}]',
      );
      expect(asset.wasBuiltOnce(), true);
      expect(
        asset.inputFiles.map((File f) {
          return f.path;
        }),
        <String>[
          packagesPath,
          globals.fs.path.join(dataPath, 'font', 'pubspec.yaml'),
          manifestPath,
          globals.fs.path.join(dataPath, 'font', 'test_font_file'),
        ],
      );
    });

    testUsingContext('handles empty pubspec with .packages', () async {
      final String dataPath = globals.fs.path.join(
        getFlutterRoot(),
        'packages',
        'flutter_tools',
        'test',
        'data',
        'fuchsia_test',
      );
      final AssetBundle asset = AssetBundleFactory.instance.createBundle();
      await asset.build(
        manifestPath: globals.fs.path
            .join(dataPath, 'main', 'pubspec.yaml'), // file doesn't exist
        packagesPath: globals.fs.path.join(dataPath, 'main', '.packages'),
      );
      expect(asset.wasBuiltOnce(), true);
      expect(
        asset.inputFiles.map((File f) {
          return f.path;
        }),
        <String>[],
      );
    });
  });

const String packageConfig = '''
{
  "configVersion": 2,
  "packages":[
    {
      "name": "my_package",
      "rootUri": "file:///",
      "packageUri": "lib/",
      "languageVersion": "2.17"
    }
  ]
}
''';

const String pubspecDotYaml = '''
name: my_package
''';

  testUsingContext('Bundles material shaders on non-web platforms', () async {
    final String shaderPath = globals.fs.path.join(
      Cache.flutterRoot!,
      'packages', 'flutter', 'lib', 'src', 'material', 'shaders', 'ink_sparkle.frag'
    );
    globals.fs.file(shaderPath).createSync(recursive: true);
    globals.fs.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(packageConfig);
    globals.fs.file('pubspec.yaml').writeAsStringSync(pubspecDotYaml);
    final AssetBundle asset = AssetBundleFactory.instance.createBundle();

    await asset.build(packagesPath: '.packages', targetPlatform: TargetPlatform.android_arm);

    expect(asset.entries.keys, contains('shaders/ink_sparkle.frag'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.empty(),
  });

<<<<<<< HEAD
  testUsingContext('Does not bundles material shaders on web platforms', () async {
=======
  testUsingContext('Does bundle material shaders on web platforms', () async {
>>>>>>> d3d8effc686d73e0114d71abdcccef63fa1f25d2
    final String shaderPath = globals.fs.path.join(
      Cache.flutterRoot!,
      'packages', 'flutter', 'lib', 'src', 'material', 'shaders', 'ink_sparkle.frag'
    );
    globals.fs.file(shaderPath).createSync(recursive: true);
    globals.fs.file('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(packageConfig);
    globals.fs.file('pubspec.yaml').writeAsStringSync(pubspecDotYaml);
    final AssetBundle asset = AssetBundleFactory.instance.createBundle();

    await asset.build(packagesPath: '.packages', targetPlatform: TargetPlatform.web_javascript);

<<<<<<< HEAD
    expect(asset.entries.keys, isNot(contains('shaders/ink_sparkle.frag')));
=======
    expect(asset.entries.keys, contains('shaders/ink_sparkle.frag'));
>>>>>>> d3d8effc686d73e0114d71abdcccef63fa1f25d2
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.empty(),
  });
}

Future<String> getValueAsString(String key, AssetBundle asset) async {
  return String.fromCharCodes(await asset.entries[key]!.contentsAsBytes());
}
