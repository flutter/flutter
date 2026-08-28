// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class FakeAndroidSdk extends Fake implements AndroidSdk {}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String? get javaPath => null;
}

class FakeBuildTargets extends Fake implements BuildTargets {}

class FakeCocoaPods extends Fake implements CocoaPods {}

class FakeCocoaPodsValidator extends Fake implements CocoaPodsValidator {}

class FakeIOSSimulatorUtils extends Fake implements IOSSimulatorUtils {}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {}

class FakePlistParser extends Fake implements PlistParser {}

class FakeXCDevice extends Fake implements XCDevice {}

class FakeXcode extends Fake implements Xcode {}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {}

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

      // Verify AppleContext (lazy getters evaluated on access)
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

    testUsingContext('shares memoized instance across multiple property reads', () async {
      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      final Xcode xcode1 = dependencies.appleContext.xcode;
      final Xcode xcode2 = dependencies.appleContext.xcode;
      expect(xcode1, same(xcode2));

      final CocoaPods pods1 = dependencies.appleContext.cocoaPods;
      final CocoaPods pods2 = dependencies.appleContext.cocoaPods;
      expect(pods1, same(pods2));
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

    testUsingContext('respects explicit overrides for Apple dependencies', () async {
      final mockCocoaPods = FakeCocoaPods();
      final mockCocoaPodsValidator = FakeCocoaPodsValidator();
      final mockIOSSimulatorUtils = FakeIOSSimulatorUtils();
      final mockIOSWorkflow = FakeIOSWorkflow();
      final mockPlistParser = FakePlistParser();
      final mockXCDevice = FakeXCDevice();
      final mockXcode = FakeXcode();
      final mockXcodeProjectInterpreter = FakeXcodeProjectInterpreter();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        cocoaPods: mockCocoaPods,
        cocoapodsValidator: mockCocoaPodsValidator,
        fs: fs,
        iosSimulatorUtils: mockIOSSimulatorUtils,
        iosWorkflow: mockIOSWorkflow,
        logger: logger,
        platform: platform,
        plistParser: mockPlistParser,
        processManager: processManager,
        xcdevice: mockXCDevice,
        xcode: mockXcode,
        xcodeProjectInterpreter: mockXcodeProjectInterpreter,
      );

      expect(dependencies.appleContext.cocoaPods, same(mockCocoaPods));
      expect(dependencies.appleContext.cocoapodsValidator, same(mockCocoaPodsValidator));
      expect(dependencies.appleContext.iosSimulatorUtils, same(mockIOSSimulatorUtils));
      expect(dependencies.appleContext.iosWorkflow, same(mockIOSWorkflow));
      expect(dependencies.appleContext.plistParser, same(mockPlistParser));
      expect(dependencies.appleContext.xcdevice, same(mockXCDevice));
      expect(dependencies.appleContext.xcode, same(mockXcode));
      expect(dependencies.appleContext.xcodeProjectInterpreter, same(mockXcodeProjectInterpreter));
    });
  });

  group('AppleContext', () {
    testWithoutContext('evaluates all dependencies lazily and memoizes results', () {
      var cocoaPodsEvaluations = 0;
      var cocoapodsValidatorEvaluations = 0;
      var iosSimulatorUtilsEvaluations = 0;
      var iosWorkflowEvaluations = 0;
      var plistParserEvaluations = 0;
      var xcdeviceEvaluations = 0;
      var xcodeEvaluations = 0;
      var xcodeProjectInterpreterEvaluations = 0;

      final mockCocoaPods = FakeCocoaPods();
      final mockCocoaPodsValidator = FakeCocoaPodsValidator();
      final mockIOSSimulatorUtils = FakeIOSSimulatorUtils();
      final mockIOSWorkflow = FakeIOSWorkflow();
      final mockPlistParser = FakePlistParser();
      final mockXCDevice = FakeXCDevice();
      final mockXcode = FakeXcode();
      final mockXcodeProjectInterpreter = FakeXcodeProjectInterpreter();

      final context = AppleContext(
        cocoaPodsBuilder: () {
          cocoaPodsEvaluations++;
          return mockCocoaPods;
        },
        cocoapodsValidatorBuilder: () {
          cocoapodsValidatorEvaluations++;
          return mockCocoaPodsValidator;
        },
        iosSimulatorUtilsBuilder: () {
          iosSimulatorUtilsEvaluations++;
          return mockIOSSimulatorUtils;
        },
        iosWorkflowBuilder: () {
          iosWorkflowEvaluations++;
          return mockIOSWorkflow;
        },
        plistParserBuilder: () {
          plistParserEvaluations++;
          return mockPlistParser;
        },
        xcdeviceBuilder: () {
          xcdeviceEvaluations++;
          return mockXCDevice;
        },
        xcodeBuilder: () {
          xcodeEvaluations++;
          return mockXcode;
        },
        xcodeProjectInterpreterBuilder: () {
          xcodeProjectInterpreterEvaluations++;
          return mockXcodeProjectInterpreter;
        },
      );

      // No builder has been invoked upon instantiation.
      expect(cocoaPodsEvaluations, 0);
      expect(cocoapodsValidatorEvaluations, 0);
      expect(iosSimulatorUtilsEvaluations, 0);
      expect(iosWorkflowEvaluations, 0);
      expect(plistParserEvaluations, 0);
      expect(xcdeviceEvaluations, 0);
      expect(xcodeEvaluations, 0);
      expect(xcodeProjectInterpreterEvaluations, 0);

      // Accessing properties multiple times evaluates builder exactly once.
      expect(context.cocoaPods, same(mockCocoaPods));
      expect(context.cocoaPods, same(mockCocoaPods));
      expect(cocoaPodsEvaluations, 1);

      expect(context.cocoapodsValidator, same(mockCocoaPodsValidator));
      expect(context.cocoapodsValidator, same(mockCocoaPodsValidator));
      expect(cocoapodsValidatorEvaluations, 1);

      expect(context.iosSimulatorUtils, same(mockIOSSimulatorUtils));
      expect(context.iosSimulatorUtils, same(mockIOSSimulatorUtils));
      expect(iosSimulatorUtilsEvaluations, 1);

      expect(context.iosWorkflow, same(mockIOSWorkflow));
      expect(context.iosWorkflow, same(mockIOSWorkflow));
      expect(iosWorkflowEvaluations, 1);

      expect(context.plistParser, same(mockPlistParser));
      expect(context.plistParser, same(mockPlistParser));
      expect(plistParserEvaluations, 1);

      expect(context.xcdevice, same(mockXCDevice));
      expect(context.xcdevice, same(mockXCDevice));
      expect(xcdeviceEvaluations, 1);

      expect(context.xcode, same(mockXcode));
      expect(context.xcode, same(mockXcode));
      expect(xcodeEvaluations, 1);

      expect(context.xcodeProjectInterpreter, same(mockXcodeProjectInterpreter));
      expect(context.xcodeProjectInterpreter, same(mockXcodeProjectInterpreter));
      expect(xcodeProjectInterpreterEvaluations, 1);
    });
  });
}
