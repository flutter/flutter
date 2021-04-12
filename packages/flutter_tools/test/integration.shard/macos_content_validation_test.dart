// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import '../src/darwin_common.dart';
import 'test_utils.dart';

void main() {
  for (final String buildMode in <String>['Debug', 'Release']) {
    final String buildModeLower = buildMode.toLowerCase();
    test('flutter build macos --$buildModeLower builds a valid app', () {
      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );
      final String flutterBin = fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'flutter',
      );

      processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);

      final File podfile = fileSystem.file(fileSystem.path.join(workingDirectory, 'macos', 'Podfile'));
      final File podfileLock = fileSystem.file(fileSystem.path.join(workingDirectory, 'macos', 'Podfile.lock'));
      expect(podfile, exists);
      expect(podfileLock, exists);

      // Simulate a newer Podfile than Podfile.lock.
      podfile.setLastModifiedSync(DateTime.now());
      podfileLock.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 1)));
      expect(podfileLock.lastModifiedSync().isBefore(podfile.lastModifiedSync()), isTrue);

      final List<String> buildCommand = <String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'macos',
        '--$buildModeLower',
      ];
      final ProcessResult result = processManager.runSync(buildCommand, workingDirectory: workingDirectory);

      print(result.stdout);
      print(result.stderr);
      expect(result.exitCode, 0);

      expect(result.stdout, contains('Running pod install'));

      final Directory outputApp = fileSystem.directory(fileSystem.path.join(
        workingDirectory,
        'build',
        'macos',
        'Build',
        'Products',
        buildMode,
        'flutter_gallery.app',
      ));
      expect(podfile.lastModifiedSync().isBefore(podfileLock.lastModifiedSync()), isTrue);

      final Directory outputAppFramework =
          fileSystem.directory(fileSystem.path.join(
        outputApp.path,
        'Contents',
        'Frameworks',
        'App.framework',
      ));

      expect(outputAppFramework.childFile('App'), exists);
      expect(outputAppFramework.childLink('Resources'), exists);

      final File vmSnapshot = fileSystem.file(fileSystem.path.join(
        outputApp.path,
        'Contents',
        'Frameworks',
        'App.framework',
        'Resources',
        'flutter_assets',
        'vm_snapshot_data',
      ));

      expect(vmSnapshot.existsSync(), buildMode == 'Debug');

      final Directory outputFlutterFramework = fileSystem.directory(
        fileSystem.path.join(
          outputApp.path,
          'Contents',
          'Frameworks',
          'FlutterMacOS.framework',
        ),
      );

      // Check complicated macOS framework symlink structure.
      final Link current = outputFlutterFramework.childDirectory('Versions').childLink('Current');

      expect(current.targetSync(), 'A');

      expect(outputFlutterFramework.childLink('FlutterMacOS').targetSync(),
          fileSystem.path.join('Versions', 'Current', 'FlutterMacOS'));

      expect(outputFlutterFramework.childLink('Resources'), exists);
      expect(outputFlutterFramework.childLink('Resources').targetSync(),
          fileSystem.path.join('Versions', 'Current', 'Resources'));

      expect(outputFlutterFramework.childLink('Headers'), isNot(exists));
      expect(outputFlutterFramework.childDirectory('Headers'), isNot(exists));
      expect(outputFlutterFramework.childLink('Modules'), isNot(exists));
      expect(outputFlutterFramework.childDirectory('Modules'), isNot(exists));

      // Archiving should contain a bitcode blob, but not building.
      // This mimics Xcode behavior and prevents a developer from having to install a
      // 300+MB app.
      final File outputFlutterFrameworkBinary = outputFlutterFramework
          .childDirectory('Versions')
          .childDirectory('A')
          .childFile('FlutterMacOS');
      expect(
        containsBitcode(outputFlutterFrameworkBinary.path, processManager),
        isFalse,
      );

      // Build again without cleaning.
      final ProcessResult secondBuild = processManager.runSync(buildCommand, workingDirectory: workingDirectory);

      print(secondBuild.stdout);
      print(secondBuild.stderr);
      expect(secondBuild.exitCode, 0);

      expect(secondBuild.stdout, isNot(contains('Running pod install')));

      processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);
    }, skip: !platform.isMacOS,
       timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
