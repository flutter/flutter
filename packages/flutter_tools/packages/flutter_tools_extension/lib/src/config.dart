// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving and managing configuration flags and feature toggles.
abstract base class ConfigurationExtension extends ToolExtensionService {
  /// Service namespace identifier for configuration services.
  static const String serviceNamespace = 'config';

  /// RPC method identifier to retrieve the extension title.
  static const String getTitleMethod = 'config.getTitle';

  /// RPC method identifier to query contributed feature flags.
  static const String getFeatureFlagsMethod = 'config.getFeatureFlags';

  /// RPC method identifier to query configuration options.
  static const String getConfigurationsMethod = 'config.getConfigurations';

  /// RPC method identifier to query interactive or custom configuration actions.
  static const String getConfigActionsMethod = 'config.getConfigActions';

  /// RPC method identifier to execute a configuration action.
  static const String runConfigActionMethod = 'config.runConfigAction';

  /// Parameter key for the configuration action name in [runConfigActionMethod].
  static const String actionNameParam = 'name';

  /// Parameter key for the current settings map in [runConfigActionMethod].
  static const String currentSettingsParam = 'currentSettings';

  @override
  String get namespace => serviceNamespace;

  /// The human-readable title of the extension providing these configuration settings.
  String get title;

  /// Fetches the extension title asynchronously.
  Future<String> fetchTitle() async => title;

  /// Returns the feature flags contributed by this extension.
  Future<List<FeatureFlag>> getFeatureFlags() async => const <FeatureFlag>[];

  /// Returns the configuration options supported by this extension.
  Future<List<ConfigOption>> getConfigurations() async => const <ConfigOption>[];

  /// Returns the interactive or custom configuration actions supported by this extension.
  Future<List<ConfigAction>> getConfigActions() async => const <ConfigAction>[];

  /// Executes the configuration action named [name] given the extension's
  /// [currentSettings] and returns a map of updated setting keys to their new
  /// values (or `null` to clear a setting).
  ///
  /// Every returned key must belong to this extension's declared [ConfigOption]
  /// names or the corresponding [ConfigAction.settingsKeys].
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    throw UnsupportedError('Unknown config action: $name');
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getTitle': _getTitleRpc,
      'getFeatureFlags': _getFeatureFlagsRpc,
      'getConfigurations': _getConfigurationsRpc,
      'getConfigActions': _getConfigActionsRpc,
      'runConfigAction': _runConfigActionRpc,
    };
  }

  Future<String> _getTitleRpc(Map<String, Object?> params) async => title;

  Future<List<Map<String, Object?>>> _getFeatureFlagsRpc(Map<String, Object?> params) async {
    final List<FeatureFlag> flags = await getFeatureFlags();
    return <Map<String, Object?>>[for (final FeatureFlag flag in flags) flag.toMap()];
  }

  Future<List<Map<String, Object?>>> _getConfigurationsRpc(Map<String, Object?> params) async {
    final List<ConfigOption> configs = await getConfigurations();
    return <Map<String, Object?>>[for (final ConfigOption config in configs) config.toMap()];
  }

  Future<List<Map<String, Object?>>> _getConfigActionsRpc(Map<String, Object?> params) async {
    final List<ConfigAction> actions = await getConfigActions();
    return <Map<String, Object?>>[for (final ConfigAction action in actions) action.toMap()];
  }

  Future<Map<String, String?>> _runConfigActionRpc(Map<String, Object?> params) {
    final String name;
    final Map<String, String?> currentSettings;
    try {
      name = params.requiredField<String>(actionNameParam);
      if (name.isEmpty) {
        throw const FormatException('Parameter "$actionNameParam" must not be empty.');
      }
      final Map<String, Object?>? rawSettings = params.nullableField<Map<String, Object?>>(
        currentSettingsParam,
      );
      currentSettings = <String, String?>{
        if (rawSettings != null)
          for (final MapEntry(:key, :value) in rawSettings.entries)
            key: switch (value) {
              final String? s => s,
              _ => throw FormatException(
                'Invalid "$currentSettingsParam" entry "$key": expected String?, got ${value.runtimeType}.',
              ),
            },
      };
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return runConfigAction(name, currentSettings: currentSettings);
  }
}
