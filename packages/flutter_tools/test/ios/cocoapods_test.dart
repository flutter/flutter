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
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-objc'
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Objective-C podfile template');
    fs.file(fs.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'cocoapods', 'Podfile-swift'
    ))
        ..createSync(recursive: true)
        ..writeAsStringSync('Swift podfile template');
    cocoaPodsUnderTest = const TestCocoaPods();

    when(mockProcessManager.run(
      <String>['pod', 'install', '--verbose'],
      workingDirectory: 'project/ios',
      environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
    )).thenReturn(exitsHappy);
  });

  testUsingContext(
    'create objective-c Podfile when not present',
    () async {
      await cocoaPodsUnderTest.processPods(
        appIosDir: projectUnderTest,
        iosEngineDir: 'engine/path',
      );
      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Objective-C podfile template');
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
      ));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'create swift Podfile if swift',
    () async {
      await cocoaPodsUnderTest.processPods(
        appIosDir: projectUnderTest,
        iosEngineDir: 'engine/path',
        isSwift: true,
      );
      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Swift podfile template');
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
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
      await cocoaPodsUnderTest.processPods(
        appIosDir: projectUnderTest,
        iosEngineDir: 'engine/path',
      );
      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Existing Podfile');
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
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
        await cocoaPodsUnderTest.processPods(
          appIosDir: projectUnderTest,
          iosEngineDir: 'engine/path',
        );
        fail('Expected tool error');
      } catch (ToolExit) {
        verifyNever(mockProcessManager.run(
          <String>['pod', 'install', '--verbose'],
          workingDirectory: 'project/ios',
          environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
        ));
      }
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'outdated specs repo should print error',
    () async {
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsString('Existing Podfile');

      when(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
      )).thenReturn(new ProcessResult(
        1,
        1,
        '''
[!] Unable to satisfy the following requirements:

- `Firebase/Auth` required by `Podfile`
- `Firebase/Auth (= 4.0.0)` required by `Podfile.lock`

None of your spec sources contain a spec satisfying the dependencies: `Firebase/Auth, Firebase/Auth (= 4.0.0)`.

You have either:
 * out-of-date source repos which you can update with `pod repo update` or with `pod install --repo-update`.
 * mistyped the name or version.
 * not added the source repo that hosts the Podspec to your Podfile.

Note: as of CocoaPods 1.0, `pod repo update` does not happen on `pod install` by default.''',
        '',
      ));
      try {
        await cocoaPodsUnderTest.processPods(
          appIosDir: projectUnderTest,
          iosEngineDir: 'engine/path',
        );      expect(fs.file(fs.path.join('project', 'ios', 'Podfile')).readAsStringSync() , 'Existing Podfile');
        fail('Exception expected');
      } catch (ToolExit) {
        expect(testLogger.errorText, contains("CocoaPods's specs repository is too out-of-date to satisfy dependencies"));
      }
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'Run pod install if plugins or flutter framework have changes.',
        () async {
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsString('Existing Podfile');
      fs.file(fs.path.join('project', 'ios', 'Podfile.lock'))
        ..createSync()
        ..writeAsString('Existing lock files.');
      fs.file(fs.path.join('project', 'ios', 'Pods','Manifest.lock'))
        ..createSync(recursive: true)
        ..writeAsString('Existing lock files.');
      await cocoaPodsUnderTest.processPods(
          appIosDir: projectUnderTest,
          iosEngineDir: 'engine/path',
          pluginOrFlutterPodChanged: true
      );
      verify(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
      ));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    },
  );

  testUsingContext(
    'Skip pod install if plugins and flutter framework remain unchanged.',
        () async {
      fs.file(fs.path.join('project', 'ios', 'Podfile'))
        ..createSync()
        ..writeAsString('Existing Podfile');
      fs.file(fs.path.join('project', 'ios', 'Podfile.lock'))
        ..createSync()
        ..writeAsString('Existing lock files.');
      fs.file(fs.path.join('project', 'ios', 'Pods','Manifest.lock'))
        ..createSync(recursive: true)
        ..writeAsString('Existing lock files.');
      await cocoaPodsUnderTest.processPods(
          appIosDir: projectUnderTest,
          iosEngineDir: 'engine/path',
          pluginOrFlutterPodChanged: false
      );
      verifyNever(mockProcessManager.run(
        <String>['pod', 'install', '--verbose'],
        workingDirectory: 'project/ios',
        environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': 'engine/path', 'COCOAPODS_DISABLE_STATS': 'true'},
      ));
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
  1, // pid
  0, // exitCode
  '', // stdout
  '', // stderr
);