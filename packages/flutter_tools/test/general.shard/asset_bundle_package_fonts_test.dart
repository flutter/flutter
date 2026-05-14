// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';

import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import '../src/package_config.dart';

void main() {
  String fixPath(String path) {
    // The in-memory file system is strict about slashes on Windows being the
    // correct way so until https://github.com/google/file.dart/issues/112 is
    // fixed we fix them here.
    // TODO(dantup): Remove this function once the above issue is fixed and
    // rolls into Flutter.
    return path.replaceAll('/', globals.fs.path.separator);
  }

  void writePubspecFile(
    String path,
    String name, {
    String? fontsSection,
    Map<String, String> deps = const <String, String>{},
  }) {
    if (fontsSection == null) {
      fontsSection = '';
    } else {
      fontsSection =
          '''
flutter:
     fonts:
$fontsSection
''';
    }

    globals.fs.file(fixPath(path))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: $name
dependencies:
  flutter:
    sdk: flutter
${deps.entries.map((MapEntry<String, String> entry) => '  ${entry.key}: {path: ${entry.value}}').join('\n')}
$fontsSection
''');
  }

  Future<void> buildAndVerifyFonts(
    List<String> localFonts,
    List<String> packageFonts,
    List<String> packages,
    String expectedAssetManifest,
  ) async {
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    await bundle.build(
      packageConfigPath: '.dart_tool/package_config.json',
      targetPlatform: TargetPlatform.tester,
    );

    for (final packageName in packages) {
      for (final packageFont in packageFonts) {
        final entryKey = 'packages/$packageName/$packageFont';
        expect(bundle.entries.containsKey(entryKey), true);
        expect(utf8.decode(await bundle.entries[entryKey]!.contentsAsBytes()), packageFont);
      }

      for (final localFont in localFonts) {
        expect(bundle.entries.containsKey(localFont), true);
        expect(utf8.decode(await bundle.entries[localFont]!.contentsAsBytes()), localFont);
      }
    }

    expect(
      json.decode(utf8.decode(await bundle.entries['FontManifest.json']!.contentsAsBytes())),
      json.decode(expectedAssetManifest),
    );
  }

  void writeFontAsset(String path, String font) {
    globals.fs.file(fixPath('$path$font'))
      ..createSync(recursive: true)
      ..writeAsStringSync(font);
  }

  group('AssetBundle fonts from packages', () {
    FileSystem? testFileSystem;

    setUp(() async {
      testFileSystem = MemoryFileSystem(
        style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
      );
      testFileSystem!.currentDirectory = testFileSystem!.systemTempDirectory.createTempSync(
        'flutter_asset_bundle_test.',
      );
    });

    testUsingContext(
      'App includes neither font manifest nor fonts when no defines fonts',
      () async {
        final deps = <String, String>{'test_package': 'p/p/'};
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: deps,
          mainLibName: 'test',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>['AssetManifest.bin', 'FontManifest.json', 'NOTICES.Z']),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App font uses font file from package',
      () async {
        const fontsSection = '''
       - family: foo
         fonts:
           - asset: packages/test_package/bar
''';
        writePubspecFile('pubspec.yaml', 'my_app', fontsSection: fontsSection);

        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,

          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'my_app',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        const font = 'bar';
        writeFontAsset('p/p/lib/', font);

        const expectedFontManifest =
            '[{"fonts":[{"asset":"packages/test_package/bar"}],"family":"foo"}]';
        await buildAndVerifyFonts(
          <String>[],
          <String>[font],
          <String>['test_package'],
          expectedFontManifest,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App font uses local font file and package font file',
      () async {
        const fontsSection = '''
       - family: foo
         fonts:
           - asset: packages/test_package/bar
           - asset: a/bar
''';
        writePubspecFile('pubspec.yaml', 'my_app', fontsSection: fontsSection);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,

          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'my_app',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        const packageFont = 'bar';
        writeFontAsset('p/p/lib/', packageFont);
        const localFont = 'a/bar';
        writeFontAsset('', localFont);

        const expectedFontManifest =
            '[{"fonts":[{"asset":"packages/test_package/bar"},{"asset":"a/bar"}],'
            '"family":"foo"}]';
        await buildAndVerifyFonts(<String>[localFont], <String>[packageFont], <String>[
          'test_package',
        ], expectedFontManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App uses package font with own font file',
      () async {
        final deps = <String, String>{'test_package': 'p/p/'};
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,

          packages: deps,
          mainLibName: 'test',
        );
        const fontsSection = '''
       - family: foo
         fonts:
           - asset: a/bar
''';
        writePubspecFile('p/p/pubspec.yaml', 'test_package', fontsSection: fontsSection);

        const font = 'a/bar';
        writeFontAsset('p/p/', font);

        const expectedFontManifest =
            '[{"family":"packages/test_package/foo",'
            '"fonts":[{"asset":"packages/test_package/a/bar"}]}]';
        await buildAndVerifyFonts(
          <String>[],
          <String>[font],
          <String>['test_package'],
          expectedFontManifest,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App uses package font with font file from another package',
      () async {
        final deps = <String, String>{'test_package': 'p/p/', 'test_package2': 'p2/p/'};
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,

          packages: deps,
          mainLibName: 'test',
        );
        const fontsSection = '''
       - family: foo
         fonts:
           - asset: packages/test_package2/bar
''';
        writePubspecFile('p/p/pubspec.yaml', 'test_package', fontsSection: fontsSection);
        writePubspecFile('p2/p/pubspec.yaml', 'test_package2');

        const font = 'bar';
        writeFontAsset('p2/p/lib/', font);

        const expectedFontManifest =
            '[{"family":"packages/test_package/foo",'
            '"fonts":[{"asset":"packages/test_package2/bar"}]}]';
        await buildAndVerifyFonts(
          <String>[],
          <String>[font],
          <String>['test_package2'],
          expectedFontManifest,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App uses package font with properties and own font file',
      () async {
        final deps = <String, String>{'test_package': 'p/p/'};
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,

          packages: deps,
          mainLibName: 'test',
        );

        const pubspec = '''
       - family: foo
         fonts:
           - style: italic
             weight: 400
             asset: a/bar
''';
        writePubspecFile('p/p/pubspec.yaml', 'test_package', fontsSection: pubspec);
        const font = 'a/bar';
        writeFontAsset('p/p/', font);

        const expectedFontManifest =
            '[{"family":"packages/test_package/foo",'
            '"fonts":[{"weight":400,"style":"italic","asset":"packages/test_package/a/bar"}]}]';
        await buildAndVerifyFonts(
          <String>[],
          <String>[font],
          <String>['test_package'],
          expectedFontManifest,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'App uses local font and package font with own font file.',
      () async {
        final deps = <String, String>{'test_package': 'p/p/'};
        const fontsSection = '''
       - family: foo
         fonts:
           - asset: a/bar
''';
        writePubspecFile('pubspec.yaml', 'test', fontsSection: fontsSection);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: deps,
          mainLibName: 'test',
        );

        writePubspecFile('p/p/pubspec.yaml', 'test_package', fontsSection: fontsSection);

        const font = 'a/bar';
        writeFontAsset('', font);
        writeFontAsset('p/p/', font);

        const expectedFontManifest =
            '[{"fonts":[{"asset":"a/bar"}],"family":"foo"},'
            '{"family":"packages/test_package/foo",'
            '"fonts":[{"asset":"packages/test_package/a/bar"}]}]';
        await buildAndVerifyFonts(<String>[font], <String>[font], <String>[
          'test_package',
        ], expectedFontManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}
