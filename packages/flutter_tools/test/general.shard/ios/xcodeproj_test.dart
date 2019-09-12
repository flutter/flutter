// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' as mocks;
import '../../src/pubspec_schema.dart';

const String xcodebuild = '/usr/bin/xcodebuild';

void main() {
  group('xcodebuild versioning', () {
    mocks.MockProcessManager mockProcessManager;
    XcodeProjectInterpreter xcodeProjectInterpreter;
    FakePlatform macOS;
    FileSystem fs;

    setUp(() {
      mockProcessManager = mocks.MockProcessManager();
      xcodeProjectInterpreter = XcodeProjectInterpreter();
      macOS = fakePlatform('macos');
      fs = MemoryFileSystem();
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
          .thenThrow(const ProcessException(xcodebuild, <String>['-version']));
      expect(xcodeProjectInterpreter.versionText, isNull);
    });

    testUsingOsxContext('versionText returns null when xcodebuild is not fully installed', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
        ProcessResult(
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
          .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.versionText, 'Xcode 8.3.3, Build version 8E3004b');
    });

    testUsingOsxContext('versionText handles Xcode version string with unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.versionText, 'Xcode Ultra5000, Build version 8E3004b');
    });

    testUsingOsxContext('majorVersion returns major version', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.majorVersion, 8);
    });

    testUsingOsxContext('majorVersion is null when version has unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.majorVersion, isNull);
    });

    testUsingOsxContext('minorVersion returns minor version', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, 3);
    });

    testUsingOsxContext('minorVersion returns 0 when minor version is unspecified', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode 8\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, 0);
    });

    testUsingOsxContext('minorVersion is null when version has unexpected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.minorVersion, isNull);
    });

    testUsingContext('isInstalled is false when not on MacOS', () {
      fs.file(xcodebuild).deleteSync();
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    }, overrides: <Type, Generator>{
      Platform: () => fakePlatform('notMacOS'),
    });

    testUsingOsxContext('isInstalled is false when xcodebuild does not exist', () {
      fs.file(xcodebuild).deleteSync();
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    });

    testUsingOsxContext('isInstalled is false when Xcode is not fully installed', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
        ProcessResult(
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
          .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.isInstalled, isFalse);
    });

    testUsingOsxContext('isInstalled is true when version has expected format', () {
      when(mockProcessManager.runSync(<String>[xcodebuild, '-version']))
          .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));
      expect(xcodeProjectInterpreter.isInstalled, isTrue);
    });

    testUsingOsxContext('build settings is empty when xcodebuild failed to get the build settings', () {
      when(mockProcessManager.runSync(
               argThat(contains(xcodebuild)),
               workingDirectory: anyNamed('workingDirectory'),
               environment: anyNamed('environment')))
          .thenReturn(ProcessResult(0, 1, '', ''));
      expect(xcodeProjectInterpreter.getBuildSettings('', ''), const <String, String>{});
    });

    testUsingContext('build settings flakes', () async {
      const Duration delay = Duration(seconds: 1);
      mockProcessManager.processFactory = mocks.flakyProcessFactory(
        flakes: 1,
        delay: delay + const Duration(seconds: 1),
      );
      expect(await xcodeProjectInterpreter.getBuildSettingsAsync(
                 '', '', timeout: delay),
             const <String, String>{});
      // build settings times out and is killed once, then succeeds.
      verify(mockProcessManager.killPid(any)).called(1);
      // The verbose logs should tell us something timed out.
      expect(testLogger.traceText, contains('timed out'));
    }, overrides: <Type, Generator>{
      Platform: () => macOS,
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
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
      final XcodeProjectInfo info = XcodeProjectInfo.fromXcodeBuildOutput(output);
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
      final XcodeProjectInfo info = XcodeProjectInfo.fromXcodeBuildOutput(output);
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
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.profile, 'Runner'), 'Profile');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
    });
    test('expected scheme for flavored build is the title-cased flavor', () {
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.debug, 'hello')), 'Hello');
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.profile, 'HELLO')), 'HELLO');
      expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.release, 'Hello')), 'Hello');
    });
    test('expected build configuration for flavored build is Mode-Flavor', () {
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.debug, 'hello'), 'Hello'), 'Debug-Hello');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.profile, 'HELLO'), 'Hello'), 'Profile-Hello');
      expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.release, 'Hello'), 'Hello'), 'Release-Hello');
    });
    test('scheme for default project is Runner', () {
      final XcodeProjectInfo info = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>['Runner']);
      expect(info.schemeFor(BuildInfo.debug), 'Runner');
      expect(info.schemeFor(BuildInfo.profile), 'Runner');
      expect(info.schemeFor(BuildInfo.release), 'Runner');
      expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'unknown')), isNull);
    });
    test('build configuration for default project is matched against BuildMode', () {
      final XcodeProjectInfo info = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Profile', 'Release'], <String>['Runner']);
      expect(info.buildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
      expect(info.buildConfigurationFor(BuildInfo.profile, 'Runner'), 'Profile');
      expect(info.buildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
    });
    test('scheme for project with custom schemes is matched against flavor', () {
      final XcodeProjectInfo info = XcodeProjectInfo(
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
      final XcodeProjectInfo info = XcodeProjectInfo(
        <String>['Runner'],
        <String>['debug (free)', 'Debug paid', 'profile - Free', 'Profile-Paid', 'release - Free', 'Release-Paid'],
        <String>['Free', 'Paid'],
      );
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'free'), 'Free'), 'debug (free)');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Paid'), 'Paid'), 'Debug paid');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'FREE'), 'Free'), 'profile - Free');
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'paid'), 'Paid'), 'Release-Paid');
    });
    test('build configuration for project with inconsistent naming is null', () {
      final XcodeProjectInfo info = XcodeProjectInfo(
        <String>['Runner'],
        <String>['Debug-F', 'Dbg Paid', 'Rel Free', 'Release Full'],
        <String>['Free', 'Paid'],
      );
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Free'), 'Free'), null);
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'Free'), 'Free'), null);
      expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'Paid'), 'Paid'), null);
    });
  });

  group('updateGeneratedXcodeProperties', () {
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform macOS;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      macOS = fakePlatform('macos');
      fs.file(xcodebuild).createSync(recursive: true);
    });

    void testUsingOsxContext(String description, dynamic testMethod()) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        ProcessManager: () => mockProcessManager,
        Platform: () => macOS,
        FileSystem: () => fs,
      });
    }

    testUsingOsxContext('sets ARCHS=armv7 when armv7 local engine is set', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));

      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('ARCHS=armv7'), isTrue);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('ARCHS=armv7'), isTrue);
    });

    testUsingOsxContext('sets TRACK_WIDGET_CREATION=true when trackWidgetCreation is true', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, trackWidgetCreation: true);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('TRACK_WIDGET_CREATION=true'), isTrue);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isTrue);
    });

    testUsingOsxContext('does not set TRACK_WIDGET_CREATION when trackWidgetCreation is false', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('TRACK_WIDGET_CREATION=true'), isFalse);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isFalse);
    });

    testUsingOsxContext('sets ARCHS=armv7 when armv7 local engine is set', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null);

      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('ARCHS=arm64'), isTrue);
    });

    String propertyFor(String key, File file) {
      final List<String> properties = file
          .readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1])
          .toList();
      return properties.isEmpty ? null : properties.first;
    }

    Future<void> checkBuildVersion({
      String manifestString,
      BuildInfo buildInfo,
      String expectedBuildName,
      String expectedBuildNumber,
    }) async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios'));

      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifestString);

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);

      await updateGeneratedXcodeProperties(
        project: FlutterProject.fromPath('path/to/project'),
        buildInfo: buildInfo,
      );

      final File localPropertiesFile = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(propertyFor('FLUTTER_BUILD_NAME', localPropertiesFile), expectedBuildName);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), expectedBuildNumber);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), isNotNull);
    }

    testUsingOsxContext('extract build name and number from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext('extract build name from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1.0.0',
      );
    });

    testUsingOsxContext('allow build info to override build name', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext('allow build info to override build name with build number fallback', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1.0.2',
      );
    });

    testUsingOsxContext('allow build info to override build number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildNumber: '3');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and set number', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to set build name and number', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });
  });
}

Platform fakePlatform(String name) {
  return FakePlatform.fromPlatform(const LocalPlatform())..operatingSystem = name;
}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter { }
