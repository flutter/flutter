// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class FakeAndroidSdk extends Fake implements AndroidSdk {}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String? get javaPath => null;
}

class FakeBuildTargets extends Fake implements BuildTargets {}

class FakeGradleUtils extends Fake implements GradleUtils {}

class FakeJava extends Fake implements Java {}

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
      expect(dependencies.buildTargets, isNull);
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

    testUsingContext('respects explicit overrides for BuildTargets', () async {
      final mockBuildTargets = FakeBuildTargets();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        buildTargets: mockBuildTargets,
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      expect(dependencies.buildTargets, same(mockBuildTargets));
    });

    testUsingContext(
      'lazily evaluates androidStudio and shares instance between AndroidContext and Java',
      () async {
        // Mock Android SDK directory to allow SDK detection.
        fs.directory('/home/user/Android/Sdk/licenses').createSync(recursive: true);

        final ToolDependencies dependencies = await ToolDependencies.bootstrap(
          fs: fs,
          logger: logger,
          platform: platform,
          processManager: processManager,
        );

        // Java and AndroidStudio are not evaluated until accessed.
        final Java? java = dependencies.androidContext.java;
        final AndroidStudio? studio = dependencies.androidContext.androidStudio;

        // If Java home was resolved from AndroidStudio, verify same instance was used.
        if (java != null && java.javaSource == JavaSource.androidStudio) {
          expect(java.javaHome, studio?.javaPath);
        }
      },
    );

    testUsingContext('lazily evaluates androidSdk upon first access in AndroidContext', () async {
      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      final AndroidSdk? sdk = dependencies.androidContext.androidSdk;
      expect(sdk, isNull);
    });
  });

  group('AndroidContext', () {
    testWithoutContext(
      'evaluates androidSdk, androidStudio, and java lazily and memoizes results',
      () {
        var sdkEvaluations = 0;
        var studioEvaluations = 0;
        var javaEvaluations = 0;

        final mockSdk = FakeAndroidSdk();
        final mockStudio = FakeAndroidStudio();
        final mockJava = FakeJava();

        final context = AndroidContext(
          androidSdkBuilder: () {
            sdkEvaluations++;
            return mockSdk;
          },
          androidStudioBuilder: () {
            studioEvaluations++;
            return mockStudio;
          },
          gradleUtils: FakeGradleUtils(),
          javaBuilder: () {
            javaEvaluations++;
            return mockJava;
          },
        );

        // No factory has been invoked upon instantiation.
        expect(sdkEvaluations, 0);
        expect(studioEvaluations, 0);
        expect(javaEvaluations, 0);

        // Accessing androidSdk multiple times evaluates factory exactly once.
        expect(context.androidSdk, same(mockSdk));
        expect(context.androidSdk, same(mockSdk));
        expect(sdkEvaluations, 1);
        expect(studioEvaluations, 0);
        expect(javaEvaluations, 0);

        // Accessing androidStudio multiple times evaluates factory exactly once.
        expect(context.androidStudio, same(mockStudio));
        expect(context.androidStudio, same(mockStudio));
        expect(studioEvaluations, 1);
        expect(javaEvaluations, 0);

        // Accessing java multiple times evaluates factory exactly once.
        expect(context.java, same(mockJava));
        expect(context.java, same(mockJava));
        expect(javaEvaluations, 1);
      },
    );

    testWithoutContext('memoizes null results without re-invoking factory closures', () {
      var sdkEvaluations = 0;
      var studioEvaluations = 0;
      var javaEvaluations = 0;

      final context = AndroidContext(
        androidSdkBuilder: () {
          sdkEvaluations++;
          return null;
        },
        androidStudioBuilder: () {
          studioEvaluations++;
          return null;
        },
        gradleUtils: FakeGradleUtils(),
        javaBuilder: () {
          javaEvaluations++;
          return null;
        },
      );

      expect(context.androidSdk, isNull);
      expect(context.androidSdk, isNull);
      expect(sdkEvaluations, 1);

      expect(context.androidStudio, isNull);
      expect(context.androidStudio, isNull);
      expect(studioEvaluations, 1);

      expect(context.java, isNull);
      expect(context.java, isNull);
      expect(javaEvaluations, 1);
    });
  });
}
