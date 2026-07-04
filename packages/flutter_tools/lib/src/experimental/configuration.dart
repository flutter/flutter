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
         extensionManager: extensionManager,
         logger: logger ?? globals.logger,
         platform: platform ?? globals.platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

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
          core.ConfigurationService.serviceNamespace,
          core.ConfigurationService.getOptionsMethod,
          core.ConfigurationOption.listFromJson,
        );

    _cachedOptions = options;
    return options;
  }

  /// Request validation of an option value over extension protocol RPC.
  Future<core.OptionValidationResult> validate(String option, Object? value) async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return core.OptionValidationResult.failed('Extension protocol prototype feature disabled.');
    }

    for (final ToolExtension extension in await _discoveryHelper.getExtensionsSupporting(
      core.ConfigurationService.serviceNamespace,
    )) {
      try {
        final Object? result = await extension
            .callMethod(
              core.ConfigurationService.validateMethod,
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
