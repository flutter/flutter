// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../base/config.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../context/tool_context.dart';
import 'extension_discovery.dart';

/// Represents a group of configuration settings provided by a specific extension.
class ExtensionSettingsGroup {
  ExtensionSettingsGroup({
    required this.configOptions,
    required this.extension,
    required this.extensionName,
    required this.featureFlags,
    required this.title,
    this.configActions = const <ConfigAction>[],
  });

  /// The human-readable title of the extension.
  final String title;

  /// Identifier of the extension (package name when backed by an isolate
  /// connection, or extension title otherwise), used to namespace settings
  /// under `"extensions": { "<extensionName>": { ... } }` in `flutter_settings`.
  final String extensionName;

  /// The [ConfigurationExtension] that produced this group.
  final ConfigurationExtension extension;

  /// Feature flags registered by the extension.
  final List<FeatureFlag> featureFlags;

  /// Config options registered by the extension.
  final List<ConfigOption> configOptions;

  /// Interactive or custom configuration actions registered by the extension.
  final List<ConfigAction> configActions;

  /// Section header attributing this group to its declaring extension package.
  String get displayTitle =>
      extension is ConfigurationExtensionClient ? '$title (package:$extensionName)' : title;

  /// Settings keys declared by [configActions] that do not already correspond to
  /// a [FeatureFlag] or [ConfigOption] in this group.
  late final List<String> actionOnlySettingsKeys = () {
    final seen = <String>{
      for (final FeatureFlag(:settingName) in featureFlags) settingName,
      for (final ConfigOption(:name) in configOptions) name,
    };
    return List<String>.unmodifiable(<String>[
      for (final ConfigAction(:settingsKeys) in configActions)
        for (final String key in settingsKeys)
          if (seen.add(key)) key,
    ]);
  }();

  /// Whether this group contains any settings that should be displayed in
  /// `flutter config --list` ([featureFlags], [configOptions], or
  /// [ConfigAction.settingsKeys]).
  bool get hasDisplayableSettings =>
      featureFlags.isNotEmpty || configOptions.isNotEmpty || actionOnlySettingsKeys.isNotEmpty;
}

/// A host-side configuration manager that delegates feature flag, option, and action queries to extensions.
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

  /// Collects the persisted setting values scoped to [configOptions] and
  /// [configActions]'s [ConfigAction.settingsKeys] (excluding feature flags
  /// unless explicitly listed in [ConfigAction.settingsKeys]), normalized to
  /// `String?` for passing to [ConfigurationExtension.runConfigAction].
  static Map<String, String?> collectActionSettings(
    Config config, {
    required List<ConfigAction> configActions,
    required List<ConfigOption> configOptions,
    required String extensionName,
  }) {
    final values = <String, String?>{};
    final aliasesByOptionName = <String, List<String>>{};
    for (final ConfigOption(:name, :aliases) in configOptions) {
      aliasesByOptionName[name] = aliases;
      final Object? rawValue = lookupSettingValue(
        config,
        name,
        extensionName: extensionName,
        aliases: aliases,
      );
      if (rawValue != null) {
        values[name] = rawValue.toString();
      }
    }
    for (final ConfigAction(:settingsKeys) in configActions) {
      for (final key in settingsKeys) {
        if (values.containsKey(key)) {
          continue;
        }
        final Object? rawValue = lookupSettingValue(
          config,
          key,
          extensionName: extensionName,
          aliases: aliasesByOptionName[key] ?? const <String>[],
        );
        if (rawValue != null) {
          values[key] = rawValue.toString();
        }
      }
    }
    return values;
  }

  /// Queries [extension] for its declared feature flags, configuration options,
  /// and configuration actions, and returns a map of its owned keys to their
  /// resolved values (`environmentOverride` > `"extensions"` settings > default
  /// value; `bool` for feature flags, `String` for options and action keys,
  /// omitting unset keys).
  static Future<Map<String, Object?>> resolveConfigurationValues({
    required Config config,
    required Map<String, String> environment,
    required ConfigurationExtension extension,
    required String extensionName,
  }) async {
    final List<FeatureFlag> flags = await extension.getFeatureFlags();
    final List<ConfigOption> options = await extension.getConfigurations();
    final List<ConfigAction> actions = await extension.getConfigActions();
    final values = <String, Object?>{
      ...collectActionSettings(
        config,
        configActions: actions,
        configOptions: options,
        extensionName: extensionName,
      ),
    };
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

  /// Retrieves feature flags provided by all registered extensions.
  Future<List<FeatureFlag>> fetchFeatureFlags() async {
    _logger.printTrace(
      'ExtensionConfiguration fetching feature flags across ${extensions.length} extension(s)...',
    );
    final List<List<FeatureFlag>> results = await Future.wait(
      extensions.map((ConfigurationExtension ext) async {
        try {
          return await ext.getFeatureFlags();
        } on ToolExtensionException catch (err) {
          _logger.printWarning('Extension "${_extensionIdentifier(ext)}": ${err.message}');
          return const <FeatureFlag>[];
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
        } on ToolExtensionException catch (err) {
          _logger.printWarning('Extension "${_extensionIdentifier(ext)}": ${err.message}');
          return const <ConfigOption>[];
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

  /// Executes [action] on [group]'s extension with [currentSettings] and
  /// validates that every returned setting key belongs to the extension's
  /// declared [ConfigOption] names or [ConfigAction.settingsKeys].
  static Future<Map<String, String?>> runConfigAction({
    required ConfigAction action,
    required Map<String, String?> currentSettings,
    required ExtensionSettingsGroup group,
  }) async {
    final Map<String, String?> updates = await group.extension.runConfigAction(
      action.name,
      currentSettings: currentSettings,
    );
    final allowedKeys = <String>{
      for (final ConfigOption(:name) in group.configOptions) name,
      ...action.settingsKeys,
    };
    for (final String key in updates.keys) {
      if (!allowedKeys.contains(key)) {
        throw ToolExtensionException(
          'Extension "${group.extensionName}" config action "${action.name}" '
          'returned undeclared setting key "$key" (allowed: ${allowedKeys.toList()}).',
        );
      }
    }
    return updates;
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
          final List<ConfigAction> actions = await ext.getConfigActions();
          return ExtensionSettingsGroup(
            configActions: actions,
            configOptions: options,
            extension: ext,
            extensionName: _extensionIdentifier(ext),
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

/// Handles host-side interactive terminal prompt RPCs (`terminal.promptForOption`
/// and `terminal.promptForInput`) for tool extensions.
class ExtensionTerminalPrompter {
  ExtensionTerminalPrompter({required this._toolContext});

  final ToolContext _toolContext;
  bool _isMachineMode = false;

  Logger get _logger => _toolContext.logger;
  Stdio get _stdio => _toolContext.stdio;
  Terminal get _terminal => _toolContext.terminal;

  /// Marks the current CLI invocation as running in `--machine` mode so
  /// interactive terminal prompt RPCs fail fast with
  /// [ToolExtensionException.domainErrorCode].
  void enableMachineMode() {
    _isMachineMode = true;
  }

  void _ensureInteractiveTerminal() {
    if (_isMachineMode) {
      throw const ToolExtensionException(
        'Cannot prompt for user input when "--machine" is enabled.',
      );
    }
    if (!_terminal.stdinHasTerminal) {
      throw const ToolExtensionException(
        'Cannot prompt for user input in a non-interactive terminal.',
      );
    }
  }

  Future<String?> _readStdinLine() async {
    _terminal.usesTerminalUi = true;
    try {
      return await _terminal.readLine();
    } on StateError {
      return null;
    }
  }

  /// Handles a `terminal.promptForOption` RPC request from an extension isolate.
  Future<Map<String, Object?>> handlePromptForOption(Map<String, Object?> params) async {
    final String message;
    final List<String> options;
    final int? defaultChoiceIndex;
    try {
      message = params.requiredField<String>(ToolExtensionService.promptMessageParam);
      options = <String>[
        for (final Object? item in params.requiredField<List<Object?>>(
          ToolExtensionService.promptOptionsParam,
        ))
          switch (item) {
            final String option => option,
            _ => throw FormatException(
              'Invalid "${ToolExtensionService.promptOptionsParam}" element: '
              'expected String, got ${item.runtimeType}.',
            ),
          },
      ];
      defaultChoiceIndex = params.nullableField<int>(
        ToolExtensionService.promptDefaultChoiceIndexParam,
      );
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    if (defaultChoiceIndex != null &&
        (defaultChoiceIndex < 0 || defaultChoiceIndex >= options.length)) {
      throw json_rpc.RpcException.invalidParams(
        'Default choice index $defaultChoiceIndex is out of range for ${options.length} option(s).',
      );
    }
    _ensureInteractiveTerminal();
    if (options.isEmpty) {
      return <String, Object?>{ToolExtensionService.promptSelectedIndexKey: null};
    }

    final int count = options.length;
    for (var i = 0; i < count; i++) {
      final defaultSuffix = i == defaultChoiceIndex ? ' (default)' : '';
      _logger.printStatus('[${i + 1}] ${options[i]}$defaultSuffix');
    }
    final promptText = '$message (or "q" to quit)';

    while (true) {
      _logger.printStatus('$promptText: ', emphasis: true, newline: false);
      final String? rawLine = await _readStdinLine();
      if (rawLine == null) {
        return <String, Object?>{ToolExtensionService.promptSelectedIndexKey: null};
      }
      final String trimmed = rawLine.trim();
      if (trimmed.isEmpty && defaultChoiceIndex != null) {
        return <String, Object?>{ToolExtensionService.promptSelectedIndexKey: defaultChoiceIndex};
      }
      if (trimmed == 'q') {
        return <String, Object?>{ToolExtensionService.promptSelectedIndexKey: null};
      }
      final int? selectedNumber = int.tryParse(trimmed);
      if (selectedNumber != null && selectedNumber >= 1 && selectedNumber <= count) {
        return <String, Object?>{ToolExtensionService.promptSelectedIndexKey: selectedNumber - 1};
      }
    }
  }

  /// Handles a `terminal.promptForInput` RPC request from an extension isolate.
  Future<Map<String, Object?>> handlePromptForInput(Map<String, Object?> params) async {
    final String message;
    final String? defaultValue;
    final bool echo;
    try {
      message = params.requiredField<String>(ToolExtensionService.promptMessageParam);
      defaultValue = params.nullableField<String>(ToolExtensionService.promptDefaultValueParam);
      echo = params.optionalField<bool>(ToolExtensionService.promptEchoParam, defaultValue: true);
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    _ensureInteractiveTerminal();

    final formattedPrompt = defaultValue != null && defaultValue.isNotEmpty
        ? '$message [$defaultValue]: '
        : '$message: ';
    _logger.printStatus(formattedPrompt, emphasis: true, newline: false);

    Stdin? rawStdin;
    bool? previousEchoMode;
    if (!echo) {
      if (_stdio.stdin case final Stdin stdin) {
        try {
          previousEchoMode = stdin.echoMode;
          stdin.echoMode = false;
          rawStdin = stdin;
        } on StdinException {
          // Ignore if stdin does not support changing echoMode.
        }
      }
    }
    String? line;
    try {
      line = await _readStdinLine();
    } finally {
      if (rawStdin != null && previousEchoMode != null) {
        try {
          rawStdin.echoMode = previousEchoMode;
        } on StdinException {
          // Ignore if stdin closed before echoMode was restored.
        }
        _logger.printStatus('');
      }
    }

    if (line == null) {
      return <String, Object?>{ToolExtensionService.promptValueKey: null};
    }
    final String resolvedValue = line.isEmpty && defaultValue != null ? defaultValue : line;
    return <String, Object?>{ToolExtensionService.promptValueKey: resolvedValue};
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
  List<FeatureFlag>? _featureFlagsCache;
  List<ConfigOption>? _configurationsCache;
  List<ConfigAction>? _configActionsCache;

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

  Future<List<T>?> _fetchList<T>(
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
    return null;
  }

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    if (_featureFlagsCache case final cached?) {
      return cached;
    }
    final List<FeatureFlag>? flags = await _fetchList(
      ConfigurationExtension.getFeatureFlagsMethod,
      'feature flag(s)',
      FeatureFlag.listFromJson,
    );
    return flags != null ? (_featureFlagsCache = flags) : const <FeatureFlag>[];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    if (_configurationsCache case final cached?) {
      return cached;
    }
    final List<ConfigOption>? options = await _fetchList(
      ConfigurationExtension.getConfigurationsMethod,
      'config option(s)',
      ConfigOption.listFromJson,
    );
    return options != null ? (_configurationsCache = options) : const <ConfigOption>[];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    if (_configActionsCache case final cached?) {
      return cached;
    }
    final List<ConfigAction>? actions = await _fetchList(
      ConfigurationExtension.getConfigActionsMethod,
      'config action(s)',
      ConfigAction.listFromJson,
    );
    return actions != null ? (_configActionsCache = actions) : const <ConfigAction>[];
  }

  @override
  Future<Map<String, String?>> runConfigAction(
    String name, {
    required Map<String, String?> currentSettings,
  }) async {
    _logger.printTrace(
      'ConfigurationExtensionClient running config action "$name" via RPC ("${ConfigurationExtension.runConfigActionMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      ConfigurationExtension.runConfigActionMethod,
      params: <String, Object?>{
        ConfigurationExtension.actionNameParam: name,
        ConfigurationExtension.currentSettingsParam: currentSettings,
      },
      timeout: null,
    );
    if (rawResult is! Map<String, Object?>) {
      throw ToolExtensionException(
        'Extension "${connection.extensionName}" returned an invalid response for "${ConfigurationExtension.runConfigActionMethod}".',
      );
    }
    return <String, String?>{
      for (final MapEntry(:String key, :Object? value) in rawResult.entries)
        key: switch (value) {
          final String? stringValue => stringValue,
          _ => throw ToolExtensionException(
            'Extension "${connection.extensionName}" returned a non-string value for setting "$key" '
            'from "${ConfigurationExtension.runConfigActionMethod}".',
          ),
        },
    };
  }
}
