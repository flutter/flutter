// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/ios/cocoapods.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

typedef InvokeProcess = Future<ProcessResult> Function();

void main() {
  FileSystem fs;
  ProcessManager mockProcessManager;
  MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
  FlutterProject projectUnderTest;
  CocoaPods cocoaPodsUnderTest;
  InvokeProcess resultOfPodVersion;

  void pretendPodIsNotInstalled() {
    resultOfPodVersion = () async => throw 'Executable does not exist';
  }

  void pretendPodVersionFails() {
    resultOfPodVersion = () async => exitsWithError();
  }

  void pretendPodVersionIs(String versionText) {
    resultOfPodVersion = () async => exitsHappy(versionText);
  }

  setUp(() async {
    Cache.flutterRoot = 'flutter';
    fs = MemoryFileSystem();
    mockProcessManager = MockProcessManager();
    mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
    projectUnderTest = await FlutterProject.fromDirectory(fs.directory('project'));
    projectUnderTest.ios.xcodeProject.createSync(recursive: true);
    cocoaPodsUnderTest = CocoaPods();
    pretendPodVersionIs('1.5.0');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-objc'
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Objective-C podfile template');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-swift'
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Swift podfile template');
    fs.directory(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master')).createSync(recursive: true);
    when(mockProcessManager.run(
      <String>['pod', '--version'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) => resultOfPodVersion());
    when(mockProcessManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: 'project/ios',
      environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
    )).thenAnswer((_) async => exitsHappy());
  });

  group('Evaluate installation', () {
    testUsingContext('detects not installed, if pod exec does not exist', () async {
      pretendPodIsNotInstalled();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.notInstalled);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects not installed, if pod version fails', () async {
      pretendPodVersionFails();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.notInstalled);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects installed', () async {
      pretendPodVersionIs('0.0.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, isNot(CocoaPodsStatus.notInstalled));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects below minimum version', () async {
      pretendPodVersionIs('0.39.8');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowMinimumVersion);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects below recommended version', () async {
      pretendPodVersionIs('1.4.99');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowRecommendedVersion);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects at recommended version', () async {
      pretendPodVersionIs('1.5.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects above recommended version', () async {
      pretendPodVersionIs('1.5.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('Setup Podfile', () {
    testUsingContext('creates objective-c Podfile when not present', () async {
      cocoaPodsUnderTest.setupPodfile(projectUnderTest.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Objective-C podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('creates swift Podfile if swift', () async {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.getBuildSettings(any, any)).thenReturn(<String, String>{
        'SWIFT_VERSION': '4.0',
      });

      final FlutterProject project = await FlutterProject.fromPath('project');
      cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Swift podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('does not recreate Podfile when already present', () async {
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      final FlutterProject project = await FlutterProject.fromPath('project');
      cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Existing Podfile');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('does not create Podfile when we cannot interpret Xcode projects', () async {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

      final FlutterProject project = await FlutterProject.fromPath('project');
      cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('includes Pod config in xcconfig files, if not present', () async {
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.xcodeConfigFor('Debug')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing debug config');
      projectUnderTest.ios.xcodeConfigFor('Release')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing release config');

      final FlutterProject project = await FlutterProject.fromPath('project');
      cocoaPodsUnderTest.setupPodfile(project.ios);

      final String debugContents = projectUnderTest.ios.xcodeConfigFor('Debug').readAsStringSync();
      expect(debugContents, contains(
          '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"\n'));
      expect(debugContents, contains('Existing debug config'));
      final String releaseContents = projectUnderTest.ios.xcodeConfigFor('Release').readAsStringSync();
      expect(releaseContents, contains(
          '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"\n'));
      expect(releaseContents, contains('Existing release config'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });

  group('Process pods', () {
    testUsingContext('prints error, if CocoaPods is not installed', () async {
      pretendPodIsNotInstalled();
      projectUnderTest.ios.podfile.createSync();
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
      );
      verifyNever(mockProcessManager.run(
      argThat(containsAllInOrder(<String>['pod', 'install'])),
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
      expect(testLogger.errorText, contains('not installed'));
      expect(testLogger.errorText, contains('Skipping pod install'));
      expect(didInstall, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('throws, if Podfile is missing.', () async {
      try {
        await cocoaPodsUnderTest.processPods(
          iosProject: projectUnderTest.ios,
          iosEngineDir: 'engine/path',
        );
        fail('ToolExit expected');
      } catch(e) {
        expect(e, isInstanceOf<ToolExit>());
        verifyNever(mockProcessManager.run(
        argThat(containsAllInOrder(<String>['pod', 'install'])),
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('throws, if specs repo is outdated.', () async {
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      when(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      )).thenAnswer((_) async => exitsWithError(
        '''
[!] Unable to satisfy the following requirements:

- `Firebase/Auth` required by `Podfile`
- `Firebase/Auth (= 4.0.0)` required by `Podfile.lock`

None of your spec sources contain a spec satisfying the dependencies: `Firebase/Auth, Firebase/Auth (= 4.0.0)`.

You have either:
 * out-of-date source repos which you can update with `pod repo update` or with `pod install --repo-update`.
 * mistyped the name or version.
 * not added the source repo that hosts the Podspec to your Podfile.

Note: as of CocoaPods 1.0, `pod repo update` does not happen on `pod install` by default.''',
      ));
      try {
        await cocoaPodsUnderTest.processPods(
          iosProject: projectUnderTest.ios,
          iosEngineDir: 'engine/path',
        );
        fail('ToolExit expected');
      } catch (e) {
        expect(e, isInstanceOf<ToolExit>());
        expect(
          testLogger.errorText,
          contains("CocoaPods's specs repository is too out-of-date to satisfy dependencies"),
        );
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('run pod install, if Podfile.lock is missing', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Manifest.lock is missing', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Manifest.lock different from Podspec.lock', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Different lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if flutter framework changed', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: true,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Podfile.lock is older than Podfile', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      projectUnderTest.ios.podfile
        ..writeAsStringSync('Updated Podfile');
      await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: false,
      );
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('skips pod install, if nothing changed', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        iosProject: projectUnderTest.ios,
        iosEngineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isFalse);
      verifyNever(mockProcessManager.run(
      argThat(containsAllInOrder(<String>['pod', 'install'])),
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('a failed pod install deletes Pods/Manifest.lock', () async {
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');

      when(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
        },
      )).thenAnswer(
        (_) async => exitsWithError()
      );

      try {
        await cocoaPodsUnderTest.processPods(
          iosProject: projectUnderTest.ios,
          iosEngineDir: 'engine/path',
          dependenciesChanged: true,
        );
        fail('Tool throw expected when pod install fails');
      } on ToolExit {
        expect(projectUnderTest.ios.podManifestLock.existsSync(), isFalse);
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}

ProcessResult exitsWithError([String stdout = '']) => ProcessResult(1, 1, stdout, '');
ProcessResult exitsHappy([String stdout = '']) => ProcessResult(1, 0, stdout, '');
