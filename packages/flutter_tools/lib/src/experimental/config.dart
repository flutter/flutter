// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import 'extension_discovery.dart';

/// Represents a group of configuration settings provided by a specific extension.
class ExtensionSettingsGroup {
  /// Creates an [ExtensionSettingsGroup] with the given [title], [featureFlags], and [configOptions].
  const ExtensionSettingsGroup({
    required this.title,
    required this.featureFlags,
    required this.configOptions,
  });

  /// The human-readable title of the extension.
  final String title;

  /// Feature flags registered by the extension.
  final List<FeatureFlag> featureFlags;

  /// Config options registered by the extension.
  final List<ConfigOption> configOptions;
}

/// A host-side configuration manager that delegates feature flag and option queries to extensions.
class ExtensionConfiguration {
  /// Creates an [ExtensionConfiguration] for the provided [extensions].
  ExtensionConfiguration({required List<ConfigurationExtension> extensions, required Logger logger})
    : extensions = List<ConfigurationExtension>.unmodifiable(extensions),
      _logger = logger;

  /// The active extension services executing configuration queries.
  final List<ConfigurationExtension> extensions;
  final Logger _logger;

  /// Retrieves feature flags provided by all registered extensions.
  Future<List<FeatureFlag>> fetchFeatureFlags() async {
    _logger.printTrace(
      'ExtensionConfiguration fetching feature flags across ${extensions.length} extension(s)...',
    );
    final List<List<FeatureFlag>> results = await Future.wait(
      extensions.map((ConfigurationExtension ext) async {
        try {
          return await ext.getFeatureFlags();
        } on Object catch (err, stack) {
          _logger.printTrace(
            'Failed to fetch feature flags from extension "${ext.title}": $err\n$stack',
          );
          return const <FeatureFlag>[];
        }
      }),
    );
    final List<FeatureFlag> flags = results.expand((List<FeatureFlag> flags) => flags).toList();
    _logger.printTrace('ExtensionConfiguration retrieved ${flags.length} total feature flag(s).');
    return flags;
  }

  /// Retrieves configuration options provided by all registered extensions.
  Future<List<ConfigOption>> fetchConfigurations() async {
    _logger.printTrace(
      'ExtensionConfiguration fetching config options across ${extensions.length} extension(s)...',
    );
    final List<List<ConfigOption>> results = await Future.wait(
      extensions.map((ConfigurationExtension ext) async {
        try {
          return await ext.getConfigurations();
        } on Object catch (err, stack) {
          _logger.printTrace(
            'Failed to fetch config options from extension "${ext.title}": $err\n$stack',
          );
          return const <ConfigOption>[];
        }
      }),
    );
    final List<ConfigOption> options = results
        .expand((List<ConfigOption> options) => options)
        .toList();
    _logger.printTrace(
      'ExtensionConfiguration retrieved ${options.length} total config option(s).',
    );
    return options;
  }

  /// Retrieves configuration settings grouped by extension name.
  Future<List<ExtensionSettingsGroup>> fetchExtensionSettings() async {
    _logger.printTrace(
      'ExtensionConfiguration fetching settings groups across ${extensions.length} extension(s)...',
    );
    final List<ExtensionSettingsGroup> groups = (await Future.wait(
      extensions.map((ConfigurationExtension ext) async {
        try {
          String title;
          if (ext is ConfigurationExtensionClient) {
            title = await ext.fetchTitle();
          } else {
            title = ext.title;
          }
          final List<FeatureFlag> flags = await ext.getFeatureFlags();
          final List<ConfigOption> options = await ext.getConfigurations();
          return ExtensionSettingsGroup(title: title, featureFlags: flags, configOptions: options);
        } on Object catch (err, stack) {
          _logger.printTrace(
            'Failed to fetch settings from extension "${ext.title}": $err\n$stack',
          );
          return null;
        }
      }),
    )).whereType<ExtensionSettingsGroup>().toList();
    _logger.printTrace('ExtensionConfiguration retrieved ${groups.length} settings group(s).');
    return groups;
  }
}

/// A host-side [ConfigurationExtension] client adapter that delegates RPC queries to an [ExtensionConnection].
class ConfigurationExtensionClient extends ConfigurationExtension {
  /// Creates a [ConfigurationExtensionClient] wrapping the host [connection].
  ConfigurationExtensionClient(
    this.connection, {
    required Logger logger,
    String defaultTitle = 'Tool Extension Configuration',
  }) : _defaultTitle = defaultTitle,
       _logger = logger;

  /// The active extension isolate connection.
  final ExtensionConnection connection;
  final String _defaultTitle;
  final Logger _logger;
  String? _titleCache;

  @override
  String get title => _titleCache ?? _defaultTitle;

  /// Fetches the extension title from the remote extension isolate.
  Future<String> fetchTitle() async {
    final Object? response = await connection.sendRequest(ConfigurationExtension.getTitleMethod);
    _titleCache = response is String ? response : _defaultTitle;
    _logger.printTrace('ConfigurationExtensionClient received title: "$_titleCache".');
    return _titleCache!;
  }

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    _logger.printTrace(
      'ConfigurationExtensionClient fetching feature flags via RPC ("${ConfigurationExtension.getFeatureFlagsMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      ConfigurationExtension.getFeatureFlagsMethod,
    );
    if (rawResult is! List<Object?>) {
      _logger.printTrace(
        'ConfigurationExtensionClient received invalid or null feature flags response.',
      );
      return const <FeatureFlag>[];
    }
    final List<FeatureFlag> flags = rawResult
        .cast<Map<String, Object?>>()
        .map(FeatureFlag.fromJson)
        .toList();
    _logger.printTrace(
      'ConfigurationExtensionClient received ${flags.length} feature flag(s) via RPC.',
    );
    return flags;
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    _logger.printTrace(
      'ConfigurationExtensionClient fetching config options via RPC ("${ConfigurationExtension.getConfigurationsMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      ConfigurationExtension.getConfigurationsMethod,
    );
    if (rawResult is! List<Object?>) {
      _logger.printTrace(
        'ConfigurationExtensionClient received invalid or null configurations response.',
      );
      return const <ConfigOption>[];
    }
    final List<ConfigOption> options = rawResult
        .cast<Map<String, Object?>>()
        .map(ConfigOption.fromJson)
        .toList();
    _logger.printTrace(
      'ConfigurationExtensionClient received ${options.length} config option(s) via RPC.',
    );
    return options;
  }
}
