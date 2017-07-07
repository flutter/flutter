// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/ios/cocoapods.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  FileSystem fs;
  ProcessManager mockProcessManager;
  Directory projectUnderTest;
  CocoaPods cocoaPodsUnderTest;

  setUp(() {
    Cache.flutterRoot = 'flutter';
    fs = new MemoryFileSystem();
    mockProcessManager = new MockProcessManager();
    projectUnderTest = fs.directory(fs.path.join('project', 'ios'))..createSync(recursive: true);
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile'
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Podfile template');
    cocoaPodsUnderTest = const TestCocoaPods();

    when(mockProcessManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: 'project/ios',
      environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path'},
    )).thenReturn(exitsHappy);
  });

  testUsingContext(
    'create Podfile when not present',
    () async {
      await cocoaPodsUnderTest.processPods(projectUnderTest, 'engine/path');
      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Podfile template');
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path'},
      ));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'do not recreate Podfile when present',
    () async {
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsString('Existing Podfile');
      await cocoaPodsUnderTest.processPods(projectUnderTest, 'engine/path');
      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Existing Podfile');
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path'},
      ));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'missing CocoaPods throws',
    () async {
      cocoaPodsUnderTest = const TestCocoaPods(false);
      try {
        await cocoaPodsUnderTest.processPods(projectUnderTest, 'engine/path');
        fail('Expected tool error');
      } catch (ToolExit) {
        verifyNever(mockProcessManager.run(
          <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path'},
        ));
      }
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );
}

class MockProcessManager extends Mock implements ProcessManager {}

class TestCocoaPods extends CocoaPods {
  const TestCocoaPods([this._hasCocoaPods = true]);

  final bool _hasCocoaPods;

  @override
  Future<bool> get hasCocoaPods => new Future<bool>.value(_hasCocoaPods);

  @override
  Future<String> get cocoaPodsVersionText async => new Future<String>.value('1.5.0');

  @override
  Future<bool> get isCocoaPodsInitialized => new Future<bool>.value(true);
}

final ProcessResult exitsHappy = new ProcessResult(
  1,     // pid
  0,     // exitCode
  '',    // stdout
  '',    // stderr
);