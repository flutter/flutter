// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  late BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  group('IMobileDevice', () {
    late Artifacts artifacts;
    late Cache cache;

    setUp(() {
      artifacts = Artifacts.test();
      cache = Cache.test(
        artifacts: <ArtifactSet>[
          FakeDyldEnvironmentArtifact(),
        ],
        processManager: FakeProcessManager.any(),
      );
    });

    group('screenshot', () {
      late FakeProcessManager fakeProcessManager;
      late File outputFile;

      setUp(() {
        fakeProcessManager = FakeProcessManager.empty();
        outputFile = MemoryFileSystem.test().file('image.png');
      });

      testWithoutContext('error if idevicescreenshot is not installed', () async {
        // Let `idevicescreenshot` fail with exit code 1.
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'HostArtifact.idevicescreenshot',
            outputFile.path,
            '--udid',
            '1234',
          ],
          environment: const <String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/libraries',
          },
          exitCode: 1,
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        expect(() async => iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceConnectionInterface.usb,
        ), throwsA(anything));
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });

      testWithoutContext('idevicescreenshot captures and returns USB screenshot', () async {
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'HostArtifact.idevicescreenshot', outputFile.path, '--udid', '1234',
          ],
          environment: const <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libraries'},
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceConnectionInterface.usb,
        );
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });

      testWithoutContext('idevicescreenshot captures and returns network screenshot', () async {
        fakeProcessManager.addCommand(FakeCommand(
          command: <String>[
            'HostArtifact.idevicescreenshot', outputFile.path, '--udid', '1234', '--network',
          ],
          environment: const <String, String>{'DYLD_LIBRARY_PATH': '/path/to/libraries'},
        ));

        final IMobileDevice iMobileDevice = IMobileDevice(
          artifacts: artifacts,
          cache: cache,
          processManager: fakeProcessManager,
          logger: logger,
        );

        await iMobileDevice.takeScreenshot(
          outputFile,
          '1234',
          IOSDeviceConnectionInterface.network,
        );
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      });
    });
  });

  group('Diagnose Xcode build failure', () {
    late Map<String, String> buildSettings;
    late TestUsage testUsage;

    setUp(() {
      buildSettings = <String, String>{
        'PRODUCT_BUNDLE_IDENTIFIER': 'test.app',
      };
      testUsage = TestUsage();
    });

    testWithoutContext('Sends analytics when bitcode fails', () async {
      const List<String> buildCommands = <String>['xcrun', 'cc', 'blah'];
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: 'BITCODE_ENABLED = YES',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: buildCommands,
          appDirectory: '/blah/blah',
          environmentType: EnvironmentType.physical,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(testUsage.events, contains(
        TestUsageEvent(
          'build',
          'ios',
          label: 'xcode-bitcode-failure',
          parameters: CustomDimensions(
            buildEventCommand: buildCommands.toString(),
            buildEventSettings: buildSettings.toString(),
          ),
        ),
      ));
    });

    testWithoutContext('fallback to stdout: No provisioning profile shows message', () async {
      final Map<String, String> buildSettingsWithDevTeam = <String, String>{
        'PRODUCT_BUNDLE_IDENTIFIER': 'test.app',
        'DEVELOPMENT_TEAM': 'a team',
      };
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Launching lib/main.dart on iPhone in debug mode...
Signing iOS app for device deployment using developer identity: "iPhone Developer: test@flutter.io (1122334455)"
Running Xcode build...                                1.3s
Failed to build iOS app
Error output from Xcode build:
↳
    ** BUILD FAILED **


    The following build commands failed:
    	Check dependencies
    (1 failure)
Xcode's output:
↳
    Build settings from command line:
        ARCHS = arm64
        BUILD_DIR = /Users/blah/blah
        DEVELOPMENT_TEAM = AABBCCDDEE
        ONLY_ACTIVE_ARCH = YES
        SDKROOT = iphoneos10.3

    === CLEAN TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    [BCEROR]"Runner" requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor.
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'

    Create product structure
    /bin/mkdir -p /Users/blah/Runner.app

    Clean.Remove clean /Users/blah/Runner.app.dSYM
        builtin-rm -rf /Users/blah/Runner.app.dSYM

    Clean.Remove clean /Users/blah/Runner.app
        builtin-rm -rf /Users/blah/Runner.app

    Clean.Remove clean /Users/blah/Runner-dfvicjniknvzghgwsthwtgcjhtsk/Build/Intermediates/Runner.build/Release-iphoneos/Runner.build
        builtin-rm -rf /Users/blah/Runner-dfvicjniknvzghgwsthwtgcjhtsk/Build/Intermediates/Runner.build/Release-iphoneos/Runner.build

    ** CLEAN SUCCEEDED **

    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    No profiles for 'com.example.test' were found:  Xcode couldn't find a provisioning profile matching 'com.example.test'.
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'

Could not build the precompiled application for the device.

Error launching application on iPhone.''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          environmentType: EnvironmentType.physical,
          buildSettings: buildSettingsWithDevTeam,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains(noProvisioningProfileInstruction),
      );
    });

    testWithoutContext('No development team shows message', () async {
      final XcodeBuildResult buildResult = XcodeBuildResult(
        success: false,
        stdout: '''
Running "flutter pub get" in flutter_gallery...  0.6s
Launching lib/main.dart on x in release mode...
Running pod install...                                1.2s
Running Xcode build...                                1.4s
Failed to build iOS app
Error output from Xcode build:
↳
    ** BUILD FAILED **


    The following build commands failed:
    	Check dependencies
    (1 failure)
Xcode's output:
↳
    blah

    === CLEAN TARGET url_launcher OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === CLEAN TARGET Pods-Runner OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === CLEAN TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    [BCEROR]Signing for "Runner" requires a development team. Select a development team in the project editor.
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    [BCEROR]Code signing is required for product type 'Application' in SDK 'iOS 10.3'

    blah

    ** CLEAN SUCCEEDED **

    === BUILD TARGET url_launcher OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === BUILD TARGET Pods-Runner OF PROJECT Pods WITH CONFIGURATION Release ===

    Check dependencies

    blah

    === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Release ===

    Check dependencies
    Signing for "Runner" requires a development team. Select a development team in the project editor.
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'
    Code signing is required for product type 'Application' in SDK 'iOS 10.3'

Could not build the precompiled application for the device.''',
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: <String>['xcrun', 'xcodebuild', 'blah'],
          appDirectory: '/blah/blah',
          environmentType: EnvironmentType.physical,
          buildSettings: buildSettings,
        ),
      );

      await diagnoseXcodeBuildFailure(buildResult, testUsage, logger);
      expect(
        logger.errorText,
        contains('Building a deployable iOS app requires a selected Development Team with a \nProvisioning Profile.'),
      );
    });
  });

  group('Upgrades project.pbxproj for old asset usage', () {
    const String flutterAssetPbxProjLines =
      '/* flutter_assets */\n'
      '/* App.framework\n'
      'another line';

    const String appFlxPbxProjLines =
      '/* app.flx\n'
      '/* App.framework\n'
      'another line';

    const String cleanPbxProjLines =
      '/* App.framework\n'
      'another line';

    testWithoutContext('upgradePbxProjWithFlutterAssets', () async {
      final File pbxprojFile = MemoryFileSystem.test().file('project.pbxproj')
        ..writeAsStringSync(flutterAssetPbxProjLines);
      final FakeIosProject project = FakeIosProject(pbxprojFile);

      bool result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to flutter_assets'),
      );
      logger.clear();

      pbxprojFile.writeAsStringSync(appFlxPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        contains('Removing obsolete reference to app.flx'),
      );
      logger.clear();

      pbxprojFile.writeAsStringSync(cleanPbxProjLines);
      result = upgradePbxProjWithFlutterAssets(project, logger);
      expect(result, true);
      expect(
        logger.statusText,
        isEmpty,
      );
    });
  });

  group('remove Finder extended attributes', () {
    late Directory projectDirectory;
    setUp(() {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      projectDirectory = fs.directory('flutter_project');
    });

    testWithoutContext('removes xattr', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'xattr',
          '-r',
          '-d',
          'com.apple.FinderInfo',
          projectDirectory.path,
        ]),
      ]);

      await removeFinderExtendedAttributes(projectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('ignores errors', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            projectDirectory.path,
          ],
          exitCode: 1,
        ),
      ]);

      await removeFinderExtendedAttributes(projectDirectory, ProcessUtils(processManager: processManager, logger: logger), logger);
      expect(logger.traceText, contains('Failed to remove xattr com.apple.FinderInfo'));
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject(this.xcodeProjectInfoFile);
  @override
  final File xcodeProjectInfoFile;

  @override
  Future<String> hostAppBundleName(BuildInfo? buildInfo) async => 'UnitTestRunner.app';

  @override
  Directory get xcodeProject => xcodeProjectInfoFile.fileSystem.directory('Runner.xcodeproj');
}
