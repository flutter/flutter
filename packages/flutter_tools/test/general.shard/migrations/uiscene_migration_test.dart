// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/migrations/uiscene_migration.dart';

import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('UISceneMigration', () {
    testWithoutContext('fails if Info.plist is not found', () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser();

      final migration = UISceneMigration(
        setupFakeIosProject(fileSystem),
        logger,
        plistParser: plistParser,
        isMigrationFeatureEnabled: true,
      );

      await migration.migrate();
      expect(logger.traceText, contains('UIScene migration: unable to find Info.plist'));
      expect(
        logger.errorText,
        contains(
          'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
          'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
          'for the migration guide.\nSee https://flutter.dev/to/uiscene-migration/#hide-migration-warning'
          ' for instructions to hide this warning.',
        ),
      );
    });

    testWithoutContext('skips if already migrated', () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser();

      final migration = UISceneMigration(
        setupFakeIosProject(fileSystem, infoPlistContent: validMigratedInfoPlist),
        logger,
        isMigrationFeatureEnabled: true,
        plistParser: plistParser,
      );

      await migration.migrate();
      expect(logger.traceText, isEmpty);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('skips if feature disabled', () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser();

      final migration = UISceneMigration(
        setupFakeIosProject(fileSystem),
        logger,
        plistParser: plistParser,
        isMigrationFeatureEnabled: false,
      );

      await migration.migrate();
      expect(logger.traceText, isEmpty);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('Fails if unable to find storyboard', () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser(storyboardName: null);

      final migration = UISceneMigration(
        setupFakeIosProject(fileSystem, infoPlistContent: ''),
        logger,
        isMigrationFeatureEnabled: true,
        plistParser: plistParser,
      );

      await migration.migrate();
      expect(logger.traceText, contains('UIScene migration: unable to find matching storyboard'));
      expect(
        logger.errorText,
        contains(
          'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
          'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
          'for the migration guide.',
        ),
      );
    });

    testWithoutContext('fails if storyboard does not match default', () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser(storyboardName: 'notMain');

      final migration = UISceneMigration(
        setupFakeIosProject(fileSystem, infoPlistContent: ''),
        logger,
        isMigrationFeatureEnabled: true,
        plistParser: plistParser,
      );

      await migration.migrate();
      expect(logger.traceText, contains('UIScene migration: unable to find matching storyboard'));
      expect(
        logger.errorText,
        contains(
          'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
          'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
          'for the migration guide.',
        ),
      );
    });

    group('for Swift', () {
      testWithoutContext('fails if AppDelegate.swift is not exact match', () async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        final plistParser = FakePlistParser();

        final migration = UISceneMigration(
          setupFakeIosProject(
            fileSystem,
            infoPlistContent: validUnmigratedInfoPlist,
            swiftAppDelegateConent: 'not matching content',
          ),
          logger,
          isMigrationFeatureEnabled: true,
          plistParser: plistParser,
        );

        await migration.migrate();
        expect(
          logger.traceText,
          contains('UIScene migration: AppDelegate does not match original template.'),
        );
        expect(
          logger.errorText,
          contains(
            'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
            'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
            'for the migration guide.',
          ),
        );
      });

      testWithoutContext('replaces if AppDelegate.swift is exact match', () async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        final plistParser = FakePlistParser();

        final migration = UISceneMigration(
          setupFakeIosProject(
            fileSystem,
            infoPlistContent: validUnmigratedInfoPlist,
            swiftAppDelegateConent: UISceneMigration.originalSwiftAppDelegate,
          ),
          logger,
          isMigrationFeatureEnabled: true,
          plistParser: plistParser,
        );

        await migration.migrate();
        expect(logger.traceText, isEmpty);
        expect(logger.errorText, isEmpty);
        expect(plistParser.insertKeyCalled, isTrue);
        final File appDelegateSwift = fileSystem.systemTempDirectory.childFile('AppDelegate.swift');
        expect(appDelegateSwift.readAsStringSync(), equals(UISceneMigration.newSwiftAppDelegate));
      });
    });

    group('for ObjC', () {
      testWithoutContext('fails if AppDelegate.h is not exact match', () async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        final plistParser = FakePlistParser();

        final migration = UISceneMigration(
          setupFakeIosProject(
            fileSystem,
            infoPlistContent: validUnmigratedInfoPlist,
            objcAppDelegateHeaderContent: 'not a match',
            objcAppDelegateContent: UISceneMigration.originalObjCAppDelegateImplementation,
          ),
          logger,
          isMigrationFeatureEnabled: true,
          plistParser: plistParser,
        );

        await migration.migrate();
        expect(
          logger.traceText,
          contains('UIScene migration: AppDelegate does not match original template.'),
        );
        expect(
          logger.errorText,
          contains(
            'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
            'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
            'for the migration guide.',
          ),
        );
      });

      testWithoutContext('fails if AppDelegate.m is not exact match', () async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        final plistParser = FakePlistParser();

        final migration = UISceneMigration(
          setupFakeIosProject(
            fileSystem,
            infoPlistContent: validUnmigratedInfoPlist,
            objcAppDelegateHeaderContent: UISceneMigration.originalObjCAppDelegateHeader,
            objcAppDelegateContent: 'not a match',
          ),
          logger,
          isMigrationFeatureEnabled: true,
          plistParser: plistParser,
        );

        await migration.migrate();
        expect(
          logger.traceText,
          contains('UIScene migration: AppDelegate does not match original template.'),
        );
        expect(
          logger.errorText,
          contains(
            'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
            'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
            'for the migration guide.',
          ),
        );
      });

      testWithoutContext('replaces if AppDelegate.h and AppDelegate.m is exact match', () async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        final plistParser = FakePlistParser();

        final migration = UISceneMigration(
          setupFakeIosProject(
            fileSystem,
            infoPlistContent: validUnmigratedInfoPlist,
            objcAppDelegateHeaderContent: UISceneMigration.originalObjCAppDelegateHeader,
            objcAppDelegateContent: UISceneMigration.originalObjCAppDelegateImplementation,
          ),
          logger,
          isMigrationFeatureEnabled: true,
          plistParser: plistParser,
        );

        await migration.migrate();
        expect(logger.traceText, isEmpty);
        expect(logger.errorText, isEmpty);
        expect(plistParser.insertKeyCalled, isTrue);
        final File appDelegateHeader = fileSystem.systemTempDirectory.childFile('AppDelegate.h');
        expect(
          appDelegateHeader.readAsStringSync(),
          equals(UISceneMigration.newObjCAppDelegateHeader),
        );
        final File appDelegateImplementation = fileSystem.systemTempDirectory.childFile(
          'AppDelegate.m',
        );
        expect(
          appDelegateImplementation.readAsStringSync(),
          equals(UISceneMigration.newObjCAppDelegateImplementation),
        );
      });
    });

    testWithoutContext("fails if can't insert into Info.plist", () async {
      final logger = BufferLogger.test();
      final fileSystem = MemoryFileSystem.test();
      final plistParser = FakePlistParser(insertKeySucceeds: false);

      final migration = UISceneMigration(
        setupFakeIosProject(
          fileSystem,
          infoPlistContent: validUnmigratedInfoPlist,
          objcAppDelegateHeaderContent: UISceneMigration.originalObjCAppDelegateHeader,
          objcAppDelegateContent: UISceneMigration.originalObjCAppDelegateImplementation,
        ),
        logger,
        isMigrationFeatureEnabled: true,
        plistParser: plistParser,
      );

      await migration.migrate();
      expect(logger.traceText, contains('UIScene migration: unable to insert into Info.plist'));
      expect(
        logger.errorText,
        contains(
          'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
          'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
          'for the migration guide.',
        ),
      );
    });
  });
}

FakeIosProject setupFakeIosProject(
  MemoryFileSystem fileSystem, {
  String? infoPlistContent,
  String? swiftAppDelegateConent,
  String? objcAppDelegateHeaderContent,
  String? objcAppDelegateContent,
}) {
  final File infoPlist = fileSystem.systemTempDirectory.childFile('Info.plist');
  if (infoPlistContent != null) {
    infoPlist
      ..createSync()
      ..writeAsStringSync(infoPlistContent);
  }
  final File appDelegateSwift = fileSystem.systemTempDirectory.childFile('AppDelegate.swift');
  if (swiftAppDelegateConent != null) {
    appDelegateSwift
      ..createSync()
      ..writeAsStringSync(swiftAppDelegateConent);
  }

  final File appDelegateObjcImplementation = fileSystem.systemTempDirectory.childFile(
    'AppDelegate.m',
  );
  if (objcAppDelegateContent != null) {
    appDelegateObjcImplementation
      ..createSync()
      ..writeAsStringSync(objcAppDelegateContent);
  }
  final File appDelegateObjcHeader = fileSystem.systemTempDirectory.childFile('AppDelegate.h');
  if (objcAppDelegateHeaderContent != null) {
    appDelegateObjcHeader
      ..createSync()
      ..writeAsStringSync(objcAppDelegateHeaderContent);
  }

  return FakeIosProject(
    defaultHostInfoPlist: infoPlist,
    appDelegateSwift: appDelegateSwift,
    appDelegateObjcImplementation: appDelegateObjcImplementation,
    appDelegateObjcHeader: appDelegateObjcHeader,
  );
}

const validUnmigratedInfoPlist = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>UIMainStoryboardFile</key>
 <string>Main</string>
</dict>
''';

const validMigratedInfoPlist = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>UIMainStoryboardFile</key>
 <string>Main</string>
 <key>UIApplicationSceneManifest</key>
 <dict>
  <key>UIApplicationSupportsMultipleScenes</key>
  <false/>
  <key>UISceneConfigurations</key>
  <dict>
  <key>UIWindowSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneClassName</key>
        <string>UIWindowScene</string>
        <key>UISceneDelegateClassName</key>
        <string>FlutterSceneDelegate</string>
        <key>UISceneConfigurationName</key>
        <string>flutter</string>
        <key>UISceneStoryboardFile</key>
        <string>Main</string>
      </dict>
    </array>
   </dict>
 </dict>
</dict>
''';

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({
    required this.defaultHostInfoPlist,
    required this.appDelegateSwift,
    required this.appDelegateObjcImplementation,
    required this.appDelegateObjcHeader,
  });

  @override
  File defaultHostInfoPlist;

  @override
  File appDelegateSwift;

  @override
  File appDelegateObjcImplementation;

  @override
  File appDelegateObjcHeader;
}

class FakePlistParser extends Fake implements PlistParser {
  FakePlistParser({this.storyboardName = 'Main', this.insertKeySucceeds = true});

  final String? storyboardName;
  final bool insertKeySucceeds;
  bool insertKeyCalled = false;

  @override
  T? getValueFromFile<T>(String plistFilePath, String key) {
    if (key == 'UIMainStoryboardFile') {
      return storyboardName as T?;
    }
    return null;
  }

  @override
  bool insertKeyWithJson(String plistPath, {required String key, required String json}) {
    insertKeyCalled = true;
    return insertKeySucceeds;
  }
}
