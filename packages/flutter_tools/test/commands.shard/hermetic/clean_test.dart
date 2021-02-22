// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('clean command', () {
    Xcode xcode;
    MockXcodeProjectInterpreter mockXcodeProjectInterpreter;

    setUp(() {
      mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      xcode = Xcode.test(
        processManager: FakeProcessManager.any(),
        xcodeProjectInterpreter: mockXcodeProjectInterpreter,
      );
    });

    group('general', () {
      MemoryFileSystem fs;
      Directory buildDirectory;
      FlutterProject projectUnderTest;

      setUp(() {
        fs = MemoryFileSystem.test();

        final Directory currentDirectory = fs.currentDirectory;
        buildDirectory = currentDirectory.childDirectory('build');
        buildDirectory.createSync(recursive: true);

        projectUnderTest = FlutterProject.fromDirectory(currentDirectory);
        projectUnderTest.ios.xcodeWorkspace.createSync(recursive: true);
        projectUnderTest.macos.xcodeWorkspace.createSync(recursive: true);

        projectUnderTest.dartTool.createSync(recursive: true);
        projectUnderTest.packagesFile.createSync(recursive: true);
        projectUnderTest.android.ephemeralDirectory.createSync(recursive: true);

        projectUnderTest.ios.ephemeralDirectory.createSync(recursive: true);
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
      });

      testUsingContext('$CleanCommand removes build and .dart_tool and ephemeral directories, cleans Xcode', () async {
        // Xcode is installed and version satisfactory.
        when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
        when(mockXcodeProjectInterpreter.majorVersion).thenReturn(1000);
        await CleanCommand().runCommand();

        expect(buildDirectory.existsSync(), isFalse);
        expect(projectUnderTest.dartTool.existsSync(), isFalse);
        expect(projectUnderTest.android.ephemeralDirectory.existsSync(), isFalse);

        expect(projectUnderTest.ios.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.ios.generatedXcodePropertiesFile.existsSync(), isFalse);
        expect(projectUnderTest.ios.generatedEnvironmentVariableExportScript.existsSync(), isFalse);
        expect(projectUnderTest.ios.deprecatedCompiledDartFramework.existsSync(), isFalse);
        expect(projectUnderTest.ios.deprecatedProjectFlutterFramework.existsSync(), isFalse);
        expect(projectUnderTest.ios.flutterPodspec.existsSync(), isFalse);

        expect(projectUnderTest.linux.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.macos.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.windows.ephemeralDirectory.existsSync(), isFalse);

        expect(projectUnderTest.flutterPluginsFile.existsSync(), isFalse);
        expect(projectUnderTest.flutterPluginsDependenciesFile.existsSync(), isFalse);
        expect(projectUnderTest.packagesFile.existsSync(), isFalse);

        verify(mockXcodeProjectInterpreter.cleanWorkspace(any, 'Runner', verbose: false)).called(2);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => xcode,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      });

      testUsingContext('$CleanCommand cleans Xcode verbosely', () async {
        // Xcode is installed and version satisfactory.
        when(mockXcodeProjectInterpreter.isInstalled).thenReturn(true);
        when(mockXcodeProjectInterpreter.majorVersion).thenReturn(1000);

        await CleanCommand(verbose: true).runCommand();
        verify(mockXcodeProjectInterpreter.cleanWorkspace(any, 'Runner', verbose: true)).called(2);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => xcode,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
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
        when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

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

      testUsingContext('$CleanCommand handles missing permissions;', () async {
        when(mockXcodeProjectInterpreter.isInstalled).thenReturn(false);

        final MockFile mockFile = MockFile();
        when(mockFile.existsSync()).thenThrow(const FileSystemException('OS error: Access Denied'));
        when(mockFile.path).thenReturn('foo.dart');

        final CleanCommand command = CleanCommand();
        command.deleteFile(mockFile);
        expect(testLogger.errorText, contains('Cannot clean foo.dart'));
        verifyNever(mockFile.deleteSync(recursive: true));
      }, overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
        Xcode: () => xcode,
      });
    });
  });
}

class MockFile extends Mock implements File {}

class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {
  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(null, null, <String>['Runner'], BufferLogger.test());
  }
}
