// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:io';

import 'package:dwds/src/utilities/sdk_configuration.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

var _throwsDoesNotExistException = throwsA(
    isA<InvalidSdkConfigurationException>()
        .having((e) => '$e', 'message', contains('does not exist')));

void main() {
  group('Basic configuration', () {
    test('Can validate default configuration layout', () async {
      final defaultConfiguration =
          await DefaultSdkConfigurationProvider().configuration;
      defaultConfiguration.validateSdkDir();
      defaultConfiguration.validate();
    });

    test('Cannot validate an empty configuration layout', () async {
      final emptyConfiguration = SdkConfiguration();
      expect(() => emptyConfiguration.validateSdkDir(),
          _throwsDoesNotExistException);
      expect(() => emptyConfiguration.validate(), _throwsDoesNotExistException);
    });
  });

  group('Non-standard configuration', () {
    Directory outputDir;

    setUp(() async {
      final systemTempDir = Directory.systemTemp;
      outputDir = systemTempDir.createTempSync('foo bar');
    });

    tearDown(() async {
      await outputDir?.delete(recursive: true);
    });

    test('Can validate existing configuration layout', () async {
      final defaultSdkConfiguration =
          await DefaultSdkConfigurationProvider().configuration;

      final sdkDirectory = outputDir.path;
      final librariesDir = p.join(sdkDirectory, 'specs');
      final librariesPath = p.join(librariesDir, 'libraries.json');

      Directory(librariesDir).createSync(recursive: true);
      File(defaultSdkConfiguration.librariesPath).copySync(librariesPath);

      final summariesDir = p.join(sdkDirectory, 'summaries');
      final unsoundSdkSummaryPath = p.join(summariesDir, 'ddc_sdk.dill');
      final soundSdkSummaryPath =
          p.join(summariesDir, 'ddc_outline_sound.dill');

      Directory(summariesDir).createSync(recursive: true);
      File(defaultSdkConfiguration.unsoundSdkSummaryPath)
          .copySync(unsoundSdkSummaryPath);
      File(defaultSdkConfiguration.soundSdkSummaryPath)
          .copySync(soundSdkSummaryPath);

      final workerDir = p.join(sdkDirectory, 'snapshots');
      final compilerWorkerPath = p.join(workerDir, 'dartdevc.dart.snapshot');

      Directory(workerDir).createSync(recursive: true);
      File(defaultSdkConfiguration.compilerWorkerPath)
          .copySync(compilerWorkerPath);

      final sdkConfiguration = SdkConfiguration(
        sdkDirectory: sdkDirectory,
        soundSdkSummaryPath: soundSdkSummaryPath,
        unsoundSdkSummaryPath: unsoundSdkSummaryPath,
        librariesPath: librariesPath,
        compilerWorkerPath: compilerWorkerPath,
      );

      expect(sdkConfiguration.sdkDirectory, equals(sdkDirectory));
      expect(sdkConfiguration.unsoundSdkSummaryPath,
          equals(unsoundSdkSummaryPath));
      expect(sdkConfiguration.soundSdkSummaryPath, equals(soundSdkSummaryPath));
      expect(sdkConfiguration.librariesPath, equals(librariesPath));
      expect(sdkConfiguration.compilerWorkerPath, equals(compilerWorkerPath));

      sdkConfiguration.validateSdkDir();
      sdkConfiguration.validate();
    });

    test('Cannot validate non-existing configuration layout', () async {
      final sdkDir = outputDir.path;
      final librariesDir = p.join(sdkDir, 'fakespecs');
      final librariesPath = p.join(librariesDir, 'libraries.json');
      final summariesDir = p.join(sdkDir, 'fakesummaries');
      final unsoundSdkSummaryPath = p.join(summariesDir, 'ddc_sdk.dill');
      final soundSdkSummaryPath =
          p.join(summariesDir, 'ddc_outline_sound.dill');
      final workerDir = p.join(sdkDir, 'fakesnapshots');
      final compilerWorkerPath = p.join(workerDir, 'dartdevc.dart.snapshot');

      final sdkConfiguration = SdkConfiguration(
        sdkDirectory: sdkDir,
        soundSdkSummaryPath: soundSdkSummaryPath,
        unsoundSdkSummaryPath: unsoundSdkSummaryPath,
        librariesPath: librariesPath,
        compilerWorkerPath: compilerWorkerPath,
      );

      sdkConfiguration.validateSdkDir();
      expect(() => sdkConfiguration.validate(), _throwsDoesNotExistException);
    });
  });

  group('SDK configuration', () {
    MemoryFileSystem fs;

    final root = '/root';
    final sdkDirectory = root;
    final soundSdkSummaryPath = _dartSoundSdkSummaryPath(sdkDirectory);
    final unsoundSdkSummaryPath = _dartUnsoundSdkSummaryPath(sdkDirectory);
    final librariesPath = _librariesPath(sdkDirectory);
    final compilerWorkerPath = _compilerWorkerPath(root);

    setUp(() async {
      fs = MemoryFileSystem();
      await fs.directory(sdkDirectory).create(recursive: true);
      await fs.file(soundSdkSummaryPath).create(recursive: true);
      await fs.file(unsoundSdkSummaryPath).create(recursive: true);
      await fs.file(librariesPath).create(recursive: true);
      await fs.file(compilerWorkerPath).create(recursive: true);
    });

    test('Can create and validate default SDK configuration', () async {
      final configuration = SdkConfiguration(
        sdkDirectory: sdkDirectory,
        soundSdkSummaryPath: soundSdkSummaryPath,
        unsoundSdkSummaryPath: unsoundSdkSummaryPath,
        librariesPath: librariesPath,
        compilerWorkerPath: compilerWorkerPath,
      );

      expect(configuration.sdkDirectory, equals(sdkDirectory));
      expect(configuration.soundSdkSummaryPath, equals(soundSdkSummaryPath));
      expect(
          configuration.unsoundSdkSummaryPath, equals(unsoundSdkSummaryPath));
      expect(configuration.librariesPath, equals(librariesPath));
      expect(configuration.compilerWorkerPath, equals(compilerWorkerPath));

      configuration.validateSdkDir(fileSystem: fs);
      configuration.validate(fileSystem: fs);
    });
  });
}

String _dartUnsoundSdkSummaryPath(String sdkDir) =>
    p.join(sdkDir, 'lib', '_internal', 'ddc_sdk.dill');

String _dartSoundSdkSummaryPath(String sdkDir) =>
    p.join(sdkDir, 'lib', '_internal', 'ddc_outline_sound.dill');

String _librariesPath(String sdkDir) => p.join(sdkDir, 'lib', 'libraries.json');

String _compilerWorkerPath(String binDir) =>
    p.join(binDir, 'snapshots', 'dartdevc.dart.snapshot');
