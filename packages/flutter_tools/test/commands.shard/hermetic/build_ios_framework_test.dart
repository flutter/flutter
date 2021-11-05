// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=1000"
@Tags(<String>['no-shuffle'])

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_ios_framework.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

void main() {
  group('build ios-framework', () {
    MemoryFileSystem memoryFileSystem;
    Directory outputDirectory;
    FakePlatform fakePlatform;

    setUpAll(() {
      Cache.disableLocking();
    });

    const String storageBaseUrl = 'https://fake.googleapis.com';
    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      fakePlatform = FakePlatform(
        operatingSystem: 'macos',
        environment: <String, String>{
          'FLUTTER_STORAGE_BASE_URL': storageBaseUrl,
        },
      );

      outputDirectory = memoryFileSystem.systemTempDirectory
          .createTempSync('flutter_build_ios_framework_test_output.')
          .childDirectory('Debug')
        ..createSync();
    });

    group('podspec', () {
      const String engineRevision = '0123456789abcdef';
      Cache cache;

      setUp(() {
        final Directory rootOverride = memoryFileSystem.directory('cache');
        cache = Cache.test(
          rootOverride: rootOverride,
          platform: fakePlatform,
          fileSystem: memoryFileSystem,
          processManager: FakeProcessManager.any(),
        );
        rootOverride.childDirectory('bin').childDirectory('internal').childFile('engine.version')
          ..createSync(recursive: true)
          ..writeAsStringSync(engineRevision);
      });

      testUsingContext('version unknown', () async {
        const String frameworkVersion = '0.0.0-unknown';
        final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(frameworkVersion: frameworkVersion);

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: fakeFlutterVersion,
          cache: cache,
          verboseHelp: false,
        );

        expect(() => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(message: 'Detected version is $frameworkVersion'));
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('throws when not on a released version', () async {
        const String frameworkVersion = 'v1.13.10+hotfix-pre.2';
        const GitTagVersion gitTagVersion = GitTagVersion(
          x: 1,
          y: 13,
          z: 10,
          hotfix: 13,
          commits: 2,
        );
        final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(
          gitTagVersion: gitTagVersion,
          frameworkVersion: frameworkVersion,
        );

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: fakeFlutterVersion,
          cache: cache,
          verboseHelp: false,
        );

        expect(() => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(message: 'Detected version is $frameworkVersion'));
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('throws when license not found', () async {
        final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(
          gitTagVersion: const GitTagVersion(
            x: 1,
            y: 13,
            z: 10,
            hotfix: 13,
            commits: 0,
          ),
        );

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: fakeFlutterVersion,
          cache: cache,
          verboseHelp: false,
        );

        expect(() => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(message: 'Could not find license'));
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      group('is created', () {
        const String frameworkVersion = 'v1.13.11+hotfix.13';
        const String licenseText = 'This is the license!';

        setUp(() {
          cache.getLicenseFile()
            ..createSync(recursive: true)
            ..writeAsStringSync(licenseText);
        });

        group('on master channel', () {
          testUsingContext('created when forced', () async {
            const GitTagVersion gitTagVersion = GitTagVersion(
              x: 1,
              y: 13,
              z: 11,
              hotfix: 13,
              commits: 100,
            );
            final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(
              gitTagVersion: gitTagVersion,
              frameworkVersion: frameworkVersion,
            );

            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              platform: fakePlatform,
              flutterVersion: fakeFlutterVersion,
              cache: cache,
              verboseHelp: false,
            );
            command.produceFlutterPodspec(BuildMode.debug, outputDirectory, force: true);

            final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
            expect(expectedPodspec.existsSync(), isTrue);
          }, overrides: <Type, Generator>{
            FileSystem: () => memoryFileSystem,
            ProcessManager: () => FakeProcessManager.any(),
          });
        });

        group('not on master channel', () {
          FakeFlutterVersion fakeFlutterVersion;
          setUp(() {
            const GitTagVersion gitTagVersion = GitTagVersion(
              x: 1,
              y: 13,
              z: 11,
              hotfix: 13,
              commits: 0,
            );
            fakeFlutterVersion = FakeFlutterVersion(
              gitTagVersion: gitTagVersion,
              frameworkVersion: frameworkVersion,
            );
          });

          testUsingContext('contains license and version', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              platform: fakePlatform,
              flutterVersion: fakeFlutterVersion,
              cache: cache,
              verboseHelp: false,
            );
            command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

            final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
            final String podspecContents = expectedPodspec.readAsStringSync();
            expect(podspecContents, contains("'1.13.1113'"));
            expect(podspecContents, contains('# $frameworkVersion'));
            expect(podspecContents, contains(licenseText));
          }, overrides: <Type, Generator>{
            FileSystem: () => memoryFileSystem,
            ProcessManager: () => FakeProcessManager.any(),
          });

          testUsingContext('debug URL', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              platform: fakePlatform,
              flutterVersion: fakeFlutterVersion,
              cache: cache,
              verboseHelp: false,
            );
            command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

            final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
            final String podspecContents = expectedPodspec.readAsStringSync();
            expect(podspecContents, contains("'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios/artifacts.zip'"));
          }, overrides: <Type, Generator>{
            FileSystem: () => memoryFileSystem,
            ProcessManager: () => FakeProcessManager.any(),
          });

          testUsingContext('profile URL', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              platform: fakePlatform,
              flutterVersion: fakeFlutterVersion,
              cache: cache,
              verboseHelp: false,
            );
            command.produceFlutterPodspec(BuildMode.profile, outputDirectory);

            final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
            final String podspecContents = expectedPodspec.readAsStringSync();
            expect(podspecContents, contains("'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios-profile/artifacts.zip'"));
          }, overrides: <Type, Generator>{
            FileSystem: () => memoryFileSystem,
            ProcessManager: () => FakeProcessManager.any(),
          });

          testUsingContext('release URL', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              platform: fakePlatform,
              flutterVersion: fakeFlutterVersion,
              cache: cache,
              verboseHelp: false,
            );
            command.produceFlutterPodspec(BuildMode.release, outputDirectory);

            final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
            final String podspecContents = expectedPodspec.readAsStringSync();
            expect(podspecContents, contains("'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios-release/artifacts.zip'"));
          }, overrides: <Type, Generator>{
            FileSystem: () => memoryFileSystem,
            ProcessManager: () => FakeProcessManager.any(),
          });
        });
      });
    });
  });
}
