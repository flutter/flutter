// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('PrebuiltMacOSApp', () {
    late FakeOperatingSystemUtils os;
    late FileSystem fileSystem;
    late BufferLogger logger;
    late FakePlistUtils plistParser;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      os = FakeOperatingSystemUtils();
      logger = BufferLogger.test();
      plistParser = FakePlistUtils(fileSystem);
    });

    testWithoutContext('Error on non-existing file', () {
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('not_existing.app'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(logger.errorText, contains('File "not_existing.app" does not exist.'));
    });

    testWithoutContext('Error on non-app-bundle folder', () {
      fileSystem.directory('regular_folder').createSync();
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('regular_folder'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(logger.errorText, contains('Folder "regular_folder" is not an app bundle.'));
    });

    testWithoutContext('Error on no info.plist', () {
      fileSystem.directory('bundle.app').createSync();
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('bundle.app'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(
        logger.errorText,
        contains('Invalid prebuilt macOS app. Does not contain Info.plist.'),
      );
    });

    testWithoutContext('Error on info.plist missing bundle identifier', () {
      final String contentsDirectory = fileSystem.path.join('bundle.app', 'Contents');
      fileSystem.directory(contentsDirectory).createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join('bundle.app', 'Contents', 'Info.plist'))
          .writeAsStringSync(badPlistData);
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('bundle.app'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(
        logger.errorText,
        contains('Invalid prebuilt macOS app. Info.plist does not contain bundle identifier'),
      );
    });

    testWithoutContext('Error on info.plist missing executable', () {
      final String contentsDirectory = fileSystem.path.join('bundle.app', 'Contents');
      fileSystem.directory(contentsDirectory).createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join('bundle.app', 'Contents', 'Info.plist'))
          .writeAsStringSync(badPlistDataNoExecutable);
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('bundle.app'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(
        logger.errorText,
        contains('Invalid prebuilt macOS app. Info.plist does not contain bundle executable'),
      );
    });

    testWithoutContext('Success with app bundle', () {
      final String appDirectory = fileSystem.path.join('bundle.app', 'Contents', 'MacOS');
      fileSystem.directory(appDirectory).createSync(recursive: true);
      fileSystem
          .file(fileSystem.path.join('bundle.app', 'Contents', 'Info.plist'))
          .writeAsStringSync(plistData);
      fileSystem.file(fileSystem.path.join(appDirectory, executableName)).createSync();
      final macosApp =
          MacOSApp.fromPrebuiltApp(
                fileSystem.file('bundle.app'),
                fileSystem: fileSystem,
                logger: logger,
                operatingSystemUtils: os,
                plistParser: plistParser,
              )!
              as PrebuiltMacOSApp;

      expect(logger.errorText, isEmpty);
      expect(macosApp.uncompressedBundle.path, 'bundle.app');
      expect(macosApp.id, 'fooBundleId');
      expect(macosApp.bundleName, 'bundle.app');
    });

    testWithoutContext('Bad zipped app, no payload dir', () {
      fileSystem.file('app.zip').createSync();
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('app.zip'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(logger.errorText, contains('Archive "app.zip" does not contain a single app bundle.'));
    });

    testWithoutContext('Bad zipped app, two app bundles', () {
      fileSystem.file('app.zip').createSync();
      os.unzipOverride = (File zipFile, Directory targetDirectory) {
        if (zipFile.path != 'app.zip') {
          return;
        }
        final String bundlePath1 = fileSystem.path.join(targetDirectory.path, 'bundle1.app');
        final String bundlePath2 = fileSystem.path.join(targetDirectory.path, 'bundle2.app');
        fileSystem.directory(bundlePath1).createSync(recursive: true);
        fileSystem.directory(bundlePath2).createSync(recursive: true);
      };
      final macosApp = MacOSApp.fromPrebuiltApp(
        fileSystem.file('app.zip'),
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as PrebuiltMacOSApp?;

      expect(macosApp, isNull);
      expect(logger.errorText, contains('Archive "app.zip" does not contain a single app bundle.'));
    });

    testWithoutContext('Success with zipped app', () {
      fileSystem.file('app.zip').createSync();
      os.unzipOverride = (File zipFile, Directory targetDirectory) {
        if (zipFile.path != 'app.zip') {
          return;
        }
        final Directory bundleAppContentsDir = fileSystem.directory(
          fileSystem.path.join(targetDirectory.path, 'bundle.app', 'Contents'),
        );
        bundleAppContentsDir.createSync(recursive: true);
        fileSystem
            .file(fileSystem.path.join(bundleAppContentsDir.path, 'Info.plist'))
            .writeAsStringSync(plistData);
        fileSystem.directory(fileSystem.path.join(bundleAppContentsDir.path, 'MacOS')).createSync();
        fileSystem
            .file(fileSystem.path.join(bundleAppContentsDir.path, 'MacOS', executableName))
            .createSync();
      };
      final macosApp =
          MacOSApp.fromPrebuiltApp(
                fileSystem.file('app.zip'),
                fileSystem: fileSystem,
                logger: logger,
                operatingSystemUtils: os,
                plistParser: plistParser,
              )!
              as PrebuiltMacOSApp;

      expect(logger.errorText, isEmpty);
      expect(macosApp.uncompressedBundle.path, endsWith('bundle.app'));
      expect(macosApp.id, 'fooBundleId');
      expect(macosApp.bundleName, endsWith('bundle.app'));
    });

    testWithoutContext('Success with project', () {
      final macosApp = MacOSApp.fromMacOSProject(
        FlutterProject.fromDirectoryTest(fileSystem.currentDirectory).macos,
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      );

      expect(logger.errorText, isEmpty);
      expect(macosApp.id, 'com.example.placeholder');
      expect(macosApp.name, 'macOS');
    });

    testWithoutContext('Chooses the correct directory for application.', () {
      final MacOSProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory)
          .macos;
      final macosApp = MacOSApp.fromMacOSProject(
        project,
        fileSystem: fileSystem,
        logger: logger,
        operatingSystemUtils: os,
        plistParser: plistParser,
      ) as BuildableMacOSApp;

      const vanillaApp = BuildInfo(
        BuildMode.debug,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      String? applicationBundle = macosApp.bundleDirectory(vanillaApp);
      expect(applicationBundle, 'Debug');

      const flavoredApp = BuildInfo(
        BuildMode.release,
        'flavor',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      applicationBundle = macosApp.bundleDirectory(flavoredApp);
      expect(applicationBundle, 'Release-flavor');
    });
  });
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils();

  void Function(File, Directory)? unzipOverride;

  @override
  void unzip(File file, Directory targetDirectory) {
    unzipOverride?.call(file, targetDirectory);
  }
}

class FakePlistUtils extends Fake implements PlistParser {
  FakePlistUtils(this.fileSystem);

  final FileSystem? fileSystem;

  @override
  Map<String, Object> parseFile(String plistFilePath) {
    final File file = fileSystem!.file(plistFilePath);
    if (!file.existsSync()) {
      return <String, Object>{};
    }
    return castStringKeyedMap(json.decode(file.readAsStringSync()))!.cast();
  }
}

// Contains no bundle identifier.
const badPlistData = '''
{}
''';

// Contains no bundle executable.
const badPlistDataNoExecutable = '''
{"CFBundleIdentifier": "fooBundleId"}
''';

const executableName = 'foo';

const plistData =
    '''
{"CFBundleIdentifier": "fooBundleId", "CFBundleExecutable": "$executableName"}
''';
