// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testWithoutContext('FlutterValidator shows an error message if gen_snapshot is '
    'downloaded and exits with code 1', () async {
    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Artifacts artifacts = Artifacts.test();
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(
        operatingSystem: 'linux',
        localeName: 'en_US.UTF-8',
        environment: <String, String>{},
      ),
      flutterVersion: () => flutterVersion,
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      flutterRoot: () => 'sdk/flutter',
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Linux'),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['Artifact.genSnapshot'],
          exitCode: 1,
        )
      ])
    );
    fileSystem.file(artifacts.getArtifactPath(Artifact.genSnapshot)).createSync(recursive: true);


    expect(await flutterValidator.validate(), matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel unknown, Unknown, on Linux, locale en_US.UTF-8',
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
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(
        operatingSystem: 'windows',
        localeName: 'en_US.UTF-8',
        environment: <String, String>{},
      ),
      flutterVersion: () => MockFlutterVersion(),
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      flutterRoot: () => 'sdk/flutter',
    );

    // gen_snapshot is downloaded on demand, and the doctor should not
    // fail if the gen_snapshot binary is not present.
    expect(await flutterValidator.validate(), matchDoctorValidation(
      validationType: ValidationType.installed,
      statusInfo: 'Channel unknown, Unknown, on Windows, locale en_US.UTF-8',
      messages: anything,
    ));
  });

  testWithoutContext('FlutterValidator handles exception thrown by version checking', () async {
    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: FakePlatform(operatingSystem: 'windows', localeName: 'en_US.UTF-8'),
      flutterVersion: () => flutterVersion,
      userMessages: UserMessages(),
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      flutterRoot: () => 'sdk/flutter',
    );

    when(flutterVersion.channel).thenReturn('unknown');
    when(flutterVersion.frameworkVersion).thenReturn('0.0.0');
    when(flutterVersion.frameworkDate).thenThrow(VersionCheckError('version error'));

    expect(await flutterValidator.validate(), matchDoctorValidation(
      validationType: ValidationType.partial,
      statusInfo: 'Channel unknown, 0.0.0, on Windows, locale en_US.UTF-8',
      messages: const <ValidationMessage>[
        ValidationMessage('Flutter version 0.0.0 at sdk/flutter'),
        ValidationMessage.error('version error'),
      ]),
    );
  });

  testWithoutContext('FlutterValidator shows mirrors on pub and flutter cloud storage', () async {
    final Platform platform = FakePlatform(
      operatingSystem: 'windows',
      localeName: 'en_US.UTF-8',
      environment: <String, String>{
        'PUB_HOSTED_URL': 'https://example.com/pub',
        'FLUTTER_STORAGE_BASE_URL': 'https://example.com/flutter',
      },
    );
    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Artifacts artifacts = Artifacts.test();
    final FlutterValidator flutterValidator = FlutterValidator(
      platform: platform,
      flutterVersion: () => flutterVersion,
      userMessages: UserMessages(),
      artifacts: artifacts,
      fileSystem: fileSystem,
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(name: 'Windows'),
      flutterRoot: () => 'sdk/flutter'
    );

    expect(await flutterValidator.validate(), matchDoctorValidation(
      validationType: ValidationType.installed,
      statusInfo: 'Channel unknown, Unknown, on Windows, locale en_US.UTF-8',
      messages: containsAll(const <ValidationMessage>[
        ValidationMessage('Pub download mirror https://example.com/pub'),
        ValidationMessage('Flutter download mirror https://example.com/flutter'),
      ])
    ));
  });
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({this.name});

  @override
  final String name;
}
