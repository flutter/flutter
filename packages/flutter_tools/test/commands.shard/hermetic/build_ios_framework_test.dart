// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_ios_framework.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('build ios-framework', () {
    MemoryFileSystem memoryFileSystem;
    MockFlutterVersion mockFlutterVersion;
    MockGitTagVersion mockGitTagVersion;
    Directory outputDirectory;
    FakePlatform fakePlatform;

    setUpAll(() {
      Cache.disableLocking();
    });

    const String storageBaseUrl = 'https://fake.googleapis.com';
    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      mockFlutterVersion = MockFlutterVersion();
      mockGitTagVersion = MockGitTagVersion();
      fakePlatform = FakePlatform(
        operatingSystem: 'macos',
        environment: <String, String>{
          'FLUTTER_STORAGE_BASE_URL': storageBaseUrl,
        },
      );

      when(mockFlutterVersion.gitTagVersion).thenReturn(mockGitTagVersion);
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
        );
        rootOverride.childDirectory('bin').childDirectory('internal').childFile('engine.version')
          ..createSync(recursive: true)
          ..writeAsStringSync(engineRevision);
        when(mockFlutterVersion.gitTagVersion).thenReturn(mockGitTagVersion);
      });

      testUsingContext('version unknown', () async {
        const String frameworkVersion = '0.0.0-unknown';
        when(mockFlutterVersion.frameworkVersion).thenReturn(frameworkVersion);

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: MockBuildSystem(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
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
        when(mockFlutterVersion.frameworkVersion).thenReturn(frameworkVersion);

        when(mockGitTagVersion.x).thenReturn(1);
        when(mockGitTagVersion.y).thenReturn(13);
        when(mockGitTagVersion.z).thenReturn(10);
        when(mockGitTagVersion.hotfix).thenReturn(13);
        when(mockGitTagVersion.commits).thenReturn(2);

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: MockBuildSystem(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
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
        when(mockGitTagVersion.x).thenReturn(1);
        when(mockGitTagVersion.y).thenReturn(13);
        when(mockGitTagVersion.z).thenReturn(10);
        when(mockGitTagVersion.hotfix).thenReturn(13);
        when(mockGitTagVersion.commits).thenReturn(0);

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          buildSystem: MockBuildSystem(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
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
          when(mockGitTagVersion.x).thenReturn(1);
          when(mockGitTagVersion.y).thenReturn(13);
          when(mockGitTagVersion.z).thenReturn(11);
          when(mockGitTagVersion.hotfix).thenReturn(13);

          when(mockFlutterVersion.frameworkVersion).thenReturn(frameworkVersion);

          cache.getLicenseFile()
            ..createSync(recursive: true)
            ..writeAsStringSync(licenseText);
        });

        group('on master channel', () {
          setUp(() {
            when(mockGitTagVersion.commits).thenReturn(100);
          });

          testUsingContext('created when forced', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: MockBuildSystem(),
              platform: fakePlatform,
              flutterVersion: mockFlutterVersion,
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
          setUp(() {
            when(mockGitTagVersion.commits).thenReturn(0);
          });

          testUsingContext('contains license and version', () async {
            final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
              buildSystem: MockBuildSystem(),
              platform: fakePlatform,
              flutterVersion: mockFlutterVersion,
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
              buildSystem: MockBuildSystem(),
              platform: fakePlatform,
              flutterVersion: mockFlutterVersion,
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
              buildSystem: MockBuildSystem(),
              platform: fakePlatform,
              flutterVersion: mockFlutterVersion,
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
              buildSystem: MockBuildSystem(),
              platform: fakePlatform,
              flutterVersion: mockFlutterVersion,
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

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockGitTagVersion extends Mock implements GitTagVersion {}
class MockBuildSystem extends Mock implements BuildSystem {}
