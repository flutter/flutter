// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/flutter_project_metadata.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/migrate_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';


void main() {
  Directory tempDir;
  FlutterRunTestDriver flutter;
  Logger logger;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    flutter = FlutterRunTestDriver(tempDir);
    logger = BufferLogger.test();
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('parse simple config file', () async {
    final File metadataFile = tempDir.childFile('.metadata');
    metadataFile.createSync(recursive: true);
    metadataFile.writeAsStringSync('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: fj19vkla9vnlka9vni3n808v3nch8cd
  channel: stable

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: fj19vkla9vnlka9vni3n808v3nch8cd
      base_revision: 93kf9v3njfa90vnidfjvn39nvi3vnie
    - platform: android
      create_revision: abfj19vkla9vnlka9vni3n808v3nch8cd
      base_revision: ab93kf9v3njfa90vnidfjvn39nvi3vnie

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - lib/main.dart
    - ios/Runner.xcodeproj/project.pbxproj
    - lib/file1/etc.dart
    - android/my_file.java
''', flush: true);
    FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, logger);

    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.root].createRevision, equals('fj19vkla9vnlka9vni3n808v3nch8cd'));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.root].baseRevision, equals('93kf9v3njfa90vnidfjvn39nvi3vnie'));

    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.android].createRevision, equals('abfj19vkla9vnlka9vni3n808v3nch8cd'));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.android].baseRevision, equals('ab93kf9v3njfa90vnidfjvn39nvi3vnie'));

    expect(metadata.migrateConfig.unmanagedFiles[0], equals('lib/main.dart'));
    expect(metadata.migrateConfig.unmanagedFiles[1], equals('ios/Runner.xcodeproj/project.pbxproj'));
    expect(metadata.migrateConfig.unmanagedFiles[2], equals('lib/file1/etc.dart'));
    expect(metadata.migrateConfig.unmanagedFiles[3], equals('android/my_file.java'));

    metadataFile.writeAsStringSync('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: fj19vkla9vnlka9vni3n808v3nch8cd
  channel: stable

project_type: app
''', flush: true);

    metadata = FlutterProjectMetadata(metadataFile, logger);

    expect(metadata.migrateConfig.isEmpty, equals(true));
    expect(metadata.versionRevision, equals('fj19vkla9vnlka9vni3n808v3nch8cd'));
    expect(metadata.versionChannel, equals('stable'));
  });

  testUsingContext('write simple config file', () async {
    const String testCreateRevision = 'testmc9skl32nlnf23lnakcs9njr3';
    const String testBaseRevision = 'testanas9anlnq9ba7bjhavan3kma';
    MigrateConfig config = MigrateConfig(
      platformConfigs: <SupportedPlatform, MigratePlatformConfig>{
        SupportedPlatform.android: MigratePlatformConfig(createRevision: testCreateRevision, baseRevision: testBaseRevision),
        SupportedPlatform.ios: MigratePlatformConfig(createRevision: testCreateRevision, baseRevision: testBaseRevision),
        SupportedPlatform.root: MigratePlatformConfig(createRevision: testCreateRevision, baseRevision: testBaseRevision),
        SupportedPlatform.windows: MigratePlatformConfig(createRevision: testCreateRevision, baseRevision: testBaseRevision),
      },
      unmanagedFiles: <String>[
        'lib/main.dart',
        'ios/Runner.xcodeproj/project.pbxproj',
        'lib/file1/etc.dart',
      ],
    );
    String outputString = config.getOutputFileString();
    expect(outputString, equals('''

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: android
      create_revision: $testCreateRevision
      base_revision: $testBaseRevision
    - platform: ios
      create_revision: $testCreateRevision
      base_revision: $testBaseRevision
    - platform: root
      create_revision: $testCreateRevision
      base_revision: $testBaseRevision
    - platform: windows
      create_revision: $testCreateRevision
      base_revision: $testBaseRevision

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
    - 'lib/file1/etc.dart'
'''));

    config = MigrateConfig();
    outputString = config.getOutputFileString();
    expect(outputString, equals(''));
  });

  testUsingContext('populate migrate config', () async {
    // Flutter Stable 1.22.6 hash: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    final MigrateProject project = MigrateProject('version:1.22.6_stable');
    await project.setUpIn(tempDir);

    final File metadataFile = tempDir.childFile('.metadata');

    const String currentRevision = 'test_base_revision';
    const String createRevision = 'test_create_revision';

    final FlutterProjectMetadata metadata = FlutterProjectMetadata(metadataFile, logger);
    metadata.migrateConfig.populate(
      projectDirectory: tempDir,
      currentRevision: currentRevision,
      createRevision: createRevision,
      create: true,
      update: true,
      logger: logger,
    );

    expect(metadata.migrateConfig.platformConfigs.length, equals(3));

    final List<SupportedPlatform> keyList = List<SupportedPlatform>.from(metadata.migrateConfig.platformConfigs.keys);

    expect(keyList[0], equals(SupportedPlatform.root));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.root].baseRevision, equals(currentRevision));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.root].createRevision, equals(createRevision));

    expect(keyList[1], equals(SupportedPlatform.android));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.android].baseRevision, equals(currentRevision));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.android].createRevision, equals(createRevision));

    expect(keyList[2], equals(SupportedPlatform.ios));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.ios].baseRevision, equals(currentRevision));
    expect(metadata.migrateConfig.platformConfigs[SupportedPlatform.ios].createRevision, equals(createRevision));

    final File metadataFileOutput = tempDir.childFile('.metadata_output');
    metadata.writeFile(outputFile: metadataFileOutput);
    expect(metadataFileOutput.readAsStringSync(), equals('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
  channel: unknown

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: $createRevision
      base_revision: $currentRevision
    - platform: android
      create_revision: $createRevision
      base_revision: $currentRevision
    - platform: ios
      create_revision: $createRevision
      base_revision: $currentRevision

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
'''));
  });
}
