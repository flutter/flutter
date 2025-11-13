// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/generate.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    
    // Create a mock Flutter project structure in current directory
    final Directory projectDir = fileSystem.currentDirectory;
    projectDir.childDirectory('lib').createSync();
    projectDir.childFile('pubspec.yaml').writeAsStringSync('''
name: test_project
description: A test Flutter project.
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');
    
    // Create .dart_tool/package_config.json for FlutterProject.current()
    projectDir.childDirectory('.dart_tool').createSync();
    projectDir.childDirectory('.dart_tool').childFile('package_config.json').writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test_project",
      "rootUri": "../",
      "packageUri": "lib/"
    },
    {
      "name": "flutter",
      "rootUri": "../packages/flutter",
      "packageUri": "lib/"
    }
  ]
}
''');
  });

  group('GenerateCommand', () {
    testUsingContext('shows help when no subcommand is provided', () async {
      final GenerateCommand command = GenerateCommand();
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['generate']),
        throwsA(isA<UsageException>()),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('generates a stateless widget by default', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'widget', 'MyButton']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('my_button.dart');
      expect(generatedFile.existsSync(), isTrue);
      
      final String content = generatedFile.readAsStringSync();
      expect(content, contains('class MyButton extends StatelessWidget'));
      expect(content, contains('const MyButton({super.key})'));
      expect(content, contains('const Placeholder()'));
      expect(content, contains("import 'package:flutter/material.dart'"));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('generates a stateful widget with -s flag', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'widget', 'UserCard', '-s']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('user_card.dart');
      expect(generatedFile.existsSync(), isTrue);
      
      final String content = generatedFile.readAsStringSync();
      expect(content, contains('class UserCard extends StatefulWidget'));
      expect(content, contains('class _UserCardState extends State<UserCard>'));
      expect(content, contains('const Placeholder()'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('generates widget with custom output directory', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'widget', 'CustomWidget', '-o', 'lib/widgets']);
      
      final File generatedFile = fileSystem.currentDirectory
          .childDirectory('lib')
          .childDirectory('widgets')
          .childFile('custom_widget.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('generates screen with Scaffold', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'screen', 'HomePage']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('home_page.dart');
      expect(generatedFile.existsSync(), isTrue);
      
      final String content = generatedFile.readAsStringSync();
      expect(content, contains('class HomePage extends StatelessWidget'));
      expect(content, contains('Scaffold'));
      expect(content, contains('AppBar'));
      expect(content, contains('body:'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('generates stateful screen with -s flag', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'screen', 'ProfileScreen', '-s']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('profile_screen.dart');
      expect(generatedFile.existsSync(), isTrue);
      
      final String content = generatedFile.readAsStringSync();
      expect(content, contains('class ProfileScreen extends StatefulWidget'));
      expect(content, contains('class _ProfileScreenState extends State<ProfileScreen>'));
      expect(content, contains('Scaffold'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('page command is alias for screen', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'page', 'LoginPage']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('login_page.dart');
      expect(generatedFile.existsSync(), isTrue);
      
      final String content = generatedFile.readAsStringSync();
      expect(content, contains('Scaffold'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('converts PascalCase to snake_case for filename', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'widget', 'MyVeryLongWidgetName']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('my_very_long_widget_name.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws error when name starts with lowercase', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await expectLater(
        () => runner.run(<String>['generate', 'widget', 'myWidget']),
        throwsToolExit(message: 'Invalid name'),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws error when file already exists', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      // Create the file first
      await runner.run(<String>['generate', 'widget', 'ExistingWidget']);
      
      // Try to create it again
      await expectLater(
        () => runner.run(<String>['generate', 'widget', 'ExistingWidget']),
        throwsToolExit(message: 'File already exists'),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws error when no name is provided', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await expectLater(
        () => runner.run(<String>['generate', 'widget']),
        throwsToolExit(message: 'Please provide a name'),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('works with short alias "w" for widget', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'w', 'AliasWidget']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('alias_widget.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('works with short alias "s" for screen', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 's', 'SettingsScreen']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('settings_screen.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('works with short alias "p" for page', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'p', 'DashboardPage']);
      
      final File generatedFile = fileSystem.currentDirectory.childDirectory('lib').childFile('dashboard_page.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('creates nested directories when needed', () async {
      final GenerateCommand command = GenerateCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      
      await runner.run(<String>['generate', 'widget', 'DeepWidget', '-o', 'lib/features/auth/widgets']);
      
      final Directory nestedDir = fileSystem.currentDirectory
          .childDirectory('lib')
          .childDirectory('features')
          .childDirectory('auth')
          .childDirectory('widgets');
      expect(nestedDir.existsSync(), isTrue);
      
      final File generatedFile = nestedDir.childFile('deep_widget.dart');
      expect(generatedFile.existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}
