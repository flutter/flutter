// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

typedef InvokeProcess = Future<ProcessResult> Function();

void main() {
  FileSystem fileSystem;
  ProcessManager mockProcessManager;
  MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
  FlutterProject projectUnderTest;
  CocoaPods cocoaPodsUnderTest;
  InvokeProcess resultOfPodVersion;
  BufferLogger logger;

  void pretendPodVersionFails() {
    resultOfPodVersion = () async => exitsWithError();
  }

  void pretendPodVersionIs(String versionText) {
    resultOfPodVersion = () async => exitsHappy(versionText);
  }

  void podsIsInHomeDir() {
    fileSystem.directory(fileSystem.path.join(
      '.cocoapods',
      'repos',
      'master',
    )).createSync(recursive: true);
  }

  String podsIsInCustomDir({String cocoapodsReposDir}) {
    cocoapodsReposDir ??= fileSystem.path.join(
      'cache',
      'cocoapods',
      'repos',
    );
    fileSystem.directory(fileSystem.path.join(cocoapodsReposDir, 'master')).createSync(recursive: true);
    return cocoapodsReposDir;
  }

  setUp(() async {
    Cache.flutterRoot = 'flutter';
    fileSystem = MemoryFileSystem.test();
    mockProcessManager = MockProcessManager();
    logger = BufferLogger.test();
    mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
    projectUnderTest = FlutterProject.fromDirectory(fileSystem.directory('project'));
    projectUnderTest.ios.xcodeProject.createSync(recursive: true);
    cocoaPodsUnderTest = CocoaPods(
      fileSystem: fileSystem,
      processManager: mockProcessManager,
      logger: logger,
      platform: FakePlatform(),
      xcodeProjectInterpreter: mockXcodeProjectInterpreter,
      timeoutConfiguration: const TimeoutConfiguration(),
    );
    pretendPodVersionIs('1.8.0');
    fileSystem.file(fileSystem.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-objc',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Objective-C iOS podfile template');
    fileSystem.file(fileSystem.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-swift',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Swift iOS podfile template');
    fileSystem.file(fileSystem.path.join(
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
    fileSystem.file('.packages').writeAsStringSync('\n');
  });

  void pretendPodIsNotInstalled() {
    when(mockProcessManager.run(
      <String>['which', 'pod'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) async => exitsWithError());
  }

  void pretendPodIsBroken() {
    // it is present
    when(mockProcessManager.run(
      <String>['which', 'pod'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((_) async => exitsHappy());

    // but is not working
    when(mockProcessManager.run(
      <String>['pod', '--version'],
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
    setUp(() {
      // Assume all binaries can run
      when(mockProcessManager.canRun(any)).thenReturn(true);
    });

    testWithoutContext('detects not installed, if pod exec does not exist', () async {
      pretendPodIsNotInstalled();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.notInstalled);
    });

    testWithoutContext('detects not installed, if pod is installed but version fails', () async {
      pretendPodIsInstalled();
      pretendPodVersionFails();
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.brokenInstall);
    });

    testWithoutContext('detects installed', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('0.0.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, isNot(CocoaPodsStatus.notInstalled));
    });

    testWithoutContext('detects unknown version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('Plugin loaded.\n1.5.3');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.unknownVersion);
    });

    testWithoutContext('detects below minimum version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.5.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowMinimumVersion);
    });

    testWithoutContext('detects below recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.6.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowRecommendedVersion);
    });

    testWithoutContext('detects at recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.8.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    });

    testWithoutContext('detects above recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.8.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    });

    testWithoutContext('detects initialized over 1.8.0', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.8.0');
      expect(await cocoaPodsUnderTest.isCocoaPodsInitialized, isTrue);
    });
  });

  group('Setup Podfile', () {
    setUp(() {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
    });

    testWithoutContext('creates objective-c Podfile when not present', () async {
      when(mockXcodeProjectInterpreter.getBuildSettings(any, scheme: null, timeout: anyNamed('timeout')))
        .thenAnswer((_) async => <String, String>{});
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Objective-C iOS podfile template');
    });

    testUsingContext('creates swift Podfile if swift', () async {
      when(mockXcodeProjectInterpreter.getBuildSettings(any, scheme: null, timeout: anyNamed('timeout')))
        .thenAnswer((_) async => <String, String>{
          'SWIFT_VERSION': '5.0',
        });

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Swift iOS podfile template');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });

    testWithoutContext('creates macOS Podfile when not present', () async {
      projectUnderTest.macos.xcodeProject.createSync(recursive: true);
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.macos);

      expect(projectUnderTest.macos.podfile.readAsStringSync(), 'macOS podfile template');
    });

    testUsingContext('does not recreate Podfile when already present', () async {
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Existing Podfile');
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('does not create Podfile when we cannot interpret Xcode projects', () async {
      when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

      final FlutterProject project = FlutterProject.fromPath('project');
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
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
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Update xcconfig', () {
    testUsingContext('includes Pod config in xcconfig files, if the user manually added Pod dependencies without using Flutter plugins', () async {
      globals.fs.file(globals.fs.path.join('project', 'foo', '.packages'))
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');
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
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Process pods', () {
    setUp(() {
      podsIsInHomeDir();
      // Assume all binaries can run
      when(mockProcessManager.canRun(any)).thenReturn(true);
    });

    testWithoutContext('throwsToolExit if CocoaPods is not installed', () async {
      pretendPodIsNotInstalled();
      projectUnderTest.ios.podfile.createSync();
      final Function invokeProcessPods = () async => await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(invokeProcessPods, throwsToolExit());
      verifyNever(mockProcessManager.run(
      argThat(containsAllInOrder(<String>['pod', 'install'])),
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
    });

    testWithoutContext('throwsToolExit if CocoaPods install is broken', () async {
      pretendPodIsBroken();
      projectUnderTest.ios.podfile.createSync();
      final Function invokeProcessPods = () async => await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(invokeProcessPods, throwsToolExit());
      verifyNever(mockProcessManager.run(
      argThat(containsAllInOrder(<String>['pod', 'install'])),
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
    });

    testWithoutContext('prints warning, if Podfile creates the Flutter engine symlink', () async {
      pretendPodIsInstalled();

      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      final Directory symlinks = projectUnderTest.ios.symlinks
        ..createSync(recursive: true);
      symlinks.childLink('flutter').createSync('cache');

      await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(logger.errorText, contains('Warning: Podfile is out of date'));
    });

    testWithoutContext('prints warning, if Podfile parses .flutter-plugins', () async {
      pretendPodIsInstalled();

      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('plugin_pods = parse_KV_file(\'../.flutter-plugins\')');

      await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        engineDir: 'engine/path',
      );
      expect(logger.errorText, contains('Warning: Podfile is out of date'));
    });

    testWithoutContext('throws, if Podfile is missing.', () async {
      pretendPodIsInstalled();
      try {
        await cocoaPodsUnderTest.processPods(
          xcodeProject: projectUnderTest.ios,
          engineDir: 'engine/path',
        );
        fail('ToolExit expected');
      } on Exception catch (e) {
        expect(e, isA<ToolExit>());
        verifyNever(mockProcessManager.run(
        argThat(containsAllInOrder(<String>['pod', 'install'])),
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        ));
      }
    });

    testWithoutContext('throws, if specs repo is outdated.', () async {
      pretendPodIsInstalled();
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
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
      } on Exception catch (e) {
        expect(e, isA<ToolExit>());
        expect(
          logger.errorText,
          contains("CocoaPods's specs repository is too out-of-date to satisfy dependencies"),
        );
      }
    });

    testWithoutContext('run pod install, if Podfile.lock is missing', () async {
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
    });

    testWithoutContext('runs pod install, if Manifest.lock is missing', () async {
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
    });

    testWithoutContext('runs pod install, if Manifest.lock different from Podspec.lock', () async {
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
    });

    testWithoutContext('runs pod install, if flutter framework changed', () async {
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
    });

    testWithoutContext('runs pod install, if Podfile.lock is older than Podfile', () async {
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
        .writeAsStringSync('Updated Podfile');
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
    });

    testWithoutContext('skips pod install, if nothing changed', () async {
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
    });

    testWithoutContext('a failed pod install deletes Pods/Manifest.lock', () async {
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
    });
  });

  group('Pods repos dir is custom', () {
    String cocoapodsRepoDir;
    Map<String, String> environment;
    setUp(() {
      // Assume binaries exist and can run
      when(mockProcessManager.canRun(any)).thenReturn(true);
      cocoapodsRepoDir = podsIsInCustomDir();
      environment = <String, String>{
        'FLUTTER_FRAMEWORK_DIR': 'engine/path',
        'COCOAPODS_DISABLE_STATS': 'true',
        'CP_REPOS_DIR': cocoapodsRepoDir,
        'LANG': 'en_US.UTF8',
      };
    });

    testWithoutContext('succeeds, if specs repo is in CP_REPOS_DIR.', () async {
      pretendPodIsInstalled();
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
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
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}

ProcessResult exitsWithError([ String stdout = '' ]) => ProcessResult(1, 1, stdout, '');
ProcessResult exitsHappy([ String stdout = '' ]) => ProcessResult(1, 0, stdout, '');
