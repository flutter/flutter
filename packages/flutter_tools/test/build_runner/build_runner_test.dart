// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_runner/build_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('experimentalBuildEnabled', () {
    final MockProcessManager mockProcessManager = MockProcessManager();
    final MockPlatform mockPlatform = MockPlatform();
    final MockFileSystem mockFileSystem = MockFileSystem();

    setUp(() {
      experimentalBuildEnabled = null;
    });
    testUsingContext('is enabled if environment variable is enabled and project '
      'contains a dependency on flutter_build and build_runner', () async {
        final MockDirectory projectDirectory = MockDirectory();
        final MockDirectory exampleDirectory = MockDirectory();
        final MockFile packagesFile = MockFile();
        final MockFile pubspecFile = MockFile();
        final MockFile examplePubspecFile = MockFile();
        const String packages = r'''
flutter_build:file:///Users/tester/.pub-cache/hosted/pub.dartlang.org/flutter_build/lib/
build_runner:file:///Users/tester/.pub-cache/hosted/pub.dartlang.org/build_runner/lib/
example:lib/
''';
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_EXPERIMENTAL_BUILD': 'true'});
        when(mockFileSystem.currentDirectory).thenReturn(projectDirectory);
        when(mockFileSystem.isFileSync(any)).thenReturn(false);
        when(projectDirectory.childFile('pubspec.yaml')).thenReturn(pubspecFile);
        when(projectDirectory.childFile('.packages')).thenReturn(packagesFile);
        when(projectDirectory.childDirectory('example')).thenReturn(exampleDirectory);
        when(exampleDirectory.childFile('pubspec.yaml')).thenReturn(examplePubspecFile);
        when(packagesFile.path).thenReturn('/test/.packages');
        when(pubspecFile.path).thenReturn('/test/pubspec.yaml');
        when(examplePubspecFile.path).thenReturn('/test/example/pubspec.yaml');
        when(mockFileSystem.file('/test/.packages')).thenReturn(packagesFile);
        when(packagesFile.readAsBytesSync()).thenReturn(utf8.encode(packages));

        expect(await experimentalBuildEnabled, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => mockPlatform,
      FileSystem: () => mockFileSystem,
    });

    testUsingContext('is not enabled if environment variable is enabled and project '
      'does not contain a dependency on flutter_build', () async {
        final MockDirectory projectDirectory = MockDirectory();
        final MockDirectory exampleDirectory = MockDirectory();
        final MockFile packagesFile = MockFile();
        final MockFile pubspecFile = MockFile();
        final MockFile examplePubspecFile = MockFile();
        const String packages = r'''
build_runner:file:///Users/tester/.pub-cache/hosted/pub.dartlang.org/build_runner/lib/
example:lib/
''';
        when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_EXPERIMENTAL_BUILD': 'true'});
        when(mockFileSystem.currentDirectory).thenReturn(projectDirectory);
        when(mockFileSystem.isFileSync(any)).thenReturn(false);
        when(projectDirectory.childFile('pubspec.yaml')).thenReturn(pubspecFile);
        when(projectDirectory.childFile('.packages')).thenReturn(packagesFile);
        when(projectDirectory.childDirectory('example')).thenReturn(exampleDirectory);
        when(exampleDirectory.childFile('pubspec.yaml')).thenReturn(examplePubspecFile);
        when(packagesFile.path).thenReturn('/test/.packages');
        when(pubspecFile.path).thenReturn('/test/pubspec.yaml');
        when(examplePubspecFile.path).thenReturn('/test/example/pubspec.yaml');
        when(mockFileSystem.file('/test/.packages')).thenReturn(packagesFile);
        when(packagesFile.readAsBytesSync()).thenReturn(utf8.encode(packages));

        expect(await experimentalBuildEnabled, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => mockPlatform,
      FileSystem: () => mockFileSystem,
    });


    testUsingContext('is not enabed if environment varable is not enabled', () async {
      when(mockPlatform.environment).thenReturn(<String, String>{});
      expect(await experimentalBuildEnabled, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => mockPlatform,
      FileSystem: () => mockFileSystem,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockPlatform extends Mock implements Platform {}
class MockFileSystem extends Mock implements FileSystem {}
class MockDirectory extends Mock implements Directory {}
class MockFile extends Mock implements File {}
