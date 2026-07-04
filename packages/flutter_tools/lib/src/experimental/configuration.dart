// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../flutter_tools_core/configuration.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../globals.dart' as globals;
import 'extension_discovery.dart';

/// Retrieve the [ExtensionConfigurationManager] from the context.
ExtensionConfigurationManager? get extensionConfigurationManager =>
    context.get<ExtensionConfigurationManager>();

/// Manages querying configuration options and validation from extension isolates.
class ExtensionConfigurationManager {
  /// Create a new instance of [ExtensionConfigurationManager].
  ExtensionConfigurationManager({
    required ToolExtensionManager extensionManager,
    Logger? logger,
    Platform? platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger ?? globals.logger,
         extensionManager: extensionManager,
         platform: platform ?? globals.platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  static const String _serviceNamespace = 'config';
  static const String _getOptionsMethod = 'config.getOptions';
  static const String _validateMethod = 'config.validate';

  final Set<String> _registeredExtensionFlags = <String>{};

  /// The set of extension flags successfully registered on the CLI.
  Set<String> get registeredExtensionFlags => _registeredExtensionFlags;

  /// Register an extension flag name.
  void registerExtensionFlag(String flagName) {
    _registeredExtensionFlags.add(flagName);
  }

  List<core.ConfigurationOption>? _cachedOptions;

  /// Retrieve the cached options synchronously.
  List<core.ConfigurationOption> get cachedOptions =>
      _cachedOptions ?? const <core.ConfigurationOption>[];

  static List<core.ConfigurationOption> _decodeOptions(Object? rpcResult) {
    final options = <core.ConfigurationOption>[];
    if (rpcResult case final List<Object?> resultList) {
      for (final item in resultList) {
        if (item case final Map<Object?, Object?> itemMap) {
          options.add(ExtensionConfigurationOption.fromJson(itemMap.cast<String, Object?>()));
        }
      }
    }
    return options;
  }

  /// Retrieve configuration options by routing config.getOptions to active tool extensions.
  Future<List<core.ConfigurationOption>> getOptions() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return const <core.ConfigurationOption>[];
    }
    if (_cachedOptions != null) {
      return _cachedOptions!;
    }

    final List<core.ConfigurationOption> options = await _discoveryHelper
        .getListFromExtensions<core.ConfigurationOption>(
          _serviceNamespace,
          _getOptionsMethod,
          _decodeOptions,
        );

    _cachedOptions = options;
    return options;
  }

  /// Validates a value for a configuration option by routing to extension isolates.
  Future<core.OptionValidationResult> validate(String option, Object? value) async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return core.OptionValidationResult.failed('Tool extension prototype is not enabled.');
    }

    for (final ToolExtension extension in await _discoveryHelper.getExtensionsSupporting(
      _serviceNamespace,
    )) {
      try {
        final Object? result = await extension
            .callMethod(
              _validateMethod,
              params: <String, Object?>{'option': option, 'value': value},
            )
            .timeout(const Duration(seconds: 5));
        if (result case final Map<Object?, Object?> resultMap) {
          return core.OptionValidationResult.fromJson(resultMap.cast<String, Object?>());
        }
      } on Object catch (e) {
        return core.OptionValidationResult.failed('Validation extension call failed: $e');
      }
    }

    return core.OptionValidationResult.failed(
      'No extension service registered configuration option: $option',
    );
  }
}

/// A concrete host-side representation of an extension configuration option.
base class ExtensionConfigurationOption extends core.ConfigurationOption {
  /// Create a new instance of [ExtensionConfigurationOption].
  ExtensionConfigurationOption({required this.description, required this.name});

  /// Parse an option from a JSON extension map representation.
  factory ExtensionConfigurationOption.fromJson(Map<String, Object?> json) {
    if (json case {'name': final String name, 'description': final String description}) {
      return ExtensionConfigurationOption(name: name, description: description);
    }
    throw FormatException('Invalid extension configuration option format: $json');
  }

  @override
  final String name;

  @override
  final String description;

  @override
  core.OptionValidationResult validate(String option, Object? value) {
    throw UnimplementedError(
      'Host-side validation should call ExtensionConfigurationManager.validate',
    );
  }
}
