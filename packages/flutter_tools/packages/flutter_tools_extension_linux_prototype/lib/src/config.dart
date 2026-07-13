// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux platform extension configuration and feature flag provider.
class LinuxConfigurationExtension extends ConfigurationExtension {
  @override
  String get title => 'Linux Custom Extension Prototype';
  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    // TODO(bkonyi): return prototype feature flags for Linux target platform.
    return const <FeatureFlag>[
      FeatureFlag(
        name: 'enable-linux-custom-prototype',
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
        name: 'linux-gtk-version',
        help: 'Target GTK version for custom Linux desktop application builds.',
        value: '3',
      ),
    ];
  }
}
