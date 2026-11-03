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
import '../convert.dart';
import 'extension_discovery.dart';

/// Represents a group of configuration settings provided by a specific extension.
class ExtensionSettingsGroup {
  const ExtensionSettingsGroup({
    required this.title,
    required this.featureFlags,
    required this.configOptions,
    this.configActions = const <ConfigAction>[],
    this.extension,
    this.extensionName,
  });

  /// The human-readable title of the extension.
  final String title;

  /// Optional identifier of the extension package (used to namespace settings in
  /// `flutter_settings` as `<extensionName>.<key>`).
  final String? extensionName;

  /// The [ConfigurationExtension] that produced this group, if available.
  final ConfigurationExtension? extension;

  /// Feature flags registered by the extension.
  final List<FeatureFlag> featureFlags;

  /// Config options registered by the extension.
  final List<ConfigOption> configOptions;

  /// Interactive or custom configuration actions registered by the extension.
  final List<ConfigAction> configActions;

  /// Settings keys declared by [configActions] that do not already correspond to
  /// a [FeatureFlag] or [ConfigOption] in this group.
  List<String> get actionOnlySettingsKeys {
    final declaredKeys = <String>{
      for (final FeatureFlag(:settingName) in featureFlags) settingName,
      for (final ConfigOption(:name) in configOptions) name,
    };
    final actionKeys = <String>[];
    final seen = <String>{};
    for (final ConfigAction(:settingsKeys) in configActions) {
      for (final key in settingsKeys) {
        if (!declaredKeys.contains(key) && seen.add(key)) {
          actionKeys.add(key);
        }
      }
    }
    return actionKeys;
  }

  /// Whether this group contains any settings that should be displayed in
  /// `flutter config --list` ([featureFlags], [configOptions], or
  /// [ConfigAction.settingsKeys]).
  bool get hasDisplayableSettings =>
      featureFlags.isNotEmpty || configOptions.isNotEmpty || actionOnlySettingsKeys.isNotEmpty;

  /// Whether this group contains any feature flags, configuration options, or
  /// configuration actions.
  bool get isNotEmpty =>
      featureFlags.isNotEmpty || configOptions.isNotEmpty || configActions.isNotEmpty;

  /// Whether this group is empty.
  bool get isEmpty => !isNotEmpty;
}

/// A host-side configuration manager that delegates feature flag, option, and action queries to extensions.
class ExtensionConfiguration {
  ExtensionConfiguration({required List<ConfigurationExtension> extensions, required this._logger})
    : extensions = List<ConfigurationExtension>.unmodifiable(extensions);

  /// The active extension services executing configuration queries.
  final List<ConfigurationExtension> extensions;
  final Logger _logger;

  String _extensionIdentifier(ConfigurationExtension ext) =>
      ext is ConfigurationExtensionClient ? ext.connection.extensionName : ext.title;

  String? _extensionStorageNamespace(ConfigurationExtension ext) =>
      ext is ConfigurationExtensionClient ? ext.connection.extensionName : null;

  /// Returns the storage key in `flutter_settings` for [key] under optional
  /// [extensionName] (`<extensionName>.<key>` when [extensionName] is non-empty,
  /// or unprefixed [key] otherwise).
  static String storageKey(String key, {String? extensionName}) {
    if (extensionName != null && extensionName.isNotEmpty) {
      return '$extensionName.$key';
    }
    return key;
  }

  /// Looks up a setting [key] (and optional [aliases]) in [config], checking
  /// `<extensionName>.<key>` first when [extensionName] is non-empty before
  /// falling back to unprefixed `<key>` and any aliases.
  static Object? lookupSettingValue(
    Config config,
    String key, {
    String? extensionName,
    List<String> aliases = const <String>[],
  }) {
    final bool hasPrefix = extensionName != null && extensionName.isNotEmpty;
    if (hasPrefix) {
      final Object? prefixed = config.getValue('$extensionName.$key');
      if (prefixed != null) {
        return prefixed;
      }
    }
    final Object? unprefixed = config.getValue(key);
    if (unprefixed != null) {
      return unprefixed;
    }
    for (final alias in aliases) {
      if (hasPrefix) {
        final Object? prefixedAlias = config.getValue('$extensionName.$alias');
        if (prefixedAlias != null) {
          return prefixedAlias;
        }
      }
      final Object? unprefixedAlias = config.getValue(alias);
      if (unprefixedAlias != null) {
        return unprefixedAlias;
      }
    }
    return null;
  }

  /// Removes a setting [key] (both `<extensionName>.<key>` and unprefixed `<key>`,
  /// plus any [aliases]) from [config].
  static void removeSettingValue(
    Config config,
    String key, {
    String? extensionName,
    List<String> aliases = const <String>[],
  }) {
    final bool hasPrefix = extensionName != null && extensionName.isNotEmpty;
    if (hasPrefix && config.containsKey('$extensionName.$key')) {
      config.removeValue('$extensionName.$key');
    }
    if (config.containsKey(key)) {
      config.removeValue(key);
    }
    for (final alias in aliases) {
      if (hasPrefix && config.containsKey('$extensionName.$alias')) {
        config.removeValue('$extensionName.$alias');
      }
      if (config.containsKey(alias)) {
        config.removeValue(alias);
      }
    }
  }

  /// Persists [value] for [key] under [extensionName] in [config] and removes
  /// any pre-existing legacy unprefixed or [aliases] keys.
  static void setSettingValue(
    Config config,
    String key,
    Object value, {
    String? extensionName,
    List<String> aliases = const <String>[],
  }) {
    final bool hasPrefix = extensionName != null && extensionName.isNotEmpty;
    if (hasPrefix && config.containsKey(key)) {
      config.removeValue(key);
    }
    for (final alias in aliases) {
      if (hasPrefix && config.containsKey('$extensionName.$alias')) {
        config.removeValue('$extensionName.$alias');
      }
      if (config.containsKey(alias)) {
        config.removeValue(alias);
      }
    }
    config.setValue(storageKey(key, extensionName: extensionName), value);
  }

  /// Collects the persisted configuration values owned by [group] from [config],
  /// returning native `bool` values for declared [FeatureFlag.settingName] keys
  /// and `String` values for declared [ConfigOption.name] and
  /// [ConfigAction.settingsKeys] (omitting unset keys).
  static Map<String, Object?> collectConfigurationValues(
    Config config,
    ExtensionSettingsGroup group,
  ) {
    final values = <String, Object?>{};
    final String? extensionName = group.extensionName;
    for (final FeatureFlag(:settingName) in group.featureFlags) {
      final Object? rawValue = lookupSettingValue(
        config,
        settingName,
        extensionName: extensionName,
      );
      if (rawValue is bool) {
        values[settingName] = rawValue;
      } else if (rawValue == 'true') {
        values[settingName] = true;
      } else if (rawValue == 'false') {
        values[settingName] = false;
      }
    }
    final aliasesByOptionName = <String, List<String>>{};
    for (final ConfigOption(:name, :aliases) in group.configOptions) {
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
    for (final ConfigAction(:settingsKeys) in group.configActions) {
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

  /// Collects the persisted setting values scoped to [group]'s declared
  /// [ConfigOption.name] and [ConfigAction.settingsKeys] (excluding feature
  /// flags unless explicitly listed in [ConfigAction.settingsKeys]), normalized
  /// to `String?` for passing to [ConfigurationExtension.runConfigAction].
  static Map<String, String?> collectActionSettings(Config config, ExtensionSettingsGroup group) {
    final values = <String, String?>{};
    final String? extensionName = group.extensionName;
    final aliasesByOptionName = <String, List<String>>{};
    for (final ConfigOption(:name, :aliases) in group.configOptions) {
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
    for (final ConfigAction(:settingsKeys) in group.configActions) {
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
  /// persisted values in [config] (`bool` for feature flags, `String` for
  /// options and action keys, omitting unset keys).
  static Future<Map<String, Object?>> resolveConfigurationValues({
    required Config config,
    required ConfigurationExtension extension,
    String? extensionName,
  }) async {
    final List<FeatureFlag> flags = await extension.getFeatureFlags();
    final List<ConfigOption> options = await extension.getConfigurations();
    final List<ConfigAction> actions = await extension.getConfigActions();
    final group = ExtensionSettingsGroup(
      title: extension.title,
      extension: extension,
      extensionName: extensionName,
      featureFlags: flags,
      configOptions: options,
      configActions: actions,
    );
    return collectConfigurationValues(config, group);
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

  /// Executes [action] on [extension] with [currentSettings] and validates that
  /// every returned setting key is declared in [ConfigAction.settingsKeys].
  Future<Map<String, String?>> runConfigAction({
    required ConfigurationExtension extension,
    required ConfigAction action,
    required Map<String, String?> currentSettings,
  }) async {
    final Map<String, String?> updates = await extension.runConfigAction(
      action.name,
      currentSettings: currentSettings,
    );
    final Set<String> allowedKeys = action.settingsKeys.toSet();
    for (final String key in updates.keys) {
      if (!allowedKeys.contains(key)) {
        throw ToolExtensionException(
          'Extension "${_extensionIdentifier(extension)}" config action "${action.name}" '
          'returned undeclared setting key "$key" (allowed: ${action.settingsKeys}).',
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
            title: title,
            extension: ext,
            extensionName: _extensionStorageNamespace(ext),
            featureFlags: flags,
            configOptions: options,
            configActions: actions,
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
  ExtensionTerminalPrompter({required this._logger, this._stdio, this._terminal});

  final Logger _logger;
  final Stdio? _stdio;
  final Terminal? _terminal;
  bool _isMachineMode = false;
  Stream<String>? _stdioLines;

  /// Marks the current CLI invocation as running in `--machine` mode so
  /// interactive terminal prompt RPCs fail fast with
  /// [ToolExtensionException.nonInteractiveErrorCode].
  void enableMachineMode() {
    _isMachineMode = true;
  }

  void _ensureInteractiveTerminal() {
    if (_isMachineMode) {
      throw const ToolExtensionException(
        'Cannot prompt for user input when "--machine" is enabled.',
        code: ToolExtensionException.nonInteractiveErrorCode,
      );
    }
    final bool hasTerminal =
        (_terminal?.stdinHasTerminal ?? false) || (_stdio?.stdinHasTerminal ?? false);
    if (!hasTerminal) {
      throw const ToolExtensionException(
        'Cannot prompt for user input in a non-interactive terminal.',
        code: ToolExtensionException.nonInteractiveErrorCode,
      );
    }
  }

  Future<String?> _readStdinLine() async {
    final Terminal? terminal = _terminal;
    if (terminal != null && terminal.stdinHasTerminal) {
      terminal.usesTerminalUi = true;
      try {
        return await terminal.readLine();
      } on StateError {
        return null;
      }
    }
    final Stdio? stdio = _stdio;
    if (stdio == null) {
      return null;
    }
    final Stream<String> lines = _stdioLines ??= stdio.stdin
        .transform<String>(const Utf8Decoder(reportErrors: false))
        .transform<String>(const LineSplitter())
        .asBroadcastStream(
          onListen: (StreamSubscription<String> subscription) => subscription.resume(),
          onCancel: (StreamSubscription<String> subscription) => subscription.pause(),
        );
    try {
      return await lines.first;
    } on StateError {
      return null;
    }
  }

  /// Handles a `terminal.promptForOption` RPC request from an extension isolate.
  Future<Map<String, Object?>> handlePromptForOption(Map<String, Object?> params) async {
    final String message;
    final Map<String, String> options;
    final String? defaultOptionId;
    try {
      message = params.requiredField<String>(ToolExtensionService.promptMessageParam);
      options = params.stringMap(ToolExtensionService.promptOptionsParam);
      defaultOptionId = params.nullableField<String>(
        ToolExtensionService.promptDefaultOptionIdParam,
      );
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    if (defaultOptionId != null && !options.containsKey(defaultOptionId)) {
      throw json_rpc.RpcException.invalidParams(
        'Default option ID "$defaultOptionId" is not present in options.',
      );
    }
    _ensureInteractiveTerminal();
    if (options.isEmpty) {
      return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
    }

    final List<MapEntry<String, String>> entries = options.entries.toList();
    final int count = entries.length;
    final int defaultIndex = defaultOptionId != null
        ? entries.indexWhere((MapEntry<String, String> entry) => entry.key == defaultOptionId)
        : -1;
    for (var i = 0; i < count; i++) {
      final defaultSuffix = i == defaultIndex ? ' (default)' : '';
      _logger.printStatus('[${i + 1}] ${entries[i].value}$defaultSuffix');
    }
    final promptText = '$message (or "q" to quit)';

    final Terminal? terminal = _terminal;
    if (terminal != null && terminal.stdinHasTerminal && count <= 9) {
      terminal.usesTerminalUi = true;
      final String choice;
      try {
        choice = await terminal.promptForCharInput(
          List<String>.generate(count, (int number) => '${number + 1}')..add('q'),
          prompt: promptText,
          defaultChoiceIndex: defaultIndex >= 0 ? defaultIndex : null,
          logger: _logger,
          displayAcceptedCharacters: false,
        );
      } on StateError {
        return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
      }
      if (choice == 'q') {
        return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
      }
      final int? selectedNumber = int.tryParse(choice);
      if (selectedNumber != null && selectedNumber >= 1 && selectedNumber <= count) {
        return <String, Object?>{
          ToolExtensionService.promptOptionIdKey: entries[selectedNumber - 1].key,
        };
      }
      return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
    }

    while (true) {
      _logger.printStatus('$promptText: ', emphasis: true, newline: false);
      final String? rawLine = await _readStdinLine();
      if (rawLine == null) {
        return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
      }
      final String trimmed = rawLine.trim();
      if (trimmed.isEmpty && defaultIndex >= 0) {
        return <String, Object?>{ToolExtensionService.promptOptionIdKey: entries[defaultIndex].key};
      }
      if (trimmed == 'q') {
        return <String, Object?>{ToolExtensionService.promptOptionIdKey: null};
      }
      final int? selectedNumber = int.tryParse(trimmed);
      if (selectedNumber != null && selectedNumber >= 1 && selectedNumber <= count) {
        return <String, Object?>{
          ToolExtensionService.promptOptionIdKey: entries[selectedNumber - 1].key,
        };
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

    final Stdin? rawStdin = switch (_stdio?.stdin) {
      final Stdin stdin => stdin,
      _ => null,
    };
    bool? previousEchoMode;
    if (!echo && rawStdin != null) {
      try {
        previousEchoMode = rawStdin.echoMode;
        rawStdin.echoMode = false;
      } on StdinException {
        // Ignore if stdin does not support changing echoMode.
      }
    }
    String? line;
    try {
      line = await _readStdinLine();
    } finally {
      if (!echo && rawStdin != null && previousEchoMode != null) {
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
class ConfigurationExtensionClient extends ConfigurationExtension {
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
    T Function(Map<String, Object?>) fromJson,
  ) async {
    _logger.printTrace('ConfigurationExtensionClient fetching $entityName via RPC ("$method")...');
    try {
      final Object? rawResult = await connection.sendRequest(method);
      if (rawResult case final List<Object?> list) {
        final results = <T>[
          for (final Object? element in list)
            if (element case final Map<String, Object?> map) fromJson(map),
        ];
        _logger.printTrace(
          'ConfigurationExtensionClient received ${results.length} $entityName via RPC.',
        );
        return List<T>.unmodifiable(results);
      }
      _logger.printTrace(
        'ConfigurationExtensionClient received invalid or null $entityName response: $rawResult',
      );
    } on ToolExtensionException {
      rethrow;
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
      FeatureFlag.fromJson,
    );
    if (flags != null) {
      return _featureFlagsCache = flags;
    }
    return const <FeatureFlag>[];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    if (_configurationsCache case final cached?) {
      return cached;
    }
    final List<ConfigOption>? options = await _fetchList(
      ConfigurationExtension.getConfigurationsMethod,
      'config option(s)',
      ConfigOption.fromJson,
    );
    if (options != null) {
      return _configurationsCache = options;
    }
    return const <ConfigOption>[];
  }

  @override
  Future<List<ConfigAction>> getConfigActions() async {
    if (_configActionsCache case final cached?) {
      return cached;
    }
    const String method = ConfigurationExtension.getConfigActionsMethod;
    _logger.printTrace(
      'ConfigurationExtensionClient fetching config action(s) via RPC ("$method")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(method);
      if (rawResult case final List<Object?> list) {
        final results = List<ConfigAction>.unmodifiable(ConfigAction.listFromJson(list));
        _configActionsCache = results;
        _logger.printTrace(
          'ConfigurationExtensionClient received ${results.length} config action(s) via RPC.',
        );
        return results;
      }
      _logger.printTrace(
        'ConfigurationExtensionClient received invalid or null config action(s) response: $rawResult',
      );
    } on ToolExtensionException {
      rethrow;
    } on Object catch (err, stack) {
      _logger.printTrace(
        'ConfigurationExtensionClient failed to get config action(s): $err\n$stack',
      );
    }
    return const <ConfigAction>[];
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
      for (final MapEntry(:key, :value) in rawResult.entries) key: value?.toString(),
    };
  }
}
