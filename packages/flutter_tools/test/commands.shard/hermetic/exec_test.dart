// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/exec.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('ExecCommand', () {
    late FileSystem fileSystem;
    late BufferLogger logger;
    late FakeProcessManager processManager;
    late CommandRunner<void> runner;

    setUp(() {
      Cache.disableLocking();
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      processManager = FakeProcessManager.empty();
      runner = createTestCommandRunner(ExecCommand());
    });

    testUsingContext(
      'shows error when no script name provided',
      () async {
        await expectLater(
          runner.run(<String>['exec']),
          throwsToolExit(message: 'No script name provided'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'shows error when no pubspec.yaml exists',
      () async {
        await expectLater(
          runner.run(<String>['exec', 'test']),
          throwsToolExit(message: 'No scripts defined in pubspec.yaml'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'shows error when no scripts section in pubspec.yaml',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
''');

        await expectLater(
          runner.run(<String>['exec', 'test']),
          throwsToolExit(message: 'No scripts defined in pubspec.yaml'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'shows error when script not found',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  build: flutter build apk
''');

        await expectLater(
          runner.run(<String>['exec', 'test']),
          throwsToolExit(message: 'Script "test" not found in pubspec.yaml'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'lists scripts when --list flag is used',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  test: dart test
  build: flutter build apk
  format: dart format .
''');

        await runner.run(<String>['exec', '--list']);

        expect(logger.statusText, contains('Available scripts:'));
        expect(logger.statusText, contains('test: dart test'));
        expect(logger.statusText, contains('build: flutter build apk'));
        expect(logger.statusText, contains('format: dart format .'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'shows message when no scripts defined and --list is used',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
''');

        await runner.run(<String>['exec', '--list']);

        expect(logger.statusText, contains('No scripts defined in pubspec.yaml'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script successfully',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  test: dart test
''');

        processManager.addCommand(
          const FakeCommand(command: <String>['dart', 'test'], stdout: 'All tests passed!'),
        );

        await runner.run(<String>['exec', 'test']);

        expect(logger.statusText, contains('Running script "test": dart test'));
        expect(logger.statusText, contains('All tests passed!'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with multiple arguments',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  build: flutter build apk --release --dart-define-from-file=config.json
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>[
              'flutter',
              'build',
              'apk',
              '--release',
              '--dart-define-from-file=config.json',
            ],
            stdout: 'Build completed successfully!',
          ),
        );

        await runner.run(<String>['exec', 'build']);

        expect(logger.statusText, contains('Running script "build"'));
        expect(logger.statusText, contains('Build completed successfully!'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'handles script execution failure',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  test: dart test
''');

        processManager.addCommand(
          const FakeCommand(command: <String>['dart', 'test'], exitCode: 1, stderr: 'Test failed!'),
        );

        await expectLater(
          runner.run(<String>['exec', 'test']),
          throwsToolExit(message: 'Script "test" failed with exit code 1'),
        );

        expect(logger.errorText, contains('Test failed!'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'handles invalid scripts section in pubspec.yaml',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts: "not a map"
''');

        await expectLater(
          runner.run(<String>['exec', 'test']),
          throwsToolExit(message: 'No scripts defined in pubspec.yaml'),
        );

        expect(logger.errorText, contains('Expected "scripts" to be a map'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'handles script with invalid command value',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  test: 123
''');

        await runner.run(<String>['exec', '--list']);

        expect(logger.errorText, contains('Expected script command to be a string'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'handles script with invalid script name',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  123: dart test
''');

        await runner.run(<String>['exec', '--list']);

        expect(logger.errorText, contains('Expected script name to be a string'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with quoted arguments correctly',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  greet: echo "Hello World"
''');

        processManager.addCommand(
          const FakeCommand(command: <String>['echo', 'Hello World'], stdout: 'Hello World'),
        );

        await runner.run(<String>['exec', 'greet']);

        expect(logger.statusText, contains('Running script "greet": echo "Hello World"'));
        expect(logger.statusText, contains('Hello World'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with shell operators using sh -c',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  multi: echo "Hello" && echo "World"
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>['sh', '-c', 'echo "Hello" && echo "World"'],
            stdout: 'Hello\nWorld',
          ),
        );

        await runner.run(<String>['exec', 'multi']);

        expect(logger.statusText, contains('Running script "multi": echo "Hello" && echo "World"'));
        expect(logger.statusText, contains('Hello\nWorld'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with pipe operators using sh -c',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  pipe: ls | grep test
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>['sh', '-c', 'ls | grep test'],
            stdout: 'test_file.dart',
          ),
        );

        await runner.run(<String>['exec', 'pipe']);

        expect(logger.statusText, contains('Running script "pipe": ls | grep test'));
        expect(logger.statusText, contains('test_file.dart'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with mixed quotes and spaces',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  complex: flutter build --name "My App" --verbose
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>['flutter', 'build', '--name', 'My App', '--verbose'],
            stdout: 'Build completed',
          ),
        );

        await runner.run(<String>['exec', 'complex']);

        expect(logger.statusText, contains('Running script "complex"'));
        expect(logger.statusText, contains('Build completed'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with single quotes',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  single: echo 'Hello Single Quote'
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>['echo', 'Hello Single Quote'],
            stdout: 'Hello Single Quote',
          ),
        );

        await runner.run(<String>['exec', 'single']);

        expect(logger.statusText, contains('Running script "single"'));
        expect(logger.statusText, contains('Hello Single Quote'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'executes script with semicolon operator using sh -c',
      () async {
        fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: test_app
dependencies:
  flutter:
    sdk: flutter
scripts:
  sequence: dart format .; dart analyze
''');

        processManager.addCommand(
          const FakeCommand(
            command: <String>['sh', '-c', 'dart format .; dart analyze'],
            stdout: 'Formatted and analyzed',
          ),
        );

        await runner.run(<String>['exec', 'sequence']);

        expect(logger.statusText, contains('Running script "sequence"'));
        expect(logger.statusText, contains('Formatted and analyzed'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => processManager,
        Logger: () => logger,
      },
    );
  });
}
