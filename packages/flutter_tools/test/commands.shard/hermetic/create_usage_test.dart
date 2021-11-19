// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';
import '../../src/testbed.dart';

void main() {
  group('usageValues', () {
    Testbed testbed;

    setUpAll(() {
      Cache.disableLocking();
      Cache.flutterRoot = 'flutter';
    });

    setUp(() {
      testbed = Testbed(setup: () {
        Cache.flutterRoot = 'flutter';
        final List<String> filePaths = <String>[
          globals.fs.path.join('flutter', 'packages', 'flutter', 'pubspec.yaml'),
          globals.fs.path.join('flutter', 'packages', 'flutter_driver', 'pubspec.yaml'),
          globals.fs.path.join('flutter', 'packages', 'flutter_test', 'pubspec.yaml'),
          globals.fs.path.join('flutter', 'bin', 'cache', 'artifacts', 'gradle_wrapper', 'wrapper'),
          globals.fs.path.join('usr', 'local', 'bin', 'adb'),
          globals.fs.path.join('Android', 'platform-tools', 'adb.exe'),
        ];
        for (final String filePath in filePaths) {
          globals.fs.file(filePath).createSync(recursive: true);
        }
        final List<String> templatePaths = <String>[
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'app'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'app_shared'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'cocoapods'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'skeleton'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'module', 'common'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'package'),
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin'),
        ];
        for (final String templatePath in templatePaths) {
          globals.fs.directory(templatePath).createSync(recursive: true);
        }
        // Set up enough of the packages to satisfy the templating code.
        final File packagesFile = globals.fs.file(
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', '.dart_tool', 'package_config.json'));
        final File flutterManifest = globals.fs.file(
          globals.fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'template_manifest.json'))
            ..createSync(recursive: true);
        final Directory templateImagesDirectory = globals.fs.directory('flutter_template_images');
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
      }, overrides: <Type, Generator>{
        DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      });
    });

    testUsingContext('set template type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', '--template=module', 'testy']);
      expect((await command.usageValues).commandCreateProjectType, 'module');

      await runner.run(<String>['create', '--no-pub', '--template=app', 'testy']);
      expect((await command.usageValues).commandCreateProjectType, 'app');

      await runner.run(<String>['create', '--no-pub', '--template=skeleton', 'testy']);
      expect((await command.usageValues).commandCreateProjectType, 'skeleton');

      await runner.run(<String>['create', '--no-pub', '--template=package', 'testy']);
      expect((await command.usageValues).commandCreateProjectType, 'package');

      await runner.run(<String>['create', '--no-pub', '--template=plugin', 'testy']);
      expect((await command.usageValues).commandCreateProjectType, 'plugin');
    }));

    testUsingContext('set iOS host language type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>[
        'create', '--no-pub', '--template=app', 'testy']);
      expect((await command.usageValues).commandCreateIosLanguage, 'swift');

      await runner.run(<String>[
        'create',
        '--no-pub',
        '--template=app',
        '--ios-language=objc',
        'testy',
      ]);
      expect((await command.usageValues).commandCreateIosLanguage, 'objc');

    }));

    testUsingContext('set Android host language type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', '--template=app', 'testy']);
      expect((await command.usageValues).commandCreateAndroidLanguage, 'kotlin');

      await runner.run(<String>[
        'create',
        '--no-pub',
        '--template=app',
        '--android-language=java',
        'testy',
      ]);
      expect((await command.usageValues).commandCreateAndroidLanguage, 'java');
    }));
  });
}

class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}
