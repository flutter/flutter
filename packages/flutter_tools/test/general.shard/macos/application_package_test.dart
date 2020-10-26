// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/bundle_processor.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('PrebuiltMacOSApp', () {
    MockOperatingSystemUtils os;
    final Map<Type, Generator> overrides = <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      PlistParser: () => MockPlistUtils(),
      Platform: _kNoColorTerminalPlatform,
      OperatingSystemUtils: () => os,
    };

    setUp(() {
      os = MockOperatingSystemUtils();
    });

    testUsingContext('Error on non-existing file', () {
      final PrebuiltMacOSApp macosApp =
          MacOSApp.fromPrebuiltApp(globals.fs.file('not_existing.app'))
              as PrebuiltMacOSApp;
      expect(macosApp, isNull);
      expect(
        testLogger.errorText,
        'File "not_existing.app" does not exist.\n',
      );
    }, overrides: overrides);

    testUsingContext('Error on non-app-bundle folder', () {
      globals.fs.directory('regular_folder').createSync();
      final PrebuiltMacOSApp macosApp =
          MacOSApp.fromPrebuiltApp(globals.fs.file('regular_folder'))
              as PrebuiltMacOSApp;
      expect(macosApp, isNull);
      expect(testLogger.errorText,
          'Folder "regular_folder" is not an app bundle.\n');
    }, overrides: overrides);

    testUsingContext('Error on no info.plist', () {
      globals.fs.directory('bundle.app').createSync();
      final PrebuiltMacOSApp macosApp =
          MacOSApp.fromPrebuiltApp(globals.fs.file('bundle.app'))
              as PrebuiltMacOSApp;
      expect(macosApp, isNull);
      expect(
        testLogger.errorText,
        'Invalid prebuilt macOS app. Does not contain Info.plist.\n',
      );
    }, overrides: overrides);

    testUsingContext('Error on bad info.plist', () {
      final String contentsDirectory =
          globals.fs.path.join('bundle.app', 'Contents');
      globals.fs.directory(contentsDirectory).createSync(recursive: true);
      globals.fs
          .file(globals.fs.path.join('bundle.app', 'Contents', 'Info.plist'))
          .writeAsStringSync(badPlistData);
      final PrebuiltMacOSApp macosApp =
          MacOSApp.fromPrebuiltApp(globals.fs.file('bundle.app'))
              as PrebuiltMacOSApp;
      expect(macosApp, isNull);
      expect(
        testLogger.errorText,
        contains(
            'Invalid prebuilt macOS app. Info.plist does not contain bundle identifier\n'),
      );
    }, overrides: overrides);

    testUsingContext('Success with app bundle', () {
      final String appDirectory =
          globals.fs.path.join('bundle.app', 'Contents', 'MacOS');
      globals.fs.directory(appDirectory).createSync(recursive: true);
      globals.fs
          .file(globals.fs.path.join('bundle.app', 'Contents', 'Info.plist'))
          .writeAsStringSync(plistData);
      globals.fs
          .file(globals.fs.path.join(appDirectory, executableName))
          .createSync();
      final PrebuiltMacOSApp macosApp =
          MacOSApp.fromPrebuiltApp(globals.fs.file('bundle.app'))
              as PrebuiltMacOSApp;
      expect(testLogger.errorText, isEmpty);
      expect(macosApp.bundleDir.path, 'bundle.app');
      expect(macosApp.id, 'fooBundleId');
      expect(macosApp.bundleName, 'bundle.app');
    }, overrides: overrides);

    group('with a zip bundle processor', () {
      final Map<Type, Generator> zipOverrides = <Type, Generator>{
        BundleProcessor: () => ZipBundleProcessor(globals.fs, globals.logger),
      }..addAll(overrides);

      testUsingContext('Bad zipped app, no payload dir', () {
        globals.fs.file('app.zip').createSync();
        when(os.unzip(globals.fs.file('app.zip'), any))
            .thenAnswer((Invocation _) {});
        final PrebuiltMacOSApp macosApp =
            MacOSApp.fromPrebuiltApp(globals.fs.file('app.zip'))
                as PrebuiltMacOSApp;
        expect(macosApp, isNull);
        expect(
          testLogger.errorText,
          'Archive "app.zip" does not contain a single app bundle.\n',
        );
      }, overrides: zipOverrides);

      testUsingContext('Bad zipped app, two app bundles', () {
        globals.fs.file('app.zip').createSync();
        when(os.unzip(any, any)).thenAnswer((Invocation invocation) {
          final File zipFile = invocation.positionalArguments[0] as File;
          if (zipFile.path != 'app.zip') {
            return;
          }
          final Directory targetDirectory =
              invocation.positionalArguments[1] as Directory;
          final String bundlePath1 =
              globals.fs.path.join(targetDirectory.path, 'bundle1.app');
          final String bundlePath2 =
              globals.fs.path.join(targetDirectory.path, 'bundle2.app');
          globals.fs.directory(bundlePath1).createSync(recursive: true);
          globals.fs.directory(bundlePath2).createSync(recursive: true);
        });
        final PrebuiltMacOSApp macosApp =
            MacOSApp.fromPrebuiltApp(globals.fs.file('app.zip'))
                as PrebuiltMacOSApp;
        expect(macosApp, isNull);
        expect(testLogger.errorText,
            'Archive "app.zip" does not contain a single app bundle.\n');
      }, overrides: zipOverrides);

      testUsingContext('Success with zipped app', () {
        globals.fs.file('app.zip').createSync();
        when(os.unzip(any, any)).thenAnswer((Invocation invocation) {
          final File zipFile = invocation.positionalArguments[0] as File;
          if (zipFile.path != 'app.zip') {
            return;
          }
          final Directory targetDirectory =
              invocation.positionalArguments[1] as Directory;
          final Directory bundleAppContentsDir = globals.fs.directory(globals
              .fs.path
              .join(targetDirectory.path, 'bundle.app', 'Contents'));
          bundleAppContentsDir.createSync(recursive: true);
          globals.fs
              .file(
                  globals.fs.path.join(bundleAppContentsDir.path, 'Info.plist'))
              .writeAsStringSync(plistData);
          globals.fs
              .directory(
                  globals.fs.path.join(bundleAppContentsDir.path, 'MacOS'))
              .createSync();
          globals.fs
              .file(globals.fs.path
                  .join(bundleAppContentsDir.path, 'MacOS', executableName))
              .createSync();
        });
        final PrebuiltMacOSApp macosApp =
            MacOSApp.fromPrebuiltApp(globals.fs.file('app.zip'))
                as PrebuiltMacOSApp;
        expect(testLogger.errorText, isEmpty);
        expect(macosApp.bundleDir.path, endsWith('bundle.app'));
        expect(macosApp.id, 'fooBundleId');
        expect(macosApp.bundleName, endsWith('bundle.app'));
      }, overrides: zipOverrides);
    });
  });
}

class ZipBundleProcessor extends BundleProcessor {
  ZipBundleProcessor(this.fileSystem, this.logger);

  final FileSystem fileSystem;
  final Logger logger;

  @override
  Directory getAppBundle(FileSystemEntity applicationBundle) {
    // Try to unpack as a zip.
    final Directory tempDir =
        fileSystem.systemTempDirectory.createTempSync('flutter_app.');
    shutdownHooks.addShutdownHook(() async {
      await tempDir.delete(recursive: true);
    }, ShutdownStage.STILL_RECORDING);
    try {
      globals.os.unzip(globals.fs.file(applicationBundle), tempDir);
    } on ProcessException {
      globals.printError(
          'Invalid prebuilt macOS app. Unable to extract bundle from archive.');
      return null;
    }
    try {
      return tempDir
          .listSync()
          .whereType<Directory>()
          .singleWhere(BundleProcessor.isBundleDirectory);
    } on StateError {
      globals.printError(
          'Archive "${applicationBundle.path}" does not contain a single app bundle.');
      return null;
    }
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

final Generator _kNoColorTerminalPlatform =
    () => FakePlatform(stdoutSupportsAnsi: false);
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

class MockPlistUtils extends Mock implements PlistParser {
  @override
  Map<String, dynamic> parseFile(String plistFilePath) {
    final File file = globals.fs.file(plistFilePath);
    if (!file.existsSync()) {
      return <String, dynamic>{};
    }
    return castStringKeyedMap(json.decode(file.readAsStringSync()));
  }
}

// Contains no bundle identifier.
const String badPlistData = '''
{}
''';

const String executableName = 'foo';

const String plistData = '''
{"CFBundleIdentifier": "fooBundleId", "CFBundleExecutable": "$executableName"}
''';
