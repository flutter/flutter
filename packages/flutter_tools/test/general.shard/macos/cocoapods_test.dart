// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';

typedef InvokeProcess = Future<ProcessResult> Function();

void main() {
  FileSystem fs;
  ProcessManager mockProcessManager;
  MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
  FlutterProject projectUnderTest;
  CocoaPods cocoaPodsUnderTest;
  InvokeProcess resultOfPodVersion;

  void pretendPodVersionFails() {
    resultOfPodVersion = () async => exitsWithError();
  }

  void pretendPodVersionIs(String versionText) {
    resultOfPodVersion = () async => exitsHappy(versionText);
  }

  void podsIsInHomeDir() {
    fs.directory(fs.path.join(
      globals.fsUtils.homeDirPath,
      '.cocoapods',
      'repos',
      'master',
    )).createSync(recursive: true);
  }

  String podsIsInCustomDir({String cocoapodsReposDir}) {
    cocoapodsReposDir ??= fs.path.join(
      globals.fsUtils.homeDirPath,
      'cache',
      'cocoapods',
      'repos',
    );
    fs.directory(fs.path.join(cocoapodsReposDir, 'master')).createSync(recursive: true);
    return cocoapodsReposDir;
  }

  setUp(() async {
    Cache.flutterRoot = 'flutter';
    fs = MemoryFileSystem();
    mockProcessManager = MockProcessManager();
    mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
    projectUnderTest = FlutterProject.fromDirectory(fs.directory('project'));
    projectUnderTest.ios.xcodeProject.createSync(recursive: true);
    cocoaPodsUnderTest = CocoaPods();
    pretendPodVersionIs('1.6.0');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-objc',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Objective-C iOS podfile template');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-swift',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Swift iOS podfile template');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-macos',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('macOS podfile template');
    when(mockProcessManager.run(
      <String>['pod', '--version'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) => resultOfPodVersion());
    when(mockProcessManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: 'project/ios',
      environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
    )).thenAnswer((_) async => exitsHappy());
    when(mockProcessManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: 'project/macos',
      environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
    )).thenAnswer((_) async => exitsHappy());
  });

  void pretendPodIsNotInstalled() {
    when(mockProcessManager.run(
      <String>['which', 'pod'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) async => exitsWithError());
  }

  void pretendPodIsInstalled() {
    when(mockProcessManager.run(
      <String>['which', 'pod'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) async => exitsHappy());
  }

  group('Evaluate installation', () {
    testUsingContext('detects not installed, if pod exec does not exist', () async {
      pretendPodIsNotInstalled();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.notInstalled);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects not installed, if pod is installed but version fails', () async {
      pretendPodIsInstalled();
      pretendPodVersionFails();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.brokenInstall);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects installed', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('0.0.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, isNot(CocoaPodsStatus.notInstalled));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects unknown version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('Plugin loaded.\n1.5.3');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.unknownVersion);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects below minimum version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.5.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowMinimumVersion);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects at recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.6.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects above recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.6.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('detects initialized over 1.8.0', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.8.0');
      expect(await cocoaPodsUnderTest.isCocoaPodsInitialized, isTrue);
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(),
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });
  });

  group('Setup Podfile', () {
    testUsingContext('creates objective-c Podfile when not present', () async {
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Objective-C iOS podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('creates swift Podfile if swift', () async {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
      when(mockXcodeProjectInterpreter.getBuildSettings(any, any))
        .thenAnswer((_) async => <String, String>{
          'SWIFT_VERSION': '5.0',
        });

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Swift iOS podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testUsingContext('creates macOS Podfile when not present', () async {
      projectUnderTest.macos.xcodeProject.createSync(recursive: true);
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.macos);

      expect(projectUnderTest.macos.podfile.readAsStringSync(), 'macOS podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('does not recreate Podfile when already present', () async {
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Existing Podfile');
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('does not create Podfile when we cannot interpret Xcode projects', () async {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
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

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

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
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Update xcconfig', () {
    testUsingContext('includes Pod config in xcconfig files, if the user manually added Pod dependencies without using Flutter plugins', () async {
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Custom Podfile');
      projectUnderTest.ios.podfileLock..createSync()..writeAsStringSync('Podfile.lock from user executed `pod install`');
      projectUnderTest.packagesFile..createSync()..writeAsStringSync('');
      projectUnderTest.ios.xcodeConfigFor('Debug')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing debug config');
      projectUnderTest.ios.xcodeConfigFor('Release')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing release config');

      final FlutterProject project = FlutterProject.fromPath('project');
      await injectPlugins(project, checkProjects: true);

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
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Process pods', () {
    setUp(() {
      podsIsInHomeDir();
    });

    testUsingContext('prints error, if CocoaPods is not installed', () async {
      pretendPodIsNotInstalled();
      projectUnderTest.ios.podfile.createSync();
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
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

    testUsingContext('prints warning, if Podfile is out of date', () async {
      pretendPodIsInstalled();

      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      final Directory symlinks = projectUnderTest.ios.symlinks
        ..createSync(recursive: true);
      symlinks.childLink('flutter').createSync('cache');

      await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(testLogger.errorText, contains('Warning: Podfile is out of date'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('throws, if Podfile is missing.', () async {
      pretendPodIsInstalled();
      try {
        await cocoaPodsUnderTest.processPods(
          xcodeProject: projectUnderTest.ios,
          engineDir: 'engine/path',
        );
        fail('ToolExit expected');
      } catch(e) {
        expect(e, isA<ToolExit>());
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
      pretendPodIsInstalled();
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      when(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
          'LANG': 'en_US.UTF-8',
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
          xcodeProject: projectUnderTest.ios,
          engineDir: 'engine/path',
        );
        fail('ToolExit expected');
      } catch (e) {
        expect(e, isA<ToolExit>());
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
      pretendPodIsInstalled();
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Manifest.lock is missing', () async {
      pretendPodIsInstalled();
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
          'LANG': 'en_US.UTF-8',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Manifest.lock different from Podspec.lock', () async {
      pretendPodIsInstalled();
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
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
          'LANG': 'en_US.UTF-8',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if flutter framework changed', () async {
      pretendPodIsInstalled();
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
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
        dependenciesChanged: true,
      );
      expect(didInstall, isTrue);
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
          'LANG': 'en_US.UTF-8',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('runs pod install, if Podfile.lock is older than Podfile', () async {
      pretendPodIsInstalled();
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
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
        dependenciesChanged: false,
      );
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{
          'FLUTTER_FRAMEWORK_DIR': 'engine/path',
          'COCOAPODS_DISABLE_STATS': 'true',
          'LANG': 'en_US.UTF-8',
        },
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('skips pod install, if nothing changed', () async {
      pretendPodIsInstalled();
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
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
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
      pretendPodIsInstalled();
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
          'LANG': 'en_US.UTF-8',
        },
      )).thenAnswer(
        (_) async => exitsWithError()
      );

      try {
        await cocoaPodsUnderTest.processPods(
          xcodeProject: projectUnderTest.ios,
          engineDir: 'engine/path',
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

  group('Pods repos dir is custom', () {
    String cocoapodsRepoDir;
    Map<String, String> environment;
    setUp(() {
      cocoapodsRepoDir = podsIsInCustomDir();
      environment = <String, String>{
        'FLUTTER_FRAMEWORK_DIR': 'engine/path',
        'COCOAPODS_DISABLE_STATS': 'true',
        'CP_REPOS_DIR': cocoapodsRepoDir,
        'LANG': 'en_US.UTF8',
      };
    });

    testUsingContext('succeeds, if specs repo is in CP_REPOS_DIR.', () async {
      pretendPodIsInstalled();
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      when(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: environment,
      )).thenAnswer((_) async => exitsHappy());
      final bool success = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(success, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(environment: environment),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}

ProcessResult exitsWithError([ String stdout = '' ]) => ProcessResult(1, 1, stdout, '');
ProcessResult exitsHappy([ String stdout = '' ]) => ProcessResult(1, 0, stdout, '');
