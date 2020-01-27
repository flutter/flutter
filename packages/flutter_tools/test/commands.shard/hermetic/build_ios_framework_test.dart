// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/aot.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_ios_framework.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('build ios-framework', () {
    MemoryFileSystem memoryFileSystem;
    MockFlutterVersion mockFlutterVersion;
    MockGitTagVersion mockGitTagVersion;
    MockCache mockCache;
    Directory outputDirectory;
    FakePlatform fakePlatform;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      mockFlutterVersion = MockFlutterVersion();
      mockGitTagVersion = MockGitTagVersion();
      mockCache = MockCache();
      fakePlatform = FakePlatform()..operatingSystem = 'macos';

      when(mockFlutterVersion.gitTagVersion).thenReturn(mockGitTagVersion);
      outputDirectory = globals.fs.systemTempDirectory
          .createTempSync('flutter_build_ios_framework_test_output.')
          .childDirectory('Debug')
        ..createSync();
    });

    group('podspec', () {
      const String storageBaseUrl = 'https://fake.googleapis.com';
      const String engineRevision = '0123456789abcdef';
      File licenseFile;

      setUp(() {
        when(mockFlutterVersion.gitTagVersion).thenReturn(mockGitTagVersion);
        when(mockCache.storageBaseUrl).thenReturn(storageBaseUrl);
        when(mockCache.engineRevision).thenReturn(engineRevision);
        licenseFile = memoryFileSystem.file('LICENSE');
        when(mockCache.getLicenseFile()).thenReturn(licenseFile);
      });

      testUsingContext('version unknown', () async {
        const String frameworkVersion = '0.0.0-unknown';
        when(mockFlutterVersion.frameworkVersion).thenReturn(frameworkVersion);

        final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
          aotBuilder: MockAotBuilder(),
          bundleBuilder: MockBundleBuilder(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
          cache: mockCache
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
          aotBuilder: MockAotBuilder(),
          bundleBuilder: MockBundleBuilder(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
          cache: mockCache
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
          aotBuilder: MockAotBuilder(),
          bundleBuilder: MockBundleBuilder(),
          platform: fakePlatform,
          flutterVersion: mockFlutterVersion,
          cache: mockCache
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
          when(mockGitTagVersion.commits).thenReturn(0);

          when(mockFlutterVersion.frameworkVersion).thenReturn(frameworkVersion);

          licenseFile
            ..createSync(recursive: true)
            ..writeAsStringSync(licenseText);
        });

        testUsingContext('contains license and version', () async {
          final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
            aotBuilder: MockAotBuilder(),
            bundleBuilder: MockBundleBuilder(),
            platform: fakePlatform,
            flutterVersion: mockFlutterVersion,
            cache: mockCache
          );
          command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

          final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
          final String podspecContents = expectedPodspec.readAsStringSync();
          expect(podspecContents, contains('\'1.13.1113\''));
          expect(podspecContents, contains('# $frameworkVersion'));
          expect(podspecContents, contains(licenseText));
        }, overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        });

        testUsingContext('debug URL', () async {
          final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
            aotBuilder: MockAotBuilder(),
            bundleBuilder: MockBundleBuilder(),
            platform: fakePlatform,
            flutterVersion: mockFlutterVersion,
            cache: mockCache
          );
          command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

          final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
          final String podspecContents = expectedPodspec.readAsStringSync();
          expect(podspecContents, contains('\'$storageBaseUrl/flutter_infra/flutter/$engineRevision/ios/artifacts.zip\''));
        }, overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        });

        testUsingContext('profile URL', () async {
          final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
            aotBuilder: MockAotBuilder(),
            bundleBuilder: MockBundleBuilder(),
            platform: fakePlatform,
            flutterVersion: mockFlutterVersion,
            cache: mockCache
          );
          command.produceFlutterPodspec(BuildMode.profile, outputDirectory);

          final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
          final String podspecContents = expectedPodspec.readAsStringSync();
          expect(podspecContents, contains('\'$storageBaseUrl/flutter_infra/flutter/$engineRevision/ios-profile/artifacts.zip\''));
        }, overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        });

        testUsingContext('release URL', () async {
          final BuildIOSFrameworkCommand command = BuildIOSFrameworkCommand(
            aotBuilder: MockAotBuilder(),
            bundleBuilder: MockBundleBuilder(),
            platform: fakePlatform,
            flutterVersion: mockFlutterVersion,
            cache: mockCache
          );
          command.produceFlutterPodspec(BuildMode.release, outputDirectory);

          final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
          final String podspecContents = expectedPodspec.readAsStringSync();
          expect(podspecContents, contains('\'$storageBaseUrl/flutter_infra/flutter/$engineRevision/ios-release/artifacts.zip\''));
        }, overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        });
      });
    });
  });
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockGitTagVersion extends Mock implements GitTagVersion {}
class MockCache extends Mock implements Cache {}
class MockAotBuilder extends Mock implements AotBuilder {}
class MockBundleBuilder extends Mock implements BundleBuilder {}
