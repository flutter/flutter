// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

const String kCertificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''';

void main() {
  group('Auto signing', () {
    group('with getCodeSigningIdentityDevelopmentTeamBuildSetting', () {
      testWithoutContext('No auto-sign if Xcode project settings are not available', () async {
        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: FakeProcessManager.empty(),
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: BufferLogger.test(),
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );
        expect(signingConfigs, isNull);
      });

      testWithoutContext('No discovery if development team specified in Xcode project', () async {
        final BufferLogger logger = BufferLogger.test();
        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{'DEVELOPMENT_TEAM': 'abc'},
              platform: FakePlatform(operatingSystem: 'macos'),
              processManager: FakeProcessManager.empty(),
              logger: logger,
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );
        expect(signingConfigs, isNull);
        expect(
          logger.statusText,
          equals(
            'Automatically signing iOS for device deployment using specified development team in Xcode project: abc\n',
          ),
        );
        expect(logger.errorText, isEmpty);
        expect(logger.traceText, isEmpty);
      });

      testWithoutContext(
        'No discovery if provisioning profile specified in Xcode project',
        () async {
          final BufferLogger logger = BufferLogger.test();
          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{'PROVISIONING_PROFILE': 'abc'},
                platform: FakePlatform(operatingSystem: 'macos'),
                processManager: FakeProcessManager.empty(),
                logger: logger,
                config: Config.test(),
                terminal: FakeTerminal(),
                fileSystem: MemoryFileSystem.test(),
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: FakePlistParser(),
              );
          expect(signingConfigs, isNull);
          expect(logger.errorText, isEmpty);
          expect(logger.statusText, isEmpty);
          expect(logger.traceText, isEmpty);
        },
      );

      testWithoutContext(
        'throws error with instructions when no valid code signing certificates',
        () async {
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            ),
          ]);
          final BufferLogger logger = BufferLogger.test();
          await expectLater(
            () => getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              platform: FakePlatform(operatingSystem: 'macos'),
              processManager: processManager,
              logger: logger,
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            ),
            throwsToolExit(
              message:
                  'No development certificates available to code sign app for device deployment',
            ),
          );
          expect(logger.errorText, contains(noCertificatesInstruction));
        },
      );

      testWithoutContext('No auto-sign if security or openssl not available', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security'], exitCode: 1),
        ]);
        final BufferLogger logger = BufferLogger.test();

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );
        expect(signingConfigs, isNull);
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('Unable to validate code-signing tools'));
        expect(logger.errorText, isEmpty);
      });

      testWithoutContext('No valid code signing certificates on non-macOS platform', () async {
        final FakeProcessManager processManager = FakeProcessManager.empty();
        final BufferLogger logger = BufferLogger.test();

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(),
              logger: logger,
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        expect(signingConfigs, isNull);
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.traceText, contains('Unable to get code-sign settings on non-Mac platform'));
      });

      testWithoutContext('uses saved provisioning profile', () async {
        final Config testConfig = Config.test();
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final BufferLogger logger = BufferLogger.test();
        const String profileFilePath =
            '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
        fileSystem.file(profileFilePath).createSync(recursive: true);
        testConfig.setValue('ios-signing-profile', profileFilePath);

        final File profilePlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
        );
        final File cert = fileSystem.file(
          '/.tmp_rand0/provisioning_profile_certificates/UUID1234_0.cer',
        );

        final FakePlistParser plistParser = FakePlistParser(
          parsedValues: <Map<String, Object>>[
            <String, Object>{
              'Name': 'Company Development',
              'ExpirationDate': '2026-02-20T16:04:31Z',
              'IsXcodeManaged': false,
              'DeveloperCertificates': <List<int>>[
                <int>[0, 1, 2, 3],
              ],
              'TeamIdentifier': <String>['ABCDE1F2DH'],
              'UUID': 'UUID1234',
            },
          ],
        );
        const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Company Development (12ABCD234E)"
    1 valid identities found''';
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: certificates,
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              profileFilePath,
              '-o',
              profilePlist.path,
            ],
            onRun: (List<String> command) => profilePlist.createSync(recursive: true),
          ),
          FakeCommand(
            command: <String>['openssl', 'x509', '-subject', '-in', cert.path, '-inform', 'DER'],
            stdout:
                'subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
          ),
        ]);

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: testConfig,
              terminal: FakeTerminal(),
              fileSystem: fileSystem,
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: plistParser,
            );

        expect(processManager, hasNoRemainingExpectations);
        expect(cert.existsSync(), isTrue);
        expect(cert.readAsBytesSync(), <int>[0, 1, 2, 3]);
        expect(
          logger.statusText,
          contains('Provisioning profile "Company Development" selected for iOS code signing'),
        );
        expect(signingConfigs, <String, String>{
          'CODE_SIGN_STYLE': 'Manual',
          'DEVELOPMENT_TEAM': 'ABCDE1F2DH',
          'PROVISIONING_PROFILE_SPECIFIER': 'Company Development',
        });
      });

      testWithoutContext('does not use saved provisioning profile if does not exist', () async {
        final Config testConfig = Config.test();
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final BufferLogger logger = BufferLogger.test();
        const String profileFilePath =
            '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
        testConfig.setValue('ios-signing-profile', profileFilePath);

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
        ]);

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: testConfig,
              terminal: FakeTerminal(),
              fileSystem: fileSystem,
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        expect(processManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('Unable to find saved provisioning profile'));
        expect(signingConfigs, isNull);
      });

      testWithoutContext(
        'does not use saved provisioning profile if security fails to decode',
        () async {
          final Config testConfig = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final BufferLogger logger = BufferLogger.test();
          const String profileFilePath =
              '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
          fileSystem.file(profileFilePath).createSync(recursive: true);
          testConfig.setValue('ios-signing-profile', profileFilePath);
          final File profilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
          );

          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: kCertificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                profileFilePath,
                '-o',
                profilePlist.path,
              ],
              exitCode: 1,
            ),
          ]);

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{},
                processManager: processManager,
                platform: FakePlatform(operatingSystem: 'macos'),
                logger: logger,
                config: testConfig,
                terminal: FakeTerminal(),
                fileSystem: fileSystem,
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: FakePlistParser(),
              );

          expect(processManager, hasNoRemainingExpectations);
          expect(logger.errorText, contains('Unexpected failure from security'));
          expect(signingConfigs, isNull);
        },
      );

      testWithoutContext(
        'does not use saved provisioning profile if security fails to create plist',
        () async {
          final Config testConfig = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final BufferLogger logger = BufferLogger.test();
          const String profileFilePath =
              '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
          fileSystem.file(profileFilePath).createSync(recursive: true);
          testConfig.setValue('ios-signing-profile', profileFilePath);
          final File profilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
          );

          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: kCertificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                profileFilePath,
                '-o',
                profilePlist.path,
              ],
            ),
          ]);

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{},
                processManager: processManager,
                platform: FakePlatform(operatingSystem: 'macos'),
                logger: logger,
                config: testConfig,
                terminal: FakeTerminal(),
                fileSystem: fileSystem,
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: FakePlistParser(),
              );

          expect(processManager, hasNoRemainingExpectations);
          expect(logger.errorText, contains('Failed to decode'));
          expect(signingConfigs, isNull);
        },
      );

      testWithoutContext('does not use saved provisioning profile if fails to parse plist', () async {
        final Config testConfig = Config.test();
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final BufferLogger logger = BufferLogger.test();
        const String profileFilePath =
            '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
        fileSystem.file(profileFilePath).createSync(recursive: true);
        testConfig.setValue('ios-signing-profile', profileFilePath);
        final File profilePlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
        );

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              profileFilePath,
              '-o',
              profilePlist.path,
            ],
            onRun: (List<String> command) => profilePlist.createSync(recursive: true),
          ),
        ]);

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: testConfig,
              terminal: FakeTerminal(),
              fileSystem: fileSystem,
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        expect(processManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('Failed to parse provisioning profile'));
        expect(signingConfigs, isNull);
      });

      testWithoutContext(
        'does not uses saved provisioning profile if openssl fails to read cert',
        () async {
          final Config testConfig = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final BufferLogger logger = BufferLogger.test();
          const String profileFilePath =
              '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
          fileSystem.file(profileFilePath).createSync(recursive: true);
          testConfig.setValue('ios-signing-profile', profileFilePath);

          final File profilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
          );
          final File cert = fileSystem.file(
            '/.tmp_rand0/provisioning_profile_certificates/UUID1234_0.cer',
          );

          final FakePlistParser plistParser = FakePlistParser(
            parsedValues: <Map<String, Object>>[
              <String, Object>{
                'Name': 'Flutter Development',
                'ExpirationDate': '2026-02-20T16:04:31Z',
                'IsXcodeManaged': false,
                'DeveloperCertificates': <List<int>>[
                  <int>[0, 1, 2, 3],
                ],
                'TeamIdentifier': <String>['ABCDE1F2DH'],
                'UUID': 'UUID1234',
              },
            ],
          );
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: kCertificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                profileFilePath,
                '-o',
                profilePlist.path,
              ],
              onRun: (List<String> command) => profilePlist.createSync(recursive: true),
            ),
            FakeCommand(
              command: <String>['openssl', 'x509', '-subject', '-in', cert.path, '-inform', 'DER'],
              exitCode: 1,
            ),
          ]);

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{},
                processManager: processManager,
                platform: FakePlatform(operatingSystem: 'macos'),
                logger: logger,
                config: testConfig,
                terminal: FakeTerminal(),
                fileSystem: fileSystem,
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: plistParser,
              );

          expect(processManager, hasNoRemainingExpectations);
          expect(logger.errorText, contains('Unexpected failure from openssl'));
          expect(signingConfigs, isNull);
        },
      );

      testWithoutContext(
        'does not uses saved provisioning profile if fails to parse common name from cert',
        () async {
          final Config testConfig = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final BufferLogger logger = BufferLogger.test();
          const String profileFilePath =
              '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
          fileSystem.file(profileFilePath).createSync(recursive: true);
          testConfig.setValue('ios-signing-profile', profileFilePath);

          final File profilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
          );
          final File cert = fileSystem.file(
            '/.tmp_rand0/provisioning_profile_certificates/UUID1234_0.cer',
          );

          final FakePlistParser plistParser = FakePlistParser(
            parsedValues: <Map<String, Object>>[
              <String, Object>{
                'Name': 'Flutter Development',
                'ExpirationDate': '2026-02-20T16:04:31Z',
                'IsXcodeManaged': false,
                'DeveloperCertificates': <List<int>>[
                  <int>[0, 1, 2, 3],
                ],
                'TeamIdentifier': <String>['ABCDE1F2DH'],
                'UUID': 'UUID1234',
              },
            ],
          );
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: kCertificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                profileFilePath,
                '-o',
                profilePlist.path,
              ],
              onRun: (List<String> command) => profilePlist.createSync(recursive: true),
            ),
            FakeCommand(
              command: <String>['openssl', 'x509', '-subject', '-in', cert.path, '-inform', 'DER'],
            ),
          ]);

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{},
                processManager: processManager,
                platform: FakePlatform(operatingSystem: 'macos'),
                logger: logger,
                config: testConfig,
                terminal: FakeTerminal(),
                fileSystem: fileSystem,
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: plistParser,
              );

          expect(processManager, hasNoRemainingExpectations);
          expect(logger.errorText, contains('Unable to extract Common Name from certificate'));
          expect(signingConfigs, isNull);
        },
      );

      testWithoutContext(
        'does not use saved provisioning profile if fails to find matching identity',
        () async {
          final Config testConfig = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final BufferLogger logger = BufferLogger.test();
          const String profileFilePath =
              '/path/to/profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision';
          fileSystem.file(profileFilePath).createSync(recursive: true);
          testConfig.setValue('ios-signing-profile', profileFilePath);

          final File profilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision.plist',
          );
          final File cert = fileSystem.file(
            '/.tmp_rand0/provisioning_profile_certificates/UUID1234_0.cer',
          );

          final FakePlistParser plistParser = FakePlistParser(
            parsedValues: <Map<String, Object>>[
              <String, Object>{
                'Name': 'Flutter Development',
                'ExpirationDate': '2026-02-20T16:04:31Z',
                'IsXcodeManaged': false,
                'DeveloperCertificates': <List<int>>[
                  <int>[0, 1, 2, 3],
                ],
                'TeamIdentifier': <String>['ABCDE1F2DH'],
                'UUID': 'UUID1234',
              },
            ],
          );
          const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Not a Match (12ABCD234E)"
    1 valid identities found''';
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: certificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                profileFilePath,
                '-o',
                profilePlist.path,
              ],
              onRun: (List<String> command) => profilePlist.createSync(recursive: true),
            ),
            FakeCommand(
              command: <String>['openssl', 'x509', '-subject', '-in', cert.path, '-inform', 'DER'],
              stdout:
                  'subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
            ),
          ]);

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{},
                processManager: processManager,
                platform: FakePlatform(operatingSystem: 'macos'),
                logger: logger,
                config: testConfig,
                terminal: FakeTerminal(),
                fileSystem: fileSystem,
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: plistParser,
              );

          expect(processManager, hasNoRemainingExpectations);
          expect(
            logger.errorText,
            contains('Unable to find a valid certificate matching the provisioning profile'),
          );
          expect(signingConfigs, isNull);
        },
      );

      testWithoutContext(
        'Test single identity and certificate organization development team build setting',
        () async {
          final Completer<void> completer = Completer<void>();
          final StreamController<List<int>> controller = StreamController<List<int>>();
          const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    1 valid identities found''';
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: certificates,
            ),
            const FakeCommand(
              command: <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
              stdout: 'This is a fake certificate',
            ),
            FakeCommand(
              command: const <String>['openssl', 'x509', '-subject'],
              stdin: IOSink(controller.sink),
              stdout:
                  'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US',
              completer: completer,
            ),
          ]);

          // Verify that certificate value is passed into openssl command.
          String? stdin;
          controller.stream.listen((List<int> chunk) {
            stdin = utf8.decode(chunk);
            completer.complete();
          });

          final BufferLogger logger = BufferLogger.test();

          final Map<String, String>? signingConfigs =
              await getCodeSigningIdentityDevelopmentTeamBuildSetting(
                buildSettings: <String, String>{'bogus': 'bogus'},
                platform: FakePlatform(operatingSystem: 'macos'),
                processManager: processManager,
                logger: logger,
                config: Config.test(),
                terminal: FakeTerminal(),
                fileSystem: MemoryFileSystem.test(),
                fileSystemUtils: FakeFileSystemUtils(),
                plistParser: FakePlistParser(),
              );

          expect(logger.statusText, contains('iPhone Developer: Profile 1 (1111AAAA11)'));
          expect(logger.errorText, isEmpty);
          expect(stdin, 'This is a fake certificate');
          expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '3333CCCC33'});
          expect(processManager, hasNoRemainingExpectations);
        },
      );

      testWithoutContext(
        'Test auto-select single identity and certificate organization development team',
        () async {
          final Completer<void> completer = Completer<void>();
          final StreamController<List<int>> controller = StreamController<List<int>>();
          const String certificates = '''
    1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
        1 valid identities found''';
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: certificates,
            ),
            const FakeCommand(
              command: <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
              stdout: 'This is a fake certificate',
            ),
            FakeCommand(
              command: const <String>['openssl', 'x509', '-subject'],
              stdin: IOSink(controller.sink),
              stdout:
                  'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US',
              completer: completer,
            ),
          ]);

          // Verify that certificate value is passed into openssl command.
          String? stdin;
          controller.stream.listen((List<int> chunk) {
            stdin = utf8.decode(chunk);
            completer.complete();
          });
          final Config testConfig = Config.test();
          final BufferLogger logger = BufferLogger.test();
          final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
            processManager: processManager,
            platform: FakePlatform(operatingSystem: 'macos'),
            logger: logger,
            config: testConfig,
            terminal: FakeTerminal(),
            fileSystem: MemoryFileSystem.test(),
            fileSystemUtils: FakeFileSystemUtils(),
            plistParser: FakePlistParser(),
          );

          expect(logger.statusText, contains('iPhone Developer: Profile 1 (1111AAAA11)'));
          expect(logger.errorText, isEmpty);
          expect(stdin, 'This is a fake certificate');
          expect(developmentTeam, '3333CCCC33');
          expect(testConfig.getValue('ios-signing-cert'), isNull);
          expect(processManager, hasNoRemainingExpectations);
        },
      );

      testWithoutContext(
        'Test single identity (Catalina format) and certificate organization works',
        () async {
          final Completer<void> completer = Completer<void>();
          final StreamController<List<int>> controller = StreamController<List<int>>();
          const String certificates = '''
    1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Profile 1 (1111AAAA11)"
        1 valid identities found''';
          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: certificates,
            ),
            const FakeCommand(
              command: <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
              stdout: 'This is a fake certificate',
            ),
            FakeCommand(
              command: const <String>['openssl', 'x509', '-subject'],
              stdin: IOSink(controller.sink),
              stdout:
                  'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US',
              completer: completer,
            ),
          ]);

          // Verify that certificate value is passed into openssl command.
          String? stdin;
          controller.stream.listen((List<int> chunk) {
            stdin = utf8.decode(chunk);
            completer.complete();
          });
          final BufferLogger logger = BufferLogger.test();
          final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
            processManager: processManager,
            platform: FakePlatform(operatingSystem: 'macos'),
            logger: logger,
            config: Config.test(),
            terminal: FakeTerminal(),
            fileSystem: MemoryFileSystem.test(),
            fileSystemUtils: FakeFileSystemUtils(),
            plistParser: FakePlistParser(),
          );

          expect(logger.statusText, contains('Apple Development: Profile 1 (1111AAAA11)'));
          expect(logger.errorText, isEmpty);
          expect(stdin, 'This is a fake certificate');
          expect(developmentTeam, '3333CCCC33');
          expect(processManager, hasNoRemainingExpectations);
        },
      );

      testWithoutContext('Test multiple identity and certificate organization works', () async {
        final Completer<void> completer = Completer<void>();
        final StreamController<List<int>> controller = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(controller.sink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        // Verify that certificate value is passed into openssl command.
        String? stdin;
        controller.stream.listen((List<int> chunk) {
          stdin = utf8.decode(chunk);
          completer.complete();
        });

        final BufferLogger logger = BufferLogger.test();
        final Config testConfig = Config.test();
        final FakeTerminal testTerminal = FakeTerminal();
        testTerminal.setPrompt(<String>['1', '2', '3', 'q'], '3');

        final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
          processManager: processManager,
          platform: FakePlatform(operatingSystem: 'macos'),
          logger: logger,
          config: testConfig,
          terminal: testTerminal,
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          plistParser: FakePlistParser(),
        );

        expect(
          logger.statusText,
          contains(
            'Developer identity "iPhone Developer: Profile 3 (3333CCCC33)" selected for iOS code signing',
          ),
        );
        expect(logger.errorText, isEmpty);
        expect(stdin, 'This is a fake certificate');
        expect(developmentTeam, '4444DDDD44');
        expect(testConfig.getValue('ios-signing-cert'), 'iPhone Developer: Profile 3 (3333CCCC33)');
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Test auto-select from multiple identity in machine mode works', () async {
        final Completer<void> completer = Completer<void>();
        final StreamController<List<int>> controller = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(controller.sink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 3 (1111AAAA11)/OU=5555EEEE55/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        // Verify that certificate value is passed into openssl command.
        String? stdin;
        controller.stream.listen((List<int> chunk) {
          stdin = utf8.decode(chunk);
          completer.complete();
        });

        final BufferLogger logger = BufferLogger.test();
        final Config testConfig = Config.test();

        final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
          processManager: processManager,
          platform: FakePlatform(operatingSystem: 'macos'),
          logger: logger,
          config: testConfig,
          terminal: FakeTerminal(stdinHasTerminal: false),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          plistParser: FakePlistParser(),
        );

        expect(
          logger.statusText,
          contains(
            'Developer identity "iPhone Developer: Profile 1 (1111AAAA11)" selected for iOS code signing',
          ),
        );
        expect(logger.errorText, isEmpty);
        expect(stdin, 'This is a fake certificate');
        expect(developmentTeam, '5555EEEE55');
        expect(testConfig.getValue('ios-signing-cert'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Test saved certificate used', () async {
        final Config testConfig = Config.test();
        final BufferLogger logger = BufferLogger.test();
        testConfig.setValue('ios-signing-cert', 'iPhone Developer: Profile 3 (3333CCCC33)');
        final Completer<void> completer = Completer<void>();
        final StreamController<List<int>> controller = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(controller.sink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        // Verify that certificate value is passed into openssl command.
        String? stdin;
        controller.stream.listen((List<int> chunk) {
          stdin = utf8.decode(chunk);
          completer.complete();
        });

        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: testConfig,
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        expect(
          logger.statusText,
          contains(
            'Found saved certificate choice "iPhone Developer: Profile 3 (3333CCCC33)". To clear, use "flutter config --clear-ios-signing-settings"',
          ),
        );
        expect(
          logger.statusText,
          contains(
            'Developer identity "iPhone Developer: Profile 3 (3333CCCC33)" selected for iOS code signing',
          ),
        );
        expect(logger.errorText, isEmpty);
        expect(stdin, 'This is a fake certificate');
        expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Test invalid saved certificate shows error and prompts again', () async {
        final Config testConfig = Config.test();
        testConfig.setValue('ios-signing-cert', 'iPhone Developer: Invalid Profile');
        final Completer<void> completer = Completer<void>();
        final StreamController<List<int>> controller = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(controller.sink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        final FakeTerminal testTerminal = FakeTerminal();
        testTerminal.setPrompt(<String>['1', '2', '3', 'q'], '3');

        // Verify that certificate value is passed into openssl command.
        String? stdin;
        controller.stream.listen((List<int> chunk) {
          stdin = utf8.decode(chunk);
          completer.complete();
        });
        final BufferLogger logger = BufferLogger.test();
        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: testConfig,
              terminal: testTerminal,
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        expect(
          logger.errorText,
          containsIgnoringWhitespace(
            'Saved signing certificate "iPhone Developer: Invalid Profile" is not a valid development certificate',
          ),
        );
        expect(
          logger.statusText,
          contains('Certificate choice "iPhone Developer: Profile 3 (3333CCCC33)"'),
        );
        expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
        expect(stdin, 'This is a fake certificate');
        expect(testConfig.getValue('ios-signing-cert'), 'iPhone Developer: Profile 3 (3333CCCC33)');
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('find-identity failure', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            exitCode: 1,
          ),
        ]);

        await expectLater(
          () => getCodeSigningIdentityDevelopmentTeamBuildSetting(
            buildSettings: <String, String>{},
            platform: FakePlatform(operatingSystem: 'macos'),
            processManager: processManager,
            logger: BufferLogger.test(),
            config: Config.test(),
            terminal: FakeTerminal(),
            fileSystem: MemoryFileSystem.test(),
            fileSystemUtils: FakeFileSystemUtils(),
            plistParser: FakePlistParser(),
          ),
          throwsToolExit(
            message: 'No development certificates available to code sign app for device deployment',
          ),
        );
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('find-certificate failure', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
            exitCode: 1,
          ),
        ]);

        final FakeTerminal testTerminal = FakeTerminal();
        testTerminal.setPrompt(<String>['1', '2', '3', 'q'], '3');
        final BufferLogger logger = BufferLogger.test();
        final Map<String, String>? signingConfigs =
            await getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: <String, String>{},
              processManager: processManager,
              platform: FakePlatform(operatingSystem: 'macos'),
              logger: logger,
              config: Config.test(),
              terminal: testTerminal,
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );
        expect(signingConfigs, isNull);
        expect(processManager, hasNoRemainingExpectations);
        expect(logger.errorText, contains('Unexpected error from security'));
      });

      testWithoutContext('handles stdin pipe breaking on openssl process', () async {
        final StreamSink<List<int>> stdinSink = ClosedStdinController();

        final Completer<void> completer = Completer<void>();
        const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    1 valid identities found''';
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: certificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(stdinSink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        Future<Map<String, String>?> getCodeSigningIdentities() =>
            getCodeSigningIdentityDevelopmentTeamBuildSetting(
              buildSettings: const <String, String>{'bogus': 'bogus'},
              platform: FakePlatform(operatingSystem: 'macos'),
              processManager: processManager,
              logger: BufferLogger.test(),
              config: Config.test(),
              terminal: FakeTerminal(),
              fileSystem: MemoryFileSystem.test(),
              fileSystemUtils: FakeFileSystemUtils(),
              plistParser: FakePlistParser(),
            );

        await expectLater(
          () => getCodeSigningIdentities(),
          throwsA(
            const TypeMatcher<Exception>().having(
              (Exception e) => e.toString(),
              'message',
              equals(
                'Exception: Unexpected error when writing to openssl: SocketException: Bad pipe',
              ),
            ),
          ),
        );
      });
    });

    group('with getCodeSigningIdentityDevelopmentTeam', () {
      testWithoutContext('does not error when no valid code signing certificates', () async {
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
          ),
        ]);

        final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
          processManager: processManager,
          platform: FakePlatform(operatingSystem: 'macos'),
          logger: BufferLogger.test(),
          config: Config.test(),
          terminal: FakeTerminal(),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          plistParser: FakePlistParser(),
        );

        expect(developmentTeam, isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('does not use saved provisioning profile', () async {
        final Config testConfig = Config.test();
        testConfig.setValue(
          'ios-signing-profile',
          'Profiles/1234567a-bcde-89f0-1234-g56hi567j8kl.mobileprovision',
        );

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
        ]);

        final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
          processManager: processManager,
          platform: FakePlatform(operatingSystem: 'macos'),
          logger: BufferLogger.test(),
          config: testConfig,
          terminal: FakeTerminal(),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          plistParser: FakePlistParser(),
        );

        expect(developmentTeam, isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('Test saved certificate used', () async {
        final Config testConfig = Config.test();
        final BufferLogger logger = BufferLogger.test();
        testConfig.setValue('ios-signing-cert', 'iPhone Developer: Profile 3 (3333CCCC33)');
        final Completer<void> completer = Completer<void>();
        final StreamController<List<int>> controller = StreamController<List<int>>();
        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
          const FakeCommand(
            command: <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
            stdout: 'This is a fake certificate',
          ),
          FakeCommand(
            command: const <String>['openssl', 'x509', '-subject'],
            stdin: IOSink(controller.sink),
            stdout:
                'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US',
            completer: completer,
          ),
        ]);

        // Verify that certificate value is passed into openssl command.
        String? stdin;
        controller.stream.listen((List<int> chunk) {
          stdin = utf8.decode(chunk);
          completer.complete();
        });

        final String? developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
          processManager: processManager,
          platform: FakePlatform(operatingSystem: 'macos'),
          logger: logger,
          config: testConfig,
          terminal: FakeTerminal(),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          plistParser: FakePlistParser(),
        );

        expect(
          logger.statusText,
          contains(
            'Found saved certificate choice "iPhone Developer: Profile 3 (3333CCCC33)". To clear, use "flutter config --clear-ios-signing-settings"',
          ),
        );
        expect(
          logger.statusText,
          contains(
            'Developer identity "iPhone Developer: Profile 3 (3333CCCC33)" selected for iOS code signing',
          ),
        );
        expect(logger.errorText, isEmpty);
        expect(stdin, 'This is a fake certificate');
        expect(developmentTeam, '4444DDDD44');
        expect(processManager, hasNoRemainingExpectations);
      });
    });
  });

  group('Select signing', () {
    testWithoutContext('cancels if terminal does not have stdin', () async {
      final BufferLogger logger = BufferLogger.test();
      final Config config = Config.test();
      final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        fileSystem: MemoryFileSystem.test(),
        fileSystemUtils: FakeFileSystemUtils(),
        processUtils: ProcessUtils(processManager: FakeProcessManager.empty(), logger: logger),
        terminal: FakeTerminal(stdinHasTerminal: false),
        plistParser: FakePlistParser(),
      );
      await settings.selectSettings();
      expect(logger.errorText, contains('Unable to detect stdin for the terminal'));
      expect(config.getValue('ios-signing-cert'), isNull);
      expect(config.getValue('ios-signing-profile'), isNull);
    });

    testWithoutContext('cancels if code-signing tools are not found', () async {
      final BufferLogger logger = BufferLogger.test();
      final Config config = Config.test();
      final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        fileSystem: MemoryFileSystem.test(),
        fileSystemUtils: FakeFileSystemUtils(),
        processUtils: ProcessUtils(processManager: FakeProcessManager.empty(), logger: logger),
        terminal: FakeTerminal(),
        plistParser: FakePlistParser(),
      );
      await settings.selectSettings();
      expect(logger.errorText, contains('Unable to validate code-signing tools'));
      expect(config.getValue('ios-signing-cert'), isNull);
      expect(config.getValue('ios-signing-profile'), isNull);
    });

    testWithoutContext('cancels if signing cert already saved', () async {
      final BufferLogger logger = BufferLogger.test();
      final Config config = Config.test();
      config.setValue('ios-signing-cert', 'some value');
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['which', 'security']),
        const FakeCommand(command: <String>['which', 'openssl']),
      ]);
      final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        fileSystem: MemoryFileSystem.test(),
        fileSystemUtils: FakeFileSystemUtils(),
        processUtils: ProcessUtils(processManager: processManager, logger: logger),
        terminal: FakeTerminal(),
        plistParser: FakePlistParser(),
      );
      await settings.selectSettings();
      expect(logger.errorText, contains('Code-signing settings are already set'));
      expect(config.getValue('ios-signing-cert'), 'some value');
      expect(config.getValue('ios-signing-profile'), isNull);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('cancels if signing profile already saved', () async {
      final BufferLogger logger = BufferLogger.test();
      final Config config = Config.test();
      config.setValue('ios-signing-profile', 'some value');
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['which', 'security']),
        const FakeCommand(command: <String>['which', 'openssl']),
      ]);
      final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        fileSystem: MemoryFileSystem.test(),
        fileSystemUtils: FakeFileSystemUtils(),
        processUtils: ProcessUtils(processManager: processManager, logger: logger),
        terminal: FakeTerminal(),
        plistParser: FakePlistParser(),
      );
      await settings.selectSettings();
      expect(logger.errorText, contains('Code-signing settings are already set'));
      expect(config.getValue('ios-signing-cert'), isNull);
      expect(config.getValue('ios-signing-profile'), 'some value');
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('cancels if quit while selecting code signing style', () async {
      final BufferLogger logger = BufferLogger.test();
      final Config config = Config.test();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['which', 'security']),
        const FakeCommand(command: <String>['which', 'openssl']),
      ]);
      final FakeTerminal terminal = FakeTerminal();
      terminal.setPrompt(<String>['1', '2', 'q'], 'q');

      final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
        config: config,
        logger: logger,
        platform: FakePlatform(operatingSystem: 'macos'),
        fileSystem: MemoryFileSystem.test(),
        fileSystemUtils: FakeFileSystemUtils(),
        processUtils: ProcessUtils(processManager: processManager, logger: logger),
        terminal: terminal,
        plistParser: FakePlistParser(),
      );
      await settings.selectSettings();
      expect(
        logger.warningText,
        contains('Code-signing setup canceled. Your changes have not been saved.'),
      );
      expect(config.getValue('ios-signing-cert'), isNull);
      expect(config.getValue('ios-signing-profile'), isNull);
      expect(processManager, hasNoRemainingExpectations);
    });

    group('with automatic code signing style', () {
      testWithoutContext('cancels if no identities are found', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '1');

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
          ),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: FakePlistParser(),
        );
        await settings.selectSettings();

        expect(logger.errorText, contains(noCertificatesInstruction));
        expect(
          logger.warningText,
          contains('Code-signing setup canceled. Your changes have not been saved.'),
        );
        expect(config.getValue('ios-signing-cert'), isNull);
        expect(config.getValue('ios-signing-profile'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('cancels if quit while selecting identity', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '1');
        unawaited(
          terminal.promptCompleter.future.whenComplete(() {
            terminal.setPrompt(<String>['1', '2', '3', 'q'], 'q');
          }),
        );

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: FakePlistParser(),
        );
        await settings.selectSettings();

        expect(
          logger.warningText,
          contains('Code-signing setup canceled. Your changes have not been saved.'),
        );
        expect(config.getValue('ios-signing-cert'), isNull);
        expect(config.getValue('ios-signing-profile'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('saves to config after selection', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '1');
        unawaited(
          terminal.promptCompleter.future.whenComplete(() {
            terminal.setPrompt(<String>['1', '2', '3', 'q'], '3');
          }),
        );

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: kCertificates,
          ),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: FakePlistParser(),
        );
        await settings.selectSettings();

        expect(logger.warningText, isEmpty);
        expect(config.getValue('ios-signing-cert'), 'iPhone Developer: Profile 3 (3333CCCC33)');
        expect(config.getValue('ios-signing-profile'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });
    });

    group('with manual code signing style', () {
      testWithoutContext('cancels if no profiles are found', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '2');

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: MemoryFileSystem.test(),
          fileSystemUtils: FakeFileSystemUtils(),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: FakePlistParser(),
        );
        await settings.selectSettings();

        expect(logger.errorText, contains('No provisioning profiles were found'));
        expect(
          logger.warningText,
          contains('Code-signing setup canceled. Your changes have not been saved.'),
        );
        expect(config.getValue('ios-signing-cert'), isNull);
        expect(config.getValue('ios-signing-profile'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext('cancels if quit while selecting profile', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '2');
        unawaited(
          terminal.promptCompleter.future.whenComplete(() {
            terminal.setPrompt(<String>['1', '2', 'q'], 'q');
          }),
        );

        const String homeDir = '/Users/username';

        final Directory profileDirectory = fileSystem.directory(
          fileSystem.path.join(
            homeDir,
            'Library',
            'Developer',
            'Xcode',
            'UserData',
            'Provisioning Profiles',
          ),
        );
        final File validProfile = profileDirectory.childFile('profile1.mobileprovision')
          ..createSync(recursive: true);
        final File validProfilePlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_profile1.mobileprovision.plist',
        );
        final File validProfileCert = fileSystem.file(
          '/.tmp_rand0/provisioning_profile_certificates/UUIDProfile1_0.cer',
        );

        final FakePlistParser plistParser = FakePlistParser(
          parsedValues: <Map<String, Object>>[
            <String, Object>{
              'Name': 'Company Development',
              'ExpirationDate': '2026-02-20T16:04:31Z',
              'IsXcodeManaged': false,
              'DeveloperCertificates': <List<int>>[
                <int>[0, 1, 2, 3],
              ],
              'TeamIdentifier': <String>['ABCDE1F2DH'],
              'UUID': 'UUIDProfile1',
            },
          ],
        );
        const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Company Development (12ABCD234E)"
    1 valid identities found''';

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: certificates,
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              validProfile.path,
              '-o',
              validProfilePlist.path,
            ],
            onRun: (List<String> command) => validProfilePlist.createSync(recursive: true),
          ),
          FakeCommand(
            command: <String>[
              'openssl',
              'x509',
              '-subject',
              '-in',
              validProfileCert.path,
              '-inform',
              'DER',
            ],
            stdout:
                'subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
          ),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: fileSystem,
          fileSystemUtils: FakeFileSystemUtils(homeDirPath: homeDir),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: plistParser,
        );
        await settings.selectSettings();

        expect(logger.errorText, isEmpty);
        expect(
          logger.warningText,
          contains('Code-signing setup canceled. Your changes have not been saved.'),
        );
        expect(config.getValue('ios-signing-cert'), isNull);
        expect(config.getValue('ios-signing-profile'), isNull);
        expect(processManager, hasNoRemainingExpectations);
      });

      testWithoutContext(
        'cancels if "Other (not listed)" selected while selecting profile',
        () async {
          final BufferLogger logger = BufferLogger.test();
          final Config config = Config.test();
          final MemoryFileSystem fileSystem = MemoryFileSystem.test();
          final FakeTerminal terminal = FakeTerminal();
          terminal.setPrompt(<String>['1', '2', 'q'], '2');
          unawaited(
            terminal.promptCompleter.future.whenComplete(() {
              terminal.setPrompt(<String>['1', '2', 'q'], '2');
            }),
          );

          const String homeDir = '/Users/username';

          final Directory profileDirectory = fileSystem.directory(
            fileSystem.path.join(
              homeDir,
              'Library',
              'Developer',
              'Xcode',
              'UserData',
              'Provisioning Profiles',
            ),
          );
          final File validProfile = profileDirectory.childFile('profile1.mobileprovision')
            ..createSync(recursive: true);
          final File validProfilePlist = fileSystem.file(
            '/.tmp_rand0/provisioning_profiles/decoded_profile_profile1.mobileprovision.plist',
          );
          final File validProfileCert = fileSystem.file(
            '/.tmp_rand0/provisioning_profile_certificates/UUIDProfile1_0.cer',
          );

          final FakePlistParser plistParser = FakePlistParser(
            parsedValues: <Map<String, Object>>[
              <String, Object>{
                'Name': 'Company Development',
                'ExpirationDate': '2026-02-20T16:04:31Z',
                'IsXcodeManaged': false,
                'DeveloperCertificates': <List<int>>[
                  <int>[0, 1, 2, 3],
                ],
                'TeamIdentifier': <String>['ABCDE1F2DH'],
                'UUID': 'UUIDProfile1',
              },
            ],
          );
          const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Company Development (12ABCD234E)"
    1 valid identities found''';

          final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['which', 'security']),
            const FakeCommand(command: <String>['which', 'openssl']),
            const FakeCommand(
              command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
              stdout: certificates,
            ),
            FakeCommand(
              command: <String>[
                'security',
                'cms',
                '-D',
                '-i',
                validProfile.path,
                '-o',
                validProfilePlist.path,
              ],
              onRun: (List<String> command) => validProfilePlist.createSync(recursive: true),
            ),
            FakeCommand(
              command: <String>[
                'openssl',
                'x509',
                '-subject',
                '-in',
                validProfileCert.path,
                '-inform',
                'DER',
              ],
              stdout:
                  'subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
            ),
          ]);

          final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: FakePlatform(operatingSystem: 'macos'),
            fileSystem: fileSystem,
            fileSystemUtils: FakeFileSystemUtils(homeDirPath: homeDir),
            processUtils: ProcessUtils(processManager: processManager, logger: logger),
            terminal: terminal,
            plistParser: plistParser,
          );
          await settings.selectSettings();

          expect(
            logger.errorText,
            contains('If you have already downloaded a provisioning profile'),
          );
          expect(
            logger.warningText,
            contains('Code-signing setup canceled. Your changes have not been saved.'),
          );
          expect(config.getValue('ios-signing-cert'), isNull);
          expect(config.getValue('ios-signing-profile'), isNull);
          expect(processManager, hasNoRemainingExpectations);
        },
      );

      testWithoutContext('saves to config after selecting', () async {
        final BufferLogger logger = BufferLogger.test();
        final Config config = Config.test();
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final FakeTerminal terminal = FakeTerminal();
        terminal.setPrompt(<String>['1', '2', 'q'], '2');
        unawaited(
          terminal.promptCompleter.future.whenComplete(() {
            terminal.setPrompt(<String>['1', '2', 'q'], '1');
          }),
        );

        const String homeDir = '/Users/username';

        final Directory profileDirectory = fileSystem.directory(
          fileSystem.path.join(
            homeDir,
            'Library',
            'Developer',
            'Xcode',
            'UserData',
            'Provisioning Profiles',
          ),
        );
        final File validProfile = profileDirectory.childFile('profile1.mobileprovision')
          ..createSync(recursive: true);
        final File validProfilePlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_profile1.mobileprovision.plist',
        );
        final File validProfileInvalidCert = fileSystem.file(
          '/.tmp_rand0/provisioning_profile_certificates/UUIDProfile1_0.cer',
        );
        final File validProfileValidCert = fileSystem.file(
          '/.tmp_rand0/provisioning_profile_certificates/UUIDProfile1_1.cer',
        );

        final File xcodeManagedProfile = profileDirectory.childFile('profile2.mobileprovision')
          ..createSync(recursive: true);
        final File xcodeManagedProfilePlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_profile2.mobileprovision.plist',
        );

        final File profileWithMissingIdentity = profileDirectory.childFile(
          'profile3.mobileprovision',
        )..createSync(recursive: true);
        final File profileWithMissingIdentityPlist = fileSystem.file(
          '/.tmp_rand0/provisioning_profiles/decoded_profile_profile3.mobileprovision.plist',
        );
        final File profileWithMissingIdentityCert = fileSystem.file(
          '/.tmp_rand0/provisioning_profile_certificates/UUIDProfile3_0.cer',
        );

        final FakePlistParser plistParser = FakePlistParser(
          parsedValues: <Map<String, Object>>[
            <String, Object>{
              'Name': 'Company Development',
              'ExpirationDate': '2026-02-20T16:04:31Z',
              'IsXcodeManaged': false,
              'DeveloperCertificates': <List<int>>[
                <int>[0, 1, 2, 3],
                <int>[0, 1, 2, 3, 4],
              ],
              'TeamIdentifier': <String>['ABCDE1F2DH'],
              'UUID': 'UUIDProfile1',
            },
            <String, Object>{
              'Name': 'Company Development',
              'ExpirationDate': '2026-02-20T16:04:31Z',
              'IsXcodeManaged': true,
              'DeveloperCertificates': <List<int>>[
                <int>[0, 1, 2, 3],
              ],
              'TeamIdentifier': <String>['ABCDE1F2DH'],
              'UUID': 'UUIDProfile2',
            },
            <String, Object>{
              'Name': 'Company Development',
              'ExpirationDate': '2026-02-20T16:04:31Z',
              'IsXcodeManaged': false,
              'DeveloperCertificates': <List<int>>[
                <int>[0, 1, 2, 3],
              ],
              'TeamIdentifier': <String>['ABCDE1F2DH'],
              'UUID': 'UUIDProfile3',
            },
          ],
        );
        const String certificates = '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Company Development (12ABCD234E)"
    1 valid identities found''';

        final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(command: <String>['which', 'security']),
          const FakeCommand(command: <String>['which', 'openssl']),
          const FakeCommand(
            command: <String>['security', 'find-identity', '-p', 'codesigning', '-v'],
            stdout: certificates,
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              validProfile.path,
              '-o',
              validProfilePlist.path,
            ],
            onRun: (List<String> command) => validProfilePlist.createSync(recursive: true),
          ),
          FakeCommand(
            command: <String>[
              'openssl',
              'x509',
              '-subject',
              '-in',
              validProfileInvalidCert.path,
              '-inform',
              'DER',
            ],
            stdout:
                'subject= /UID=A123BC4D5E/CN=Apple Development: No matching (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
          ),
          FakeCommand(
            command: <String>[
              'openssl',
              'x509',
              '-subject',
              '-in',
              validProfileValidCert.path,
              '-inform',
              'DER',
            ],
            stdout:
                'subject= /UID=A123BC4D5E/CN=Apple Development: Company Development (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              xcodeManagedProfile.path,
              '-o',
              xcodeManagedProfilePlist.path,
            ],
            onRun: (List<String> command) => xcodeManagedProfilePlist.createSync(recursive: true),
          ),
          FakeCommand(
            command: <String>[
              'security',
              'cms',
              '-D',
              '-i',
              profileWithMissingIdentity.path,
              '-o',
              profileWithMissingIdentityPlist.path,
            ],
            onRun:
                (List<String> command) =>
                    profileWithMissingIdentityPlist.createSync(recursive: true),
          ),
          FakeCommand(
            command: <String>[
              'openssl',
              'x509',
              '-subject',
              '-in',
              profileWithMissingIdentityCert.path,
              '-inform',
              'DER',
            ],
            stdout:
                'subject= /UID=A123BC4D5E/CN=Apple Development: No match (12ABCD234E)/OU=ABCDE1F2DH/O=Company LLC/C=US',
          ),
        ]);

        final XcodeCodeSigningSettings settings = XcodeCodeSigningSettings(
          config: config,
          logger: logger,
          platform: FakePlatform(operatingSystem: 'macos'),
          fileSystem: fileSystem,
          fileSystemUtils: FakeFileSystemUtils(homeDirPath: homeDir),
          processUtils: ProcessUtils(processManager: processManager, logger: logger),
          terminal: terminal,
          plistParser: plistParser,
        );
        await settings.selectSettings();

        expect(logger.errorText, isEmpty);
        expect(logger.warningText, isEmpty);
        expect(config.getValue('ios-signing-cert'), isNull);
        expect(config.getValue('ios-signing-profile'), validProfile.path);
        expect(processManager, hasNoRemainingExpectations);
      });
    });
  });
}

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({this.stdinHasTerminal = true, this.supportsColor = false});

  @override
  final bool stdinHasTerminal;

  @override
  final bool supportsColor;

  @override
  bool get isCliAnimationEnabled => supportsColor;

  @override
  bool usesTerminalUi = true;

  @override
  bool singleCharMode = false;

  late Completer<void> promptCompleter;

  void setPrompt(List<String> characters, String result) {
    _nextPrompt = characters;
    _nextResult = result;
    promptCompleter = Completer<void>();
  }

  List<String>? _nextPrompt;
  late String _nextResult;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, _nextPrompt);
    promptCompleter.complete();
    return _nextResult;
  }
}

class FakeFileSystemUtils extends Fake implements FileSystemUtils {
  FakeFileSystemUtils({this.homeDirPath});

  @override
  String? homeDirPath;
}

class FakePlistParser extends Fake implements PlistParser {
  FakePlistParser({List<Map<String, Object>>? parsedValues})
    : _parsedValues = parsedValues ?? <Map<String, Object>>[];

  final List<Map<String, Object>> _parsedValues;

  @override
  Map<String, Object> parseFile(String plistFilePath) {
    if (_parsedValues.isEmpty) {
      return <String, Object>{};
    }
    return _parsedValues.removeAt(0);
  }
}
