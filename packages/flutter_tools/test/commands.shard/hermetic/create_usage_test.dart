// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('usageValues', () {
    FileSystem fileSystem;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      Cache.flutterRoot = 'flutter';
      final List<String> paths = <String>[
        fileSystem.path.join('flutter', 'packages', 'flutter', 'pubspec.yaml'),
        fileSystem.path.join('flutter', 'packages', 'flutter_driver', 'pubspec.yaml'),
        fileSystem.path.join('flutter', 'packages', 'flutter_test', 'pubspec.yaml'),
        fileSystem.path.join('flutter', 'bin', 'cache', 'artifacts', 'gradle_wrapper', 'wrapper'),
        fileSystem.path.join('usr', 'local', 'bin', 'adb'),
        fileSystem.path.join('Android', 'platform-tools', 'adb.exe'),
      ];
      for (final String path in paths) {
        fileSystem.file(path).createSync(recursive: true);
      }
      // Set up enough of the packages to satisfy the templating code.
      final File packagesFile = fileSystem.file(
        fileSystem.path.join('flutter', 'packages', 'flutter_tools', '.dart_tool', 'package_config.json'));
      final File flutterManifest = fileSystem.file(
        fileSystem.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'template_manifest.json'))
          ..createSync(recursive: true);
      final Directory templateImagesDirectory = fileSystem.directory('flutter_template_images');
      templateImagesDirectory.createSync(recursive: true);
      packagesFile.createSync(recursive: true);
      packagesFile.writeAsStringSync(json.encode(<String, Object>{
        'configVersion': 2,
        'packages': <Object>[
          <String, Object>{
            'name': 'flutter_template_images',
            'languageVersion': '2.8',
            'rootUri': templateImagesDirectory.uri.toString(),
            'packageUri': 'lib/',
          },
        ],
      }));
      flutterManifest.writeAsStringSync('{"files":[]}');
    });

    testUsingContext('set template type as usage value', () async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', '--template=module', 'testy']);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateProjectType, 'module'));

      await runner.run(<String>['create', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateProjectType, 'app'));

      await runner.run(<String>['create', '--no-pub', '--template=package', 'testy']);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateProjectType, 'package'));

      await runner.run(<String>['create', '--no-pub', '--template=plugin', 'testy']);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateProjectType, 'plugin'));
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('set iOS host language type as usage value', () async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>[
        'create', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues,
             containsPair(CustomDimensions.commandCreateIosLanguage, 'swift'));

      await runner.run(<String>[
        'create',
        '--no-pub',
        '--template=app',
        '--ios-language=objc',
        'testy',
      ]);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateIosLanguage, 'objc'));
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });


    testUsingContext('set Android host language type as usage value', () async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateAndroidLanguage, 'kotlin'));

      await runner.run(<String>[
        'create',
        '--no-pub',
        '--template=app',
        '--android-language=java',
        'testy',
      ]);
      expect(await command.usageValues, containsPair(CustomDimensions.commandCreateAndroidLanguage, 'java'));
    }, overrides: <Type, Generator>{
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}
