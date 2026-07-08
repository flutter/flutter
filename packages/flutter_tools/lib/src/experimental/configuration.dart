// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Configuration manager for tool extensions.
///
/// This library manages discovery of custom configuration options from active
/// tool extensions and handles routing validation requests to them.
library experimental.configuration;

import 'dart:async';

import '../../flutter_tools_core.dart' as core;
import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../generic_extension_protocol/manager.dart';
import 'extension_discovery.dart';

/// Retrieve the [ExtensionConfigurationManager] from the context.
ExtensionConfigurationManager? get extensionConfigurationManager =>
    context.get<ExtensionConfigurationManager>();

/// Manages querying configuration options and validation from extension isolates.
///
/// This manager interacts with active [ToolExtension]s to discover custom
/// configuration options and validate their values over the extension protocol RPC.
base class ExtensionConfigurationManager extends core.ConfigurationService {
  ExtensionConfigurationManager({
    required ToolExtensionManager extensionManager,
    required Logger logger,
    required Platform platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager,
         platform: platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  static const String _serviceNamespace = core.ConfigurationService.serviceNamespace;
  static const String _getOptionsMethod = core.ConfigurationService.getOptionsMethod;
  static const String _validateMethod = core.ConfigurationService.validateMethod;

  final Set<String> _registeredExtensionFlags = <String>{};

  /// The set of extension flags successfully registered on the CLI.
  ///
  /// These flags are used to identify which configuration settings are managed
  /// by tool extensions and need to be cleared or validated specially.
  Set<String> get registeredExtensionFlags => _registeredExtensionFlags;

  /// Register an extension flag name.
  ///
  /// This tracks which configuration flags are owned by extensions.
  void registerExtensionFlag(String flagName) {
    _registeredExtensionFlags.add(flagName);
  }

  List<core.ConfigurationOption>? _cachedOptions;

  /// Retrieve the cached options synchronously.
  ///
  /// Returns the list of configuration options cached from the last [getOptions] call.
  List<core.ConfigurationOption> get cachedOptions =>
      _cachedOptions ?? const <core.ConfigurationOption>[];

  /// Retrieve configuration options by routing `config.getOptions` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
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
          core.ExtensionConfigurationOption.listFromJson,
        );

    _cachedOptions = options;
    return options;
  }

  /// Validates a value for a configuration option by routing to extension isolates.
  ///
  /// Sends a validation request to the active tool extension that supports the
  /// configuration service namespace, passing the [option] name and [value] to validate.
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
        if (result case final Map<dynamic, dynamic> resultMap) {
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

  @override
  List<core.ConfigurationOption> get options => cachedOptions;
}
