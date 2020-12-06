// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    MockXcode mockXcode;
    setUp(() {
      mockXcode = MockXcode();
    });

    group('general', () {
      MemoryFileSystem fs;
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      Directory buildDirectory;
      FlutterProject projectUnderTest;

      setUp(() {
        fs = MemoryFileSystem();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();

        final Directory currentDirectory = fs.currentDirectory;
        buildDirectory = currentDirectory.childDirectory('build');
        buildDirectory.createSync(recursive: true);

        projectUnderTest = FlutterProject.fromDirectory(currentDirectory);
        projectUnderTest.ios.xcodeWorkspace.createSync(recursive: true);
        projectUnderTest.macos.xcodeWorkspace.createSync(recursive: true);

        projectUnderTest.dartTool.createSync(recursive: true);
        projectUnderTest.android.ephemeralDirectory.createSync(recursive: true);

        projectUnderTest.ios.ephemeralDirectory.createSync(recursive: true);
        projectUnderTest.ios.generatedXcodePropertiesFile.createSync(recursive: true);
        projectUnderTest.ios.generatedEnvironmentVariableExportScript.createSync(recursive: true);
        projectUnderTest.ios.compiledDartFramework.createSync(recursive: true);

        projectUnderTest.linux.ephemeralDirectory.createSync(recursive: true);
        projectUnderTest.macos.ephemeralDirectory.createSync(recursive: true);
        projectUnderTest.windows.ephemeralDirectory.createSync(recursive: true);
        projectUnderTest.flutterPluginsFile.createSync(recursive: true);
        projectUnderTest.flutterPluginsDependenciesFile.createSync(recursive: true);
      });

      testUsingContext('$CleanCommand removes build and .dart_tool and ephemeral directories, cleans Xcode', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
        await CleanCommand().runCommand();

        expect(buildDirectory.existsSync(), isFalse);
        expect(projectUnderTest.dartTool.existsSync(), isFalse);
        expect(projectUnderTest.android.ephemeralDirectory.existsSync(), isFalse);

        expect(projectUnderTest.ios.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.ios.generatedXcodePropertiesFile.existsSync(), isFalse);
        expect(projectUnderTest.ios.generatedEnvironmentVariableExportScript.existsSync(), isFalse);
        expect(projectUnderTest.ios.compiledDartFramework.existsSync(), isFalse);

        expect(projectUnderTest.linux.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.macos.ephemeralDirectory.existsSync(), isFalse);
        expect(projectUnderTest.windows.ephemeralDirectory.existsSync(), isFalse);

        expect(projectUnderTest.flutterPluginsFile.existsSync(), isFalse);
        expect(projectUnderTest.flutterPluginsDependenciesFile.existsSync(), isFalse);

        verify(mockXcodeProjectInterpreter.cleanWorkspace(any, 'Runner', verbose: false)).called(2);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => mockXcode,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      });

      testUsingContext('$CleanCommand cleans Xcode verbosely', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
        await CleanCommand(verbose: true).runCommand();
        verify(mockXcodeProjectInterpreter.cleanWorkspace(any, 'Runner', verbose: true)).called(2);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Xcode: () => mockXcode,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      });
    });

    group('Windows', () {
      MockPlatform windowsPlatform;
      setUp(() {
        windowsPlatform = MockPlatform();
      });

      testUsingContext('$CleanCommand prints a helpful error message on Windows', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
        when(windowsPlatform.isWindows).thenReturn(true);

        final MockFile mockFile = MockFile();
        when(mockFile.existsSync()).thenReturn(true);

        when(mockFile.deleteSync(recursive: true)).thenThrow(const FileSystemException('Deletion failed'));
        final CleanCommand command = CleanCommand();
        command.deleteFile(mockFile);
        expect(testLogger.errorText, contains('A program may still be using a file'));
        verify(mockFile.deleteSync(recursive: true)).called(1);
      }, overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
        Xcode: () => mockXcode,
      });

      testUsingContext('$CleanCommand handles missing permissions;', () async {
        when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

        final MockFile mockFile = MockFile();
        when(mockFile.existsSync()).thenThrow(const FileSystemException('OS error: Access Denied'));
        when(mockFile.path).thenReturn('foo.dart');

        final CleanCommand command = CleanCommand();
        command.deleteFile(mockFile);
        expect(testLogger.errorText, contains('Cannot clean foo.dart'));
        verifyNever(mockFile.deleteSync(recursive: true));
      }, overrides: <Type, Generator>{
        Platform: () => windowsPlatform,
        Xcode: () => mockXcode,
      });
    });
  });
}

class MockFile extends Mock implements File {}
class MockPlatform extends Mock implements Platform {}
class MockXcode extends Mock implements Xcode {}

class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {
  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(null, null, <String>['Runner'], BufferLogger.test());
  }
}
