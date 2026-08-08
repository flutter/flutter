// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'swift_package_manager_utils.dart';
import 'test_utils.dart';

void main() {
  test(
    'Convert ephemeral iOS module to non-ephemeral iOS module',
    () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'ios_module_conversion_test.',
      );
      final String workingDirectoryPath = workingDirectory.path;
      try {
        await SwiftPackageManagerUtils.enableSwiftPackageManager(flutterBin, workingDirectoryPath);

        final String moduleDirectoryPath = await SwiftPackageManagerUtils.createApp(
          flutterBin,
          workingDirectoryPath,
          platform: 'ios',
          options: <String>['--template=module'],
          name: 'my_module',
        );

        final Directory moduleDir = fileSystem.directory(moduleDirectoryPath);
        final File pubspecFile = moduleDir.childFile('pubspec.yaml');
        expect(pubspecFile, exists);

        // First, configure as ephemeral module (iosEphemeral: true) and run create.
        String pubspecContent = pubspecFile.readAsStringSync();
        pubspecContent = pubspecContent.replaceAll('iosEphemeral: false', 'iosEphemeral: true');
        pubspecFile.writeAsStringSync(pubspecContent);

        final Directory ephemeralIosDir = moduleDir.childDirectory('.ios');
        final Directory nonEphemeralIosDir = moduleDir.childDirectory('ios');
        if (nonEphemeralIosDir.existsSync()) {
          nonEphemeralIosDir.deleteSync(recursive: true);
        }

        await SwiftPackageManagerUtils.buildApp(
          flutterBin,
          moduleDirectoryPath,
          options: <String>['ios', '--config-only', '-v'],
          expectedExitCode: 1,
          expectedLines: <Pattern>['Swift Package Manager is enabled, but this project has an ephemeral iOS project']
        );

        expect(ephemeralIosDir, exists);
        expect(nonEphemeralIosDir, isNot(exists));

        pubspecContent = pubspecFile.readAsStringSync();
        pubspecContent = pubspecContent.replaceAll('iosEphemeral: true', 'iosEphemeral: false');
        pubspecFile.writeAsStringSync(pubspecContent);

        final ProcessResult result = await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'create',
          '--org',
          'io.flutter.devicelab',
          '.',
        ], workingDirectory: moduleDirectoryPath);
        expect(
          result.exitCode,
          0,
          reason: 'Failed to convert to non-ephemeral module: ${result.stderr}',
        );

        expect(ephemeralIosDir, isNot(exists));
        expect(nonEphemeralIosDir, exists);

        await SwiftPackageManagerUtils.buildApp(
          flutterBin,
          moduleDirectoryPath,
          options: <String>['ios', '-v'],
        );

      } finally {
        await SwiftPackageManagerUtils.disableSwiftPackageManager(flutterBin, workingDirectoryPath);
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      }
    },
    skip: !platform.isMacOS, // [intended] iOS integration tests only work on macOS.
  );
}
