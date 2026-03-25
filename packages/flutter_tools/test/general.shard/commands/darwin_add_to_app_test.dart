// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/darwin_add_to_app.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  group('DarwinAddToAppCodesigning', () {
    testWithoutContext('getCodesignIdentity returns null if codesign is disabled', () async {
      final logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(),
      );
      final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
        buildInfo: BuildInfo.debug,
        xcodeProject: FakeXcodeBasedProject(),
        codesignIdentityOption: null,
        identityFile: MemoryFileSystem.test().file('.codesign_identity'),
        codesignEnabled: false,
      );
      expect(codesignIdentity, null);
      expect(logger.statusText, contains('Skipping code-signing...'));
    });

    testWithoutContext(
      'getCodesignIdentity warns if codesign is disabled and identity has changed',
      () async {
        final logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(),
        );
        final fs = MemoryFileSystem.test();
        final File identityFile = fs.file('.codesign_identity');
        identityFile.writeAsStringSync('old identity');
        final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(),
          codesignIdentityOption: null,
          identityFile: identityFile,
          codesignEnabled: false,
        );
        expect(codesignIdentity, null);
        expect(logger.statusText, contains('Skipping code-signing...'));
        expect(logger.warningText, '''
   └── Identity has changed since last run. Previous identity: old identity
       If this triggers a notice in Xcode, select "Accept Change" to accept the new identity.
''');
        expect(identityFile.readAsStringSync(), '');
      },
    );

    testWithoutContext('getCodesignIdentity uses codesignIdentityOption if provided', () async {
      final logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(),
      );
      final fs = MemoryFileSystem.test();
      final File identityFile = fs.file('.codesign_identity');
      identityFile.writeAsStringSync('old identity');
      final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
        buildInfo: BuildInfo.debug,
        xcodeProject: FakeXcodeBasedProject(),
        codesignIdentityOption: 'new identity',
        identityFile: identityFile,
        codesignEnabled: true,
      );
      expect(codesignIdentity, 'new identity');
      expect(logger.statusText, contains('Using code-signing identity: new identity'));
      expect(logger.warningText, '''
   └── Identity has changed since last run. Previous identity: old identity
       If this triggers a notice in Xcode, select "Accept Change" to accept the new identity.
''');
      expect(identityFile.readAsStringSync(), 'new identity');
    });

    testWithoutContext(
      'getCodesignIdentity has different warning when codesign cache file does not exist',
      () async {
        final logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(),
        );
        final fs = MemoryFileSystem.test();
        final File identityFile = fs.file('.codesign_identity');
        final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(),
          codesignIdentityOption: 'new identity',
          identityFile: identityFile,
          codesignEnabled: true,
        );
        expect(codesignIdentity, 'new identity');
        expect(logger.statusText, contains('Using code-signing identity: new identity'));
        expect(logger.warningText, '''
   └── Unable to verify if code-signing identity has changed. If this triggers a notice in Xcode,
       select "Accept Change" to accept the new identity.
''');
        expect(identityFile.readAsStringSync(), 'new identity');
      },
    );

    testWithoutContext('getCodesignIdentity throws if tools are not available', () async {
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(validTools: false),
      );
      await expectLater(
        addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(),
          codesignIdentityOption: null,
          identityFile: MemoryFileSystem.test().file('.codesign_identity'),
          codesignEnabled: true,
        ),
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
        addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(),
          codesignIdentityOption: null,
          identityFile: MemoryFileSystem.test().file('.codesign_identity'),
          codesignEnabled: true,
        ),
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
          addtoAppCodesigning.getCodesignIdentity(
            buildInfo: BuildInfo.debug,
            xcodeProject: FakeXcodeBasedProject(),
            codesignIdentityOption: null,
            identityFile: MemoryFileSystem.test().file('.codesign_identity'),
            codesignEnabled: true,
          ),
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
        final File identityFile = fs.file('.codesign_identity');
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
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(
            buildSettings: <String, String>{
              'CODE_SIGN_STYLE': 'Manual',
              'DEVELOPMENT_TEAM': teamId,
              'PROVISIONING_PROFILE_SPECIFIER': provisioningProfileName,
            },
          ),
          codesignIdentityOption: null,
          identityFile: identityFile,
          codesignEnabled: true,
        );
        expect(codesignIdentity, commonName);
        expect(identityFile.readAsStringSync(), commonName);
      },
    );

    testWithoutContext(
      'getCodesignIdentity from project uses team for automatic codesigning',
      () async {
        const userId = 'ABC1DEF23G';
        const entityName = 'User Name';
        const organizationalUnitId = 'A1BC2DF345';
        const commonName = 'Apple Development: $entityName ($userId)';
        final fs = MemoryFileSystem.test();
        final File identityFile = fs.file('.codesign_identity');
        final Logger logger = BufferLogger.test();
        final addtoAppCodesigning = DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
            identities: <String>[commonName],
            identityToTeam: {commonName: organizationalUnitId},
          ),
        );
        final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(
            buildSettings: <String, String>{'DEVELOPMENT_TEAM': organizationalUnitId},
          ),
          codesignIdentityOption: null,
          identityFile: identityFile,
          codesignEnabled: true,
        );
        expect(codesignIdentity, commonName);
        expect(identityFile.readAsStringSync(), commonName);
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
            buildInfo: BuildInfo.debug,
            xcodeProject: FakeXcodeBasedProject(
              buildSettings: <String, String>{'DEVELOPMENT_TEAM': organizationalUnit},
            ),
            codesignIdentityOption: null,
            identityFile: MemoryFileSystem.test().file('.codesign_identity'),
            codesignEnabled: true,
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
      final File identityFile = fs.file('.codesign_identity');
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
        buildInfo: BuildInfo.debug,
        xcodeProject: FakeXcodeBasedProject(),
        codesignIdentityOption: null,
        identityFile: identityFile,
        codesignEnabled: true,
      );
      expect(codesignIdentity, commonName);
      expect(identityFile.readAsStringSync(), commonName);
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
        addtoAppCodesigning.getCodesignIdentity(
          buildInfo: BuildInfo.debug,
          xcodeProject: FakeXcodeBasedProject(),
          codesignIdentityOption: null,
          identityFile: MemoryFileSystem.test().file('.codesign_identity'),
          codesignEnabled: true,
        ),
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
      final fs = MemoryFileSystem.test();
      final File identityFile = fs.file('.codesign_identity');
      final Logger logger = BufferLogger.test();
      final addtoAppCodesigning = DarwinAddToAppCodesigning(
        logger: logger,
        xcodeCodeSigningSettings: FakeXcodeCodeSigningSettings(
          identities: <String>[commonName],
          identityFromCertFromConfig: commonName,
        ),
      );
      final String? codesignIdentity = await addtoAppCodesigning.getCodesignIdentity(
        buildInfo: BuildInfo.debug,
        xcodeProject: FakeXcodeBasedProject(),
        codesignIdentityOption: null,
        identityFile: identityFile,
        codesignEnabled: true,
      );
      expect(codesignIdentity, commonName);
      expect(identityFile.readAsStringSync(), commonName);
    });

    testWithoutContext('codesign for release mode', () async {
      final fs = MemoryFileSystem.test();
      final fakeProcessManager = FakeProcessManager.list([
        const FakeCommand(
          command: [
            'codesign',
            '--force',
            '--sign',
            'Apple Development: ENTITY_NAME (TEAM_ID)',
            'test.xcframework',
          ],
        ),
      ]);
      await DarwinAddToAppCodesigning.codesign(
        artifact: fs.directory('test.xcframework'),
        processManager: fakeProcessManager,
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.release,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('codesign uses timestamp=none for non-release mode', () async {
      final fs = MemoryFileSystem.test();
      final fakeProcessManager = FakeProcessManager.list([
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
      ]);
      await DarwinAddToAppCodesigning.codesign(
        artifact: fs.directory('test.xcframework'),
        processManager: fakeProcessManager,
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('codesignFlutterXCFramework codesigns if not already codesigned', () async {
      final fs = MemoryFileSystem.test();
      final Directory flutterXCFramework = fs.directory('Flutter.xcframework');
      final fakeProcessManager = FakeProcessManager.list([
        const FakeCommand(
          command: ['codesign', '-d', 'Flutter.xcframework'],
          stderr: 'Flutter.xcframework: code object is not signed at all',
        ),
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
      ]);
      await DarwinAddToAppCodesigning.codesignFlutterXCFramework(
        xcframework: flutterXCFramework,
        processManager: fakeProcessManager,
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('codesignFlutterXCFramework skips when already codesigned', () async {
      final fs = MemoryFileSystem.test();
      final Directory flutterXCFramework = fs.directory('Flutter.xcframework');
      final fakeProcessManager = FakeProcessManager.list([
        const FakeCommand(command: ['codesign', '-d', 'Flutter.xcframework']),
      ]);
      await DarwinAddToAppCodesigning.codesignFlutterXCFramework(
        xcframework: flutterXCFramework,
        processManager: fakeProcessManager,
        codesignIdentity: 'Apple Development: ENTITY_NAME (TEAM_ID)',
        buildMode: BuildMode.debug,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
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
