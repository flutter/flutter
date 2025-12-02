// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

/// Matches a doctor validation result.
Matcher _matchDoctorValidation({
  required ValidationType validationType,
  required String statusInfo,
  required Object messages,
}) {
  return const TypeMatcher<ValidationResult>()
      .having((ValidationResult result) => result.type, 'type', validationType)
      .having((ValidationResult result) => result.statusInfo, 'statusInfo', statusInfo)
      .having((ValidationResult result) => result.messages, 'messages', messages);
}

void main() {
  testWithoutContext('FlutterValidator shows an error message if gen_snapshot is '
      'downloaded and exits with code 1', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta');
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8', environment: <String, String>{}),
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      flutterRoot: () => '/sdk/flutter',
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['Artifact.genSnapshot'], exitCode: 1),
      ]),
      featureFlags: TestFeatureFlags(),
    );
    fileSystem.file(artifacts.getArtifactPath(Artifact.genSnapshot)).createSync(recursive: true);

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage.error(
            'Downloaded executables cannot execute on host.\n'
            'See https://github.com/flutter/flutter/issues/6207 for more information.\n'
            'On Debian/Ubuntu/Mint: sudo apt-get install lib32stdc++6\n'
            'On Fedora: dnf install libstdc++.i686\n'
            'On Arch: pacman -S lib32-gcc-libs\n',
          ),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator shows an error message if Rosetta is needed', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta');
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(
        operatingSystem: 'macos',
        localeName: 'en_US.UTF-8',
        environment: <String, String>{},
      ),
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      flutterRoot: () => 'sdk/flutter',
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: 'macOS',
        hostPlatform: HostPlatform.darwin_arm64,
      ),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['Artifact.genSnapshot'], exitCode: 1),
      ]),
      featureFlags: TestFeatureFlags(),
    );
    fileSystem.file(artifacts.getArtifactPath(Artifact.genSnapshot)).createSync(recursive: true);

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on macOS, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage.error(
            'Downloaded executables cannot execute on host.\n'
            'See https://github.com/flutter/flutter/issues/6207 for more information.\n'
            'Flutter requires the Rosetta translation environment on ARM Macs. Try running:\n'
            '  sudo softwareupdate --install-rosetta --agree-to-license\n',
          ),
        ]),
      ),
    );
  });

  testWithoutContext(
    'FlutterValidator does not run gen_snapshot binary check if it is not already downloaded',
    () async {
      final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta');
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(
          operatingSystem: 'windows',
          localeName: 'en_US.UTF-8',
          environment: <String, String>{},
        ),
        flutterVersion: () => flutterVersion,
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
        processManager: FakeProcessManager.empty(),
        flutterRoot: () => '/sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      // gen_snapshot is downloaded on demand, and the doctor should not
      // fail if the gen_snapshot binary is not present.
      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.success,
          statusInfo: 'Channel beta, 1.0.0, on Windows, locale en_US.UTF-8',
          messages: anything,
        ),
      );
    },
  );

  testWithoutContext('FlutterValidator handles exception thrown by version checking', () async {
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeThrowingFlutterVersion(),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      processManager: FakeProcessManager.empty(),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 0.0.0, on Windows, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage('Flutter version 0.0.0 on channel beta at /sdk/flutter'),
          ValidationMessage.error('version error'),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator shows mirrors on pub and flutter cloud storage', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta');
    final Platform platform = FakePlatform(
      operatingSystem: 'windows',
      localeName: 'en_US.UTF-8',
      environment: <String, String>{
        'PUB_HOSTED_URL': 'https://example.com/pub',
        'FLUTTER_STORAGE_BASE_URL': 'https://example.com/flutter',
      },
    );
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.success,
        statusInfo: 'Channel beta, 1.0.0, on Windows, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage('Pub download mirror https://example.com/pub'),
          ValidationMessage('Flutter download mirror https://example.com/flutter'),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator shows enabled (by default) feature flags', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0');
    final Platform platform = FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8');
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: const FakeFlutterFeatures(<Feature>[
        emitUnicornEmojisDefaultTrue,
      ], enabled: true),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.success,
        statusInfo: 'Channel master, 1.0.0, on Windows, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage('Feature flags: emit-unicorn-emojis'),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator shows enabled (by user) feature flags', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0');
    final Platform platform = FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8');
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: const FakeFlutterFeatures(<Feature>[
        emitUnicornEmojisDefaultFalse,
      ], enabled: true),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.success,
        statusInfo: 'Channel master, 1.0.0, on Windows, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage('Feature flags: emit-unicorn-emojis'),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator shows disabled (by user) feature flags', () async {
    final flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0');
    final Platform platform = FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8');
    final fileSystem = MemoryFileSystem.test();
    final artifacts = Artifacts.test();
    final flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: const FakeFlutterFeatures(<Feature>[
        emitUnicornEmojisDefaultTrue,
      ], enabled: false),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.success,
        statusInfo: 'Channel master, 1.0.0, on Windows, locale en_US.UTF-8',
        messages: containsAll(const <ValidationMessage>[
          ValidationMessage('Feature flags: no-emit-unicorn-emojis'),
        ]),
      ),
    );
  });

  testWithoutContext(
    'FlutterValidator shows FLUTTER_GIT_URL when set and fails if upstream is not the same',
    () async {
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(
          localeName: 'en_US.UTF-8',
          environment: <String, String>{'FLUTTER_GIT_URL': 'https://githubmirror.com/flutter.git'},
        ),
        flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => '/sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.partial,
          statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
          messages: containsAll(const <ValidationMessage>[
            ValidationMessage.hint(
              'Upstream repository https://github.com/flutter/flutter.git is not the same as FLUTTER_GIT_URL',
            ),
            ValidationMessage('FLUTTER_GIT_URL = https://githubmirror.com/flutter.git'),
            ValidationMessage(
              'If those were intentional, you can disregard the above warnings; however it is '
              'recommended to use "git" directly to perform update checks and upgrades.',
            ),
          ]),
        ),
      );
    },
  );

  testWithoutContext('FlutterValidator fails when channel is unknown', () async {
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(branch: 'unknown', frameworkVersion: '1.0.0'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel [user-branch], 1.0.0, on Linux, locale en_US.UTF-8',
        messages: containsAll(<ValidationMessage>[
          const ValidationMessage.hint(
            'Flutter version 1.0.0 on channel [user-branch] at /sdk/flutter\n'
            'Currently on an unknown channel. Run `flutter channel` to switch to an official channel.\n'
            "If that doesn't fix the issue, reinstall Flutter by following instructions at https://flutter.dev/setup.",
          ),
          const ValidationMessage(
            'If those were intentional, you can disregard the above warnings; however it is '
            'recommended to use "git" directly to perform update checks and upgrades.',
          ),
        ]),
      ),
    );
  });

  testWithoutContext('FlutterValidator fails when framework version is unknown', () async {
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '0.0.0-unknown', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 0.0.0-unknown, on Linux, locale en_US.UTF-8',
        messages: containsAll(<ValidationMessage>[
          const ValidationMessage.hint(
            'Flutter version 0.0.0-unknown on channel beta at /sdk/flutter\n'
            'Cannot resolve current version, possibly due to local changes.\n'
            'Reinstall Flutter by following instructions at https://flutter.dev/setup.',
          ),
          const ValidationMessage(
            'If those were intentional, you can disregard the above warnings; however it is '
            'recommended to use "git" directly to perform update checks and upgrades.',
          ),
        ]),
      ),
    );
  });

  group('FlutterValidator shows flutter upstream remote', () {
    testWithoutContext('standard url', () async {
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => '/sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.success,
          statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
          messages: contains(
            const ValidationMessage('Upstream repository https://github.com/flutter/flutter.git'),
          ),
        ),
      );
    });

    testWithoutContext('non-standard url', () async {
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(
          frameworkVersion: '1.0.0',
          branch: 'beta',
          repositoryUrl: 'https://githubmirror.com/flutter.git',
        ),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => 'sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.partial,
          statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
          messages: containsAll(<ValidationMessage>[
            const ValidationMessage.hint(
              'Upstream repository https://githubmirror.com/flutter.git is not a standard remote.\n'
              'Set environment variable "FLUTTER_GIT_URL" to '
              'https://githubmirror.com/flutter.git to dismiss this error.',
            ),
            const ValidationMessage(
              'If those were intentional, you can disregard the above warnings; however it is '
              'recommended to use "git" directly to perform update checks and upgrades.',
            ),
          ]),
        ),
      );
    });

    testWithoutContext('as unknown if upstream is null', () async {
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () =>
            FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta', repositoryUrl: null),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => 'sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.partial,
          statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
          messages: containsAll(<ValidationMessage>[
            const ValidationMessage.hint(
              'Unknown upstream repository.\n'
              'Reinstall Flutter by following instructions at https://flutter.dev/setup.',
            ),
            const ValidationMessage(
              'If those were intentional, you can disregard the above warnings; however it is '
              'recommended to use "git" directly to perform update checks and upgrades.',
            ),
          ]),
        ),
      );
    });
  });

  testWithoutContext(
    'Do not show the message for intentional errors if FlutterValidator passes',
    () async {
      final flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => '/sdk/flutter',
        featureFlags: TestFeatureFlags(),
      );

      expect(
        await flutterValidator.validate(),
        _matchDoctorValidation(
          validationType: ValidationType.success,
          statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
          messages: isNot(
            contains(
              const ValidationMessage(
                'If those were intentional, you can disregard the above warnings; however it is '
                'recommended to use "git" directly to perform update checks and upgrades.',
              ),
            ),
          ),
        ),
      );
    },
  );

  testWithoutContext('detects no flutter and dart on path', () async {
    const flutterRoot = 'sdk/flutter';
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: 'Linux',
        whichLookup: const <String, File>{},
      ),
      flutterRoot: () => flutterRoot,
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: contains(
          const ValidationMessage.hint(
            'The flutter binary is not on your path. Consider adding $flutterRoot/bin to your path.',
          ),
        ),
      ),
    );
  });

  testWithoutContext('allows case differences in paths on Windows', () async {
    const flutterRoot = r'c:\path\to\flutter-sdk';
    const osName = 'Microsoft Windows';
    final fs = MemoryFileSystem.test(style: FileSystemStyle.windows);
    // The windows' file system is not case sensitive, so changing the case
    // here should not matter.
    final File flutterBinary = fs.file('${flutterRoot.toUpperCase()}\\bin\\flutter')
      ..createSync(recursive: true);
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: fs,
      processManager: FakeProcessManager.empty(),
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: osName,
        whichLookup: <String, File>{'flutter': flutterBinary},
      ),
      flutterRoot: () => flutterRoot,
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on $osName, locale en_US.UTF-8',
        messages: everyElement(
          isA<ValidationMessage>().having(
            (ValidationMessage message) => message.message,
            'message',
            isNot(contains('Warning: `flutter` on your path resolves to')),
          ),
        ),
      ),
    );
  });

  testWithoutContext('allows different separator types in paths on Windows', () async {
    const flutterRoot = r'c:\path\to\flutter-sdk';
    const osName = 'Microsoft Windows';
    final fs = MemoryFileSystem.test(style: FileSystemStyle.windows);
    const filePath = '$flutterRoot\\bin\\flutter';
    // force posix style path separators
    final File flutterBinary = fs.file(filePath.replaceAll(r'\', '/'))..createSync(recursive: true);
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: fs,
      processManager: FakeProcessManager.empty(),
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: osName,
        whichLookup: <String, File>{'flutter': flutterBinary},
      ),
      flutterRoot: () => flutterRoot,
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on $osName, locale en_US.UTF-8',
        messages: everyElement(
          isA<ValidationMessage>().having(
            (ValidationMessage message) => message.message,
            'message',
            isNot(contains('Warning: `flutter` on your path resolves to')),
          ),
        ),
      ),
    );
  });

  testWithoutContext('detects flutter and dart from outside flutter sdk', () async {
    final FileSystem fs = MemoryFileSystem.test();
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: fs,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: 'Linux',
        whichLookup: <String, File>{
          'flutter': fs.file('/sdk/flutter-beta')..createSync(recursive: true),
          'dart': fs.file('/sdk/flutter-beta')..createSync(recursive: true),
        },
      ),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: contains(
          const ValidationMessage.hint(
            'Warning: `flutter` on your path resolves to /sdk/flutter-beta, which '
            'is not inside your current Flutter SDK checkout at /sdk/flutter. '
            'Consider adding /sdk/flutter/bin to the front of your path.',
          ),
        ),
      ),
    );
  });

  testWithoutContext('no warnings if flutter & dart binaries are inside the Flutter SDK', () async {
    final FileSystem fs = MemoryFileSystem.test();
    final flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(frameworkVersion: '1.0.0', branch: 'beta'),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: fs,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(
        name: 'Linux',
        whichLookup: <String, File>{
          'flutter': fs.file('/sdk/flutter/bin/flutter')..createSync(recursive: true),
          'dart': fs.file('/sdk/flutter/bin/dart')..createSync(recursive: true),
        },
      ),
      flutterRoot: () => '/sdk/flutter',
      featureFlags: TestFeatureFlags(),
    );

    expect(
      await flutterValidator.validate(),
      _matchDoctorValidation(
        validationType: ValidationType.success,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: isNot(
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage message) => message.message,
              'message',
              contains('Consider adding /sdk/flutter/bin to the front of your path'),
            ),
          ),
        ),
      ),
    );
  });
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({
    required this.name,
    this.hostPlatform = HostPlatform.linux_x64,
    this.whichLookup,
    FileSystem? fs,
  }) {
    fs ??= MemoryFileSystem.test();
    whichLookup ??= <String, File>{
      'flutter': fs.file('/sdk/flutter/bin/flutter')..createSync(recursive: true),
      'dart': fs.file('/sdk/flutter/bin/dart')..createSync(recursive: true),
    };
  }

  /// A map of [File]s that calls to [which] will return.
  Map<String, File>? whichLookup;

  @override
  File? which(String execName) => whichLookup![execName];

  @override
  final String name;

  @override
  final HostPlatform hostPlatform;
}

class FakeThrowingFlutterVersion extends FakeFlutterVersion {
  @override
  String get channel => 'beta';

  @override
  String get frameworkCommitDate {
    throw VersionCheckError('version error');
  }
}

class FakeFlutterFeatures extends FeatureFlags {
  const FakeFlutterFeatures(this.allFeatures, {required bool enabled}) : _enabled = enabled;
  final bool _enabled;

  @override
  bool get isLinuxEnabled => _enabled;

  @override
  bool get isMacOSEnabled => _enabled;

  @override
  bool get isWebEnabled => _enabled;

  @override
  bool get isWindowsEnabled => _enabled;

  @override
  bool get isAndroidEnabled => _enabled;

  @override
  bool get isIOSEnabled => _enabled;

  @override
  bool get isFuchsiaEnabled => _enabled;

  @override
  bool get areCustomDevicesEnabled => _enabled;

  @override
  bool get isCliAnimationEnabled => _enabled;

  @override
  bool get isNativeAssetsEnabled => _enabled;

  @override
  bool get isSwiftPackageManagerEnabled => _enabled;

  @override
  bool get isOmitLegacyVersionFileEnabled => _enabled;

  @override
  bool get isWindowingEnabled => _enabled;

  @override
  bool get isLLDBDebuggingEnabled => _enabled;

  @override
  bool get isUISceneMigrationEnabled => _enabled;

  @override
  bool get isRiscv64SupportEnabled => _enabled;

  @override
  final List<Feature> allFeatures;

  @override
  bool isEnabled(Feature feature) => _enabled;
}

const emitUnicornEmojisDefaultFalse = Feature(
  name: 'Emit Unicorn Emojis',
  configSetting: 'emit-unicorn-emojis',
  master: FeatureChannelSetting(enabledByDefault: true),
);

const emitUnicornEmojisDefaultTrue = Feature(
  name: 'Emit Unicorn Emojis',
  configSetting: 'emit-unicorn-emojis',
  master: FeatureChannelSetting(enabledByDefault: true),
);
