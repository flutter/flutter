// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

/// Matches a doctor validation result.
Matcher _matchDoctorValidation({
  required ValidationType validationType,
  required String statusInfo,
  required Object messages
}) {
  return const TypeMatcher<ValidationResult>()
      .having((ValidationResult result) => result.type, 'type', validationType)
      .having((ValidationResult result) => result.statusInfo, 'statusInfo', statusInfo)
      .having((ValidationResult result) => result.messages, 'messages', messages);
}

void main() {
  testWithoutContext('FlutterValidator shows an error message if gen_snapshot is '
    'downloaded and exits with code 1', () async {
    final FakeFlutterVersion flutterVersion = FakeFlutterVersion(
      frameworkVersion: '1.0.0',
      channel: 'beta',
    );
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Artifacts artifacts = Artifacts.test();
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(
        localeName: 'en_US.UTF-8',
        environment: <String, String>{},
      ),
      flutterVersion: () => flutterVersion,
        devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      flutterRoot: () => 'sdk/flutter',
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['Artifact.genSnapshot'],
          exitCode: 1,
        ),
      ])
    );
    fileSystem.file(artifacts.getArtifactPath(Artifact.genSnapshot)).createSync(recursive: true);


    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
      messages: containsAll(const <ValidationMessage>[
        ValidationMessage.error(
          'Downloaded executables cannot execute on host.\n'
          'See https://github.com/flutter/flutter/issues/6207 for more information\n'
          'On Debian/Ubuntu/Mint: sudo apt-get install lib32stdc++6\n'
          'On Fedora: dnf install libstdc++.i686\n'
          'On Arch: pacman -S lib32-gcc-libs\n',
        ),
      ])),
    );
  });

  testWithoutContext('FlutterValidator does not run gen_snapshot binary check if it is not already downloaded', () async {
    final FakeFlutterVersion flutterVersion = FakeFlutterVersion(
      frameworkVersion: '1.0.0',
      channel: 'beta',
    );
    final FlutterValidator flutterValidator = FlutterValidator(
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
      flutterRoot: () => 'sdk/flutter',
    );

    // gen_snapshot is downloaded on demand, and the doctor should not
    // fail if the gen_snapshot binary is not present.
    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.installed,
      statusInfo: 'Channel beta, 1.0.0, on Windows, locale en_US.UTF-8',
      messages: anything,
    ));
  });

  testWithoutContext('FlutterValidator handles exception thrown by version checking', () async {
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeThrowingFlutterVersion(),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      processManager: FakeProcessManager.empty(),
      flutterRoot: () => 'sdk/flutter',
    );

    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel beta, 0.0.0, on Windows, locale en_US.UTF-8',
      messages: containsAll(const <ValidationMessage>[
        ValidationMessage('Flutter version 0.0.0 on channel beta at sdk/flutter'),
        ValidationMessage.error('version error'),
      ]),
    ));
  });

  testWithoutContext('FlutterValidator shows mirrors on pub and flutter cloud storage', () async {
    final FakeFlutterVersion flutterVersion = FakeFlutterVersion(
      frameworkVersion: '1.0.0',
      channel: 'beta',
    );
    final Platform platform = FakePlatform(
      operatingSystem: 'windows',
      localeName: 'en_US.UTF-8',
      environment: <String, String>{
        'PUB_HOSTED_URL': 'https://example.com/pub',
        'FLUTTER_STORAGE_BASE_URL': 'https://example.com/flutter',
      },
    );
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Artifacts artifacts = Artifacts.test();
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
        devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => 'sdk/flutter'
    );

    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.installed,
      statusInfo: 'Channel beta, 1.0.0, on Windows, locale en_US.UTF-8',
      messages: containsAll(const <ValidationMessage>[
        ValidationMessage('Pub download mirror https://example.com/pub'),
        ValidationMessage('Flutter download mirror https://example.com/flutter'),
      ])
    ));
  });

  testWithoutContext('FlutterValidator shows FLUTTER_GIT_URL when set and fails if upstream is not the same', () async {
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(
        localeName: 'en_US.UTF-8',
        environment: <String, String> {
          'FLUTTER_GIT_URL': 'https://githubmirror.com/flutter.git',
        },
      ),
      flutterVersion: () => FakeFlutterVersion(
        frameworkVersion: '1.0.0',
        channel: 'beta'
      ),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      flutterRoot: () => 'sdk/flutter',
    );

    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
      messages: containsAll(const <ValidationMessage>[
        ValidationMessage.hint('Upstream repository https://github.com/flutter/flutter.git is not the same as FLUTTER_GIT_URL'),
        ValidationMessage('FLUTTER_GIT_URL = https://githubmirror.com/flutter.git'),
      ]),
    ));
  });

  testWithoutContext('FlutterValidator fails when channel is unknown', () async {
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(
        frameworkVersion: '1.0.0',
        // channel is unknown by default
      ),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      flutterRoot: () => 'sdk/flutter',
    );

    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel unknown, 1.0.0, on Linux, locale en_US.UTF-8',
      messages: contains(const ValidationMessage.hint('Flutter version 1.0.0 on channel unknown at sdk/flutter')),
    ));
  });

  testWithoutContext('FlutterValidator fails when framework version is unknown', () async {
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(localeName: 'en_US.UTF-8'),
      flutterVersion: () => FakeFlutterVersion(
        frameworkVersion: '0.0.0-unknown',
        channel: 'beta',
      ),
      devToolsVersion: () => '2.8.0',
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      flutterRoot: () => 'sdk/flutter',
    );

    expect(await flutterValidator.validate(), _matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel beta, 0.0.0-unknown, on Linux, locale en_US.UTF-8',
      messages: contains(const ValidationMessage.hint('Flutter version 0.0.0-unknown on channel beta at sdk/flutter')),
    ));
  });

  group('FlutterValidator shows flutter upstream remote', () {
    testWithoutContext('standard url', () async {
      final FlutterValidator flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(
          frameworkVersion: '1.0.0',
          channel: 'beta'
        ),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => 'sdk/flutter',
      );

      expect(await flutterValidator.validate(), _matchDoctorValidation(
        validationType: ValidationType.installed,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: contains(const ValidationMessage('Upstream repository https://github.com/flutter/flutter.git')),
      ));
    });

    testWithoutContext('non-standard url', () async {
      final FlutterValidator flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(
          frameworkVersion: '1.0.0',
          channel: 'beta',
          repositoryUrl: 'https://githubmirror.com/flutter.git'
        ),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => 'sdk/flutter',
      );

      expect(await flutterValidator.validate(), _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: contains(const ValidationMessage.hint('Upstream repository https://githubmirror.com/flutter.git is not a standard remote')),
      ));
    });

    testWithoutContext('as unknown if upstream is null', () async {
      final FlutterValidator flutterValidator = FlutterValidator(
        platform: FakePlatform(localeName: 'en_US.UTF-8'),
        flutterVersion: () => FakeFlutterVersion(
          frameworkVersion: '1.0.0',
          channel: 'beta',
          repositoryUrl: null,
        ),
        devToolsVersion: () => '2.8.0',
        userMessages: UserMessages(),
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
        flutterRoot: () => 'sdk/flutter',
      );

      expect(await flutterValidator.validate(), _matchDoctorValidation(
        validationType: ValidationType.partial,
        statusInfo: 'Channel beta, 1.0.0, on Linux, locale en_US.UTF-8',
        messages: contains(const ValidationMessage.hint('Upstream repository unknown')),
      ));
    });
  });
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({required this.name});

  @override
  final String name;
}

class FakeThrowingFlutterVersion extends FakeFlutterVersion {
  @override
  String get channel => 'beta';

  @override
  String get frameworkCommitDate {
    throw VersionCheckError('version error');
  }
}
