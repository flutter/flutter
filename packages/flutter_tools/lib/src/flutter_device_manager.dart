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
  factory FlutterDeviceManager({
    required AndroidSdk? Function() androidSdkBuilder,
    required AndroidWorkflow androidWorkflow,
    required FeatureFlags featureFlags,
    required IOSSimulatorUtils iosSimulatorUtils,
    required IOSWorkflow iosWorkflow,
    required MacOSWorkflow macOSWorkflow,
    required ToolContext toolContext,
    required WindowsWorkflow windowsWorkflow,
    required XCDevice xcDevice,
    ExtensionManager? extensionManager,
  }) {
    final ToolContext(
      :CustomDevicesConfig customDevicesConfig,
      :FileSystem fs,
      :Logger logger,
      :OperatingSystemUtils os,
      :Platform platform,
      :ProcessManager processManager,
      :UserMessages userMessages,
    ) = toolContext;
    return FlutterDeviceManager._(
      deviceDiscoverers: <DeviceDiscovery>[
        AndroidDevices(
          logger: logger,
          androidSdkBuilder: androidSdkBuilder,
          androidWorkflow: androidWorkflow,
          processManager: processManager,
          fileSystem: fs,
          platform: platform,
          userMessages: userMessages,
        ),
        IOSDevices(
          platform: platform,
          xcdevice: xcDevice,
          iosWorkflow: iosWorkflow,
          logger: logger,
        ),
        IOSSimulators(iosSimulatorUtils: iosSimulatorUtils),
        FlutterTesterDevices(toolContext: toolContext),
        MacOSDevices(macOSWorkflow: macOSWorkflow, toolContext: toolContext),
        MacOSDesignedForIPadDevices(
          processManager: processManager,
          iosWorkflow: iosWorkflow,
          logger: logger,
          platform: platform,
          fileSystem: fs,
          operatingSystemUtils: os,
        ),
        LinuxDevices(featureFlags: featureFlags, toolContext: toolContext),
        WindowsDevices(toolContext: toolContext, windowsWorkflow: windowsWorkflow),
        WebDevices(
          featureFlags: featureFlags,
          fileSystem: fs,
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
      ],
      logger: logger,
    );
  }

  FlutterDeviceManager._({required this.deviceDiscoverers, required super.logger});

  @override
  final List<DeviceDiscovery> deviceDiscoverers;
}
