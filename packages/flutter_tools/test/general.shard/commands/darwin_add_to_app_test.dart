// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/darwin_add_to_app.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  group('DarwinAddToAppCodesigning', () {
    testWithoutContext('getCodesignIdentity throws if tools are not available', () async {
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(validTools: false),
      );
      await expectLater(
        addtoAppCodesigning.getCodesignIdentity(BuildInfo.debug, FakeXcodeBasedProject()),
        throwsToolExit(message: 'Unable to find code-signing tools'),
      );
    });

    testWithoutContext('getCodesignIdentity throws if no valid identities are found', () async {
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(),
      );
      await expectLater(
        addtoAppCodesigning.getCodesignIdentity(BuildInfo.debug, FakeXcodeBasedProject()),
        throwsToolExit(
          message: '''
No valid code signing certificates were found
You can connect to your Apple Developer account by signing in with your Apple ID
in Xcode and create an iOS Development Certificate as well as a Provisioning\u0020
Profile for your project by:
  1- Open the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- Make sure a 'Development Team' is selected under Signing & Capabilities > Team.\u0020
     You may need to:
         - Log in with your Apple ID in Xcode first
         - Ensure you have a valid unique Bundle ID
         - Register your device with your Apple Developer Account
         - Let Xcode automatically provision a profile for your app
  4- Build or run your project again

For more information, please visit:
  https://developer.apple.com/library/content/documentation/IDEs/Conceptual/
  AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html''',
        ),
      );
    });

    testWithoutContext(
      'getCodesignIdentity throws if no valid matching identities are found',
      () async {
        final Logger logger = BufferLogger.test();
        const commonName = 'Apple Development: EXAMPLE.IO LLC (A1BC2DF345)';
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(identities: <String>[commonName]),
        );
        await expectLater(
          addtoAppCodesigning.getCodesignIdentity(BuildInfo.debug, FakeXcodeBasedProject()),
          throwsToolExit(
            message:
                'No valid code-signing identity found. Please specify which identity to use with '
                '--codesign-identity or use --no-codesign',
          ),
        );
      },
    );

    testWithoutContext(
      'getCodesignIdentity from project uses provisioning profile for manual codesigning',
      () async {
        final fs = MemoryFileSystem.test();
        const provisioningProfileName = 'iOS Team Provisioning Profile: *';
        const teamId = 'A1BC2DF345';
        const entityName = 'EXAMPLE.IO LLC';
        const commonName = 'Apple Development: $entityName ($teamId)';
        final Logger logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
            identities: <String>[commonName],
            provisioningProfiles: <ProvisioningProfile>[
              ProvisioningProfile(
                filePath: 'test.mobileprovision',
                name: provisioningProfileName,
                uuid: 'test',
                teamIdentifier: teamId,
                expirationDate: DateTime.now().add(const Duration(days: 30)),
                developerCertificates: <File>[
                  fs.file('developer.cer')..writeAsStringSync(commonName),
                ],
                isXcodeManaged: false,
              ),
            ],
          ),
        );
        final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
          BuildInfo.debug,
          FakeXcodeBasedProject(
            buildSettings: <String, String>{
              'CODE_SIGN_STYLE': 'Manual',
              'DEVELOPMENT_TEAM': teamId,
              'PROVISIONING_PROFILE_SPECIFIER': provisioningProfileName,
            },
          ),
        );
        expect(codesignIdentity, commonName);
      },
    );

    testWithoutContext(
      'getCodesignIdentity from project uses team for automatic codesigning',
      () async {
        const userId = 'ABC1DEF23G';
        const entityName = 'User Name';
        const organizationalUnitId = 'A1BC2DF345';
        const commonName = 'Apple Development: $entityName ($userId)';
        final Logger logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
            identities: <String>[commonName],
            identityToTeam: {commonName: organizationalUnitId},
          ),
        );
        final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
          BuildInfo.debug,
          FakeXcodeBasedProject(
            buildSettings: <String, String>{'DEVELOPMENT_TEAM': organizationalUnitId},
          ),
        );
        expect(codesignIdentity, commonName);
      },
    );

    testWithoutContext(
      'getCodesignIdentity from project throws if multiple identities are found',
      () async {
        const organizationalUnit = 'A1BC2DF345';
        const commonName1 = 'Apple Development: User Name 1 (UserID1)';
        const commonName2 = 'Apple Development: User Name 2 (UserID2)';
        final Logger logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
            identities: <String>[commonName1, commonName2],
            identityToTeam: {commonName1: organizationalUnit, commonName2: organizationalUnit},
          ),
        );
        await expectLater(
          addtoAppCodesigning.getCodesignIdentity(
            BuildInfo.debug,
            FakeXcodeBasedProject(
              buildSettings: <String, String>{'DEVELOPMENT_TEAM': organizationalUnit},
            ),
          ),
          throwsToolExit(
            message:
                '''
Multiple identities found for development team $organizationalUnit. Please specify which identity to use with --codesign-identity.
Available identities:
  $commonName1
  $commonName2''',
          ),
        );
      },
    );

    testWithoutContext('getCodesignIdentity from config uses provisioning profile', () async {
      final fs = MemoryFileSystem.test();
      const provisioningProfileName = 'iOS Team Provisioning Profile: *';
      const teamId = 'A1BC2DF345';
      const entityName = 'EXAMPLE.IO LLC';
      const commonName = 'Apple Development: $entityName ($teamId)';
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
          identities: <String>[commonName],
          provisioningProfileFromConfig: ProvisioningProfile(
            filePath: 'test.mobileprovision',
            name: provisioningProfileName,
            uuid: 'test',
            teamIdentifier: teamId,
            expirationDate: DateTime.now().add(const Duration(days: 30)),
            developerCertificates: <File>[fs.file('developer.cer')..writeAsStringSync(commonName)],
            isXcodeManaged: false,
          ),
        ),
      );
      final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
        BuildInfo.debug,
        FakeXcodeBasedProject(),
      );
      expect(codesignIdentity, commonName);
    });

    testWithoutContext('getCodesignIdentity from config throws if multiple identities', () async {
      final fs = MemoryFileSystem.test();
      const provisioningProfileName = 'iOS Team Provisioning Profile: *';
      const teamId = 'A1BC2DF345';
      const commonName1 = 'Apple Development: User Name 1 (UserID1)';
      const commonName2 = 'Apple Development: User Name 2 (UserID2)';
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
          identities: <String>[commonName1, commonName2],
          provisioningProfileFromConfig: ProvisioningProfile(
            filePath: 'test.mobileprovision',
            name: provisioningProfileName,
            uuid: 'test',
            teamIdentifier: teamId,
            expirationDate: DateTime.now().add(const Duration(days: 30)),
            developerCertificates: <File>[
              fs.file('developer.cer')..writeAsStringSync(commonName1),
              fs.file('developer2.cer')..writeAsStringSync(commonName2),
            ],
            isXcodeManaged: false,
          ),
        ),
      );
      await expectLater(
        addtoAppCodesigning.getCodesignIdentity(BuildInfo.debug, FakeXcodeBasedProject()),
        throwsToolExit(
          message:
              '''
Multiple identities found for provisioning profile $provisioningProfileName. Please specify which identity to use with --codesign-identity.
Available identities:
  $commonName1
  $commonName2''',
        ),
      );
    });

    testWithoutContext('getCodesignIdentity from config uses identity', () async {
      const userId = 'A1BC2DF345';
      const entityName = 'EXAMPLE.IO LLC';
      const commonName = 'Apple Development: $entityName ($userId)';
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
          identities: <String>[commonName],
          identityFromCertFromConfig: commonName,
        ),
      );
      final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
        BuildInfo.debug,
        FakeXcodeBasedProject(),
      );
      expect(codesignIdentity, commonName);
    });

    testWithoutContext('codesign for release mode', () async {
      final fs = MemoryFileSystem.test();
      await DarwinAddToAppCodesigning.codesign(
        artifact: fs.directory('test.xcframework'),
        processManager: FakeProcessManager.list([
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              'test.xcframework',
            ],
          ),
        ]),
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.release,
      );
    });

    testWithoutContext('codesign uses timestamp=none for non-release mode', () async {
      final fs = MemoryFileSystem.test();
      await DarwinAddToAppCodesigning.codesign(
        artifact: fs.directory('test.xcframework'),
        processManager: FakeProcessManager.list([
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'test.xcframework',
            ],
          ),
        ]),
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
    });

    testWithoutContext('codesignFlutterXCFramework for iOS', () async {
      final fs = MemoryFileSystem.test();
      final Directory flutterXCFramework = fs.directory('Flutter.xcframework');
      flutterXCFramework.childDirectory('ios-arm64/Flutter.framework').createSync(recursive: true);
      flutterXCFramework
          .childDirectory('ios-arm64_x86_64-simulator/Flutter.framework')
          .createSync(recursive: true);
      await DarwinAddToAppCodesigning.codesignFlutterXCFramework(
        xcframework: flutterXCFramework,
        targetPlatform: FlutterDarwinPlatform.ios,
        processManager: FakeProcessManager.list([
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'Flutter.xcframework',
            ],
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'Flutter.xcframework/ios-arm64/Flutter.framework',
            ],
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework',
            ],
          ),
        ]),
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
    });

    testWithoutContext('codesignFlutterXCFramework for macOS', () async {
      final fs = MemoryFileSystem.test();
      final Directory flutterXCFramework = fs.directory('FlutterMacOS.xcframework');
      flutterXCFramework
          .childDirectory('macos-arm64_x86_64/FlutterMacOS.framework')
          .createSync(recursive: true);
      await DarwinAddToAppCodesigning.codesignFlutterXCFramework(
        xcframework: flutterXCFramework,
        targetPlatform: FlutterDarwinPlatform.macos,
        processManager: FakeProcessManager.list([
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'FlutterMacOS.xcframework',
            ],
          ),
          const FakeCommand(
            command: [
              'codesign',
              '--force',
              '--sign',
              'Apple Development: ENTITY_NAME (TEAM_ID)',
              '--timestamp=none',
              'FlutterMacOS.xcframework/macos-arm64_x86_64/FlutterMacOS.framework',
            ],
          ),
        ]),
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
    });
  });
}

class FakeXcodeCodeSigningSettings extends Fake implements XcodeCodeSigningSettings {
  FakeXcodeCodeSigningSettings({
    this.validTools = true,
    this.identities = const <String>[],
    this.provisioningProfiles = const <ProvisioningProfile>[],
    this.identityToTeam = const <String, String>{},
    this.provisioningProfileFromConfig,
    this.identityFromCertFromConfig,
  });

  final bool validTools;
  final List<String> identities;
  final List<ProvisioningProfile> provisioningProfiles;
  final Map<String, String> identityToTeam;
  final ProvisioningProfile? provisioningProfileFromConfig;
  final String? identityFromCertFromConfig;

  @override
  Future<bool> validateCodeSignSearchTools({bool printError = false}) async {
    return validTools;
  }

  @override
  Future<List<String>> getSigningIdentities() async {
    return identities;
  }

  @override
  Future<List<ProvisioningProfile>> getProvisioningProfiles({List<String>? validIdentities}) async {
    return provisioningProfiles;
  }

  @override
  Future<String?> commonNameForCertificate(File cert) async {
    if (cert.existsSync()) {
      return cert.readAsString();
    }
    return null;
  }

  @override
  Future<String?> getDevelopmentTeamFromIdentity(String identity) async {
    return identityToTeam[identity];
  }

  @override
  Future<ProvisioningProfile?> getProvisioningProfileFromConfig(
    List<String> validCodeSigningIdentities,
  ) async {
    return provisioningProfileFromConfig;
  }

  @override
  Future<String?> getIdentityFromCertFromConfig(List<String> validCodeSigningIdentities) async {
    return identityFromCertFromConfig;
  }
}

class FakeXcodeBasedProject extends Fake implements XcodeBasedProject {
  FakeXcodeBasedProject({this.buildSettings = const <String, String>{}});

  final Map<String, String> buildSettings;

  @override
  Future<Map<String, String>?> buildSettingsForBuildInfo(
    BuildInfo? buildInfo, {
    String? scheme,
    String? configuration,
    String? target,
    EnvironmentType environmentType = EnvironmentType.physical,
    String? deviceId,
    bool isWatch = false,
  }) async {
    return buildSettings;
  }
}
