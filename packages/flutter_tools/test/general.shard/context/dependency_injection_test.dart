// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/flutter_device_manager.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/cocoapods_validator.dart';
import 'package:flutter_tools/src/macos/xcdevice.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/pre_run_validator.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

class FakeAndroidSdk extends Fake implements AndroidSdk {}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String? get javaPath => null;
}

class FakeBuildTargets extends Fake implements BuildTargets {}

class FakeGradleUtils extends Fake implements GradleUtils {}

class FakeJava extends Fake implements Java {}

class _StubFlutterVersion extends Fake implements FlutterVersion {}

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
        templateRenderer: FakeTemplateRenderer(),
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
      expect(dependencies.buildTargets, isA<NoOpBuildTargets>());
      expect(dependencies.crashReporter, isNotNull);
      expect(dependencies.deviceManager, isA<FlutterDeviceManager>());
      expect(dependencies.doctor, isNotNull);
      expect(dependencies.emulatorManager, isNotNull);
      expect(dependencies.featureFlags, isNotNull);
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

      // Verify AppleContext
      final AppleContext(
        cocoaPods: CocoaPods cocoaPods,
        cocoapodsValidator: CocoaPodsValidator cocoapodsValidator,
        iosSimulatorUtils: IOSSimulatorUtils iosSimulatorUtils,
        iosWorkflow: IOSWorkflow iosWorkflow,
        plistParser: PlistParser plistParser,
        xcdevice: XCDevice xcdevice,
        xcode: Xcode xcode,
        xcodeProjectInterpreter: XcodeProjectInterpreter xcodeProjectInterpreter,
      ) = dependencies.appleContext;

      expect(cocoaPods, isNotNull);
      expect(cocoapodsValidator, isNotNull);
      expect(iosSimulatorUtils, isNotNull);
      expect(iosWorkflow, isNotNull);
      expect(plistParser, isNotNull);
      expect(xcdevice, isNotNull);
      expect(xcode, isNotNull);
      expect(xcodeProjectInterpreter, isNotNull);

      // Verify AndroidContext
      expect(dependencies.androidContext.gradleUtils, isNotNull);
    });

    testUsingContext(
      'defers XCDevice construction until accessed and memoizes across reads',
      () async {
        final shutdownHooks = ShutdownHooks();
        final ToolDependencies dependencies = await ToolDependencies.bootstrap(
          fs: fs,
          logger: logger,
          platform: platform,
          processManager: processManager,
          shutdownHooks: shutdownHooks,
          templateRenderer: FakeTemplateRenderer(),
        );

        final int hooksAfterBootstrap = shutdownHooks.registeredHooks.length;

        final XCDevice xcdevice1 = dependencies.appleContext.xcdevice;
        expect(shutdownHooks.registeredHooks, hasLength(hooksAfterBootstrap + 1));

        final XCDevice xcdevice2 = dependencies.appleContext.xcdevice;
        expect(xcdevice1, same(xcdevice2));
        expect(shutdownHooks.registeredHooks, hasLength(hooksAfterBootstrap + 1));

        final Xcode xcode1 = dependencies.appleContext.xcode;
        final Xcode xcode2 = dependencies.appleContext.xcode;
        expect(xcode1, same(xcode2));

        final CocoaPods pods1 = dependencies.appleContext.cocoaPods;
        final CocoaPods pods2 = dependencies.appleContext.cocoaPods;
        expect(pods1, same(pods2));
      },
    );

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
        templateRenderer: FakeTemplateRenderer(),
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
        templateRenderer: FakeTemplateRenderer(),
      );

      expect(dependencies.buildTargets, same(mockBuildTargets));
    });

    testUsingContext('respects explicit overrides for DeviceManager', () async {
      final mockDeviceManager = FakeDeviceManager();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        deviceManager: mockDeviceManager,
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: FakeTemplateRenderer(),
      );

      expect(dependencies.deviceManager, same(mockDeviceManager));
    });

    testUsingContext('respects explicit overrides for FeatureFlags', () async {
      final mockFeatureFlags = TestFeatureFlags();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        featureFlags: mockFeatureFlags,
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: FakeTemplateRenderer(),
      );

      expect(dependencies.featureFlags, same(mockFeatureFlags));
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
        templateRenderer: FakeTemplateRenderer(),
        xcdevice: mockXCDevice,
        xcode: mockXcode,
        xcodeProjectInterpreter: mockXcodeProjectInterpreter,
      );

      final AppleContext(
        cocoaPods: CocoaPods cocoaPods,
        cocoapodsValidator: CocoaPodsValidator cocoapodsValidator,
        iosSimulatorUtils: IOSSimulatorUtils iosSimulatorUtils,
        iosWorkflow: IOSWorkflow iosWorkflow,
        plistParser: PlistParser plistParser,
        xcdevice: XCDevice xcdevice,
        xcode: Xcode xcode,
        xcodeProjectInterpreter: XcodeProjectInterpreter xcodeProjectInterpreter,
      ) = dependencies.appleContext;

      expect(cocoaPods, same(mockCocoaPods));
      expect(cocoapodsValidator, same(mockCocoaPodsValidator));
      expect(iosSimulatorUtils, same(mockIOSSimulatorUtils));
      expect(iosWorkflow, same(mockIOSWorkflow));
      expect(plistParser, same(mockPlistParser));
      expect(xcdevice, same(mockXCDevice));
      expect(xcode, same(mockXcode));
      expect(xcodeProjectInterpreter, same(mockXcodeProjectInterpreter));
    });

    testUsingContext('resolves DeferredArtifacts to local engine artifacts', () async {
      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: FakeTemplateRenderer(),
      );

      if (dependencies.toolContext.artifacts case final DeferredArtifacts artifacts) {
        expect(artifacts.usesLocalArtifacts, isFalse);

        final localArtifacts = Artifacts.testLocalEngine(
          localEngine: 'out/host_debug',
          localEngineHost: 'out/host_debug',
        );
        artifacts.resolve(localArtifacts);

        expect(artifacts.usesLocalArtifacts, isTrue);
        expect(artifacts.localEngineInfo, isNotNull);
        expect(artifacts.localEngineInfo?.localTargetName, 'host_debug');
      } else {
        fail('Expected dependencies.toolContext.artifacts to be DeferredArtifacts');
      }
    });

    testUsingContext(
      'lazily evaluates androidStudio and java upon access in AndroidContext',
      () async {
        // Mock Android SDK directory to allow SDK detection.
        fs.directory('/home/user/Android/Sdk/licenses').createSync(recursive: true);

        var studioEvaluations = 0;
        var javaEvaluations = 0;
        final mockStudio = FakeAndroidStudio();
        final mockJava = FakeJava();

        final ToolDependencies dependencies = await ToolDependencies.bootstrap(
          androidStudioBuilder: () {
            studioEvaluations++;
            return mockStudio;
          },
          javaBuilder: () {
            javaEvaluations++;
            return mockJava;
          },
          fs: fs,
          logger: logger,
          platform: platform,
          processManager: processManager,
          templateRenderer: FakeTemplateRenderer(),
        );

        // Neither AndroidStudio nor Java is evaluated during bootstrap or EmulatorManager initialization.
        expect(studioEvaluations, 0);
        expect(javaEvaluations, 0);

        // Querying emulator discoverers does not trigger Java or AndroidStudio evaluation.
        await dependencies.emulatorManager.getAllAvailableEmulators();
        expect(studioEvaluations, 0);
        expect(javaEvaluations, 0);

        // Java and AndroidStudio are not evaluated until accessed.
        final Java? java = dependencies.androidContext.java;
        expect(javaEvaluations, 1);
        expect(studioEvaluations, 0);
        expect(java, same(mockJava));

        final AndroidStudio? studio = dependencies.androidContext.androidStudio;
        expect(studioEvaluations, 1);
        expect(studio, same(mockStudio));
      },
    );

    testUsingContext(
      'shares AndroidStudio instance between AndroidContext and default Java.find',
      () async {
        // Mock Android SDK directory to allow SDK detection.
        fs.directory('/home/user/Android/Sdk/licenses').createSync(recursive: true);

        var studioEvaluations = 0;
        final mockStudio = FakeAndroidStudio();

        final ToolDependencies dependencies = await ToolDependencies.bootstrap(
          androidStudioBuilder: () {
            studioEvaluations++;
            return mockStudio;
          },
          fs: fs,
          logger: logger,
          platform: platform,
          processManager: processManager,
          templateRenderer: FakeTemplateRenderer(),
        );

        expect(studioEvaluations, 0);

        final Java? java = dependencies.androidContext.java;
        final AndroidStudio? studio = dependencies.androidContext.androidStudio;

        // Verify AndroidStudio was only evaluated once despite Java.find referencing it.
        expect(studioEvaluations, 1);
        expect(studio, same(mockStudio));
        if (java != null && java.javaSource == JavaSource.androidStudio) {
          expect(java.javaHome, studio?.javaPath);
        }
      },
    );

    testUsingContext('lazily evaluates androidSdk upon first access in AndroidContext', () async {
      var sdkEvaluations = 0;
      final mockSdk = FakeAndroidSdk();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        androidSdkBuilder: () {
          sdkEvaluations++;
          return mockSdk;
        },
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: FakeTemplateRenderer(),
      );

      // AndroidSdk is not evaluated during bootstrap or EmulatorManager initialization.
      expect(sdkEvaluations, 0);

      // AndroidSdk is not evaluated until accessed.
      final AndroidSdk? sdk = dependencies.androidContext.androidSdk;
      expect(sdkEvaluations, 1);
      expect(sdk, same(mockSdk));

      // Subsequent access does not re-evaluate.
      expect(dependencies.androidContext.androidSdk, same(mockSdk));
      expect(sdkEvaluations, 1);
    });

    testUsingContext('lazily evaluates gradleUtils upon first access in AndroidContext', () async {
      var gradleEvaluations = 0;
      final mockGradle = FakeGradleUtils();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        gradleUtilsBuilder: () {
          gradleEvaluations++;
          return mockGradle;
        },
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: FakeTemplateRenderer(),
      );

      // GradleUtils is not evaluated during bootstrap.
      expect(gradleEvaluations, 0);

      // GradleUtils is not evaluated until accessed.
      final GradleUtils gradle = dependencies.androidContext.gradleUtils;
      expect(gradleEvaluations, 1);
      expect(gradle, same(mockGradle));

      // Subsequent access does not re-evaluate.
      expect(dependencies.androidContext.gradleUtils, same(mockGradle));
      expect(gradleEvaluations, 1);
    });

    testWithoutContext(
      'does not eagerly evaluate FlutterVersion.channel or enable PreRunValidator by default',
      () async {
        final emptyFs = MemoryFileSystem.test();
        final ToolDependencies dependencies = await ToolDependencies.bootstrap(
          analytics: const NoOpAnalytics(),
          flutterVersion: _StubFlutterVersion(),
          fs: emptyFs,
          logger: logger,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': '/missing_sdk', 'HOME': '/home/user'},
          ),
          processManager: processManager,
          templateRenderer: FakeTemplateRenderer(),
        );

        final PreRunValidator preRunValidator = dependencies.toolContext.preRunValidator;
        expect(preRunValidator, isA<NoOpPreRunValidator>());
        preRunValidator.validate();
      },
    );
  });

  group('runInContext fallback generators', () {
    var sdkEvaluations = 0;
    var javaEvaluations = 0;

    setUp(() {
      sdkEvaluations = 0;
      javaEvaluations = 0;
    });

    testUsingContext(
      'AndroidWorkflow and EmulatorManager do not eagerly evaluate AndroidSdk or Java',
      () {
        expect(androidWorkflow, isNotNull);
        expect(emulatorManager, isNotNull);
        expect(sdkEvaluations, 0);
        expect(javaEvaluations, 0);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () {
          sdkEvaluations++;
          return FakeAndroidSdk();
        },
        Java: () {
          javaEvaluations++;
          return FakeJava();
        },
        FileSystem: () => MemoryFileSystem.test(),
        Logger: () => BufferLogger.test(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home/user'},
        ),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  group('AndroidContext', () {
    testWithoutContext(
      'evaluates androidSdk, androidStudio, gradleUtils, and java lazily and memoizes results',
      () {
        var sdkEvaluations = 0;
        var studioEvaluations = 0;
        var gradleEvaluations = 0;
        var javaEvaluations = 0;

        final mockSdk = FakeAndroidSdk();
        final mockStudio = FakeAndroidStudio();
        final mockGradle = FakeGradleUtils();
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
          gradleUtilsBuilder: () {
            gradleEvaluations++;
            return mockGradle;
          },
          javaBuilder: () {
            javaEvaluations++;
            return mockJava;
          },
        );

        // No factory has been invoked upon instantiation.
        expect(sdkEvaluations, 0);
        expect(studioEvaluations, 0);
        expect(gradleEvaluations, 0);
        expect(javaEvaluations, 0);

        // Accessing androidSdk multiple times evaluates factory exactly once.
        expect(context.androidSdk, same(mockSdk));
        expect(context.androidSdk, same(mockSdk));
        expect(sdkEvaluations, 1);
        expect(studioEvaluations, 0);
        expect(gradleEvaluations, 0);
        expect(javaEvaluations, 0);

        // Accessing androidStudio multiple times evaluates factory exactly once.
        expect(context.androidStudio, same(mockStudio));
        expect(context.androidStudio, same(mockStudio));
        expect(studioEvaluations, 1);
        expect(gradleEvaluations, 0);
        expect(javaEvaluations, 0);

        // Accessing gradleUtils multiple times evaluates factory exactly once.
        expect(context.gradleUtils, same(mockGradle));
        expect(context.gradleUtils, same(mockGradle));
        expect(gradleEvaluations, 1);
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
        gradleUtilsBuilder: FakeGradleUtils.new,
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
