// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class FakeAndroidSdk extends Fake implements AndroidSdk {}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String? get javaPath => null;
}

void main() {
  group('ToolDependencies.bootstrap', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;
    late FakePlatform platform;
    late FakeProcessManager processManager;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      platform = FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home/user'},
      );
      processManager = FakeProcessManager.any();

      // Create flutter root directory and pubspec.yaml to avoid exceptions during bootstrapping
      fs.directory('/flutter/packages/flutter_tools').createSync(recursive: true);
      fs.file('/pubspec.yaml').createSync();
    });

    testUsingContext('successfully bootstraps all contexts with core overrides', () async {
      // Set up mock Android SDK directory to verify eager location works with overridden FS
      fs.directory('/home/user/Android/Sdk/licenses').createSync(recursive: true);

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      expect(dependencies.toolContext, isNotNull);
      expect(dependencies.appleContext, isNotNull);
      expect(dependencies.androidContext, isNotNull);

      // Verify that core overrides were correctly propagated
      fs.file('/test_override.txt').writeAsStringSync('propagated');
      expect(
        dependencies.toolContext.fs.file('/test_override.txt').readAsStringSync(),
        'propagated',
      );

      expect(dependencies.toolContext.logger, same(logger));
      expect(dependencies.toolContext.platform, same(platform));
      expect(dependencies.toolContext.processManager, isA<ErrorHandlingProcessManager>());

      // Verify that other platform-independent dependencies are constructed
      expect(dependencies.analytics, isNotNull);
      expect(dependencies.toolContext.botDetector, isNotNull);
      expect(dependencies.buildSystem, isNotNull);
      expect(dependencies.buildTargets, isNotNull);
      expect(dependencies.crashReporter, isNotNull);
      expect(dependencies.toolContext.cache, isNotNull);
      expect(dependencies.toolContext.config, isNotNull);
      expect(dependencies.toolContext.git, isNotNull);
      expect(dependencies.toolContext.processUtils, isNotNull);
      expect(dependencies.toolContext.projectFactory, isNotNull);
      expect(dependencies.toolContext.shutdownHooks, isNotNull);
      expect(dependencies.toolContext.stdio, isNotNull);
      expect(dependencies.toolContext.systemClock, isNotNull);
      expect(dependencies.toolContext.terminal, isNotNull);
      expect(dependencies.toolContext.userMessages, isNotNull);

      // Verify AppleContext (eagerly constructed even on Linux)
      expect(dependencies.appleContext.cocoaPods, isNotNull);
      expect(dependencies.appleContext.cocoapodsValidator, isNotNull);
      expect(dependencies.appleContext.iosSimulatorUtils, isNotNull);
      expect(dependencies.appleContext.iosWorkflow, isNotNull);
      expect(dependencies.appleContext.plistParser, isNotNull);
      expect(dependencies.appleContext.xcdevice, isNotNull);
      expect(dependencies.appleContext.xcode, isNotNull);
      expect(dependencies.appleContext.xcodeProjectInterpreter, isNotNull);

      // Verify AndroidContext
      expect(dependencies.androidContext.gradleUtils, isNotNull);
      // Verify that Android SDK was located using the overridden FS and platform
      expect(dependencies.androidContext.androidSdk, isNotNull);
      expect(dependencies.androidContext.androidSdk!.directory.path, '/home/user/Android/Sdk');
    });

    testUsingContext('respects explicit overrides for Android SDK and Studio', () async {
      final mockSdk = FakeAndroidSdk();
      final mockStudio = FakeAndroidStudio();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        androidSdk: mockSdk,
        androidStudio: mockStudio,
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      expect(dependencies.androidContext.androidSdk, same(mockSdk));
      expect(dependencies.androidContext.androidStudio, same(mockStudio));
    });
  });
}
