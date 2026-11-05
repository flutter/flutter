// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'android/android_device_discovery.dart';
import 'android/android_sdk.dart';
import 'android/android_workflow.dart';
import 'artifacts.dart';
import 'base/config.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'base/template.dart';
import 'base/user_messages.dart';
import 'build_system/build_system.dart';
import 'build_system/build_targets.dart';
import 'cache.dart';
import 'context/apple_context.dart';
import 'context/tool_context.dart';
import 'custom_devices/custom_device.dart';
import 'device.dart';
import 'experimental/extension_build_manager.dart';
import 'experimental/extension_device_manager.dart';
import 'experimental/extension_manager.dart';
import 'features.dart';
import 'ios/devices.dart';
import 'ios/simulators.dart';
import 'linux/linux_device.dart';
import 'macos/macos_device.dart';
import 'macos/macos_ipad_device.dart';
import 'macos/macos_workflow.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/windows_device.dart';
import 'windows/windows_workflow.dart';

/// A provider for all of the device discovery instances.
class FlutterDeviceManager extends DeviceManager {
  FlutterDeviceManager({
    required this._analytics,
    required this._androidSdkBuilder,
    required this._androidWorkflow,
    required this._appleContext,
    required this._buildSystem,
    required this._buildTargets,
    required this._extensionBuildManager,
    required this._extensionManager,
    required this._featureFlags,
    required this._macOSWorkflow,
    required this._templateRenderer,
    required this._toolContext,
    required this._windowsWorkflow,
  }) : super(fileSystem: _toolContext.fs, logger: _toolContext.logger);

  final Analytics _analytics;
  final AndroidSdk? Function() _androidSdkBuilder;
  final AndroidWorkflow _androidWorkflow;
  final AppleContext _appleContext;
  final BuildSystem _buildSystem;
  final BuildTargets _buildTargets;
  final ExtensionBuildManager _extensionBuildManager;
  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final MacOSWorkflow _macOSWorkflow;
  final TemplateRenderer _templateRenderer;
  final ToolContext _toolContext;
  final WindowsWorkflow _windowsWorkflow;

  @override
  late final List<DeviceDiscovery> deviceDiscoverers = _createDeviceDiscoverers();

  List<DeviceDiscovery> _createDeviceDiscoverers() {
    final ToolContext(
      :Artifacts artifacts,
      :Cache cache,
      :Config config,
      :FileSystem fs,
      :Logger logger,
      :Platform platform,
      :ProcessManager processManager,
      :UserMessages userMessages,
    ) = _toolContext;
    return <DeviceDiscovery>[
      AndroidDevices(
        logger: logger,
        androidSdkBuilder: _androidSdkBuilder,
        androidWorkflow: _androidWorkflow,
        processManager: processManager,
        fileSystem: fs,
        platform: platform,
        userMessages: userMessages,
      ),
      IOSDevices(
        platform: platform,
        xcdevice: _appleContext.xcdevice,
        iosWorkflow: _appleContext.iosWorkflow,
        logger: logger,
      ),
      IOSSimulators(
        iosSimulatorUtils: _appleContext.iosSimulatorUtils,
        iosWorkflow: _appleContext.iosWorkflow,
        platform: platform,
      ),
      FlutterTesterDevices(
        analytics: _analytics,
        buildSystem: _buildSystem,
        buildTargets: _buildTargets,
        toolContext: _toolContext,
      ),
      MacOSDevices(
        analytics: _analytics,
        appleContext: _appleContext,
        featureFlags: _featureFlags,
        macOSWorkflow: _macOSWorkflow,
        templateRenderer: _templateRenderer,
        toolContext: _toolContext,
      ),
      MacOSDesignedForIPadDevices(
        iosWorkflow: _appleContext.iosWorkflow,
        toolContext: _toolContext,
      ),
      LinuxDevices(analytics: _analytics, featureFlags: _featureFlags, toolContext: _toolContext),
      WindowsDevices(
        analytics: _analytics,
        toolContext: _toolContext,
        windowsWorkflow: _windowsWorkflow,
      ),
      WebDevices(
        featureFlags: _featureFlags,
        fileSystem: fs,
        platform: platform,
        processManager: processManager,
        logger: logger,
      ),
      CustomDevices(
        featureFlags: _featureFlags,
        analytics: _analytics,
        buildSystem: _buildSystem,
        buildTargets: _buildTargets,
        toolContext: _toolContext,
      ),
      ExtensionDevices(
        extensionBuildManager: _extensionBuildManager,
        extensionManager: _extensionManager,
        fileSystem: fs,
        logger: logger,
        artifacts: artifacts,
        cache: cache,
        config: config,
      ),
    ];
  }
}
