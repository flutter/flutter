// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core configuration service and option definitions for tool extensions.
///
/// This library defines the interface for registering custom configuration
/// options and validating them from the host tool.
library flutter_tools_core.configuration;

import '../../generic_extension_protocol.dart';

/// The service responsible for managing custom configuration options for
/// an extension.
abstract base class ConfigurationService extends ToolExtensionService {
  static const String serviceNamespace = 'config';
  static const String getOptionsMethod = 'config.getOptions';
  static const String validateMethod = 'config.validate';

  @override
  String get namespace => serviceNamespace;

  /// The set of configuration options handled by this extension.
  List<ConfigurationOption> get options;

  /// Initializes the service by registering RPC methods with the extension provider.
  ///
  /// Registers `getOptions` to list options and `validate` to validate a value.
  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'getOptions': _getOptionsRpc, 'validate': _validateRpc};
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getOptionsRpc(Map<String, Object?> params) async {
    return options.map((ConfigurationOption o) => o.toMap()).toList();
  }

  Future<Map<String, Object?>> _validateRpc(Map<String, Object?> params) async {
    if (params case {'option': final String option}) {
      final Object? value = params['value'];
      for (final ConfigurationOption o in options) {
        if (o.name == option) {
          return o.validate(option, value).toMap();
        }
      }
      return OptionValidationResult.failed('Unknown configuration option: $option').toMap();
    }
    return OptionValidationResult.failed('Missing "option" parameter.').toMap();
  }
}

/// The definition of a single option provided by the [ConfigurationService].
///
/// Extensions implement this class to define custom configuration options
/// (e.g., enabling experimental features).
abstract base class ConfigurationOption {
  /// Create a new [ConfigurationOption].
  const ConfigurationOption();

  /// The name of the option.
  String get name;

  /// The description of the option.
  String get description;

  /// Checks if [value] is valid for [option].
  OptionValidationResult validate(String option, Object? value);

  Map<String, Object?> toMap() => <String, Object?>{'name': name, 'description': description};
}

/// Result type that indicates whether or not a value is valid for an option.
///
/// Used by [ConfigurationOption.validate] to report validation success or failure.
final class OptionValidationResult {
  /// Create a successful validation result.
  OptionValidationResult.success() : success = true, failureReason = null;

  /// Create a failed validation result with a reason.
  OptionValidationResult.failed(this.failureReason) : success = false;

  /// Creates an [OptionValidationResult] from a JSON map.
  factory OptionValidationResult.fromJson(Map<String, Object?> json) {
    final success = json['success']! as bool;
    if (success) {
      return OptionValidationResult.success();
    }
    return OptionValidationResult.failed(json['failureReason'] as String?);
  }

  /// Whether validation was successful.
  final bool success;

  /// The reason why validation failed, if applicable.
  final String? failureReason;

  Map<String, Object?> toMap() => <String, Object?>{
    'success': success,
    if (failureReason != null) 'failureReason': failureReason,
  };

  static List<OptionValidationResult> listFromJson(Object? rpcResult) => <OptionValidationResult>[
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<Object?, Object?> m)
          OptionValidationResult.fromJson(m.cast<String, Object?>()),
  ];
}

/// A concrete host-side representation of an extension configuration option.
///
/// This represents an option defined by an extension on the host side.
/// Its [validate] method throws an [UnimplementedError] because validation
/// must be delegated to the extension isolate via RPC.
final class ExtensionConfigurationOption extends ConfigurationOption {
  /// Create a new instance of [ExtensionConfigurationOption].
  ExtensionConfigurationOption({required this.description, required this.name});

  /// Parses an option from a JSON extension map representation.
  factory ExtensionConfigurationOption.fromJson(Map<String, Object?> json) {
    if (json case {'name': final String name, 'description': final String description}) {
      return ExtensionConfigurationOption(name: name, description: description);
    }
    throw FormatException('Invalid extension configuration option format: $json');
  }

  /// Parse a list of [ExtensionConfigurationOption] from an RPC response.
  static List<ExtensionConfigurationOption> listFromJson(Object? rpcResult) => [
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<Object?, Object?> m)
          ExtensionConfigurationOption.fromJson(m.cast<String, Object?>()),
  ];

  @override
  final String name;

  @override
  final String description;

  @override
  OptionValidationResult validate(String option, Object? value) {
    throw UnimplementedError(
      'Host-side validation should call ExtensionConfigurationManager.validate',
    );
  }
}
