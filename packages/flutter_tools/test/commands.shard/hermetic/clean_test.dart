// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('clean command', () {
    Xcode xcode;
    FakeXcodeProjectInterpreter xcodeProjectInterpreter;

    setUp(() {
      xcodeProjectInterpreter = FakeXcodeProjectInterpreter();
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: xcodeProjectInterpreter,
      );
    });

    group('general', () {
      MemoryFileSystem fs;
      Directory buildDirectory;

      setUp(() {
        fs = MemoryFileSystem.test();

        final Directory currentDirectory = fs.currentDirectory;
        buildDirectory = currentDirectory.childDirectory('build');
        buildDirectory.createSync(recursive: true);
      });

      testUsingContext('$CleanCommand removes build and .dart_tool and ephemeral directories, cleans Xcode for iOS and macOS', () async {
        final FlutterProject projectUnderTest = setupProjectUnderTest(fs.currentDirectory);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);
        await CleanCommand().runCommand();

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

        expect(projectUnderTest.linux.ephemeralDirectory, isNot(exists));
        expect(projectUnderTest.macos.ephemeralDirectory, isNot(exists));
        expect(projectUnderTest.windows.ephemeralDirectory, isNot(exists));

        expect(projectUnderTest.flutterPluginsFile, isNot(exists));
        expect(projectUnderTest.flutterPluginsDependenciesFile, isNot(exists));
        expect(projectUnderTest.packagesFile, isNot(exists));

      expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', false),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', false),
        ]);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => xcode,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('$CleanCommand cleans Xcode verbosely for iOS and macOS', () async {
        setupProjectUnderTest(fs.currentDirectory);
        // Xcode is installed and version satisfactory.
        xcodeProjectInterpreter.isInstalled = true;
        xcodeProjectInterpreter.version = Version(1000, 0, 0);

        await CleanCommand(verbose: true).runCommand();

        expect(xcodeProjectInterpreter.workspaces, const <CleanWorkspaceCall>[
          CleanWorkspaceCall('/ios/Runner.xcworkspace', 'Runner', true),
          CleanWorkspaceCall('/macos/Runner.xcworkspace', 'Runner', true),
        ]);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => xcode,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });
    });

    group('Windows', () {
      FakePlatform windowsPlatform;
      MemoryFileSystem fileSystem;
      FileExceptionHandler exceptionHandler;

      setUp(() {
        windowsPlatform = FakePlatform(operatingSystem: 'windows');
        exceptionHandler = FileExceptionHandler();
        fileSystem = MemoryFileSystem.test(opHandle: exceptionHandler.opHandle);
      });

      testUsingContext('$CleanCommand prints a helpful error message on Windows', () async {
        xcodeProjectInterpreter.isInstalled = false;

        final File file = fileSystem.file('file')..createSync();
        exceptionHandler.addError(
          file,
          FileSystemOp.delete,
          const FileSystemException('Deletion failed'),
        );

        final CleanCommand command = CleanCommand();
        command.deleteFile(file);
        expect(testLogger.errorText, contains('A program may still be using a file'));
      }, overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
        Xcode: () => xcode,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('$CleanCommand handles missing delete permissions', () async {
        final FileExceptionHandler handler = FileExceptionHandler();
        final FileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);
        final File throwingFile = fileSystem.file('bad')
          ..createSync();
        handler.addError(throwingFile, FileSystemOp.delete, const FileSystemException('OS error: Access Denied'));

        xcodeProjectInterpreter.isInstalled = false;

        final CleanCommand command = CleanCommand();
        command.deleteFile(throwingFile);

        expect(testLogger.errorText, contains('Failed to remove bad. A program may still be using a file in the directory or the directory itself'));
        expect(throwingFile, exists);
      }, overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
        Xcode: () => xcode,
      });
    });
  });
}

FlutterProject setupProjectUnderTest(Directory currentDirectory) {
  // This needs to be run within testWithoutContext and not setUp since FlutterProject uses context.
  final FlutterProject projectUnderTest = FlutterProject.fromDirectory(currentDirectory);
  projectUnderTest.ios.xcodeWorkspace.createSync(recursive: true);
  projectUnderTest.macos.xcodeWorkspace.createSync(recursive: true);

  projectUnderTest.dartTool.createSync(recursive: true);
  projectUnderTest.packagesFile.createSync(recursive: true);
  projectUnderTest.android.ephemeralDirectory.createSync(recursive: true);

  projectUnderTest.ios.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.ios.ephemeralModuleDirectory.createSync(recursive: true);
  projectUnderTest.ios.generatedXcodePropertiesFile.createSync(recursive: true);
  projectUnderTest.ios.generatedEnvironmentVariableExportScript.createSync(recursive: true);
  projectUnderTest.ios.deprecatedCompiledDartFramework.createSync(recursive: true);
  projectUnderTest.ios.deprecatedProjectFlutterFramework.createSync(recursive: true);
  projectUnderTest.ios.flutterPodspec.createSync(recursive: true);

  projectUnderTest.linux.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.macos.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.windows.ephemeralDirectory.createSync(recursive: true);
  projectUnderTest.flutterPluginsFile.createSync(recursive: true);
  projectUnderTest.flutterPluginsDependenciesFile.createSync(recursive: true);

  return projectUnderTest;
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  @override
  bool isInstalled = true;

  @override
  Version version = Version(0, 0, 0);

  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(null, null, <String>['Runner'], BufferLogger.test());
  }

  final List<CleanWorkspaceCall> workspaces = <CleanWorkspaceCall>[];

  @override
  Future<void> cleanWorkspace(String workspacePath, String scheme, {bool verbose = false}) async {
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
  bool operator ==(Object other) => other is CleanWorkspaceCall &&
    workspacePath == other.workspacePath &&
    scheme == other.scheme &&
    verbose == other.verbose;

  @override
  int get hashCode => Object.hash(workspacePath, scheme, verbose);

  @override
  String toString() => '{$workspacePath, $scheme, $verbose}';
}
