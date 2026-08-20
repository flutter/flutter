// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'protocol_base/service.dart';

/// Extension service interface for retrieving and managing configuration flags and feature toggles.
abstract class ConfigurationExtension extends ToolExtensionService {
  /// Service namespace identifier for configuration services.
  static const String serviceNamespace = 'config';

  /// RPC method identifier to retrieve the extension title.
  static const String getTitleMethod = 'config.getTitle';

  /// RPC method identifier to query contributed feature flags.
  static const String getFeatureFlagsMethod = 'config.getFeatureFlags';

  /// RPC method identifier to query configuration options.
  static const String getConfigurationsMethod = 'config.getConfigurations';

  @override
  String get namespace => serviceNamespace;

  /// The human-readable title of the extension providing these configuration settings.
  String get title;

  /// Returns the feature flags contributed by this extension.
  Future<List<FeatureFlag>> getFeatureFlags() async => const <FeatureFlag>[];

  /// Returns the configuration options supported by this extension.
  Future<List<ConfigOption>> getConfigurations() async => const <ConfigOption>[];

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getTitle': _getTitleRpc,
      'getFeatureFlags': _getFeatureFlagsRpc,
      'getConfigurations': _getConfigurationsRpc,
    };
  }

  Future<String> _getTitleRpc(Map<String, Object?> params) async => title;

  Future<List<Map<String, Object?>>> _getFeatureFlagsRpc(Map<String, Object?> params) async {
    final List<FeatureFlag> flags = await getFeatureFlags();
    return flags.map((FeatureFlag flag) => flag.toMap()).toList();
  }

  Future<List<Map<String, Object?>>> _getConfigurationsRpc(Map<String, Object?> params) async {
    final List<ConfigOption> configs = await getConfigurations();
    return configs.map((ConfigOption config) => config.toMap()).toList();
  }
}
