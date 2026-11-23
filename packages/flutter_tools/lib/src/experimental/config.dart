// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/config.dart';
import '../base/logger.dart';
import 'extension_discovery.dart';

/// Represents a group of configuration settings provided by a specific extension.
class ExtensionSettingsGroup {
  const ExtensionSettingsGroup({
    required this.configOptions,
    required this.extension,
    required this.extensionName,
    required this.featureFlags,
    required this.title,
  });

  /// The configuration extension that owns these settings.
  final ConfigurationExtension extension;

  /// The human-readable title of the extension.
  final String title;

  /// Section header attributing this group to its declaring extension package.
  String get displayTitle =>
      extension is ConfigurationExtensionClient ? '$title (package:$extensionName)' : title;

  /// Identifier of the extension (package name when backed by an isolate
  /// connection, or extension title otherwise), used to namespace settings
  /// under `"extensions": { "<extensionName>": { ... } }` in `flutter_settings`.
  final String extensionName;

  /// Feature flags registered by the extension.
  final List<FeatureFlag> featureFlags;

  /// Config options registered by the extension.
  final List<ConfigOption> configOptions;

  /// Whether this group contains any settings that should be displayed in
  /// `flutter config --list`.
  bool get hasDisplayableSettings => featureFlags.isNotEmpty || configOptions.isNotEmpty;
}

/// A host-side configuration manager that delegates feature flag and option queries to extensions.
class ExtensionConfiguration {
  ExtensionConfiguration({required List<ConfigurationExtension> extensions, required this._logger})
    : extensions = _sortedExtensions(extensions);

  /// Top-level JSON map key in Flutter's global settings file storing nested
  /// per-extension configuration maps (`"extensions": { "<package_name>": { ... } }`).
  static const String extensionsSettingsKey = 'extensions';

  /// The active extension services executing configuration queries, sorted in
  /// lexicographical `<package_name>` order.
  final List<ConfigurationExtension> extensions;
  final Logger _logger;

  static List<ConfigurationExtension> _sortedExtensions(List<ConfigurationExtension> extensions) {
    return List<ConfigurationExtension>.unmodifiable(
      <ConfigurationExtension>[...extensions]..sort(
        (ConfigurationExtension a, ConfigurationExtension b) =>
            _extensionIdentifier(a).compareTo(_extensionIdentifier(b)),
      ),
    );
  }

  static String _extensionIdentifier(ConfigurationExtension ext) =>
      ext is ConfigurationExtensionClient ? ext.connection.extensionName : ext.title;

  /// Looks up a persisted setting [key] (and optional [aliases]) under
  /// `"extensions"[extensionName]` in [config], falling back to legacy
  /// top-level [aliases].
  @visibleForTesting
  static Object? lookupSettingValue(
    Config config,
    String key, {
    required String extensionName,
    List<String> aliases = const <String>[],
  }) {
    if (config.getValue(extensionsSettingsKey) case final Map<String, Object?> extensionsMap) {
      if (extensionsMap[extensionName] case final Map<String, Object?> pkgMap) {
        if (pkgMap[key] case final Object value) {
          return value;
        }
      }
    }
    for (final alias in aliases) {
      if (config.getValue(alias) case final Object aliasValue) {
        return aliasValue;
      }
    }
    return null;
  }

  /// Removes a setting [key] (and any legacy [aliases]) under [extensionName]
  /// from [config].
  static void removeSettingValue(
    Config config,
    String key, {
    required String extensionName,
    List<String> aliases = const <String>[],
  }) {
    for (final alias in aliases) {
      if (config.containsKey(alias)) {
        config.removeValue(alias);
      }
    }
    if (config.getValue(extensionsSettingsKey) case final Map<String, Object?> existing) {
      final extensionsMap = <String, Object?>{...existing};
      if (extensionsMap[extensionName] case final Map<String, Object?> existingPkg) {
        final pkgMap = <String, Object?>{...existingPkg}..remove(key);
        if (pkgMap.isEmpty) {
          extensionsMap.remove(extensionName);
        } else {
          extensionsMap[extensionName] = pkgMap;
        }
        if (extensionsMap.isEmpty) {
          config.removeValue(extensionsSettingsKey);
        } else {
          config.setValue(extensionsSettingsKey, extensionsMap);
        }
      }
    }
  }

  /// Persists [value] for [key] under `"extensions"[extensionName]` in [config]
  /// and removes any pre-existing legacy [aliases] keys.
  static void setSettingValue(
    Config config,
    String key,
    Object value, {
    required String extensionName,
    List<String> aliases = const <String>[],
  }) {
    for (final alias in aliases) {
      if (config.containsKey(alias)) {
        config.removeValue(alias);
      }
    }
    final extensionsMap = <String, Object?>{
      if (config.getValue(extensionsSettingsKey) case final Map<String, Object?> existing)
        ...existing,
    };
    final pkgMap = <String, Object?>{
      if (extensionsMap[extensionName] case final Map<String, Object?> existingPkg) ...existingPkg,
    };
    pkgMap[key] = value;
    extensionsMap[extensionName] = pkgMap;
    config.setValue(extensionsSettingsKey, extensionsMap);
  }

  /// Resolves the value of [flag] (`environmentOverride` > persisted
  /// `"extensions"` setting > [FeatureFlag.enabledByDefault]).
  static bool resolveFeatureFlagValue(
    Config config,
    FeatureFlag flag, {
    required Map<String, String> environment,
    required String extensionName,
  }) {
    if (flag.environmentOverride case final String envVar when envVar.isNotEmpty) {
      switch (environment[envVar]?.trim().toLowerCase()) {
        case 'true' || '1':
          return true;
        case 'false' || '0':
          return false;
      }
    }
    final Object? rawValue = lookupSettingValue(
      config,
      flag.settingName,
      extensionName: extensionName,
    );
    return switch (rawValue) {
      final bool b => b,
      'true' => true,
      'false' => false,
      _ => flag.enabledByDefault,
    };
  }

  /// Resolves the value of [option] (`environmentOverride` > persisted
  /// `"extensions"` setting / legacy [ConfigOption.aliases] >
  /// [ConfigOption.value]).
  static String? resolveConfigOptionValue(
    Config config,
    ConfigOption option, {
    required Map<String, String> environment,
    required String extensionName,
  }) {
    if (option.environmentOverride case final String envVar when envVar.isNotEmpty) {
      final String? envValue = environment[envVar];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    }
    final Object? rawValue = lookupSettingValue(
      config,
      option.name,
      extensionName: extensionName,
      aliases: option.aliases,
    );
    if (rawValue != null) {
      return rawValue.toString();
    }
    return option.value;
  }

  /// Returns persisted settings under `"extensions"` in [config] for packages
  /// not in [activeExtensionNames], sorted lexicographically by package name
  /// and setting key.
  static Map<String, Map<String, Object?>> inactiveSavedExtensionSettings(
    Config config, {
    required Set<String> activeExtensionNames,
  }) {
    if (config.getValue(extensionsSettingsKey) case final Map<String, Object?> rawExtensions) {
      final packageNames = <String>[
        for (final String pkg in rawExtensions.keys)
          if (!activeExtensionNames.contains(pkg)) pkg,
      ]..sort();
      final result = <String, Map<String, Object?>>{};
      for (final pkg in packageNames) {
        if (rawExtensions[pkg] case final Map<String, Object?> pkgMap) {
          final List<String> sortedKeys = pkgMap.keys.toList()..sort();
          final entries = <String, Object?>{
            for (final String key in sortedKeys)
              if (pkgMap[key] != null) key: pkgMap[key],
          };
          if (entries.isNotEmpty) {
            result[pkg] = entries;
          }
        }
      }
      return result;
    }
    return const <String, Map<String, Object?>>{};
  }

  /// Queries [extension] for its declared feature flags and configuration
  /// options, and returns a map of its owned keys to their resolved values
  /// (`environmentOverride` > `"extensions"` settings > default value; `bool`
  /// for feature flags, `String` for options, omitting unset keys).
  static Future<Map<String, Object?>> resolveConfigurationValues({
    required Config config,
    required Map<String, String> environment,
    required ConfigurationExtension extension,
    required String extensionName,
  }) async {
    final List<FeatureFlag> flags = await extension.getFeatureFlags();
    final List<ConfigOption> options = await extension.getConfigurations();
    final values = <String, Object?>{};
    for (final flag in flags) {
      values[flag.settingName] = resolveFeatureFlagValue(
        config,
        flag,
        environment: environment,
        extensionName: extensionName,
      );
    }
    for (final option in options) {
      final String? resolved = resolveConfigOptionValue(
        config,
        option,
        environment: environment,
        extensionName: extensionName,
      );
      if (resolved != null) {
        values[option.name] = resolved;
      }
    }
    return values;
  }

  /// Retrieves configuration settings grouped by extension name.
  Future<List<ExtensionSettingsGroup>> fetchExtensionSettings() async {
    _logger.printTrace(
      'ExtensionConfiguration fetching settings groups across ${extensions.length} extension(s)...',
    );
    final List<ExtensionSettingsGroup> groups = (await Future.wait(
      extensions.map((ConfigurationExtension ext) async {
        try {
          final String title = await ext.fetchTitle();
          final String extensionName = _extensionIdentifier(ext);
          final List<FeatureFlag> flags = await ext.getFeatureFlags();
          final List<ConfigOption> options = await ext.getConfigurations();
          return ExtensionSettingsGroup(
            configOptions: options,
            extension: ext,
            extensionName: extensionName,
            featureFlags: flags,
            title: title,
          );
        } on ToolExtensionException catch (err) {
          _logger.printWarning('Extension "${_extensionIdentifier(ext)}": ${err.message}');
          return null;
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
final class ConfigurationExtensionClient extends ConfigurationExtension {
  ConfigurationExtensionClient(
    this.connection, {
    required this._logger,
    this._defaultTitle = 'Tool Extension Configuration',
  });

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
    } on ToolExtensionException catch (err) {
      _logger.printWarning('Extension "${connection.extensionName}": ${err.message}');
    } on Object catch (err, stack) {
      _logger.printTrace('ConfigurationExtensionClient failed to fetch title: $err\n$stack');
    }
    return _titleCache ?? _defaultTitle;
  }

  Future<List<T>> _fetchList<T>(
    String method,
    String entityName,
    List<T> Function(List<Object?>) listFromJson,
  ) async {
    _logger.printTrace('ConfigurationExtensionClient fetching $entityName via RPC ("$method")...');
    try {
      final Object? rawResult = await connection.sendRequest(method);
      if (rawResult case final List<Object?> list) {
        final results = List<T>.unmodifiable(listFromJson(list));
        _logger.printTrace(
          'ConfigurationExtensionClient received ${results.length} $entityName via RPC.',
        );
        return results;
      }
      _logger.printWarning(
        'Extension "${connection.extensionName}" returned an invalid $entityName response for "$method": '
        'expected List, got ${rawResult.runtimeType}.',
      );
    } on ToolExtensionException {
      rethrow;
    } on FormatException catch (err) {
      _logger.printWarning(
        'Extension "${connection.extensionName}" returned malformed $entityName for "$method": ${err.message}',
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
    FeatureFlag.listFromJson,
  );

  @override
  Future<List<ConfigOption>> getConfigurations() => _fetchList(
    ConfigurationExtension.getConfigurationsMethod,
    'config option(s)',
    ConfigOption.listFromJson,
  );
}
