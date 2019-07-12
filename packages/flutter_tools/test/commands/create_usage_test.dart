// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/usage.dart';

import '../src/common.dart';
import '../src/testbed.dart';


void main() {
  group('usageValues', () {
    Testbed testbed;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      testbed = Testbed(setup: () {
        final List<String> paths = <String>[
          fs.path.join('flutter', 'packages', 'flutter', 'pubspec.yaml'),
          fs.path.join('flutter', 'packages', 'flutter_driver', 'pubspec.yaml'),
          fs.path.join('flutter', 'packages', 'flutter_test', 'pubspec.yaml'),
          fs.path.join('flutter', 'bin', 'cache', 'artifacts', 'gradle_wrapper', 'wrapper'),
          fs.path.join('usr', 'local', 'bin', 'adb'),
          fs.path.join('Android', 'platform-tools', 'foo'),
        ];
        for (String path in paths) {
          fs.file(path).createSync(recursive: true);
        }
      }, overrides: <Type, Generator>{
        DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      });
    });

    test('set template type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--flutter-root=flutter', '--no-pub', '--template=module', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateProjectType, 'module'));

      await runner.run(<String>['create',  '--flutter-root=flutter', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateProjectType, 'app'));

      await runner.run(<String>['create',  '--flutter-root=flutter', '--no-pub', '--template=package', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateProjectType, 'package'));

      await runner.run(<String>['create',  '--flutter-root=flutter', '--no-pub', '--template=plugin', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateProjectType, 'plugin'));
    }));

    test('set iOS host language type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--flutter-root=flutter', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateIosLanguage, 'objc'));

      await runner.run(<String>[
        'create',
        '--flutter-root=flutter',
        '--no-pub',
        '--template=app',
        '--ios-language=swift',
        'testy',
      ]);
      expect(await command.usageValues, containsPair(kCommandCreateIosLanguage, 'swift'));

    }));

    test('set Android host language type as usage value', () => testbed.run(() async {
      final CreateCommand command = CreateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--flutter-root=flutter', '--no-pub', '--template=app', 'testy']);
      expect(await command.usageValues, containsPair(kCommandCreateAndroidLanguage, 'java'));

      await runner.run(<String>[
        'create',
        '--flutter-root=flutter',
        '--no-pub',
        '--template=app',
        '--android-language=kotlin',
        'testy',
      ]);
      expect(await command.usageValues, containsPair(kCommandCreateAndroidLanguage, 'kotlin'));
    }));
  });
}

class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}
