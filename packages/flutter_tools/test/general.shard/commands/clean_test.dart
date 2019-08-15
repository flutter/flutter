// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  MockFileSystem mockFileSystem;
  MockDirectory currentDirectory;
  MockDirectory exampleDirectory;
  MockDirectory buildDirectory;
  MockDirectory dartToolDirectory;
  MockDirectory androidEphemeralDirectory;
  MockDirectory iosEphemeralDirectory;
  MockFile pubspec;
  MockFile examplePubspec;
  MockPlatform windowsPlatform;

  setUp(() {
    mockFileSystem = MockFileSystem();
    currentDirectory = MockDirectory();
    exampleDirectory = MockDirectory();
    buildDirectory = MockDirectory();
    dartToolDirectory = MockDirectory();
    androidEphemeralDirectory = MockDirectory();
    iosEphemeralDirectory = MockDirectory();
    pubspec = MockFile();
    examplePubspec = MockFile();
    windowsPlatform = MockPlatform();
    when(mockFileSystem.currentDirectory).thenReturn(currentDirectory);
    when(currentDirectory.childDirectory('example')).thenReturn(exampleDirectory);
    when(currentDirectory.childFile('pubspec.yaml')).thenReturn(pubspec);
    when(pubspec.path).thenReturn('/test/pubspec.yaml');
    when(exampleDirectory.childFile('pubspec.yaml')).thenReturn(examplePubspec);
    when(currentDirectory.childDirectory('.dart_tool')).thenReturn(dartToolDirectory);
    when(currentDirectory.childDirectory('.android')).thenReturn(androidEphemeralDirectory);
    when(currentDirectory.childDirectory('.ios')).thenReturn(iosEphemeralDirectory);
    when(examplePubspec.path).thenReturn('/test/example/pubspec.yaml');
    when(mockFileSystem.isFileSync('/test/pubspec.yaml')).thenReturn(false);
    when(mockFileSystem.isFileSync('/test/example/pubspec.yaml')).thenReturn(false);
    when(mockFileSystem.directory('build')).thenReturn(buildDirectory);
    when(mockFileSystem.path).thenReturn(fs.path);
    when(buildDirectory.existsSync()).thenReturn(true);
    when(dartToolDirectory.existsSync()).thenReturn(true);
    when(androidEphemeralDirectory.existsSync()).thenReturn(true);
    when(iosEphemeralDirectory.existsSync()).thenReturn(true);
    when(windowsPlatform.isWindows).thenReturn(true);
  });

  group(CleanCommand, () {
    testUsingContext('removes build and .dart_tool and ephemeral directories', () async {
      await CleanCommand().runCommand();
      verify(buildDirectory.deleteSync(recursive: true)).called(1);
      verify(dartToolDirectory.deleteSync(recursive: true)).called(1);
      verify(androidEphemeralDirectory.deleteSync(recursive: true)).called(1);
      verify(iosEphemeralDirectory.deleteSync(recursive: true)).called(1);
    }, overrides: <Type, Generator>{
      Config: () => null,
      FileSystem: () => mockFileSystem,
    });

    testUsingContext('prints a helpful error message on Windows', () async {
      final BufferLogger logger = context.get<Logger>();
      when(buildDirectory.deleteSync(recursive: true)).thenThrow(
          const FileSystemException('Deletion failed'));
      expect(() async => await CleanCommand().runCommand(), throwsA(isInstanceOf<ToolExit>()));
      expect(logger.errorText, contains('A program may still be using a file'));
    }, overrides: <Type, Generator>{
      Config: () => null,
      FileSystem: () => mockFileSystem,
      Platform: () => windowsPlatform,
      Logger: () => BufferLogger(),
    });
  });
}

class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
class MockDirectory extends Mock implements Directory {}
class MockPlatform extends Mock implements Platform {}
