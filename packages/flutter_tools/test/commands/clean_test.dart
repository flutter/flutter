// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';


void main() {
  final MockFileSystem mockFileSystem = MockFileSystem();
  final MockDirectory currentDirectory = MockDirectory();
  final MockDirectory exampleDirectory = MockDirectory();
  final MockDirectory buildDirectory = MockDirectory();
  final MockDirectory androidBuildDirectory = MockDirectory();
  final MockDirectory dartToolDirectory = MockDirectory();
  final MockFile pubspec = MockFile();
  final MockFile examplePubspec = MockFile();
  const String pubspecContents = '''name: plugin_tester
description: A new Flutter project.
version: 1.0.0+1
environment:
  sdk: ">=2.1.0 <3.0.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''';


  when(mockFileSystem.currentDirectory).thenReturn(currentDirectory);
  when(currentDirectory.childDirectory('example')).thenReturn(exampleDirectory);
  when(currentDirectory.childFile('pubspec.yaml')).thenReturn(pubspec);
  when(pubspec.path).thenReturn('/test/pubspec.yaml');
  when(exampleDirectory.childFile('pubspec.yaml')).thenReturn(examplePubspec);
  when(currentDirectory.childDirectory('.dart_tool')).thenReturn(dartToolDirectory);
  when(examplePubspec.path).thenReturn('/test/example/pubspec.yaml');
  when(mockFileSystem.isFileSync('/test/pubspec.yaml')).thenReturn(false);
  when(mockFileSystem.isFileSync('/test/example/pubspec.yaml')).thenReturn(false);
  when(pubspec.readAsString()).thenAnswer((_) => Future<String>.value(pubspecContents));
  when(mockFileSystem.directory('build')).thenReturn(buildDirectory);
  when(mockFileSystem.directory('android/app/build')).thenReturn(androidBuildDirectory);
  when(mockFileSystem.path).thenReturn(fs.path);
  when(buildDirectory.existsSync()).thenReturn(true);
  when(androidBuildDirectory.existsSync()).thenReturn(true);
  when(dartToolDirectory.existsSync()).thenReturn(true);
  group(CleanCommand, () {
    testUsingContext('removes build and .dart_tool directories', () async {
      await CleanCommand().runCommand();
      verify(buildDirectory.deleteSync(recursive: true)).called(1);
      verify(androidBuildDirectory.deleteSync(recursive: true)).called(1);
      verify(dartToolDirectory.deleteSync(recursive: true)).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      Config: () => null,
    });
  });
}

class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
class MockDirectory extends Mock implements Directory {}
