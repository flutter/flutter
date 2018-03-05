// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

const String xcodebuild = '/usr/bin/xcodebuild';

void main() {
  group('xcodebuild versioning', () {
    MockProcessManager mockProcessManager;
    XcodeProjectInterpreter xcodeProjectInterpreter;
    FakePlatform macOS;
    FileSystem fs;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      xcodeProjectInterpreter = new XcodeProjectInterpreter();
      macOS = fakePlatform('macos');
      fs = new MemoryFileSystem();
      fs.file(xcodebuild).createSync(recursive: true);
    });

    void testUsingOsxContext(String description, dynamic testMethod()) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        Platform: () => macOS,
        FileSystem: () => fs,
      });
    }

    testUsingOsxContext('versionText returns null when xcodebuild is not installed', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenThrow(const ProcessException(xcodebuild, const <String>['-version']));
      expect(xcodeProjectInterpreter.versionText, isNull);
    });

    testUsingOsxContext('versionText returns null when xcodebuild is not fully installed', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
        new ProcessResult(
          0,
          1,
          "xcode-select: error: tool 'xcodebuild' requires Xcode, "
          "but active developer directory '/Library/Developer/CommandLineTools' "
          'is a command line tools instance',
          '',
        ),
      );
      expect(xcodeProjectInterpreter.versionText, isNull);
    });

    testUsingOsxContext('versionText returns formatted version text', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.versionText, 'Xcode 8.3.3, Build version 8E3004b');
    });

    testUsingOsxContext('versionText handles Xcode version string with unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.versionText, 'Xcode Ultra5000, Build version 8E3004b');
    });

    testUsingOsxContext('majorVersion returns major version', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.majorVersion, 8);
    });

    testUsingOsxContext('majorVersion is null when version has unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.majorVersion, isNull);
    });

    testUsingOsxContext('minorVersion returns minor version', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, 3);
    });

    testUsingOsxContext('minorVersion returns 0 when minor version is unspecified', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode 8\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, 0);
    });

    testUsingOsxContext('minorVersion is null when version has unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, isNull);
    });

    testUsingContext('isInstalled is false when not on MacOS', () {
      fs.file(xcodebuild).deleteSync();
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    }, overrides: <Type, Generator>{
      Platform: () => fakePlatform('notMacOS')
    });

    testUsingOsxContext('isInstalled is false when xcodebuild does not exist', () {
      fs.file(xcodebuild).deleteSync();
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    });

    testUsingOsxContext('isInstalled is false when Xcode is not fully installed', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
        new ProcessResult(
          0,
          1,
          "xcode-select: error: tool 'xcodebuild' requires Xcode, "
          "but active developer directory '/Library/Developer/CommandLineTools' "
          'is a command line tools instance',
          '',
        ),
      );
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    });

    testUsingOsxContext('isInstalled is false when version has unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    });

    testUsingOsxContext('isInstalled is true when version has expected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(new ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.isInstalled, isTrue);
    });
  });
  group('Xcode project properties', () {
    test('properties from default project can be parsed', () {
      const String output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        Runner

''';
      final XcodeProjectInfo info = new XcodeProjectInfo.fromXcodeBuildOutput(output);
      expect(info.targets, <String>['Runner']);
      expect(info.schemes, <String>['Runner']);
      expect(info.buildConfigurations, <String>['Debug', 'Release']);
    });
    test('properties from project with custom schemes can be parsed', () {
      const String output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug (Free)
        Debug (Paid)
        Release (Free)
        Release (Paid)

    If no build configuration is specified and -scheme is not passed then "Release (Free)" is used.

    Schemes:
        Free
        Paid

''';
      final XcodeProjectInfo info = new XcodeProjectInfo.fromXcodeBuildOutput(output);
      expect(info.targets, <String>['Runner']);
      expect(info.schemes, <String>['Free', 'Paid']);
      expect(info.buildConfigurations, <String>['Debug (Free)', 'Debug (Paid)', 'Release (Free)', 'Release (Paid)']);
    });
    test('expected scheme for non-flavored build is Runner', () {
      expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.debug), 'Runner');
      expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.profile), 'Runner');
      expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.release), 'Runner');
    });
    test('expected build configuration for non-flavored build is derived from BuildMode', () {
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.profile, 'Runner'), 'Release');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
    });
    test('expected scheme for flavored build is the title-cased flavor', () {
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.debug, 'hello')), 'Hello');
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.profile, 'HELLO')), 'HELLO');
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.release, 'Hello')), 'Hello');
    });
    test('expected build configuration for flavored build is Mode-Flavor', () {
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.debug, 'hello'), 'Hello'), 'Debug-Hello');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.profile, 'HELLO'), 'Hello'), 'Release-Hello');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.release, 'Hello'), 'Hello'), 'Release-Hello');
    });
    test('scheme for default project is Runner', () {
      final XcodeProjectInfo info = new XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>['Runner']);
      expect(info.schemeFor(BuildInfo.debug), 'Runner');
      expect(info.schemeFor(BuildInfo.profile), 'Runner');
      expect(info.schemeFor(BuildInfo.release), 'Runner');
      expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'unknown')), isNull);
    });
    test('build configuration for default project is matched against BuildMode', () {
      final XcodeProjectInfo info = new XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>['Runner']);
      expect(info.buildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
      expect(info.buildConfigurationFor(BuildInfo.profile, 'Runner'), 'Release');
      expect(info.buildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
    });
    test('scheme for project with custom schemes is matched against flavor', () {
      final XcodeProjectInfo info = new XcodeProjectInfo(
        <String>['Runner'],
        <String>['Debug (Free)', 'Debug (Paid)', 'Release (Free)', 'Release (Paid)'],
        <String>['Free', 'Paid'],
      );
      expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'free')), 'Free');
      expect(info.schemeFor(const BuildInfo(BuildMode.profile, 'Free')), 'Free');
      expect(info.schemeFor(const BuildInfo(BuildMode.release, 'paid')), 'Paid');
      expect(info.schemeFor(const BuildInfo(BuildMode.debug, null)), isNull);
      expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'unknown')), isNull);
    });
    test('build configuration for project with custom schemes is matched against BuildMode and flavor', () {
      final XcodeProjectInfo info = new XcodeProjectInfo(
        <String>['Runner'],
        <String>['debug (free)', 'Debug paid', 'release - Free', 'Release-Paid'],
        <String>['Free', 'Paid'],
      );
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'free'), 'Free'), 'debug (free)');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Paid'), 'Paid'), 'Debug paid');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'FREE'), 'Free'), 'release - Free');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'paid'), 'Paid'), 'Release-Paid');
    });
    test('build configuration for project with inconsistent naming is null', () {
      final XcodeProjectInfo info = new XcodeProjectInfo(
        <String>['Runner'],
        <String>['Debug-F', 'Dbg Paid', 'Rel Free', 'Release Full'],
        <String>['Free', 'Paid'],
      );
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Free'), 'Free'), null);
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'Free'), 'Free'), null);
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'Paid'), 'Paid'), null);
    });
  });
}

Platform fakePlatform(String name) {
  return new FakePlatform.fromPlatform(const LocalPlatform())..operatingSystem = name;
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter { }
