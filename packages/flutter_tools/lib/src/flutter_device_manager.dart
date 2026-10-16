// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'android/android_device_discovery.dart';
import 'android/android_sdk.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'base/user_messages.dart';
import 'context/apple_context.dart';
import 'context/tool_context.dart';
import 'custom_devices/custom_device.dart';
import 'device.dart';
import 'experimental/extension_device_manager.dart';
import 'experimental/extension_manager.dart';
import 'features.dart';
import 'ios/devices.dart';
import 'ios/ios_workflow.dart';
import 'ios/simulators.dart';
import 'linux/linux_device.dart';
import 'macos/macos_device.dart';
import 'macos/macos_ipad_device.dart';
import 'macos/macos_workflow.dart';
import 'macos/xcdevice.dart';
import 'native_assets.dart';
import 'tester/flutter_tester.dart';
import 'version.dart';
import 'web/web_device.dart';
import 'windows/windows_device.dart';
import 'windows/windows_workflow.dart';

/// A provider for all of the device discovery instances.
class FlutterDeviceManager extends DeviceManager {
  FlutterDeviceManager({
    required Analytics analytics,
    required AndroidSdk? Function() androidSdkBuilder,
    required AndroidWorkflow androidWorkflow,
    required AppleContext appleContext,
    required FeatureFlags featureFlags,
    required IOSSimulatorUtils iosSimulatorUtils,
    required IOSWorkflow iosWorkflow,
    required MacOSWorkflow macOSWorkflow,
    required ToolContext toolContext,
    required WindowsWorkflow windowsWorkflow,
    required XCDevice xcDevice,
    ExtensionManager? extensionManager,
  }) : super(logger: toolContext.logger) {
    final ToolContext(
      :Artifacts artifacts,
      :FlutterVersion flutterVersion,
      fs: FileSystem fileSystem,
      :Logger logger,
      :TestCompilerNativeAssetsBuilder? nativeAssetsBuilder,
      :Platform platform,
      :ProcessManager processManager,
      :UserMessages userMessages,
    ) = toolContext;
    deviceDiscoverers = <DeviceDiscovery>[
      AndroidDevices(
        logger: logger,
        androidSdkBuilder: androidSdkBuilder,
        androidWorkflow: androidWorkflow,
        processManager: processManager,
        fileSystem: fileSystem,
        platform: platform,
        userMessages: userMessages,
      ),
      IOSDevices(platform: platform, xcdevice: xcDevice, iosWorkflow: iosWorkflow, logger: logger),
      IOSSimulators(iosSimulatorUtils: iosSimulatorUtils),
      FlutterTesterDevices(
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        processManager: processManager,
        logger: logger,
        artifacts: artifacts,
        platform: platform,
        nativeAssetsBuilder: nativeAssetsBuilder,
      ),
      MacOSDevices(
        analytics: analytics,
        appleContext: appleContext,
        featureFlags: featureFlags,
        macOSWorkflow: macOSWorkflow,
        toolContext: toolContext,
      ),
      MacOSDesignedForIPadDevices(iosWorkflow: iosWorkflow, toolContext: toolContext),
      LinuxDevices(analytics: analytics, featureFlags: featureFlags, toolContext: toolContext),
      WindowsDevices(
        analytics: analytics,
        toolContext: toolContext,
        windowsWorkflow: windowsWorkflow,
      ),
      WebDevices(
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
      ),
      CustomDevices(featureFlags: featureFlags, toolContext: toolContext),
      if (extensionManager != null)
        ExtensionDevices(extensionManager: extensionManager, logger: logger),
    ];
  }

  @override
  late final List<DeviceDiscovery> deviceDiscoverers;
}
