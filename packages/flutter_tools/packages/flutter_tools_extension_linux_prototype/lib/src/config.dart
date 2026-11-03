// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux platform extension configuration and feature flag provider.
class LinuxConfigurationExtension extends ConfigurationExtension {
  static const String kEnableLinuxCustomPrototype = 'enable-linux-custom-prototype';
  static const String kLinuxGtkVersion = 'linux-gtk-version';
  static const String kClearLinuxCustomSettings = 'clear-linux-custom-settings';

  @override
  String get title => 'Linux Custom Extension Prototype';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    // TODO(bkonyi): return prototype feature flags for Linux target platform.
    return const <FeatureFlag>[
      FeatureFlag(
        name: kEnableLinuxCustomPrototype,
        help: 'Enable custom platform extension prototype workflows for Linux.',
        enabledByDefault: true,
      ),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    // TODO(bkonyi): return configuration settings for Linux target platform.
    return const <ConfigOption>[
      ConfigOption(
        name: kLinuxGtkVersion,
        help: 'Target GTK version for custom Linux desktop application builds.',
        value: '3',
      ),
    ];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    return const <ConfigAction>[
      ConfigAction(
        name: kClearLinuxCustomSettings,
        help: 'Clear saved custom Linux extension configuration settings.',
        settingsKeys: <String>[kLinuxGtkVersion],
      ),
    ];
  }

  @override
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    if (name == kClearLinuxCustomSettings) {
      return const <String, String?>{kLinuxGtkVersion: null};
    }
    throw ToolExtensionException('Unsupported Linux config action: $name');
  }
}
