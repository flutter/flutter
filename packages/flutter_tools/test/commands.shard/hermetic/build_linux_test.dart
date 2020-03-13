// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_linux.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/makefile.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

const String _kTestFlutterRoot = '/flutter';

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': _kTestFlutterRoot
  }
);
final Platform notLinuxPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': _kTestFlutterRoot,
  }
);


void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  FileSystem fileSystem;
  ProcessManager processManager;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    Cache.flutterRoot = _kTestFlutterRoot;
  });

  // Creates the mock files necessary to look like a Flutter project.
  void setUpMockCoreProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild({int templateVersion}) {
    setUpMockCoreProjectFiles();
    fileSystem.file(fileSystem.path.join('linux', 'Makefile')).createSync(recursive: true);

    final String versionFileSubpath = fileSystem.path.join('flutter', '.template_version');
    const int expectedTemplateVersion = 10;  // Arbitrary value for tests.
    final File sourceTemplateVersionfile = fileSystem.file(fileSystem.path.join(
      fileSystem.path.absolute(Cache.flutterRoot),
      'packages',
      'flutter_tools',
      'templates',
      'app',
      'linux.tmpl',
      versionFileSubpath,
    ));
    sourceTemplateVersionfile.createSync(recursive: true);
    sourceTemplateVersionfile.writeAsStringSync(expectedTemplateVersion.toString());

    final File projectTemplateVersionFile = fileSystem.file(
      fileSystem.path.join('linux', versionFileSubpath));
    templateVersion ??= expectedTemplateVersion;
    projectTemplateVersionFile.createSync(recursive: true);
    projectTemplateVersionFile.writeAsStringSync(templateVersion.toString());
  }

  testUsingContext('Linux build fails when there is no linux project', () async {
    final BuildCommand command = BuildCommand();
    setUpMockCoreProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit(message: 'No Linux desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => linuxPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build fails on non-linux platform', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notLinuxPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build fails with instructions when template is too old', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild(templateVersion: 1);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit(message: 'flutter create .'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build fails with instructions when template is too new', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild(templateVersion: 999);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit(message: 'Upgrade Flutter'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build invokes make and writes temporary files', () async {
    final BuildCommand command = BuildCommand();
    processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=release',
      ], onRun: () {

      })
    ]);

    setUpMockProjectFilesForBuild();

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    );
    expect(fileSystem.file('linux/flutter/ephemeral/generated_config.mk'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Handles argument error from missing make', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(command: const <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=release',
      ], onRun: () {
        throw ArgumentError();
      }),
    ]);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit(message: "make not found. Run 'flutter doctor' for more information."));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=debug',
      ], stdout: 'STDOUT STUFF'),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --debug passes debug mode to make', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=debug',
      ]),
    ]);


    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --profile passes profile mode to make', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=profile',
      ]),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--profile']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('linux can extract binary name from Makefile', () async {
    fileSystem.file('linux/Makefile')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
# Comment
SOMETHING_ELSE=FOO
BINARY_NAME=fizz_bar
''');
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(makefileExecutableName(flutterProject.linux), 'fizz_bar');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('linux can extract binary name from app config', () async {
    fileSystem.file('linux/Makefile')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
# Comment
SOMETHING_ELSE=FOO
include app_configuration.mk
''');
    fileSystem.file('linux/app_configuration.mk')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
# Comment
SOMETHING_ELSE=FOO
BINARY_NAME=fizz_bar
''');
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(makefileExecutableName(flutterProject.linux), 'fizz_bar');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Refuses to build for Linux when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'linux']),
      throwsToolExit());
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  });

  testUsingContext('Release build prints an under-construction warning', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'make',
        '-C',
        '/linux',
        'BUILD=release',
      ]),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    );
    expect(testLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('hidden when not enabled on Linux host', () {
    expect(BuildLinuxCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Platform: () => notLinuxPlatform,
  });

  testUsingContext('Not hidden when enabled and on Linux host', () {
    expect(BuildLinuxCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
    Platform: () => linuxPlatform,
  });
}
