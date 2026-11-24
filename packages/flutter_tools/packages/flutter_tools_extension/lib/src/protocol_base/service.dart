// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';

/// Typedef for an extension RPC handler function.
typedef ExtensionRpcHandler = FutureOr<Object?> Function(Map<String, Object?> params);

/// Callback signature for sending a JSON-RPC 2.0 notification from an extension
/// service to the host tool.
typedef ExtensionNotificationSender = void Function(String method, Map<String, Object?> params);

typedef _ExtensionRequestSender = Future<Object?> Function(String method, [Object? parameters]);

/// Represents a logical service exposed by a Flutter Tool Extension.
///
/// Extension authors extend this class (via specific service base classes) to
/// group related RPC endpoints under a specific [namespace] (e.g.
/// `diagnostics`, `config`, `device`, `build`, `template`).
abstract base class ToolExtensionService {
  /// JSON-RPC method name invoked by extensions to query their resolved
  /// configuration values from the host tool.
  static const String getConfigurationValuesMethod = 'extension.getConfigurationValues';

  /// JSON-RPC method name invoked by extensions to prompt the user to select
  /// an option via the host terminal.
  static const String promptForOptionMethod = 'terminal.promptForOption';

  /// JSON-RPC method name invoked by extensions to prompt the user for text
  /// input via the host terminal.
  static const String promptForInputMethod = 'terminal.promptForInput';

  /// JSON-RPC parameter key for the prompt message text.
  static const String promptMessageParam = 'message';

  /// JSON-RPC parameter key for the list of selectable option labels.
  static const String promptOptionsParam = 'options';

  /// JSON-RPC parameter key for the optional 0-based default option index.
  static const String promptDefaultChoiceIndexParam = 'defaultChoiceIndex';

  /// JSON-RPC parameter key for the optional default input value.
  static const String promptDefaultValueParam = 'defaultValue';

  /// JSON-RPC parameter key controlling whether terminal input is echoed.
  static const String promptEchoParam = 'echo';

  /// JSON-RPC response map key holding the 0-based selected option index (or `null`).
  static const String promptSelectedIndexKey = 'selectedIndex';

  /// JSON-RPC response map key holding the entered input string (or `null`).
  static const String promptValueKey = 'value';

  /// Internal JSON-RPC notification sender callback used by [sendNotification].
  ///
  /// Wired by `ToolExtensionEntryPoint.run` before the extension peer begins
  /// listening for RPC requests.
  @internal
  ExtensionNotificationSender? notificationSender;

  /// Internal JSON-RPC request sender callback used by [sendHostRequest].
  ///
  /// Wired by `ToolExtensionEntryPoint.run` to `peer.sendRequest` before the
  /// extension peer begins listening for RPC requests.
  @internal
  _ExtensionRequestSender? requestSender;

  /// The namespace string of the service (e.g. `'diagnostics'`).
  String get namespace;

  /// Initializes state needed by the service and returns a map of method handlers.
  ///
  /// The returned map maps method names (without namespace prefix) to handler functions.
  Future<Map<String, ExtensionRpcHandler>> initialize();

  /// Sends a fire-and-forget JSON-RPC 2.0 notification with [method] and
  /// [params] to the host tool.
  ///
  /// Throws a [StateError] if called before this service has been attached to
  /// an active extension peer by `ToolExtensionEntryPoint.run`.
  void sendNotification(String method, Map<String, Object?> params) {
    final ExtensionNotificationSender? sender = notificationSender;
    if (sender == null) {
      throw StateError(
        'Cannot send notification "$method": service "$namespace" is not attached to an active peer.',
      );
    }
    sender(method, params);
  }

  /// Sends a JSON-RPC 2.0 request to the host tool over the bidirectional
  /// `Peer` and returns the decoded result payload.
  ///
  /// Throws a [StateError] if called before this service has been attached to
  /// an active extension peer by `ToolExtensionEntryPoint.run`.
  @protected
  @nonVirtual
  Future<Object?> sendHostRequest(String method, Map<String, Object?> params) async {
    final _ExtensionRequestSender? sender = requestSender;
    if (sender == null) {
      throw StateError(
        'Cannot send request "$method": service "$namespace" is not attached to an active peer.',
      );
    }
    try {
      return await sender(method, params);
    } on json_rpc.RpcException catch (error) {
      if (tryParseToolExtensionRpcError(code: error.code, message: error.message, data: error.data)
          case final ToolExtensionException translated) {
        throw translated;
      }
      rethrow;
    }
  }

  /// Queries the host tool for the current persisted values of all configuration
  /// keys owned by this extension.
  ///
  /// Only keys declared by this extension's `ConfigService` (`FeatureFlag.settingName`
  /// mapped to `bool`, and `ConfigOption.name` and `ConfigAction.settingsKeys`
  /// mapped to `String`, omitting unset keys) are returned. The host resolves
  /// `environmentOverride` ahead of `"extensions"` settings in `flutter_settings`
  /// and falls back to any `ConfigOption.aliases` and default values.
  @nonVirtual
  Future<Map<String, Object?>> getConfigurationValues() async {
    final Object? rawResult = await sendHostRequest(
      getConfigurationValuesMethod,
      const <String, Object?>{},
    );
    if (rawResult case final Map<String, Object?> map) {
      return map;
    }
    throw FormatException(
      'Expected Map<String, Object?> from "$getConfigurationValuesMethod", got '
      '${rawResult.runtimeType}.',
      rawResult,
    );
  }

  /// Prompts the user via the host tool's interactive terminal to choose one of
  /// [options].
  ///
  /// Returns the selected 0-based index in [options], or `null` if the user
  /// cancels the prompt.
  ///
  /// Throws a [ToolExtensionException] when the host tool is running without an
  /// interactive terminal or in `--machine` mode.
  @nonVirtual
  Future<int?> promptForOption({
    required String message,
    required List<String> options,
    int? defaultChoiceIndex,
  }) async {
    final Object? rawResult = await sendHostRequest(promptForOptionMethod, <String, Object?>{
      promptMessageParam: message,
      promptOptionsParam: options,
      promptDefaultChoiceIndexParam: ?defaultChoiceIndex,
    });
    if (rawResult case {promptSelectedIndexKey: final int? selectedIndex}) {
      return selectedIndex;
    }
    throw FormatException(
      'Expected {"$promptSelectedIndexKey": int?} from "$promptForOptionMethod", got '
      '${rawResult.runtimeType}.',
      rawResult,
    );
  }

  /// Prompts the user via the host tool's interactive terminal for free-form
  /// text input.
  ///
  /// When [echo] is `false`, terminal character echoing is disabled while
  /// reading the line (for example, when prompting for a passphrase or token).
  ///
  /// Throws a [ToolExtensionException] when the host tool is running without an
  /// interactive terminal or in `--machine` mode.
  @nonVirtual
  Future<String?> promptForInput({
    required String message,
    String? defaultValue,
    bool echo = true,
  }) async {
    final Object? rawResult = await sendHostRequest(promptForInputMethod, <String, Object?>{
      promptMessageParam: message,
      promptDefaultValueParam: ?defaultValue,
      promptEchoParam: echo,
    });
    if (rawResult case {promptValueKey: final String? value}) {
      return value;
    }
    throw FormatException(
      'Expected {"$promptValueKey": String?} from "$promptForInputMethod", got '
      '${rawResult.runtimeType}.',
      rawResult,
    );
  }

  /// Cleans up resources held by the service when the extension is shut down.
  ///
  /// Invoked by `ToolExtensionEntryPoint.run` when the host tool sends an
  /// `extension.shutdown` RPC on CLI exit or connection disposal. Runs
  /// concurrently across all registered services in the isolate via
  /// `Future.wait`, with a short bounded grace period before the
  /// extension isolate is terminated.
  Future<void> shutdown() async {}
}

/// Represents the capabilities and supported service namespaces reported by an extension.
@immutable
class ToolExtensionCapabilities {
  /// Creates [ToolExtensionCapabilities] listing supported [services],
  /// [supportedPlatforms], and optional [extensionName].
  const ToolExtensionCapabilities({
    required this.services,
    this.extensionName,
    this.supportedPlatforms = const <String>{'linux', 'macos', 'windows'},
  });

  /// Deserializes [ToolExtensionCapabilities] from a JSON map payload.
  factory ToolExtensionCapabilities.fromJson(Map<String, Object?> json) {
    return ToolExtensionCapabilities(
      extensionName: json.nullableField<String>(extensionNameKey),
      services: json.stringIterable(servicesKey).toList(),
      supportedPlatforms: json
          .stringIterable(supportedPlatformsKey)
          .map((String p) => p.toLowerCase())
          .toSet(),
    );
  }

  /// Map key for [extensionName].
  static const String extensionNameKey = 'extensionName';

  /// Map key for [services].
  static const String servicesKey = 'services';

  /// Map key for [supportedPlatforms].
  static const String supportedPlatformsKey = 'supportedPlatforms';

  /// Optional identifier name of the extension package.
  ///
  /// When provided, this should match the extension's package name. The host
  /// tool uses this identifier in error messages and artifact cache paths.
  final String? extensionName;

  /// The list of service namespace identifiers supported by the extension.
  final List<String> services;

  /// The set of host operating system platforms supported by the extension in lowercase (e.g., `{'linux'}`).
  final Set<String> supportedPlatforms;

  /// Returns whether the extension supports the given [hostPlatform].
  bool supportsHostPlatform(String hostPlatform) {
    return supportedPlatforms.contains(hostPlatform.toLowerCase());
  }

  /// Serializes capabilities to a map payload.
  Map<String, Object?> toMap() => <String, Object?>{
    extensionNameKey: ?extensionName,
    servicesKey: services,
    supportedPlatformsKey: supportedPlatforms.toList(),
  };
}
