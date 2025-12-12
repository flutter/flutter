// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/doctor.dart';

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_project_validators.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });
  late BufferLogger logger;
  late FakeProcessManager fakeProcessManager;
  late MemoryFileSystem fs;

  setUp(() {
    logger = BufferLogger.test();
    fakeProcessManager = FakeProcessManager.empty();
    fs = MemoryFileSystem.test();
    fs.directory('/flutter/bin/cache').createSync(recursive: true);
    fs.currentDirectory = '/';
    Cache.flutterRoot = '/flutter';
  });

  testUsingContext(
    'flutter doctor --project-path runs analysis on valid project',
    () async {
      final Directory projectDir = fs.directory('my_project')..createSync();
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
      projectDir.childFile('.packages').createSync();
      projectDir.childFile('lib/main.dart').createSync(recursive: true);

      final command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['mdfind', 'kMDItemCFBundleIdentifier="com.google.android.studio*"'],
        ),
      );

      await runner.run(<String>['doctor', '--project-path', 'my_project']);

      expect(logger.statusText, contains('Project Analysis'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => fakeProcessManager,
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Logger: () => logger,
      Cache: () => Cache.test(
        rootOverride: fs.directory('/flutter'),
        fileSystem: fs,
        processManager: fakeProcessManager,
      ),
    },
  );

  testUsingContext(
    'flutter doctor implicitly runs analysis in project directory',
    () async {
      final Directory projectDir = fs.directory('my_project')..createSync();
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
      projectDir.childFile('.packages').createSync();
      projectDir.childFile('lib/main.dart').createSync(recursive: true);
      fs.currentDirectory = projectDir;

      final command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['mdfind', 'kMDItemCFBundleIdentifier="com.google.android.studio*"'],
        ),
      );

      await runner.run(<String>['doctor']);

      expect(logger.statusText, contains('Project Analysis'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => fakeProcessManager,
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Logger: () => logger,
      Cache: () => Cache.test(
        rootOverride: fs.directory('/flutter'),
        fileSystem: fs,
        processManager: fakeProcessManager,
      ),
    },
  );

  testUsingContext(
    'flutter doctor shows suggestion when not in project directory',
    () async {
      final Directory nonProjectDir = fs.directory('non_project')..createSync();
      fs.currentDirectory = nonProjectDir;

      final command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['mdfind', 'kMDItemCFBundleIdentifier="com.google.android.studio*"'],
        ),
      );

      await runner.run(<String>['doctor']);

      expect(logger.statusText, isNot(contains('Project Analysis')));
      expect(
        logger.statusText,
        contains(
          'To see project-specific issues, run doctor in some project or specify with "flutter doctor --project-path <path>"',
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => fakeProcessManager,
      DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
      Logger: () => logger,
      Cache: () => Cache.test(
        rootOverride: fs.directory('/flutter'),
        fileSystem: fs,
        processManager: fakeProcessManager,
      ),
    },
  );

  group('ProjectAnalysisValidator', () {
    testUsingContext(
      'reports success when no issues found',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server success
        fakeProcessManager.addCommand(_createAnalysisServerCommand());

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.success);
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'reports pub outdated results',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server success
        fakeProcessManager.addCommand(_createAnalysisServerCommand());
        // Mock dart pub outdated with JSON output
        fakeProcessManager.addCommand(
          const FakeCommand(
            command: <String>['Artifact.engineDartSdkPath/bin/dart', 'pub', 'outdated', '--json'],
            stdout:
                '{"packages": [{"current": {"version": "1.0.0"}}, {"current": {"version": "1.0.0"}}]}',
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.success);
        expect(
          result.messages.map((m) => m.message),
          contains('2 outdated packages found. Run `flutter pub outdated` for details.'),
        );
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'does not report pub outdated results when up to date',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server success
        fakeProcessManager.addCommand(_createAnalysisServerCommand());
        // Mock dart pub outdated with up to date message (empty packages list in JSON)
        fakeProcessManager.addCommand(
          const FakeCommand(
            command: <String>['Artifact.engineDartSdkPath/bin/dart', 'pub', 'outdated', '--json'],
            stdout: '{"packages": []}',
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.success);
        expect(result.messages.map((m) => m.message), isNot(contains('outdated package')));
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'does not report pub outdated results when command fails',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server success
        fakeProcessManager.addCommand(_createAnalysisServerCommand());
        // Mock dart pub outdated failure
        fakeProcessManager.addCommand(
          const FakeCommand(
            command: <String>['Artifact.engineDartSdkPath/bin/dart', 'pub', 'outdated', '--json'],
            exitCode: 1,
            stdout: 'error',
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.success);
        expect(result.messages.map((m) => m.message), isNot(contains('error')));
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'reports partial success when issues found',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server with errors
        fakeProcessManager.addCommand(
          _createAnalysisServerCommand(
            stdout: <String>[
              '{"event":"server.connected","params":{"version":"1.0.0","pid":123}}',
              '{"id":"1","result":{}}', // Response to setAnalysisRoots
              '{"event":"analysis.errors","params":{"file":"/my_project/lib/main.dart","errors":[{"severity":"ERROR","type":"SYNTAX_ERROR","location":{"file":"/my_project/lib/main.dart","offset":0,"length":1,"startLine":1,"startColumn":1},"message":"Syntax error","code":"syntax_error","hasFix":false}]}}',
              '{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}',
            ].join('\n'),
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.partial);
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Syntax error'),
            ),
          ),
        );
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Run `flutter analyze` for details.'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'reports partial success when warnings found',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server with warnings
        fakeProcessManager.addCommand(
          _createAnalysisServerCommand(
            stdout: <String>[
              '{"event":"server.connected","params":{"version":"1.0.0","pid":123}}',
              '{"id":"1","result":{}}', // Response to setAnalysisRoots
              '{"event":"analysis.errors","params":{"file":"/my_project/lib/main.dart","errors":[{"severity":"WARNING","type":"UNUSED_IMPORT","location":{"file":"/my_project/lib/main.dart","offset":0,"length":1,"startLine":1,"startColumn":1},"message":"Unused import","code":"unused_import","hasFix":true}]}}',
              '{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}',
            ].join('\n'),
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.partial);
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Unused import'),
            ),
          ),
        );
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Run `flutter analyze` for details.'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );

    testUsingContext(
      'reports partial success when lints found',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final validator = ProjectAnalysisValidator(
          project: FlutterProject.fromDirectory(projectDir),
          fileSystem: fs,
          platform: FakePlatform(),
          processManager: fakeProcessManager,
          terminal: Terminal.test(),
          artifacts: Artifacts.test(),
        );

        // Mock analysis server with lints (INFO)
        fakeProcessManager.addCommand(
          _createAnalysisServerCommand(
            stdout: <String>[
              '{"event":"server.connected","params":{"version":"1.0.0","pid":123}}',
              '{"id":"1","result":{}}', // Response to setAnalysisRoots
              '{"event":"analysis.errors","params":{"file":"/my_project/lib/main.dart","errors":[{"severity":"INFO","type":"LINT","location":{"file":"/my_project/lib/main.dart","offset":0,"length":1,"startLine":1,"startColumn":1},"message":"Lint rule violated","code":"lint_rule","hasFix":true}]}}',
              '{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}',
            ].join('\n'),
          ),
        );

        final ValidationResult result = await validator.validate();
        expect(result.type, ValidationType.partial);
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Lint rule violated'),
            ),
          ),
        );
        expect(
          result.messages,
          contains(
            isA<ValidationMessage>().having(
              (ValidationMessage m) => m.message,
              'message',
              contains('Run `flutter analyze` for details.'),
            ),
          ),
        );
      },
      overrides: <Type, Generator>{FileSystem: () => fs, ProcessManager: () => fakeProcessManager},
    );
  });

  group('ValidateProject', () {
    testUsingContext(
      'flutter doctor --project-path --disable-project-validators skips project analysis',
      () async {
        final Directory projectDir = fs.directory('my_project')..createSync();
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_project\n');
        projectDir.childFile('.packages').createSync();
        projectDir.childFile('lib/main.dart').createSync(recursive: true);

        final command = DoctorCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);

        fakeProcessManager.addCommand(
          const FakeCommand(
            command: <String>['mdfind', 'kMDItemCFBundleIdentifier="com.google.android.studio*"'],
          ),
        );

        await runner.run(<String>[
          'doctor',
          '--project-path',
          'my_project',
          '--disable-project-validators',
        ]);

        expect(logger.statusText, isNot(contains('Project Analysis')));
        expect(logger.statusText, isNot(contains('Project Validation')));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => fakeProcessManager,
        DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
        Logger: () => logger,
        Cache: () => Cache.test(
          rootOverride: fs.directory('/flutter'),
          fileSystem: fs,
          processManager: fakeProcessManager,
        ),
      },
    );
  });
}

class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[FakeValidator('Fake Validator')];

  @override
  List<Workflow> get workflows => <Workflow>[];
}

FakeCommand _createAnalysisServerCommand({
  String stdout = '{"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}',
}) {
  return FakeCommand(
    command: const <String>[
      'Artifact.engineDartSdkPath/bin/dart',
      'Artifact.engineDartSdkPath/bin/snapshots/analysis_server.dart.snapshot',
      '--disable-server-feature-completion',
      '--disable-server-feature-search',
      '--sdk',
      'Artifact.engineDartSdkPath',
      '--suppress-analytics',
    ],
    stdout: stdout,
  );
}

class FakeValidator extends DoctorValidator {
  FakeValidator(super.title);

  @override
  Future<ValidationResult> validateImpl() async {
    return ValidationResult(ValidationType.success, <ValidationMessage>[]);
  }
}
