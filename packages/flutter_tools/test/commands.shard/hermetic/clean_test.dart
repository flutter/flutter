// ignore_for_file: unreachable_from_main
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('clean command', () {
    late Xcode xcode;
    late FakeXcodeProjectInterpreter xcodeProjectInterpreter;

    setUp(() {
      Cache.disableLocking();
      xcodeProjectInterpreter = FakeXcodeProjectInterpreter();
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: xcodeProjectInterpreter,
      );
    });

    group('general', () {
      late MemoryFileSystem fs;
      late Directory buildDirectory;
      late BufferLogger logger;

      setUp(() {
        fs = MemoryFileSystem.test();
        fs.file('pubspec.yaml').createSync(recursive: true);
        logger = BufferLogger.test();

        final Directory currentDirectory = fs.currentDirectory;
        buildDirectory = currentDirectory.childDirectory('build');
        buildDirectory.createSync(recursive: true);
      });

      testWithoutContext(
        '$CleanCommand removes build and .dart_tool and ephemeral directories, cleans Xcode for iOS and macOS',
        () async {
          final FlutterProject projectUnderTest = setupProjectUnderTest(fs.currentDirectory, true);
          // Xcode is installed and version satisfactory.
          xcodeProjectInterpreter.isInstalled = true;
          xcodeProjectInterpreter.version = Version(1000, 0, 0);
          final CommandRunner<void> runner = createTestCommandRunner(
            createCleanCommand(
              fs: fs,
              logger: logger,
              xcode: xcode,
              xcodeProjectInterpreter: xcodeProjectInterpreter,
            ),
          );
          await runner.run(<String>['clean']);

          expect(buildDirectory, isNot(exists));
          expect(projectUnderTest.dartTool, isNot(exists));
          expect(projectUnderTest.android.ephemeralDirectory, isNot(exists));

          expect(projectUnderTest.ios.ephemeralDirectory, isNot(exists));
          expect(projectUnderTest.ios.ephemeralModuleDirectory, isNot(exists));
          expect(projectUnderTest.ios.generatedXcodePropertiesFile, isNot(exists));
          expect(projectUnderTest.ios.generatedEnvironmentVariableExportScript, isNot(exists));
          expect(projectUnderTest.ios.deprecatedCompiledDartFramework, isNot(exists));
          expect(projectUnderTest.ios.deprecatedProjectFlutterFramework, isNot(exists));
          expect(projectUnderTest.ios.flutterPodspec, isNot(exists));
          expect(projectUnderTest.ios.flutterPluginSwiftPackageDirectory, isNot(exists));

          expect(projectUnderTest.linux.ephemeralDirectory, isNot(exists));
          expect(projectUnderTest.macos.ephemeralDirectory, isNot(exists));
          expect(projectUnderTest.macos.flutterPluginSwiftPackageDirectory, isNot(exists));
          expect(projectUnderTest.windows.ephemeralDirectory, isNot(exists));

          expect(projectUnderTest.flutterPluginsDependenciesFile, isNot(exists));
          expect(
            projectUnderTest.directory
                .childDirectory('.dart_tool')
                .childFile('package_config.json'),
            isNot(exists),
          );

          expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
            CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/ios/Runner.xcworkspace', 'custom-scheme', false),
            CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/macos/Runner.xcworkspace', 'custom-scheme', false),
          ]);
        },
      );

      testWithoutContext('$CleanCommand does not clean the example directory by default', () async {
        setupProjectUnderTest(fs.currentDirectory, true);
        final FlutterProject exampleProject = setupProjectUnderTest(
          fs.currentDirectory.childDirectory('example'),
          true,
        );
        final Directory exampleBuildDir = exampleProject.directory.childDirectory('build');
        exampleBuildDir.createSync(recursive: true);

        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);
        final CommandRunner<void> runner = createTestCommandRunner(
          createCleanCommand(
            fs: fs,
            logger: logger,
            xcode: xcode,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          ),
        );
        await runner.run(<String>['clean']);

        expect(buildDirectory, isNot(exists));

        expect(exampleBuildDir, exists);
        expect(exampleProject.dartTool, exists);
        expect(exampleProject.android.ephemeralDirectory, exists);
        expect(exampleProject.ios.ephemeralDirectory, exists);
        expect(exampleProject.linux.ephemeralDirectory, exists);
        expect(exampleProject.macos.ephemeralDirectory, exists);
        expect(exampleProject.windows.ephemeralDirectory, exists);
        expect(exampleProject.flutterPluginsDependenciesFile, exists);

        expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', false),
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'custom-scheme', false),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', false),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'custom-scheme', false),
        ]);
      });

      testWithoutContext(
        '$CleanCommand cleans the example directory with --include-example',
        () async {
          final FlutterProject projectUnderTest = setupProjectUnderTest(fs.currentDirectory, true);
          final FlutterProject exampleProject = setupProjectUnderTest(
            fs.currentDirectory.childDirectory('example'),
            true,
          );
          final Directory exampleBuildDir = exampleProject.directory.childDirectory('build');
          exampleBuildDir.createSync(recursive: true);

          xcodeProjectInterpreter.isInstalled = true;
          xcodeProjectInterpreter.version = Version(1000, 0, 0);

          final CommandRunner<void> runner = createTestCommandRunner(
            createCleanCommand(
              fs: fs,
              logger: logger,
              xcode: xcode,
              xcodeProjectInterpreter: xcodeProjectInterpreter,
            ),
          );
          await runner.run(<String>['clean', '--include-example']);

          expect(buildDirectory, isNot(exists));
          expect(projectUnderTest.dartTool, isNot(exists));

          expect(exampleBuildDir, isNot(exists));
          expect(exampleProject.dartTool, isNot(exists));
          expect(exampleProject.android.ephemeralDirectory, isNot(exists));

          expect(exampleProject.ios.ephemeralDirectory, isNot(exists));
          expect(exampleProject.ios.ephemeralModuleDirectory, isNot(exists));
          expect(exampleProject.ios.generatedXcodePropertiesFile, isNot(exists));
          expect(exampleProject.ios.generatedEnvironmentVariableExportScript, isNot(exists));
          expect(exampleProject.ios.deprecatedCompiledDartFramework, isNot(exists));
          expect(exampleProject.ios.deprecatedProjectFlutterFramework, isNot(exists));
          expect(exampleProject.ios.flutterPodspec, isNot(exists));

          expect(exampleProject.linux.ephemeralDirectory, isNot(exists));
          expect(exampleProject.macos.ephemeralDirectory, isNot(exists));
          expect(exampleProject.windows.ephemeralDirectory, isNot(exists));
          expect(exampleProject.flutterPluginsDependenciesFile, isNot(exists));

          expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
            CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/ios/Runner.xcworkspace', 'custom-scheme', false),
            CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/macos/Runner.xcworkspace', 'custom-scheme', false),
            CleanWorkspaceCall('/example/ios/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/example/ios/Runner.xcworkspace', 'custom-scheme', false),
            CleanWorkspaceCall('/example/macos/Runner.xcworkspace', 'Runner', false),
            CleanWorkspaceCall('/example/macos/Runner.xcworkspace', 'custom-scheme', false),
          ]);
        },
      );

      testWithoutContext(
        '$CleanCommand warns when --include-example is passed but no example exists',
        () async {
          setupProjectUnderTest(fs.currentDirectory, true);
          // No example directory created.

          xcodeProjectInterpreter.isInstalled = true;
          xcodeProjectInterpreter.version = Version(1000, 0, 0);
          final CommandRunner<void> runner = createTestCommandRunner(
            createCleanCommand(
              fs: fs,
              logger: logger,
              xcode: xcode,
              xcodeProjectInterpreter: xcodeProjectInterpreter,
            ),
          );
          await runner.run(<String>['clean', '--include-example']);

          expect(logger.statusText, contains('No example app found'));
        },
      );

      testWithoutContext('$CleanCommand removes a specific xcode scheme --scheme', () async {
        setupProjectUnderTest(fs.currentDirectory, true);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);

        final CleanCommand command = createCleanCommand(
          fs: fs,
          logger: logger,
          xcode: xcode,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);
        await runner.run(<String>['clean', '--scheme=custom-scheme']);

        expect(xcodeProjectInterpreter.workspaces, <CleanWorkspaceCall>[
          const CleanWorkspaceCall('/ios/Runner.xcworkspace', 'custom-scheme', false),
          const CleanWorkspaceCall('/macos/Runner.xcworkspace', 'custom-scheme', false),
        ]);
      });

      testWithoutContext('$CleanCommand does not run when there is no xcworkspace', () async {
        setupProjectUnderTest(fs.currentDirectory, false);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);
        final CommandRunner<void> runner = createTestCommandRunner(
          createCleanCommand(
            fs: fs,
            logger: logger,
            xcode: xcode,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          ),
        );
        await runner.run(<String>['clean']);

        expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[]);
      });

      testWithoutContext('$CleanCommand throws when given an invalid value for --scheme', () async {
        setupProjectUnderTest(fs.currentDirectory, true);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);

        final CleanCommand command = createCleanCommand(
          fs: fs,
          logger: logger,
          xcode: xcode,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
        expect(
          () => createTestCommandRunner(command).run(<String>['clean', '--scheme']),
          throwsUsageException(),
        );
        expect(
          () => createTestCommandRunner(command).run(<String>['clean', '--scheme=unknown']),
          throwsToolExit(),
        );
      });

      testWithoutContext('$CleanCommand cleans Xcode verbosely for iOS and macOS', () async {
        setupProjectUnderTest(fs.currentDirectory, true);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);

        final CleanCommand command = createCleanCommand(
          fs: fs,
          logger: logger,
          xcode: xcode,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
          verbose: true,
        );
        final CommandRunner<void> runner = createTestCommandRunner(command);
        await runner.run(<String>['clean']);

        expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', true),
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'custom-scheme', true),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', true),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'custom-scheme', true),
        ]);
      });
    });

    group('Windows', () {
      late FakePlatform windowsPlatform;
      late MemoryFileSystem fileSystem;
      late FileExceptionHandler exceptionHandler;
      late FakeProcessManager processManager;
      late BufferLogger logger;

      setUp(() {
        windowsPlatform = FakePlatform(operatingSystem: 'windows');
        exceptionHandler = FileExceptionHandler();
        fileSystem = MemoryFileSystem.test(opHandle: exceptionHandler.opHandle);
        fileSystem.file('pubspec.yaml').createSync(recursive: true);
        processManager = FakeProcessManager.any();
        logger = BufferLogger.test();
      });

      testWithoutContext('$CleanCommand prints a helpful error message on Windows', () async {
        xcodeProjectInterpreter.isInstalled = false;

        final File file = fileSystem.file('file')..createSync();
        exceptionHandler.addError(
          file,
          FileSystemOp.delete,
          const FileSystemException('Deletion failed'),
        );

        final CleanCommand command = createCleanCommand(
          fs: fileSystem,
          logger: logger,
          platform: windowsPlatform,
          processManager: processManager,
          xcode: xcode,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
        await command.deleteFile(file);
        expect(
          logger.errorText,
          contains('A background process (e.g. Gradle daemon or Java) is locking files'),
        );
      });

      testWithoutContext('$CleanCommand handles missing delete permissions', () async {
        final handler = FileExceptionHandler();

        // Ensures we handle ErrorHandlingFileSystem appropriately in prod.
        // See https://github.com/flutter/flutter/issues/108978.
        final FileSystem fs = ErrorHandlingFileSystem(
          delegate: MemoryFileSystem.test(opHandle: handler.opHandle),
          platform: windowsPlatform,
        );
        final File throwingFile = fs.file('bad')..createSync();
        handler.addError(
          throwingFile,
          FileSystemOp.delete,
          const FileSystemException('OS error: Access Denied'),
        );

        xcodeProjectInterpreter.isInstalled = false;

        final CleanCommand command = createCleanCommand(
          fs: fs,
          logger: logger,
          platform: windowsPlatform,
          xcode: xcode,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
        );
        await command.deleteFile(throwingFile);

        expect(
          logger.errorText,
          contains(
            'Failed to remove bad. A background process (e.g. Gradle daemon or Java) is locking files',
          ),
        );
        expect(throwingFile, exists);
      });

      testWithoutContext(
        '$CleanCommand invokes gradlew --stop and retries deletion when --stop-gradle flag is passed',
        () async {
          xcodeProjectInterpreter.isInstalled = false;

          var shouldThrow = true;
          fileSystem = MemoryFileSystem.test(
            opHandle: (String path, FileSystemOp op) {
              if (shouldThrow && op == FileSystemOp.delete && path.endsWith('build')) {
                throw const FileSystemException('Locked');
              }
            },
          );
          fileSystem.file('pubspec.yaml').createSync(recursive: true);

          final FlutterProject project = setupProjectUnderTest(fileSystem.currentDirectory, false);
          final File gradlewFile = project.android.hostAppGradleRoot.childFile('gradlew.bat')
            ..createSync(recursive: true);

          final Directory buildDir = project.directory.childDirectory('build')
            ..createSync(recursive: true);
          buildDir.childFile('locked').createSync(recursive: true);

          processManager = FakeProcessManager.list(<FakeCommand>[
            FakeCommand(
              command: <String>[gradlewFile.path, '--stop'],
              workingDirectory: gradlewFile.parent.path,
              onRun: (_) {
                shouldThrow = false;
              },
            ),
          ]);

          final CleanCommand command = createCleanCommand(
            fs: fileSystem,
            logger: logger,
            platform: windowsPlatform,
            processManager: processManager,
            xcode: xcode,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          );
          final CommandRunner<void> runner = createTestCommandRunner(command);
          await runner.run(<String>['clean', '--stop-gradle']);

          expect(logger.statusText, contains('Stopping Gradle daemons'));
        },
      );

      testWithoutContext(
        '$CleanCommand prompts user and invokes gradlew --stop when locked on Windows interactively',
        () async {
          xcodeProjectInterpreter.isInstalled = false;

          var shouldThrow = true;
          fileSystem = MemoryFileSystem.test(
            opHandle: (String path, FileSystemOp op) {
              if (shouldThrow && op == FileSystemOp.delete && path.endsWith('build')) {
                throw const FileSystemException('Locked');
              }
            },
          );
          fileSystem.file('pubspec.yaml').createSync(recursive: true);

          final FlutterProject project = setupProjectUnderTest(fileSystem.currentDirectory, false);
          final File gradlewFile = project.android.hostAppGradleRoot.childFile('gradlew.bat')
            ..createSync(recursive: true);

          final Directory buildDir = project.directory.childDirectory('build')
            ..createSync(recursive: true);
          buildDir.childFile('locked').createSync(recursive: true);

          processManager = FakeProcessManager.list(<FakeCommand>[
            FakeCommand(
              command: <String>[gradlewFile.path, '--stop'],
              workingDirectory: gradlewFile.parent.path,
              onRun: (_) {
                shouldThrow = false;
              },
            ),
          ]);

          final CleanCommand command = createCleanCommand(
            fs: fileSystem,
            logger: logger,
            platform: windowsPlatform,
            processManager: processManager,
            terminal: FakeTerminal(),
            xcode: xcode,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          );
          final CommandRunner<void> runner = createTestCommandRunner(command);
          await runner.run(<String>['clean']);

          expect(logger.statusText, contains('Stopping Gradle daemons'));
        },
      );

      testWithoutContext(
        '$CleanCommand prompts user but skips gradlew --stop when user declines prompt',
        () async {
          xcodeProjectInterpreter.isInstalled = false;

          fileSystem = MemoryFileSystem.test(
            opHandle: (String path, FileSystemOp op) {
              if (op == FileSystemOp.delete && path.endsWith('build')) {
                throw const FileSystemException('Locked');
              }
            },
          );
          fileSystem.file('pubspec.yaml').createSync(recursive: true);

          final FlutterProject project = setupProjectUnderTest(fileSystem.currentDirectory, false);
          project.android.hostAppGradleRoot.childFile('gradlew.bat').createSync(recursive: true);

          final Directory buildDir = project.directory.childDirectory('build')
            ..createSync(recursive: true);
          buildDir.childFile('locked').createSync(recursive: true);

          processManager = FakeProcessManager.empty();

          final CleanCommand command = createCleanCommand(
            fs: fileSystem,
            logger: logger,
            platform: windowsPlatform,
            processManager: processManager,
            terminal: FakeTerminal(response: 'n'),
            xcode: xcode,
            xcodeProjectInterpreter: xcodeProjectInterpreter,
          );
          final CommandRunner<void> runner = createTestCommandRunner(command);
          await runner.run(<String>['clean']);

          expect(logger.statusText, isNot(contains('Stopping Gradle daemons')));
          expect(
            logger.errorText,
            contains('A background process (e.g. Gradle daemon or Java) is locking files'),
          );
        },
      );
    });
  });
}

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({this.response = 'y'});

  final String response;

  @override
  bool get stdinHasTerminal => true;

  @override
  bool get usesTerminalUi => true;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    return response;
  }
}

FlutterProject setupProjectUnderTest(Directory currentDirectory, bool setupXcodeWorkspace) {
  // This needs to be run within testWithoutContext and not setUp since FlutterProject uses context.
  final FlutterProject projectUnderTest = FlutterProject.fromDirectoryTest(currentDirectory);
  if (setupXcodeWorkspace) {
    projectUnderTest.ios.hostAppRoot
        .childDirectory('Runner.xcworkspace')
        .createSync(recursive: true);
    projectUnderTest.macos.hostAppRoot
        .childDirectory('Runner.xcworkspace')
        .createSync(recursive: true);
  }
  projectUnderTest.dartTool.createSync(recursive: true);
  writePackageConfigFiles(directory: projectUnderTest.directory, mainLibName: 'my_app');

  projectUnderTest.android.ephemeralDirectory.createSync(recursive: true);

  projectUnderTest.ios.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.ios.ephemeralModuleDirectory.createSync(recursive: true);
  projectUnderTest.ios.generatedXcodePropertiesFile.createSync(recursive: true);
  projectUnderTest.ios.generatedEnvironmentVariableExportScript.createSync(recursive: true);
  projectUnderTest.ios.deprecatedCompiledDartFramework.createSync(recursive: true);
  projectUnderTest.ios.deprecatedProjectFlutterFramework.createSync(recursive: true);
  projectUnderTest.ios.flutterPodspec.createSync(recursive: true);
  projectUnderTest.ios.flutterPluginSwiftPackageDirectory.createSync(recursive: true);

  projectUnderTest.linux.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.macos.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.macos.flutterPluginSwiftPackageDirectory.createSync(recursive: true);
  projectUnderTest.windows.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.flutterPluginsDependenciesFile.createSync(recursive: true);

  return projectUnderTest;
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  @override
  bool isInstalled = true;

  @override
  Version version = Version(0, 0, 0);

  @override
  Future<XcodeProjectInfo> getInfo(
    XcodeBasedProject xcodeProject, {
    String? projectFilename,
    required Directory buildDirectory,
  }) async {
    return XcodeProjectInfo(const <String>[], const <String>[], <String>[
      'Runner',
      'custom-scheme',
    ], BufferLogger.test());
  }

  final workspaces = <CleanWorkspaceCall>[];

  @override
  Future<void> cleanWorkspace(
    XcodeBasedProject xcodeProject,
    String workspacePath,
    String scheme, {
    required Directory buildDirectory,
    bool verbose = false,
  }) async {
    workspaces.add(CleanWorkspaceCall(workspacePath, scheme, verbose));
    return;
  }
}

@immutable
class CleanWorkspaceCall {
  const CleanWorkspaceCall(this.workspacePath, this.scheme, this.verbose);

  final String workspacePath;
  final String scheme;
  final bool verbose;

  @override
  bool operator ==(Object other) =>
      other is CleanWorkspaceCall &&
      workspacePath == other.workspacePath &&
      scheme == other.scheme &&
      verbose == other.verbose;

  @override
  int get hashCode => Object.hash(workspacePath, scheme, verbose);

  @override
  String toString() => '{$workspacePath, $scheme, $verbose}';
}

CleanCommand createCleanCommand({
  FileSystem? fs,
  Logger? logger,
  Platform? platform,
  ProcessManager? processManager,
  ProcessUtils? processUtils,
  SystemClock? systemClock,
  AnsiTerminal? terminal,
  UserMessages? userMessages,
  Config? config,
  Xcode? xcode,
  XcodeProjectInterpreter? xcodeProjectInterpreter,
  bool verbose = false,
}) {
  final FileSystem resolvedFs = fs ?? MemoryFileSystem.test();
  final Platform resolvedPlatform = platform ?? FakePlatform();
  final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
  final Logger resolvedLogger = logger ?? BufferLogger.test();
  return CleanCommand(
    toolContext: FakeToolContext(
      fs: resolvedFs,
      logger: resolvedLogger,
      platform: resolvedPlatform,
      processManager: resolvedProcessManager,
      processUtils:
          processUtils ??
          ProcessUtils(processManager: resolvedProcessManager, logger: resolvedLogger),
      systemClock: systemClock ?? const SystemClock(),
      terminal: terminal ?? AnsiTerminal(stdio: FakeStdio(), platform: resolvedPlatform),
      userMessages: userMessages ?? UserMessages(),
      config: config ?? Config.test(directory: resolvedFs.directory('/')),
      stdio: FakeStdio(),
    ),
    verbose: verbose,
    xcode: xcode ?? Xcode.test(processManager: resolvedProcessManager),
    xcodeProjectInterpreter: xcodeProjectInterpreter ?? FakeXcodeProjectInterpreter(),
  );
}
