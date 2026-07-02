// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../flutter_tools_core/configuration.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../generic_extension_protocol/service.dart';
import '../globals.dart' as globals;

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
  }) : _extensionManager = extensionManager,
       _logger = logger ?? globals.logger,
       _platform = platform ?? globals.platform;

  final ToolExtensionManager _extensionManager;
  final Logger _logger;
  final Platform _platform;

  /// Environment variable key to enable GEP prototype features.
  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';
  static const String _serviceNamespace = 'config';
  static const String _getOptionsMethod = 'config.getOptions';
  static const String _validateMethod = 'config.validate';

  final Set<String> _registeredGepFlags = <String>{};

  /// The set of GEP flags successfully registered on the CLI.
  Set<String> get registeredGepFlags => _registeredGepFlags;

  /// Register a GEP flag name.
  void registerGepFlag(String flagName) {
    _registeredGepFlags.add(flagName);
  }

  List<core.ConfigurationOption>? _cachedOptions;

  /// Retrieve the cached options synchronously.
  List<core.ConfigurationOption> get cachedOptions =>
      _cachedOptions ?? const <core.ConfigurationOption>[];

  /// Retrieve configuration options by routing config.getOptions to active GEP extensions.
  Future<List<core.ConfigurationOption>> getOptions() async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return const <core.ConfigurationOption>[];
    }
    if (_cachedOptions != null) {
      return _cachedOptions!;
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        _logger.printError('Failed to spawn prototype extension: $e');
        return const <core.ConfigurationOption>[];
      }
    }

    final options = <core.ConfigurationOption>[];

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities().timeout(const Duration(seconds: 5));
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (!capabilities.services.contains(_serviceNamespace)) {
        continue;
      }

      try {
        final Object? result = await extension
            .callMethod(_getOptionsMethod)
            .timeout(const Duration(seconds: 5));
        if (result is List) {
          for (final Object? item in result) {
            if (item is Map) {
              final Map<String, Object?> resultMap = (item as Map<Object?, Object?>)
                  .cast<String, Object?>();
              options.add(ExtensionConfigurationOption.fromJson(resultMap));
            }
          }
        }
      } on Object catch (e) {
        _logger.printError('Failed to get GEP options from extension: $e');
      }
    }

    _cachedOptions = options;
    return options;
  }

  /// Validates a value for a configuration option by routing to extension isolates.
  Future<core.OptionValidationResult> validate(String option, Object? value) async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return core.OptionValidationResult.failed('GEP Prototype is not enabled.');
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        return core.OptionValidationResult.failed('Failed to spawn prototype extension: $e');
      }
    }

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities().timeout(const Duration(seconds: 5));
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (!capabilities.services.contains(_serviceNamespace)) {
        continue;
      }

      try {
        final Object? result = await extension
            .callMethod(
              _validateMethod,
              params: <String, Object?>{'option': option, 'value': value},
            )
            .timeout(const Duration(seconds: 5));
        if (result is Map) {
          final Map<String, Object?> resultMap = (result as Map<Object?, Object?>)
              .cast<String, Object?>();
          return core.OptionValidationResult.fromJson(resultMap);
        }
      } on Object catch (e) {
        return core.OptionValidationResult.failed('Validation GEP call failed: $e');
      }
    }

    return core.OptionValidationResult.failed(
      'No extension service registered configuration option: $option',
    );
  }
}

/// A concrete host-side representation of a GEP configuration option.
base class ExtensionConfigurationOption extends core.ConfigurationOption {
  /// Create a new instance of [ExtensionConfigurationOption].
  ExtensionConfigurationOption({required this.description, required this.name});

  /// Parse an option from a JSON GEP map representation.
  factory ExtensionConfigurationOption.fromJson(Map<String, Object?> json) {
    final Object? name = json['name'];
    final Object? description = json['description'];
    if (name is! String || description is! String) {
      throw FormatException('Invalid GEP configuration option format: $json');
    }
    return ExtensionConfigurationOption(name: name, description: description);
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
