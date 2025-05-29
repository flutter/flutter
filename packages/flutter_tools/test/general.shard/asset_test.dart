// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';

// We aren't using this to construct paths—only to expose a type.
import 'package:path/path.dart' show Style; // flutter_ignore: package_path_import

import '../src/common.dart';
import '../src/package_config.dart';

void main() {
  final Style posix = Style.posix;
  final Style windows = Style.windows;
  final List<Style> styles = <Style>[posix, windows];

  for (final Style style in styles) {
    group('Assets (${style.name} file system)', () {
      late FileSystem fileSystem;
      late BufferLogger logger;
      late Platform platform;
      late String flutterRoot;

      setUp(() {
        fileSystem = MemoryFileSystem(
          style: style == Style.posix ? FileSystemStyle.posix : FileSystemStyle.windows,
        );
        logger = BufferLogger.test();
        platform = FakePlatform(operatingSystem: style == Style.posix ? 'linux' : 'windows');
        flutterRoot = Cache.defaultFlutterRoot(
          platform: platform,
          fileSystem: fileSystem,
          userMessages: UserMessages(),
        );
      });

      testWithoutContext('app font uses local font file', () async {
        final String manifestPath = fileSystem.path.join('main', 'pubspec.yaml');
        final ManifestAssetBundle assetBundle = ManifestAssetBundle(
          logger: logger,
          fileSystem: fileSystem,
          platform: platform,
          splitDeferredAssets: true,
          flutterRoot: flutterRoot,
        );

        fileSystem.file(fileSystem.path.join('font', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(r'''
name: font
description: A test project that contains a font.

environment:
  sdk: ^3.7.0-0

flutter:
  uses-material-design: false
  fonts:
  - family: test_font
    fonts:
      - asset: test_font_file
''');
        fileSystem.file(fileSystem.path.join('font', 'test_font_file'))
          ..createSync(recursive: true)
          ..writeAsStringSync('This is a fake font.');

        final String packageConfigPath =
            writePackageConfigFiles(
              directory: fileSystem.directory('main'),
              mainLibName: 'main',
              packages: <String, String>{'font': '../font'},
            ).path;
        fileSystem.file(manifestPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(r'''
name: main
description: A test project that has a package with a font as a dependency.

environment:
  sdk: ^3.7.0-0

dependencies:
  font:
    path: ../font
''');

        await assetBundle.build(
          packageConfigPath: packageConfigPath,
          manifestPath: manifestPath,
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.directory('main')),
        );

        expect(assetBundle.entries, contains('FontManifest.json'));
        expect(
          await _getValueAsString('FontManifest.json', assetBundle),
          '[{"family":"packages/font/test_font","fonts":[{"asset":"packages/font/test_font_file"}]}]',
        );
        expect(assetBundle.wasBuiltOnce(), true);
        expect(
          assetBundle.inputFiles.map((File f) => f.path),
          equals(<String>[
            packageConfigPath,
            fileSystem.path.join(fileSystem.currentDirectory.path, manifestPath),
            fileSystem.path.join(fileSystem.currentDirectory.path, 'font', 'pubspec.yaml'),
            fileSystem.path.join(fileSystem.currentDirectory.path, 'font', 'test_font_file'),
          ]),
        );
      });

      testWithoutContext(
        'does not pick up assets from dev-dependencies and workspace packages not in the transitive closure',
        () async {
          final String manifestPath = fileSystem.path.join('main', 'pubspec.yaml');
          final ManifestAssetBundle assetBundle = ManifestAssetBundle(
            logger: logger,
            fileSystem: fileSystem,
            platform: platform,
            splitDeferredAssets: true,
            flutterRoot: flutterRoot,
          );

          fileSystem.file(fileSystem.path.join('font', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(r'''
name: font
description: A test project that contains a font.

environment:
  sdk: ^3.7.0-0

flutter:
  uses-material-design: false
  fonts:
  - family: test_font
    fonts:
      - asset: test_font_file
''');
          fileSystem.file(fileSystem.path.join('font', 'test_font_file'))
            ..createSync(recursive: true)
            ..writeAsStringSync('This is a fake font.');

          fileSystem.file(fileSystem.path.join('dev_dependency', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(r'''
name: dev_dependency
description: Another test project that contains a font.

environment:
  sdk: ^3.7.0-0

flutter:
  uses-material-design: false
  fonts:
  - family: dev_dependency_test_font
    fonts:
      - asset: dev_dependency_test_font_file
''');
          fileSystem.file(fileSystem.path.join('dev_dependency', 'dev_dependency_test_font_file'))
            ..createSync(recursive: true)
            ..writeAsStringSync('This is a fake font.');

          fileSystem.file(fileSystem.path.join('dev_dependency', 'pubspec.yaml'))
            ..createSync(recursive: true)
            ..writeAsStringSync(r'''
name: dev_dependency
description: Another test project that contains a font.

environment:
  sdk: ^3.7.0-0

flutter:
  uses-material-design: false
  fonts:
  - family: dev_dependency_test_font
    fonts:
      - asset: dev_dependency_test_font_file
''');
          fileSystem.file(fileSystem.path.join('dev_dependency', 'dev_dependency_test_font_file'))
            ..createSync(recursive: true)
            ..writeAsStringSync('This is a fake font.');

          writePackageConfigFiles(
            mainLibName: 'main',
            mainLibRootUri: 'main',
            directory: fileSystem.currentDirectory,
            packages: <String, String>{
              'font': 'font',
              'dev_dependency': 'dev_dependency',
              'workspace_root': '.',
            },
            dependencies: <String>['font'],
            devDependencies: <String>['dev_dependency'],
          );

          fileSystem.file(manifestPath)
            ..createSync(recursive: true)
            ..writeAsStringSync(r'''
name: main
description: A test project that has a package with a font as a dependency.

environment:
  sdk: ^3.7.0-0

resolution: workspace

dependencies:
  font:
    path: ../font

dev_dependencies:
  dev_dependency:
    path: ../dev_dependency

flutter:
  uses-material-design: false
''');

          fileSystem.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync(r'''
name: workspace_root
description: A pubspec that defines a workspace root, but also a font.

environment:
  sdk: ^3.7.0-0

workspace:
  - main/

flutter:
  uses-material-design: false
  fonts:
  - family: root_test_font
    fonts:
      - asset: root_test_font_file
''');

          fileSystem.file('root_test_font_file')
            ..createSync(recursive: true)
            ..writeAsStringSync('This is a fake font.');
          final String packageConfigPath = fileSystem.path.join(
            '.dart_tool',
            'package_config.json',
          );
          await assetBundle.build(
            packageConfigPath: packageConfigPath,
            manifestPath: manifestPath,
            flutterProject: FlutterProject.fromDirectoryTest(fileSystem.directory('main')),
          );

          expect(assetBundle.entries, contains('FontManifest.json'));
          expect(
            await _getValueAsString('FontManifest.json', assetBundle),
            '[{"family":"packages/font/test_font","fonts":[{"asset":"packages/font/test_font_file"}]}]',
          );
          expect(assetBundle.wasBuiltOnce(), true);
          expect(
            assetBundle.inputFiles.map((File f) => f.path),
            equals(<String>[
              packageConfigPath,
              fileSystem.path.join(fileSystem.currentDirectory.path, manifestPath),
              fileSystem.path.join(fileSystem.currentDirectory.path, 'font', 'pubspec.yaml'),
              fileSystem.path.join(fileSystem.currentDirectory.path, 'font', 'test_font_file'),
            ]),
          );
        },
      );

      testWithoutContext('handles empty pubspec with .dart_tool/package_config.json', () async {
        final String packageConfigPath = fileSystem.path.join(
          'fuchsia_test',
          'main',
          '.dart_tool',
          'package_config.json',
        );
        final String manifestPath = fileSystem.path.join('fuchsia_test', 'main', 'pubspec.yaml');

        fileSystem.directory(fileSystem.file(manifestPath)).parent.createSync(recursive: true);
        fileSystem.directory(fileSystem.file(packageConfigPath)).parent.createSync(recursive: true);

        final ManifestAssetBundle assetBundle = ManifestAssetBundle(
          logger: logger,
          fileSystem: fileSystem,
          platform: platform,
          splitDeferredAssets: true,
          flutterRoot: flutterRoot,
        );

        await assetBundle.build(
          manifestPath: manifestPath, // file doesn't exist
          packageConfigPath: packageConfigPath,
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.file(manifestPath).parent),
        );

        expect(assetBundle.wasBuiltOnce(), true);
        expect(assetBundle.inputFiles.map((File f) => f.path), <String>[]);
      });

      testWithoutContext('bundles material shaders on non-web platforms', () async {
        final String shaderPath = fileSystem.path.join(
          flutterRoot,
          'packages',
          'flutter',
          'lib',
          'src',
          'material',
          'shaders',
          'ink_sparkle.frag',
        );
        fileSystem.file(shaderPath).createSync(recursive: true);
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_package');
        fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_package');
        final ManifestAssetBundle assetBundle = ManifestAssetBundle(
          logger: logger,
          fileSystem: fileSystem,
          platform: platform,
          flutterRoot: flutterRoot,
        );

        await assetBundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.android_arm,
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        );

        expect(assetBundle.entries.keys, contains('shaders/ink_sparkle.frag'));
      });

      testWithoutContext('bundles material shaders on web platforms', () async {
        final String shaderPath = fileSystem.path.join(
          flutterRoot,
          'packages',
          'flutter',
          'lib',
          'src',
          'material',
          'shaders',
          'ink_sparkle.frag',
        );
        fileSystem.file(shaderPath).createSync(recursive: true);
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_package');
        fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_package');
        final ManifestAssetBundle assetBundle = ManifestAssetBundle(
          logger: logger,
          fileSystem: fileSystem,
          platform: platform,
          flutterRoot: flutterRoot,
        );

        await assetBundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.web_javascript,
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        );

        expect(assetBundle.entries.keys, contains('shaders/ink_sparkle.frag'));
      });
    });
  }
}

Future<String> _getValueAsString(String key, AssetBundle asset) async {
  return String.fromCharCodes(await asset.entries[key]!.contentsAsBytes());
}
