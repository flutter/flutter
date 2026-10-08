// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/migrations/status_bar_appearance_migration.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

const statusBarAppearanceKey = 'UIViewControllerBasedStatusBarAppearance';

void main() {
  late File infoPlist;
  late BufferLogger logger;
  late FakeXcode xcode;
  late RecordingPlistParser plistParser;

  setUp(() {
    infoPlist = MemoryFileSystem.test().file('Info.plist');
    logger = BufferLogger.test();
    xcode = FakeXcode();
    plistParser = RecordingPlistParser();
  });

  StatusBarAppearanceMigration migration({
    EnvironmentType environmentType = EnvironmentType.physical,
  }) => StatusBarAppearanceMigration(
    infoPlist,
    logger,
    xcode: xcode,
    environmentType: environmentType,
    plistParser: plistParser,
  );

  testWithoutContext('skips missing Info.plist without parsing or querying the SDK', () async {
    await migration().migrate();

    expect(infoPlist.existsSync(), isFalse);
    expect(plistParser.readPaths, isEmpty);
    expect(plistParser.replacements, isEmpty);
    expect(xcode.queriedEnvironments, isEmpty);
    expect(logger.statusText, isEmpty);
  });

  for (final value in <Object?>[null, true, 'false', 0]) {
    testWithoutContext('leaves value $value unchanged without querying the SDK', () async {
      infoPlist.createSync();
      if (value != null) {
        plistParser.setProperty(statusBarAppearanceKey, value);
      }

      await migration().migrate();

      expect(plistParser.readPaths, <String>[infoPlist.path]);
      expect(plistParser.replacements, isEmpty);
      expect(xcode.queriedEnvironments, isEmpty);
      expect(logger.statusText, isEmpty);
    });
  }

  testWithoutContext('leaves nested status bar appearance settings unchanged', () async {
    infoPlist.createSync();
    plistParser.setProperty('Nested', <String, Object>{statusBarAppearanceKey: false});

    await migration().migrate();

    expect(plistParser.replacements, isEmpty);
    expect(xcode.queriedEnvironments, isEmpty);
  });

  for (final sdkVersion in <Version?>[null, Version(26, 5, 0)]) {
    testWithoutContext('does not migrate with SDK version $sdkVersion', () async {
      infoPlist.createSync();
      plistParser.setProperty(statusBarAppearanceKey, false);
      xcode.sdkVersion = sdkVersion;

      await migration().migrate();

      expect(plistParser.getValueFromFile<bool>(infoPlist.path, statusBarAppearanceKey), isFalse);
      expect(plistParser.replacements, isEmpty);
      expect(xcode.queriedEnvironments, <EnvironmentType>[EnvironmentType.physical]);
      expect(logger.statusText, isEmpty);
    });
  }

  for (final EnvironmentType environmentType in EnvironmentType.values) {
    testWithoutContext('queries the $environmentType SDK before migrating', () async {
      infoPlist.createSync();
      plistParser.setProperty(statusBarAppearanceKey, false);

      await migration(environmentType: environmentType).migrate();

      expect(plistParser.replacements, <(String, String, bool)>[
        (infoPlist.path, statusBarAppearanceKey, true),
      ]);
      expect(plistParser.getValueFromFile<bool>(infoPlist.path, statusBarAppearanceKey), isTrue);
      expect(xcode.queriedEnvironments, <EnvironmentType>[environmentType]);
      expect(logger.statusText, contains('view controller-based status bar appearance'));
    });
  }

  testWithoutContext('preserves other settings when migrating with a later SDK', () async {
    infoPlist.createSync();
    plistParser.setProperty(statusBarAppearanceKey, false);
    plistParser.setProperty('UIStatusBarHidden', true);
    plistParser.setProperty('Nested', <String, Object>{statusBarAppearanceKey: false});
    xcode.sdkVersion = Version(27, 1, 0);

    await migration().migrate();

    expect(plistParser.parseFile(infoPlist.path), <String, Object>{
      statusBarAppearanceKey: true,
      'UIStatusBarHidden': true,
      'Nested': <String, Object>{statusBarAppearanceKey: false},
    });
  });

  testWithoutContext('does not report success when updating the plist fails', () async {
    infoPlist.createSync();
    plistParser.setProperty(statusBarAppearanceKey, false);
    plistParser.replaceSucceeds = false;

    await migration().migrate();

    expect(plistParser.getValueFromFile<bool>(infoPlist.path, statusBarAppearanceKey), isFalse);
    expect(logger.statusText, isEmpty);
    expect(logger.traceText, contains('Unable to update Info.plist'));
  });

  testWithoutContext('does not migrate or query the SDK again after updating the plist', () async {
    infoPlist.createSync();
    plistParser.setProperty(statusBarAppearanceKey, false);
    final StatusBarAppearanceMigration migrator = migration();
    await migrator.migrate();
    logger.clear();

    await migrator.migrate();

    expect(plistParser.replacements, hasLength(1));
    expect(xcode.queriedEnvironments, <EnvironmentType>[EnvironmentType.physical]);
    expect(logger.statusText, isEmpty);
  });
}

class FakeXcode extends Fake implements Xcode {
  Version? sdkVersion = Version(27, 0, 0);
  final queriedEnvironments = <EnvironmentType>[];

  @override
  Future<Version?> sdkPlatformVersion(EnvironmentType environmentType) async {
    queriedEnvironments.add(environmentType);
    return sdkVersion;
  }
}

class RecordingPlistParser extends FakePlistParser {
  bool replaceSucceeds = true;
  final readPaths = <String>[];
  final replacements = <(String, String, bool)>[];

  @override
  T? getValueFromFile<T>(String plistFilePath, String key) {
    readPaths.add(plistFilePath);
    return super.getValueFromFile<T>(plistFilePath, key);
  }

  @override
  bool replaceKeyWithBoolean(String plistFilePath, {required String key, required bool value}) {
    replacements.add((plistFilePath, key, value));
    return replaceSucceeds && super.replaceKeyWithBoolean(plistFilePath, key: key, value: value);
  }
}
