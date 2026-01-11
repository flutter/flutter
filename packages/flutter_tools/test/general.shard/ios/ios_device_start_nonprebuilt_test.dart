// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/core_devices.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/xcode_debug.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart' hide FakeXcodeProjectInterpreter;
import '../../src/fake_devices.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/throwing_pub.dart';

List<String> _xattrArgs(FlutterProject flutterProject) {
  return <String>['xattr', '-r', '-d', 'com.apple.FinderInfo', flutterProject.directory.path];
}

const kRunReleaseArgs = <String>[
  'xcrun',
  'xcodebuild',
  '-configuration',
  'Release',
  '-quiet',
  '-allowProvisioningUpdates',
  '-allowProvisioningDeviceRegistration',
  '-workspace',
  'Runner.xcworkspace',
  '-scheme',
  'Runner',
  'BUILD_DIR=/build/ios',
  '-sdk',
  'iphoneos',
  '-destination',
  'id=123',
  'ONLY_ACTIVE_ARCH=YES',
  'ARCHS=arm64',
  '-resultBundlePath',
  '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
  '-resultBundleVersion',
  '3',
  'FLUTTER_SUPPRESS_ANALYTICS=true',
  'COMPILER_INDEX_STORE_ENABLE=NO',
];

const kConcurrentBuildErrorMessage = '''
"/Developer/Xcode/DerivedData/foo/XCBuildData/build.db":
database is locked
Possibly there are two concurrent builds running in the same filesystem location.
''';

final macPlatform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{});

final os = FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64);

void main() {
  late Artifacts artifacts;
  late String iosDeployPath;

  setUp(() {
    artifacts = Artifacts.test();
    iosDeployPath = artifacts.getHostArtifact(HostArtifact.iosDeploy).path;
  });

  group('IOSDevice.startApp succeeds in release mode', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late BufferLogger logger;
    late Xcode xcode;
    late FakeXcodeProjectInterpreter fakeXcodeProjectInterpreter;
    late XcodeProjectInfo projectInfo;
    late FakeAnalytics fakeAnalytics;

    setUp(() {
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
      processManager = FakeProcessManager.empty();
      projectInfo = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>[
        'Runner',
      ], logger);
      fakeXcodeProjectInterpreter = FakeXcodeProjectInterpreter(projectInfo: projectInfo);
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: fakeXcodeProjectInterpreter,
      );
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: fileSystem,
        fakeFlutterVersion: FakeFlutterVersion(),
      );
    });

    testUsingContext(
      'missing TARGET_BUILD_DIR',
      () async {
        final IOSDevice iosDevice = setUpIOSDevice(
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          artifacts: artifacts,
        );
        setUpIOSProject(fileSystem);
        final FlutterProject flutterProject = FlutterProject.fromDirectory(
          fileSystem.currentDirectory,
        );
        final buildableIOSApp = BuildableIOSApp(
          flutterProject.ios,
          'flutter',
          'My Super Awesome App',
        );

        processManager.addCommand(FakeCommand(command: _xattrArgs(flutterProject)));
        processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));

        final LaunchResult launchResult = await iosDevice.startApp(
          buildableIOSApp,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          platformArgs: <String, Object>{},
        );

        expect(launchResult.started, false);
        expect(
          logger.errorText,
          contains('Xcode build is missing expected TARGET_BUILD_DIR build setting'),
        );
        expect(processManager, hasNoRemainingExpectations);
        expect(
          analyticsTimingEventExists(
            sentEvents: fakeAnalytics.sentEvents,
            workflow: 'build',
            variableName: 'xcode-ios',
          ),
          true,
        );
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Pub: () => const ThrowingPub(),
        FileSystem: () => fileSystem,
        Logger: () => logger,
        OperatingSystemUtils: () => os,
        Platform: () => macPlatform,
        XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(
          buildSettings: const <String, String>{
            'WRAPPER_NAME': 'My Super Awesome App.app',
            'DEVELOPMENT_TEAM': '3333CCCC33',
          },
          projectInfo: projectInfo,
        ),
        Xcode: () => xcode,
        Analytics: () => fakeAnalytics,
        Artifacts: () => artifacts,
      },
    );

    testUsingContext(
      'missing project info',
      () async {
        final IOSDevice iosDevice = setUpIOSDevice(
          fileSystem: fileSystem,
          processManager: FakeProcessManager.any(),
          logger: logger,
          artifacts: artifacts,
        );
        setUpIOSProject(fileSystem);
        final FlutterProject flutterProject = FlutterProject.fromDirectory(
          fileSystem.currentDirectory,
        );
        final buildableIOSApp = BuildableIOSApp(
          flutterProject.ios,
          'flutter',
          'My Super Awesome App',
        );

        final LaunchResult launchResult = await iosDevice.startApp(
          buildableIOSApp,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          platformArgs: <String, Object>{},
        );

        expect(launchResult.started, false);
        expect(logger.errorText, contains('Xcode project not found'));
      },
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        FileSystem: () => fileSystem,
        Logger: () => logger,
        Platform: () => macPlatform,
        XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(),
        Xcode: () => xcode,
        Artifacts: () => artifacts,
      },
    );

    testUsingContext(
      'with buildable app',
      () async {
        final fakeExactAnalytics = FakeExactAnalytics();
        final IOSDevice iosDevice = setUpIOSDevice(
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          artifacts: artifacts,
          analytics: fakeExactAnalytics,
        );
        setUpIOSProject(fileSystem);
        final FlutterProject flutterProject = FlutterProject.fromDirectory(
          fileSystem.currentDirectory,
        );
        final buildableIOSApp = BuildableIOSApp(
          flutterProject.ios,
          'flutter',
          'My Super Awesome App',
        );
        fileSystem
            .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
            .createSync(recursive: true);

        processManager.addCommand(FakeCommand(command: _xattrArgs(flutterProject)));
        processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'rsync',
              '-8',
              '-av',
              '--delete',
              'build/ios/Release-iphoneos/My Super Awesome App.app',
              'build/ios/iphoneos',
            ],
          ),
        );
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              iosDeployPath,
              '--id',
              '123',
              '--bundle',
              'build/ios/iphoneos/My Super Awesome App.app',
              '--app_deltas',
              'build/ios/app-delta',
              '--no-wifi',
              '--justlaunch',
              '--args',
              const <String>['--enable-dart-profiling'].join(' '),
            ],
          ),
        );

        final LaunchResult launchResult = await iosDevice.startApp(
          buildableIOSApp,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          platformArgs: <String, Object>{},
        );

        expect(fileSystem.directory('build/ios/iphoneos'), exists);
        expect(launchResult.started, true);
        expect(processManager, hasNoRemainingExpectations);
        expect(fakeExactAnalytics.sentEvents, [
          Event.appleUsageEvent(
            workflow: 'ios-physical-deployment',
            parameter: IOSDeploymentMethod.iosDeployLaunch.name,
            result: 'release success',
          ),
        ]);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Pub: () => const ThrowingPub(),
        FileSystem: () => fileSystem,
        Logger: () => logger,
        OperatingSystemUtils: () => os,
        Platform: () => macPlatform,
        XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
        Xcode: () => xcode,
        Artifacts: () => artifacts,
      },
    );

    testUsingContext(
      'ONLY_ACTIVE_ARCH is NO if different host and target architectures',
      () async {
        // Host architecture is x64, target architecture is arm64.
        final fakeExactAnalytics = FakeExactAnalytics();
        final IOSDevice iosDevice = setUpIOSDevice(
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          artifacts: artifacts,
          analytics: fakeExactAnalytics,
        );
        setUpIOSProject(fileSystem);
        final FlutterProject flutterProject = FlutterProject.fromDirectory(
          fileSystem.currentDirectory,
        );
        final buildableIOSApp = BuildableIOSApp(
          flutterProject.ios,
          'flutter',
          'My Super Awesome App',
        );
        fileSystem
            .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
            .createSync(recursive: true);

        processManager.addCommand(FakeCommand(command: _xattrArgs(flutterProject)));
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-configuration',
              'Release',
              '-quiet',
              '-allowProvisioningUpdates',
              '-allowProvisioningDeviceRegistration',
              '-workspace',
              'Runner.xcworkspace',
              '-scheme',
              'Runner',
              'BUILD_DIR=/build/ios',
              '-sdk',
              'iphoneos',
              '-destination',
              'id=123',
              'ONLY_ACTIVE_ARCH=NO',
              'ARCHS=arm64',
              '-resultBundlePath',
              '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
              '-resultBundleVersion',
              '3',
              'FLUTTER_SUPPRESS_ANALYTICS=true',
              'COMPILER_INDEX_STORE_ENABLE=NO',
            ],
          ),
        );
        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'rsync',
              '-8',
              '-av',
              '--delete',
              'build/ios/Release-iphoneos/My Super Awesome App.app',
              'build/ios/iphoneos',
            ],
          ),
        );
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              iosDeployPath,
              '--id',
              '123',
              '--bundle',
              'build/ios/iphoneos/My Super Awesome App.app',
              '--app_deltas',
              'build/ios/app-delta',
              '--no-wifi',
              '--justlaunch',
              '--args',
              const <String>['--enable-dart-profiling'].join(' '),
            ],
          ),
        );

        final LaunchResult launchResult = await iosDevice.startApp(
          buildableIOSApp,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          platformArgs: <String, Object>{},
        );

        expect(fileSystem.directory('build/ios/iphoneos'), exists);
        expect(launchResult.started, true);
        expect(processManager, hasNoRemainingExpectations);
        expect(fakeExactAnalytics.sentEvents, [
          Event.appleUsageEvent(
            workflow: 'ios-physical-deployment',
            parameter: IOSDeploymentMethod.iosDeployLaunch.name,
            result: 'release success',
          ),
        ]);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        FileSystem: () => fileSystem,
        Logger: () => logger,
        OperatingSystemUtils: () => FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_x64),
        Pub: () => const ThrowingPub(),
        Platform: () => macPlatform,
        XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
        Xcode: () => xcode,
        Artifacts: () => artifacts,
      },
    );

    group('with Xcode 26', () {
      late Xcode xcode;
      late FakeXcodeProjectInterpreter fakeXcodeProjectInterpreter;
      late FakeArtifacts fakeArtifacts;

      setUp(() {
        fakeXcodeProjectInterpreter = FakeXcodeProjectInterpreter(
          projectInfo: projectInfo,
          xcodeVersion: Version(26, 0, 0),
        );
        xcode = Xcode.test(
          processManager: FakeProcessManager.any(),
          xcodeProjectInterpreter: fakeXcodeProjectInterpreter,
        );
        fakeArtifacts = FakeArtifacts(
          frameworkPath: fileSystem.systemTempDirectory.childDirectory('Flutter.framework').path,
        );
      });

      testUsingContext(
        'cleans before build when headers change when incremental build',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: processManager,
            logger: logger,
            artifacts: artifacts,
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);
          fileSystem.systemTempDirectory
              .childDirectory('Flutter.framework')
              .childDirectory('Headers')
              .childFile('FlutterPlugin.h')
              .createSync(recursive: true);
          processManager.addCommands([
            FakeCommand(command: _xattrArgs(flutterProject)),
            FakeCommand(
              command: const <String>[
                'xcrun',
                'xcodebuild',
                '-configuration',
                'Release',
                'clean',
                'build',
                '-quiet',
                '-allowProvisioningUpdates',
                '-allowProvisioningDeviceRegistration',
                '-workspace',
                'Runner.xcworkspace',
                '-scheme',
                'Runner',
                'BUILD_DIR=/build/ios',
                '-sdk',
                'iphoneos',
                '-destination',
                'id=123',
                'ONLY_ACTIVE_ARCH=NO',
                'ARCHS=arm64',
                '-resultBundlePath',
                '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
                '-resultBundleVersion',
                '3',
                'FLUTTER_SUPPRESS_ANALYTICS=true',
                'COMPILER_INDEX_STORE_ENABLE=NO',
              ],
              onRun: (command) {
                expect(
                  fileSystem
                      .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
                      .existsSync(),
                  isFalse,
                );
              },
            ),
            FakeCommand(
              command: <String>[
                iosDeployPath,
                '--id',
                '123',
                '--bundle',
                'build/ios/iphoneos/My Super Awesome App.app',
                '--app_deltas',
                'build/ios/app-delta',
                '--no-wifi',
                '--justlaunch',
                '--args',
                const <String>['--enable-dart-profiling'].join(' '),
              ],
            ),
          ]);
          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, true);
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => processManager,
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () =>
              FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_x64),
          Pub: () => const ThrowingPub(),
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => fakeArtifacts,
        },
      );

      testUsingContext(
        'cleans before build when headers change when fresh build',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: processManager,
            logger: logger,
            artifacts: artifacts,
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );

          fileSystem.directory('build/ios/iphoneos').deleteSync(recursive: true);
          fileSystem.systemTempDirectory
              .childDirectory('Flutter.framework')
              .childDirectory('Headers')
              .childFile('FlutterPlugin.h')
              .createSync(recursive: true);
          processManager.addCommands([
            FakeCommand(command: _xattrArgs(flutterProject)),
            const FakeCommand(
              command: <String>[
                'xcrun',
                'xcodebuild',
                '-configuration',
                'Release',
                '-quiet',
                '-allowProvisioningUpdates',
                '-allowProvisioningDeviceRegistration',
                '-workspace',
                'Runner.xcworkspace',
                '-scheme',
                'Runner',
                'BUILD_DIR=/build/ios',
                '-sdk',
                'iphoneos',
                '-destination',
                'id=123',
                'ONLY_ACTIVE_ARCH=NO',
                'ARCHS=arm64',
                '-resultBundlePath',
                '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
                '-resultBundleVersion',
                '3',
                'FLUTTER_SUPPRESS_ANALYTICS=true',
                'COMPILER_INDEX_STORE_ENABLE=NO',
              ],
            ),
          ]);

          await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => processManager,
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () =>
              FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_x64),
          Pub: () => const ThrowingPub(),
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => fakeArtifacts,
        },
      );
    });

    testUsingContext(
      'with concurrent build failures',
      () async {
        final fakeExactAnalytics = FakeExactAnalytics();
        final IOSDevice iosDevice = setUpIOSDevice(
          fileSystem: fileSystem,
          processManager: processManager,
          logger: logger,
          artifacts: artifacts,
          analytics: fakeExactAnalytics,
        );
        setUpIOSProject(fileSystem);
        final FlutterProject flutterProject = FlutterProject.fromDirectory(
          fileSystem.currentDirectory,
        );
        final buildableIOSApp = BuildableIOSApp(
          flutterProject.ios,
          'flutter',
          'My Super Awesome App',
        );

        processManager.addCommand(FakeCommand(command: _xattrArgs(flutterProject)));
        // The first xcrun call should fail with a
        // concurrent build exception.
        processManager.addCommand(
          const FakeCommand(
            command: kRunReleaseArgs,
            exitCode: 1,
            stdout: kConcurrentBuildErrorMessage,
          ),
        );
        processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              iosDeployPath,
              '--id',
              '123',
              '--bundle',
              'build/ios/iphoneos/My Super Awesome App.app',
              '--app_deltas',
              'build/ios/app-delta',
              '--no-wifi',
              '--justlaunch',
              '--args',
              '--enable-dart-profiling',
            ],
          ),
        );

        final fakeAsync = FakeAsync();
        final Future<LaunchResult> pendingResult = fakeAsync.run((_) async {
          return iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );
        });

        unawaited(
          pendingResult.then(
            expectAsync1((LaunchResult launchResult) {
              expect(
                logger.statusText,
                contains('Xcode build failed due to concurrent builds, will retry in 2 seconds'),
              );
              expect(launchResult.started, true);
              expect(processManager, hasNoRemainingExpectations);
              expect(fakeExactAnalytics.sentEvents, [
                Event.appleUsageEvent(
                  workflow: 'ios-physical-deployment',
                  parameter: IOSDeploymentMethod.iosDeployLaunch.name,
                  result: 'release success',
                ),
              ]);
            }),
          ),
        );

        // Wait until all asynchronous time has been elapsed.
        do {
          fakeAsync.elapse(const Duration(seconds: 2));
        } while (fakeAsync.pendingTimers.isNotEmpty);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        FileSystem: () => fileSystem,
        Logger: () => logger,
        OperatingSystemUtils: () =>
            FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm64),
        Platform: () => macPlatform,
        Pub: () => const ThrowingPub(),
        XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
        Xcode: () => xcode,
        Artifacts: () => artifacts,
      },
    );
  });

  group('IOSDevice.startApp for CoreDevice', () {
    late FileSystem fileSystem;
    late FakeProcessManager processManager;
    late BufferLogger logger;
    late Xcode xcode;
    late FakeXcodeProjectInterpreter fakeXcodeProjectInterpreter;
    late XcodeProjectInfo projectInfo;

    setUp(() {
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
      processManager = FakeProcessManager.empty();
      projectInfo = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>[
        'Runner',
      ], logger);
      fakeXcodeProjectInterpreter = FakeXcodeProjectInterpreter(
        projectInfo: projectInfo,
        xcodeVersion: Version(15, 0, 0),
      );
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: fakeXcodeProjectInterpreter,
      );
    });

    group('in release mode', () {
      testUsingContext(
        'succeeds when install and launch succeed',
        () async {
          final fakeExactAnalytics = FakeExactAnalytics();
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
            analytics: fakeExactAnalytics,
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, true);
          expect(processManager, hasNoRemainingExpectations);
          expect(fakeExactAnalytics.sentEvents, [
            Event.appleUsageEvent(
              workflow: 'ios-physical-deployment',
              parameter: IOSDeploymentMethod.coreDeviceWithoutDebugger.name,
              result: 'release success',
            ),
          ]);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'fails when install fails',
        () async {
          final fakeExactAnalytics = FakeExactAnalytics();
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(installSuccess: false),
            coreDeviceLauncher: FakeIOSCoreDeviceLauncher(launchResult: false),
            analytics: fakeExactAnalytics,
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, false);
          expect(processManager, hasNoRemainingExpectations);
          expect(fakeExactAnalytics.sentEvents, [
            Event.appleUsageEvent(
              workflow: 'ios-physical-deployment',
              parameter: IOSDeploymentMethod.coreDeviceWithoutDebugger.name,
              result: 'launch failed',
            ),
          ]);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'fails when launch fails',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(launchSuccess: false),
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, false);
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'ensure arguments passed to launch',
        () async {
          final coreDeviceControl = FakeIOSCoreDeviceControl();
          final fakeExactAnalytics = FakeExactAnalytics();
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: coreDeviceControl,
            analytics: fakeExactAnalytics,
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
            platformArgs: <String, Object>{},
          );

          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, true);
          expect(processManager, hasNoRemainingExpectations);
          expect(coreDeviceControl.argumentsUsedForLaunch, isNotNull);
          expect(coreDeviceControl.argumentsUsedForLaunch, contains('--enable-dart-profiling'));
          expect(fakeExactAnalytics.sentEvents, [
            Event.appleUsageEvent(
              workflow: 'ios-physical-deployment',
              parameter: IOSDeploymentMethod.coreDeviceWithoutDebugger.name,
              result: 'release success',
            ),
          ]);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );
    });

    group('in debug mode', () {
      testUsingContext(
        'succeeds',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
            xcodeDebug: FakeXcodeDebug(
              expectedProject: XcodeDebugProject(
                scheme: 'Runner',
                xcodeWorkspace: fileSystem.directory('/ios/Runner.xcworkspace'),
                xcodeProject: fileSystem.directory('/ios/Runner.xcodeproj'),
                hostAppProjectName: 'Runner',
              ),
              expectedDeviceId: '123',
              expectedLaunchArguments: <String>['--enable-dart-profiling'],
            ),
          );

          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final deviceLogReader = FakeDeviceLogReader();

          iosDevice.portForwarder = const NoOpDevicePortForwarder();
          iosDevice.setLogReader(buildableIOSApp, deviceLogReader);

          // Start writing messages to the log reader.
          Timer.run(() {
            deviceLogReader.addLine('Foo');
            deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
          });

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(
                BuildMode.debug,
                null,
                buildName: '1.2.3',
                buildNumber: '4',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            platformArgs: <String, Object>{},
          );

          expect(logger.errorText, isEmpty);
          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, true);
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      group('with flavor', () {
        setUp(() {
          projectInfo = XcodeProjectInfo(
            <String>['Runner'],
            <String>['Debug', 'Release', 'Debug-free', 'Release-free'],
            <String>['Runner', 'free'],
            logger,
          );
          fakeXcodeProjectInterpreter = FakeXcodeProjectInterpreter(
            projectInfo: projectInfo,
            xcodeVersion: Version(15, 0, 0),
          );
          xcode = Xcode.test(
            processManager: FakeProcessManager.any(),
            xcodeProjectInterpreter: fakeXcodeProjectInterpreter,
          );
        });

        testUsingContext(
          'succeeds',
          () async {
            const flavor = 'free';
            final IOSDevice iosDevice = setUpIOSDevice(
              fileSystem: fileSystem,
              processManager: FakeProcessManager.any(),
              logger: logger,
              artifacts: artifacts,
              isCoreDevice: true,
              coreDeviceControl: FakeIOSCoreDeviceControl(),
              xcodeDebug: FakeXcodeDebug(
                expectedProject: XcodeDebugProject(
                  scheme: flavor,
                  xcodeWorkspace: fileSystem.directory('/ios/Runner.xcworkspace'),
                  xcodeProject: fileSystem.directory('/ios/Runner.xcodeproj'),
                  hostAppProjectName: 'Runner',
                ),
                expectedDeviceId: '123',
                expectedLaunchArguments: <String>['--enable-dart-profiling'],
                expectedSchemeFilePath:
                    '/ios/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme',
              ),
            );

            setUpIOSProject(fileSystem, scheme: flavor);
            final FlutterProject flutterProject = FlutterProject.fromDirectory(
              fileSystem.currentDirectory,
            );
            final buildableIOSApp = BuildableIOSApp(
              flutterProject.ios,
              'flutter',
              'My Super Awesome App',
            );
            fileSystem
                .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
                .createSync(recursive: true);

            final deviceLogReader = FakeDeviceLogReader();

            iosDevice.portForwarder = const NoOpDevicePortForwarder();
            iosDevice.setLogReader(buildableIOSApp, deviceLogReader);

            // Start writing messages to the log reader.
            Timer.run(() {
              deviceLogReader.addLine('Foo');
              deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
            });

            final LaunchResult launchResult = await iosDevice.startApp(
              buildableIOSApp,
              debuggingOptions: DebuggingOptions.enabled(
                const BuildInfo(
                  BuildMode.debug,
                  'free',
                  buildName: '1.2.3',
                  buildNumber: '4',
                  treeShakeIcons: false,
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
              ),
              platformArgs: <String, Object>{},
            );

            expect(logger.errorText, isEmpty);
            expect(fileSystem.directory('build/ios/iphoneos'), exists);
            expect(launchResult.started, true);
            expect(processManager, hasNoRemainingExpectations);
          },
          overrides: <Type, Generator>{
            ProcessManager: () => FakeProcessManager.any(),
            Pub: () => const ThrowingPub(),
            FileSystem: () => fileSystem,
            Logger: () => logger,
            OperatingSystemUtils: () => os,
            Platform: () => macPlatform,
            XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
            Xcode: () => xcode,
            Artifacts: () => artifacts,
          },
        );
      });

      testUsingContext(
        'updates Generated.xcconfig before and after launch',
        () async {
          final debugStartedCompleter = Completer<void>();
          final debugEndedCompleter = Completer<void>();
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
            xcodeDebug: FakeXcodeDebug(
              expectedProject: XcodeDebugProject(
                scheme: 'Runner',
                xcodeWorkspace: fileSystem.directory('/ios/Runner.xcworkspace'),
                xcodeProject: fileSystem.directory('/ios/Runner.xcodeproj'),
                hostAppProjectName: 'Runner',
                expectedConfigurationBuildDir: '/build/ios/iphoneos',
              ),
              expectedDeviceId: '123',
              expectedLaunchArguments: <String>['--enable-dart-profiling'],
              debugStartedCompleter: debugStartedCompleter,
              debugEndedCompleter: debugEndedCompleter,
            ),
          );

          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final deviceLogReader = FakeDeviceLogReader();

          iosDevice.portForwarder = const NoOpDevicePortForwarder();
          iosDevice.setLogReader(buildableIOSApp, deviceLogReader);

          // Start writing messages to the log reader.
          Timer.run(() {
            deviceLogReader.addLine('Foo');
            deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
          });

          final Future<LaunchResult> futureLaunchResult = iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(
                BuildMode.debug,
                null,
                buildName: '1.2.3',
                buildNumber: '4',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            platformArgs: <String, Object>{},
          );

          await debugStartedCompleter.future;

          // Validate CoreDevice build settings were used
          final File config = fileSystem.directory('ios').childFile('Flutter/Generated.xcconfig');
          expect(config.existsSync(), isTrue);

          String contents = config.readAsStringSync();
          expect(contents, contains('CONFIGURATION_BUILD_DIR=/build/ios/iphoneos'));

          debugEndedCompleter.complete();

          await futureLaunchResult;

          // Validate CoreDevice build settings were removed after launch
          contents = config.readAsStringSync();
          expect(contents.contains('CONFIGURATION_BUILD_DIR'), isFalse);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'fails when Xcode project is not found',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(
                BuildMode.debug,
                null,
                buildName: '1.2.3',
                buildNumber: '4',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            platformArgs: <String, Object>{},
          );
          expect(logger.errorText, contains('Xcode project not found'));
          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, false);
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(),
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'fails when Xcode workspace is not found',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
          );
          setUpIOSProject(fileSystem, createWorkspace: false);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final LaunchResult launchResult = await iosDevice.startApp(
            buildableIOSApp,
            debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(
                BuildMode.debug,
                null,
                buildName: '1.2.3',
                buildNumber: '4',
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
            platformArgs: <String, Object>{},
          );
          expect(logger.errorText, contains('Unable to get Xcode workspace'));
          expect(fileSystem.directory('build/ios/iphoneos'), exists);
          expect(launchResult.started, false);
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          Pub: () => const ThrowingPub(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          OperatingSystemUtils: () => os,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );

      testUsingContext(
        'fails when scheme is not found',
        () async {
          final IOSDevice iosDevice = setUpIOSDevice(
            fileSystem: fileSystem,
            processManager: FakeProcessManager.any(),
            logger: logger,
            artifacts: artifacts,
            isCoreDevice: true,
            coreDeviceControl: FakeIOSCoreDeviceControl(),
          );
          setUpIOSProject(fileSystem);
          final FlutterProject flutterProject = FlutterProject.fromDirectory(
            fileSystem.currentDirectory,
          );
          final buildableIOSApp = BuildableIOSApp(
            flutterProject.ios,
            'flutter',
            'My Super Awesome App',
          );
          fileSystem
              .directory('build/ios/Release-iphoneos/My Super Awesome App.app')
              .createSync(recursive: true);

          final deviceLogReader = FakeDeviceLogReader();

          iosDevice.portForwarder = const NoOpDevicePortForwarder();
          iosDevice.setLogReader(buildableIOSApp, deviceLogReader);

          // Start writing messages to the log reader.
          Timer.run(() {
            deviceLogReader.addLine('Foo');
            deviceLogReader.addLine('The Dart VM service is listening on http://127.0.0.1:456');
          });

          expect(
            () async => iosDevice.startApp(
              buildableIOSApp,
              debuggingOptions: DebuggingOptions.enabled(
                const BuildInfo(
                  BuildMode.debug,
                  'Flavor',
                  buildName: '1.2.3',
                  buildNumber: '4',
                  treeShakeIcons: false,
                  packageConfigPath: '.dart_tool/package_config.json',
                ),
              ),
              platformArgs: <String, Object>{},
            ),
            throwsToolExit(),
          );
        },
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.any(),
          FileSystem: () => fileSystem,
          Logger: () => logger,
          Platform: () => macPlatform,
          XcodeProjectInterpreter: () => fakeXcodeProjectInterpreter,
          Xcode: () => xcode,
          Artifacts: () => artifacts,
        },
      );
    });
  });
}

void setUpIOSProject(
  FileSystem fileSystem, {
  bool createWorkspace = true,
  String scheme = 'Runner',
}) {
  fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
''');
  writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
  fileSystem.directory('ios').createSync();
  if (createWorkspace) {
    fileSystem.directory('ios/Runner.xcworkspace').createSync();
  }
  fileSystem.file('ios/Runner.xcodeproj/project.pbxproj').createSync(recursive: true);
  final File schemeFile = fileSystem.file(
    'ios/Runner.xcodeproj/xcshareddata/xcschemes/$scheme.xcscheme',
  )..createSync(recursive: true);
  schemeFile.writeAsStringSync(_validScheme);
  // This is the expected output directory.
  fileSystem.directory('build/ios/iphoneos/My Super Awesome App.app').createSync(recursive: true);

  // Create a dummy Info.plist with `UIApplicationSceneManifest` to spoof that the project has
  // migrated to UIScene and avoid UIScene errors.
  fileSystem.file('ios/Runner/Info.plist')
    ..createSync(recursive: true)
    ..writeAsStringSync('UIApplicationSceneManifest');
}

IOSDevice setUpIOSDevice({
  String sdkVersion = '13.0.1',
  FileSystem? fileSystem,
  Logger? logger,
  ProcessManager? processManager,
  Artifacts? artifacts,
  bool isCoreDevice = false,
  IOSCoreDeviceControl? coreDeviceControl,
  IOSCoreDeviceLauncher? coreDeviceLauncher,
  FakeXcodeDebug? xcodeDebug,
  DarwinArch cpuArchitecture = DarwinArch.arm64,
  FakeExactAnalytics? analytics,
}) {
  artifacts ??= Artifacts.test();
  final cache = Cache.test(
    artifacts: <ArtifactSet>[FakeDyldEnvironmentArtifact()],
    processManager: FakeProcessManager.any(),
  );

  logger ??= BufferLogger.test();
  return IOSDevice(
    '123',
    name: 'iPhone 1',
    sdkVersion: sdkVersion,
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    platform: macPlatform,
    iProxy: IProxy.test(logger: logger, processManager: processManager ?? FakeProcessManager.any()),
    logger: logger,
    iosDeploy: IOSDeploy(
      logger: logger,
      platform: macPlatform,
      processManager: processManager ?? FakeProcessManager.any(),
      artifacts: artifacts,
      cache: cache,
    ),
    analytics: analytics ?? FakeExactAnalytics(),
    iMobileDevice: IMobileDevice(
      logger: logger,
      processManager: processManager ?? FakeProcessManager.any(),
      artifacts: artifacts,
      cache: cache,
    ),
    coreDeviceControl: coreDeviceControl ?? FakeIOSCoreDeviceControl(),
    coreDeviceLauncher: coreDeviceLauncher ?? FakeIOSCoreDeviceLauncher(),
    xcodeDebug: xcodeDebug ?? FakeXcodeDebug(),
    cpuArchitecture: cpuArchitecture,
    connectionInterface: DeviceConnectionInterface.attached,
    isConnected: true,
    isPaired: true,
    devModeEnabled: true,
    isCoreDevice: isCoreDevice,
  );
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  FakeXcodeProjectInterpreter({
    this.projectInfo,
    this.buildSettings = const <String, String>{
      'TARGET_BUILD_DIR': 'build/ios/Release-iphoneos',
      'WRAPPER_NAME': 'My Super Awesome App.app',
      'DEVELOPMENT_TEAM': '3333CCCC33',
    },
    Version? xcodeVersion,
  }) : version = xcodeVersion ?? Version(1000, 0, 0);

  final Map<String, String> buildSettings;
  final XcodeProjectInfo? projectInfo;

  @override
  final isInstalled = true;

  @override
  Version? version;

  @override
  String get versionText => version.toString();

  @override
  List<String> xcrunCommand() => <String>['xcrun'];

  @override
  Future<XcodeProjectInfo?> getInfo(String projectPath, {String? projectFilename}) async =>
      projectInfo;

  @override
  Future<Map<String, String>> getBuildSettings(
    String projectPath, {
    required XcodeProjectBuildContext buildContext,
    Duration timeout = const Duration(minutes: 1),
  }) async => buildSettings;
}

class FakeXcodeDebug extends Fake implements XcodeDebug {
  FakeXcodeDebug({
    this.debugSuccess = true,
    this.expectedProject,
    this.expectedDeviceId,
    this.expectedLaunchArguments,
    this.expectedSchemeFilePath = '/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    this.debugStartedCompleter,
    this.debugEndedCompleter,
  });

  final bool debugSuccess;

  final XcodeDebugProject? expectedProject;
  final String? expectedDeviceId;
  final List<String>? expectedLaunchArguments;
  final Completer<void>? debugStartedCompleter;
  final Completer<void>? debugEndedCompleter;
  final String expectedSchemeFilePath;

  @override
  Future<bool> debugApp({
    required XcodeDebugProject project,
    required String deviceId,
    required List<String> launchArguments,
  }) async {
    debugStartedCompleter?.complete();
    if (expectedProject != null) {
      expect(project.scheme, expectedProject!.scheme);
      expect(project.xcodeWorkspace.path, expectedProject!.xcodeWorkspace.path);
      expect(project.xcodeProject.path, expectedProject!.xcodeProject.path);
      expect(project.isTemporaryProject, expectedProject!.isTemporaryProject);
    }
    if (expectedDeviceId != null) {
      expect(deviceId, expectedDeviceId);
    }
    if (expectedLaunchArguments != null) {
      expect(expectedLaunchArguments, launchArguments);
    }
    await debugEndedCompleter?.future;
    return debugSuccess;
  }

  @override
  void ensureXcodeDebuggerLaunchAction(File schemeFile) {
    expect(schemeFile.path, expectedSchemeFilePath);
  }
}

class FakeIOSCoreDeviceControl extends Fake implements IOSCoreDeviceControl {
  FakeIOSCoreDeviceControl({this.installSuccess = true, this.launchSuccess = true});

  final bool installSuccess;
  final bool launchSuccess;
  List<String>? _launchArguments;

  List<String>? get argumentsUsedForLaunch => _launchArguments;

  @override
  Future<(bool, IOSCoreDeviceInstallResult?)> installApp({
    required String deviceId,
    required String bundlePath,
  }) async {
    final result = IOSCoreDeviceInstallResult.fromJson(<String, Object?>{
      'info': <String, Object?>{'outcome': installSuccess ? 'success' : 'failure'},
    });
    return (installSuccess, result);
  }

  @override
  Future<IOSCoreDeviceLaunchResult?> launchApp({
    required String deviceId,
    required String bundleId,
    List<String> launchArguments = const <String>[],
    bool startStopped = false,
  }) async {
    _launchArguments = launchArguments;
    final outcome = launchSuccess ? 'success' : 'failed';
    return IOSCoreDeviceLaunchResult.fromJson(<String, Object?>{
      'info': {'outcome': outcome},
    });
  }
}

const _validScheme = '''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8080294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      enableGPUValidationMode = "1"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction>
   </ProfileAction>
   <AnalyzeAction>
   </AnalyzeAction>
   <ArchiveAction>
   </ArchiveAction>
</Scheme>
''';

class FakeIOSCoreDeviceLauncher extends Fake implements IOSCoreDeviceLauncher {
  FakeIOSCoreDeviceLauncher({this.launchResult = true});
  bool launchResult;

  @override
  Future<bool> launchAppWithoutDebugger({
    required String deviceId,
    required String bundlePath,
    required String bundleId,
    required List<String> launchArguments,
  }) async {
    return launchResult;
  }

  @override
  Future<bool> launchAppWithLLDBDebugger({
    required String deviceId,
    required String bundlePath,
    required String bundleId,
    required List<String> launchArguments,
    required ShutdownHooks shutdownHooks,
  }) async {
    return true;
  }
}

class FakeExactAnalytics extends Fake implements Analytics {
  final sentEvents = <Event>[];

  @override
  void send(Event event) {
    sentEvents.add(event);
  }
}

class FakeArtifacts extends Fake implements Artifacts {
  FakeArtifacts({required this.frameworkPath});

  final String frameworkPath;
  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    return frameworkPath;
  }

  @override
  LocalEngineInfo? get localEngineInfo => null;
}
