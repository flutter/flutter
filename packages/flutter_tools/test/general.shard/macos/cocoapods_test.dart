// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

void main() {
  late FileSystem fileSystem;
  late FakeProcessManager fakeProcessManager;
  late CocoaPods cocoaPodsUnderTest;
  late BufferLogger logger;
  late TestUsage usage;

  void pretendPodVersionFails() {
    fakeProcessManager.addCommand(
      const FakeCommand(
        command: <String>['pod', '--version'],
        exitCode: 1,
      ),
    );
  }

  void pretendPodVersionIs(String versionText) {
    fakeProcessManager.addCommand(
      FakeCommand(
        command: const <String>['pod', '--version'],
        stdout: versionText,
      ),
    );
  }

  void podsIsInHomeDir() {
    fileSystem.directory(fileSystem.path.join(
      '.cocoapods',
      'repos',
      'master',
    )).createSync(recursive: true);
  }

  FlutterProject setupProjectUnderTest() {
    // This needs to be run within testWithoutContext and not setUp since FlutterProject uses context.
    final FlutterProject projectUnderTest = FlutterProject.fromDirectory(fileSystem.directory('project'));
    projectUnderTest.ios.xcodeProject.createSync(recursive: true);
    projectUnderTest.macos.xcodeProject.createSync(recursive: true);
    return projectUnderTest;
  }

  setUp(() async {
    Cache.flutterRoot = 'flutter';
    fileSystem = MemoryFileSystem.test();
    fakeProcessManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    usage = TestUsage();
    cocoaPodsUnderTest = CocoaPods(
      fileSystem: fileSystem,
      processManager: fakeProcessManager,
      logger: logger,
      platform: FakePlatform(operatingSystem: 'macos'),
      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
      usage: usage,
    );
    fileSystem.file(fileSystem.path.join(
      Cache.flutterRoot!, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-objc',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Objective-C iOS podfile template');
    fileSystem.file(fileSystem.path.join(
      Cache.flutterRoot!, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-ios-swift',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Swift iOS podfile template');
    fileSystem.file(fileSystem.path.join(
      Cache.flutterRoot!, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-macos',
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('macOS podfile template');
  });

  void pretendPodIsNotInstalled() {
    fakeProcessManager.addCommand(
      const FakeCommand(
        command: <String>['which', 'pod'],
        exitCode: 1,
      ),
    );
  }

  void pretendPodIsBroken() {
    fakeProcessManager.addCommands(<FakeCommand>[
      // it is present
      const FakeCommand(
        command: <String>['which', 'pod'],
      ),
      // but is not working
      const FakeCommand(
        command: <String>['pod', '--version'],
        exitCode: 1,
      ),
    ]);
  }

  void pretendPodIsInstalled() {
    fakeProcessManager.addCommands(<FakeCommand>[
      const FakeCommand(
        command: <String>['which', 'pod'],
      ),
    ]);
  }

  group('Evaluate installation', () {
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
      pretendPodVersionIs('1.9.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowMinimumVersion);
    });

    testWithoutContext('detects below recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.10.5');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.belowRecommendedVersion);
    });

    testWithoutContext('detects at recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.11.0');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    });

    testWithoutContext('detects above recommended version', () async {
      pretendPodIsInstalled();
      pretendPodVersionIs('1.11.1');
      expect(await cocoaPodsUnderTest.evaluateCocoaPodsInstallation, CocoaPodsStatus.recommended);
    });
  });

  group('Setup Podfile', () {
    testUsingContext('creates objective-c Podfile when not present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Objective-C iOS podfile template');
    });

    testUsingContext('creates swift Podfile if swift', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      final FakeXcodeProjectInterpreter fakeXcodeProjectInterpreter = FakeXcodeProjectInterpreter(buildSettings: <String, String>{
        'SWIFT_VERSION': '5.0',
      });
      final CocoaPods cocoaPodsUnderTest = CocoaPods(
        fileSystem: fileSystem,
        processManager: fakeProcessManager,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        xcodeProjectInterpreter: fakeXcodeProjectInterpreter,
        usage: usage,
      );

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Swift iOS podfile template');
    });

    testUsingContext('creates macOS Podfile when not present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      projectUnderTest.macos.xcodeProject.createSync(recursive: true);
      await cocoaPodsUnderTest.setupPodfile(projectUnderTest.macos);

      expect(projectUnderTest.macos.podfile.readAsStringSync(), 'macOS podfile template');
    });

    testUsingContext('does not recreate Podfile when already present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.readAsStringSync(), 'Existing Podfile');
    });

    testUsingContext('does not create Podfile when we cannot interpret Xcode projects', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      final CocoaPods cocoaPodsUnderTest = CocoaPods(
        fileSystem: fileSystem,
        processManager: fakeProcessManager,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        xcodeProjectInterpreter: FakeXcodeProjectInterpreter(isInstalled: false),
        usage: usage,
      );

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      expect(projectUnderTest.ios.podfile.existsSync(), false);
    });

    testUsingContext('includes Pod config in xcconfig files, if not present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.xcodeConfigFor('Debug')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing debug config');
      projectUnderTest.ios.xcodeConfigFor('Release')
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing release config');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      final String debugContents = projectUnderTest.ios.xcodeConfigFor('Debug').readAsStringSync();
      expect(debugContents, contains(
          '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"\n'));
      expect(debugContents, contains('Existing debug config'));
      final String releaseContents = projectUnderTest.ios.xcodeConfigFor('Release').readAsStringSync();
      expect(releaseContents, contains(
          '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"\n'));
      expect(releaseContents, contains('Existing release config'));
    });

    testUsingContext('does not include Pod config in xcconfig files, if legacy non-option include present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      const String legacyDebugInclude = '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig';
      projectUnderTest.ios.xcodeConfigFor('Debug')
        ..createSync(recursive: true)
        ..writeAsStringSync(legacyDebugInclude);
      const String legacyReleaseInclude = '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig';
      projectUnderTest.ios.xcodeConfigFor('Release')
        ..createSync(recursive: true)
        ..writeAsStringSync(legacyReleaseInclude);

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      final String debugContents = projectUnderTest.ios.xcodeConfigFor('Debug').readAsStringSync();
      // Redundant contains check, but this documents what we're testing--that the optional
      // #include? doesn't get written in addition to the previous style #include.
      expect(debugContents, isNot(contains('#include?')));
      expect(debugContents, equals(legacyDebugInclude));
      final String releaseContents = projectUnderTest.ios.xcodeConfigFor('Release').readAsStringSync();
      expect(releaseContents, isNot(contains('#include?')));
      expect(releaseContents, equals(legacyReleaseInclude));
    });

    testUsingContext('does not include Pod config in xcconfig files, if flavor include present', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      projectUnderTest.ios.podfile..createSync()..writeAsStringSync('Existing Podfile');

      const String flavorDebugInclude = '#include? "Pods/Target Support Files/Pods-Free App/Pods-Free App.debug free.xcconfig"';
      projectUnderTest.ios.xcodeConfigFor('Debug')
        ..createSync(recursive: true)
        ..writeAsStringSync(flavorDebugInclude);
      const String flavorReleaseInclude = '#include? "Pods/Target Support Files/Pods-Free App/Pods-Free App.release free.xcconfig"';
      projectUnderTest.ios.xcodeConfigFor('Release')
        ..createSync(recursive: true)
        ..writeAsStringSync(flavorReleaseInclude);

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await cocoaPodsUnderTest.setupPodfile(project.ios);

      final String debugContents = projectUnderTest.ios.xcodeConfigFor('Debug').readAsStringSync();
      // Redundant contains check, but this documents what we're testing--that the optional
      // #include? doesn't get written in addition to the previous style #include.
      expect(debugContents, isNot(contains('Pods-Runner/Pods-Runner.debug')));
      expect(debugContents, equals(flavorDebugInclude));
      final String releaseContents = projectUnderTest.ios.xcodeConfigFor('Release').readAsStringSync();
      expect(releaseContents, isNot(contains('Pods-Runner/Pods-Runner.release')));
      expect(releaseContents, equals(flavorReleaseInclude));
    });
  });

  group('Update xcconfig', () {
    testUsingContext('includes Pod config in xcconfig files, if the user manually added Pod dependencies without using Flutter plugins', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      fileSystem.file(fileSystem.path.join('project', 'foo', '.packages'))
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

      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.directory('project'));
      await injectPlugins(project, iosPlatform: true);

      final String debugContents = projectUnderTest.ios.xcodeConfigFor('Debug').readAsStringSync();
      expect(debugContents, contains(
          '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"\n'));
      expect(debugContents, contains('Existing debug config'));
      final String releaseContents = projectUnderTest.ios.xcodeConfigFor('Release').readAsStringSync();
      expect(releaseContents, contains(
          '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"\n'));
      expect(releaseContents, contains('Existing release config'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Process pods', () {
    setUp(() {
      podsIsInHomeDir();
    });

    testUsingContext('throwsToolExit if CocoaPods is not installed', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsNotInstalled();
      projectUnderTest.ios.podfile.createSync();
      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'CocoaPods not installed or not in valid state'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('throwsToolExit if CocoaPods install is broken', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsBroken();
      projectUnderTest.ios.podfile.createSync();
      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'CocoaPods not installed or not in valid state'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('exits if Podfile creates the Flutter engine symlink', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      final Directory symlinks = projectUnderTest.ios.symlinks
        ..createSync(recursive: true);
      symlinks.childLink('flutter').createSync('cache');

      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'Podfile is out of date'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('exits if iOS Podfile parses .flutter-plugins', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync("plugin_pods = parse_KV_file('../.flutter-plugins')");

      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'Podfile is out of date'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('prints warning if macOS Podfile parses .flutter-plugins', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
        ),
        FakeCommand(
          command: <String>['touch', 'project/macos/Podfile.lock'],
        ),
      ]);

      projectUnderTest.macos.podfile
        ..createSync()
        ..writeAsStringSync("plugin_pods = parse_KV_file('../.flutter-plugins')");
      projectUnderTest.macos.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');

      await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.macos,
        buildMode: BuildMode.debug,
      );

      expect(logger.warningText, contains('Warning: Podfile is out of date'));
      expect(logger.warningText, contains('rm macos/Podfile'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('throws, if Podfile is missing.', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'Podfile missing'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('throws, if specs repo is outdated.', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{
            'COCOAPODS_DISABLE_STATS': 'true',
            'LANG': 'en_US.UTF-8',
          },
          exitCode: 1,
          stdout: '''
[!] Unable to satisfy the following requirements:

- `Firebase/Auth` required by `Podfile`
- `Firebase/Auth (= 4.0.0)` required by `Podfile.lock`

None of your spec sources contain a spec satisfying the dependencies: `Firebase/Auth, Firebase/Auth (= 4.0.0)`.

You have either:
 * out-of-date source repos which you can update with `pod repo update` or with `pod install --repo-update`.
 * mistyped the name or version.
 * not added the source repo that hosts the Podspec to your Podfile.

Note: as of CocoaPods 1.0, `pod repo update` does not happen on `pod install` by default.''',
        ),
      );

      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit());
      expect(
        logger.errorText,
        contains(
            "CocoaPods's specs repository is too out-of-date to satisfy dependencies"),
      );
    });

    final Map<String, String> possibleErrors = <String, String>{
      'symbol not found': 'LoadError - dlsym(0x7fbbeb6837d0, Init_ffi_c): symbol not found - /Library/Ruby/Gems/2.6.0/gems/ffi-1.13.1/lib/ffi_c.bundle',
      'incompatible architecture': "LoadError - (mach-o file, but is an incompatible architecture (have 'arm64', need 'x86_64')), '/usr/lib/ffi_c.bundle' (no such file) - /Library/Ruby/Gems/2.6.0/gems/ffi-1.15.4/lib/ffi_c.bundle",
      'bus error': '/Library/Ruby/Gems/2.6.0/gems/ffi-1.15.5/lib/ffi/library.rb:275: [BUG] Bus Error at 0x000000010072c000',
    };
    possibleErrors.forEach((String errorName, String cocoaPodsError) {
      testUsingContext('ffi $errorName failure on ARM macOS prompts gem install', () async {
        final FlutterProject projectUnderTest = setupProjectUnderTest();
        pretendPodIsInstalled();
        pretendPodVersionIs('100.0.0');
        fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
          ..createSync()
          ..writeAsStringSync('Existing Podfile');

        fakeProcessManager.addCommands(<FakeCommand>[
          FakeCommand(
            command: const <String>['pod', 'install', '--verbose'],
            workingDirectory: 'project/ios',
            environment: const <String, String>{
              'COCOAPODS_DISABLE_STATS': 'true',
              'LANG': 'en_US.UTF-8',
            },
            exitCode: 1,
            stderr: cocoaPodsError,
          ),
          const FakeCommand(
            command: <String>['which', 'sysctl'],
          ),
          const FakeCommand(
            command: <String>['sysctl', 'hw.optional.arm64'],
            stdout: 'hw.optional.arm64: 1',
          ),
        ]);

        await expectToolExitLater(
          cocoaPodsUnderTest.processPods(
            xcodeProject: projectUnderTest.ios,
            buildMode: BuildMode.debug,
          ),
          equals('Error running pod install'),
        );
        expect(
          logger.errorText,
          contains('set up CocoaPods for ARM macOS'),
        );
        expect(
          logger.errorText,
          contains('enable-libffi-alloc'),
        );
        expect(usage.events, contains(const TestUsageEvent('pod-install-failure', 'arm-ffi')));
      });
    });

    testUsingContext('ffi failure on x86 macOS does not prompt gem install', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      fileSystem.file(fileSystem.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsStringSync('Existing Podfile');

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{
            'COCOAPODS_DISABLE_STATS': 'true',
            'LANG': 'en_US.UTF-8',
          },
          exitCode: 1,
          stderr: 'LoadError - dlsym(0x7fbbeb6837d0, Init_ffi_c): symbol not found - /Library/Ruby/Gems/2.6.0/gems/ffi-1.13.1/lib/ffi_c.bundle',
        ),
        const FakeCommand(
          command: <String>['which', 'sysctl'],
        ),
        const FakeCommand(
          command: <String>['sysctl', 'hw.optional.arm64'],
          exitCode: 1,
        ),
      ]);

      // Capture Usage.test() events.
      final StringBuffer buffer =
      await capturedConsolePrint(() => expectToolExitLater(
        cocoaPodsUnderTest.processPods(
          xcodeProject: projectUnderTest.ios,
          buildMode: BuildMode.debug,
        ),
        equals('Error running pod install'),
      ));
      expect(
        logger.errorText,
        isNot(contains('ARM macOS')),
      );
      expect(buffer.isEmpty, true);
    });

    testUsingContext('run pod install, if Podfile.lock is missing', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');

      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
      ]);
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('runs iOS pod install, if Manifest.lock is missing', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/ios/Podfile.lock'],
        ),
      ]);
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('runs macOS pod install, if Manifest.lock is missing', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.macos.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.macos.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/macos',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/macos/Podfile.lock'],
        ),
      ]);
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.macos,
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('runs pod install, if Manifest.lock different from Podspec.lock', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Different lock file.');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/ios/Podfile.lock'],
        ),
      ]);
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('runs pod install, if flutter framework changed', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/ios/Podfile.lock'],
        ),
      ]);
      final bool didInstall = await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.traceText, contains('CocoaPods Pods-Runner-frameworks.sh script not found'));
    });

    testUsingContext('runs CocoaPods Pod runner script migrator', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podRunnerFrameworksScript
        ..createSync(recursive: true)
        ..writeAsStringSync(r'source="$(readlink "${source}")"');

      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/ios/Podfile.lock'],
        ),
      ]);

      final CocoaPods cocoaPodsUnderTestXcode143 = CocoaPods(
        fileSystem: fileSystem,
        processManager: fakeProcessManager,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        xcodeProjectInterpreter: XcodeProjectInterpreter.test(processManager: fakeProcessManager, version: Version(14, 3, 0)),
        usage: usage,
      );

      final bool didInstall = await cocoaPodsUnderTestXcode143.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      );
      expect(didInstall, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      // Now has readlink -f flag.
      expect(projectUnderTest.ios.podRunnerFrameworksScript.readAsStringSync(), contains(r'source="$(readlink -f "${source}")"'));
      expect(logger.statusText, contains('Upgrading Pods-Runner-frameworks.sh'));
    });

    testUsingContext('runs pod install, if Podfile.lock is older than Podfile', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
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
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
        ),
        FakeCommand(
          command: <String>['touch', 'project/ios/Podfile.lock'],
        ),
      ]);
      await cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('skips pod install, if nothing changed', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
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
        buildMode: BuildMode.debug,
        dependenciesChanged: false,
      );
      expect(didInstall, isFalse);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testUsingContext('a failed pod install deletes Pods/Manifest.lock', () async {
      final FlutterProject projectUnderTest = setupProjectUnderTest();
      pretendPodIsInstalled();
      pretendPodVersionIs('100.0.0');
      projectUnderTest.ios.podfile
        ..createSync()
        ..writeAsStringSync('Existing Podfile');
      projectUnderTest.ios.podfileLock
        ..createSync()
        ..writeAsStringSync('Existing lock file.');
      projectUnderTest.ios.podManifestLock
        ..createSync(recursive: true)
        ..writeAsStringSync('Existing lock file.');
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'COCOAPODS_DISABLE_STATS': 'true', 'LANG': 'en_US.UTF-8'},
          exitCode: 1,
        ),
      );

      await expectLater(cocoaPodsUnderTest.processPods(
        xcodeProject: projectUnderTest.ios,
        buildMode: BuildMode.debug,
      ), throwsToolExit(message: 'Error running pod install'));
      expect(projectUnderTest.ios.podManifestLock.existsSync(), isFalse);
    });
  });
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  FakeXcodeProjectInterpreter({this.isInstalled = true, this.buildSettings = const <String, String>{}});

  @override
  final bool isInstalled;

  @override
  Future<Map<String, String>> getBuildSettings(
    String projectPath, {
    XcodeProjectBuildContext? buildContext,
    Duration timeout = const Duration(minutes: 1),
  }) async => buildSettings;

  final Map<String, String> buildSettings;
}
