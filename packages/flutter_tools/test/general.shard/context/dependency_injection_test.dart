// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class FakeAndroidSdk extends Fake implements AndroidSdk {}

class FakeFile extends Fake implements File {
  @override
  String get path => '/dummy/path';
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  @override
  void chmod(FileSystemEntity entity, String mode) {}
}

class FakeArtifacts extends Fake implements Artifacts {
  @override
  FileSystemEntity getHostArtifact(HostArtifact artifact) {
    return FakeFile();
  }
}

class FakeAndroidWorkflow extends Fake implements AndroidWorkflow {}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {}

class FakeIOSSimulatorUtils extends Fake implements IOSSimulatorUtils {}

class FakeWindowsWorkflow extends Fake implements WindowsWorkflow {}

class FakeMacOSWorkflow extends Fake implements MacOSWorkflow {}

class FakeDeviceManager extends Fake implements DeviceManager {}

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
      expect(dependencies.toolContext.artifacts, isNotNull);
      expect(dependencies.toolContext.botDetector, isNotNull);
      expect(dependencies.buildSystem, isNotNull);
      expect(dependencies.buildTargets, isNotNull);
      expect(dependencies.crashReporter, isNotNull);
      expect(dependencies.deviceManager, isNotNull);
      expect(dependencies.macOSWorkflow, isNotNull);
      expect(dependencies.toolContext.os, isNotNull);
      expect(dependencies.windowsWorkflow, isNotNull);
      expect(dependencies.toolContext.cache, isNotNull);
      expect(dependencies.toolContext.config, isNotNull);
      expect(dependencies.doctor, isNotNull);
      expect(dependencies.toolContext.git, isNotNull);
      expect(dependencies.toolContext.processUtils, isNotNull);
      expect(dependencies.toolContext.projectFactory, isNotNull);
      expect(dependencies.toolContext.shutdownHooks, isNotNull);
      expect(dependencies.toolContext.stdio, isNotNull);
      expect(dependencies.toolContext.systemClock, isNotNull);
      expect(dependencies.toolContext.terminal, isNotNull);
      expect(dependencies.toolContext.userMessages, isNotNull);

      // Verify AppleContext (workflow fields only non-null on macOS)
      expect(dependencies.appleContext.cocoaPods, isNotNull);
      expect(dependencies.appleContext.cocoapodsValidator, isNotNull);
      expect(dependencies.appleContext.iosSimulatorUtils, platform.isMacOS ? isNotNull : isNull);
      expect(dependencies.appleContext.iosWorkflow, platform.isMacOS ? isNotNull : isNull);
      expect(dependencies.appleContext.plistParser, isNotNull);
      expect(dependencies.appleContext.xcdevice, isNotNull);
      expect(dependencies.appleContext.xcode, isNotNull);
      expect(dependencies.appleContext.xcodeProjectInterpreter, isNotNull);

      // Verify AndroidContext
      expect(dependencies.androidContext.androidWorkflow, isNotNull);
      expect(dependencies.androidContext.gradleUtils, isNotNull);
      // Verify that Android SDK was located using the overridden FS and platform
      expect(dependencies.androidContext.androidSdk, isNotNull);
      expect(dependencies.androidContext.androidSdk!.directory.path, '/home/user/Android/Sdk');
    });

    testUsingContext('successfully bootstraps Apple workflow fields on macOS', () async {
      final macOSPlatform = FakePlatform(
        operatingSystem: 'macos',
        environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home/user'},
      );

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        fs: fs,
        logger: logger,
        platform: macOSPlatform,
        processManager: processManager,
      );

      expect(dependencies.appleContext.iosSimulatorUtils, isNotNull);
      expect(dependencies.appleContext.iosWorkflow, isNotNull);
    });

    testUsingContext('respects explicit overrides for new fields', () async {
      final mockOS = FakeOperatingSystemUtils();
      final mockArtifacts = FakeArtifacts();
      final mockAndroidWorkflow = FakeAndroidWorkflow();
      final mockIOSWorkflow = FakeIOSWorkflow();
      final mockIOSSimulatorUtils = FakeIOSSimulatorUtils();
      final mockWindowsWorkflow = FakeWindowsWorkflow();
      final mockMacOSWorkflow = FakeMacOSWorkflow();
      final mockDeviceManager = FakeDeviceManager();

      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        os: mockOS,
        artifacts: mockArtifacts,
        androidWorkflow: mockAndroidWorkflow,
        iosWorkflow: mockIOSWorkflow,
        iosSimulatorUtils: mockIOSSimulatorUtils,
        windowsWorkflow: mockWindowsWorkflow,
        macOSWorkflow: mockMacOSWorkflow,
        deviceManager: mockDeviceManager,
        fs: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );

      expect(dependencies.toolContext.os, same(mockOS));
      expect(dependencies.toolContext.artifacts, same(mockArtifacts));
      expect(dependencies.androidContext.androidWorkflow, same(mockAndroidWorkflow));
      expect(dependencies.appleContext.iosWorkflow, same(mockIOSWorkflow));
      expect(dependencies.appleContext.iosSimulatorUtils, same(mockIOSSimulatorUtils));
      expect(dependencies.windowsWorkflow, same(mockWindowsWorkflow));
      expect(dependencies.macOSWorkflow, same(mockMacOSWorkflow));
      expect(dependencies.deviceManager, same(mockDeviceManager));
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
