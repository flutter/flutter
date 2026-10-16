// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'android/android_device_discovery.dart';
import 'android/android_sdk.dart';
import 'android/android_workflow.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/user_messages.dart';
import 'context/tool_context.dart';
import 'custom_devices/custom_device.dart';
import 'custom_devices/custom_devices_config.dart';
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
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/windows_device.dart';
import 'windows/windows_workflow.dart';

/// A provider for all of the device discovery instances.
class FlutterDeviceManager extends DeviceManager {
  FlutterDeviceManager({
    required AndroidSdk? Function() androidSdkBuilder,
    required FeatureFlags featureFlags,
    required IOSSimulatorUtils iosSimulatorUtils,
    required XCDevice xcDevice,
    required AndroidWorkflow androidWorkflow,
    required IOSWorkflow iosWorkflow,
    required MacOSWorkflow macOSWorkflow,
    required WindowsWorkflow windowsWorkflow,
    required ToolContext toolContext,
    ExtensionManager? extensionManager,
  }) : super(logger: toolContext.logger) {
    final ToolContext(
      :CustomDevicesConfig customDevicesConfig,
      fs: FileSystem fileSystem,
      :Logger logger,
      os: OperatingSystemUtils operatingSystemUtils,
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
      FlutterTesterDevices(toolContext: toolContext),
      MacOSDevices(macOSWorkflow: macOSWorkflow, toolContext: toolContext),
      MacOSDesignedForIPadDevices(
        processManager: processManager,
        iosWorkflow: iosWorkflow,
        logger: logger,
        platform: platform,
        fileSystem: fileSystem,
        operatingSystemUtils: operatingSystemUtils,
      ),
      LinuxDevices(
        platform: platform,
        featureFlags: featureFlags,
        processManager: processManager,
        logger: logger,
        fileSystem: fileSystem,
        operatingSystemUtils: operatingSystemUtils,
      ),
      WindowsDevices(
        processManager: processManager,
        operatingSystemUtils: operatingSystemUtils,
        logger: logger,
        fileSystem: fileSystem,
        windowsWorkflow: windowsWorkflow,
      ),
      WebDevices(
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
        logger: logger,
      ),
      CustomDevices(
        featureFlags: featureFlags,
        processManager: processManager,
        logger: logger,
        config: customDevicesConfig,
      ),
      if (extensionManager != null)
        ExtensionDevices(extensionManager: extensionManager, logger: logger),
    ];
  }

  @override
  late final List<DeviceDiscovery> deviceDiscoverers;
}
