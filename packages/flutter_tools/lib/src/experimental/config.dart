// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import 'extension_discovery.dart';

/// Represents a group of configuration settings provided by a specific extension.
class ExtensionSettingsGroup {
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

  /// Whether this group contains any feature flags or configuration options.
  bool get isNotEmpty => featureFlags.isNotEmpty || configOptions.isNotEmpty;

  /// Whether this group is empty.
  bool get isEmpty => !isNotEmpty;
}

/// A host-side configuration manager that delegates feature flag and option queries to extensions.
class ExtensionConfiguration {
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
    final flags = <FeatureFlag>[for (final list in results) ...list];
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
    final options = <ConfigOption>[for (final list in results) ...list];
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
          final String title = ext is ConfigurationExtensionClient
              ? await ext.fetchTitle()
              : ext.title;
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

  @override
  Future<String> fetchTitle() async {
    if (_titleCache != null) {
      return _titleCache!;
    }
    _logger.printTrace(
      'ConfigurationExtensionClient fetching title via RPC ("${ConfigurationExtension.getTitleMethod}")...',
    );
    try {
      final Object? response = await connection.sendRequest(ConfigurationExtension.getTitleMethod);
      if (response case final String title) {
        _titleCache = title;
      } else {
        _logger.printTrace(
          'ConfigurationExtensionClient received invalid title response: $response',
        );
      }
    } on Object catch (err, stack) {
      _logger.printTrace('ConfigurationExtensionClient failed to fetch title: $err\n$stack');
    }
    return _titleCache ?? _defaultTitle;
  }

  Future<List<T>> _fetchList<T>(
    String method,
    String entityName,
    T Function(Map<String, Object?>) fromJson,
  ) async {
    _logger.printTrace('ConfigurationExtensionClient fetching $entityName via RPC ("$method")...');
    try {
      final Object? rawResult = await connection.sendRequest(method);
      if (rawResult case final List<Object?> list) {
        final results = <T>[
          for (final Object? element in list)
            if (element case final Map<Object?, Object?> map) fromJson(map.cast<String, Object?>()),
        ];
        _logger.printTrace(
          'ConfigurationExtensionClient received ${results.length} $entityName via RPC.',
        );
        return results;
      }
      _logger.printTrace(
        'ConfigurationExtensionClient received invalid or null $entityName response: $rawResult',
      );
    } on Object catch (err, stack) {
      _logger.printTrace('ConfigurationExtensionClient failed to get $entityName: $err\n$stack');
    }
    return <T>[];
  }

  @override
  Future<List<FeatureFlag>> getFeatureFlags() => _fetchList(
    ConfigurationExtension.getFeatureFlagsMethod,
    'feature flag(s)',
    FeatureFlag.fromJson,
  );

  @override
  Future<List<ConfigOption>> getConfigurations() => _fetchList(
    ConfigurationExtension.getConfigurationsMethod,
    'config option(s)',
    ConfigOption.fromJson,
  );
}
