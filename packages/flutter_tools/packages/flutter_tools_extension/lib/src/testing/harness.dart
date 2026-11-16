// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';

import '../protocol_base/clients.dart';
import '../protocol_base/connection.dart';
import '../protocol_base/service.dart';

/// In-process Isolate and JSON-RPC 2.0 test harness for Flutter tool extensions.
///
/// Spawns an extension isolate via [spawn] or [spawnUri], completes the
/// `extension.getCapabilities` handshake, and exposes shared typed protocol
/// clients ([diagnosticsClient], [configClient], [templateClient],
/// [deviceClient], [buildClient], [artifactClient], [cleanClient]) along with
/// structured log and isolate-error streams ([onLog], [onIsolateError],
/// [onNotification]) and raw JSON-RPC helpers ([sendRawRequest],
/// [sendNotification]).
final class ExtensionTestHarness {
  ExtensionTestHarness._({
    required this._connection,
    required this._isolateErrorController,
    required this._isolateErrors,
    required this._logController,
    required this._logs,
  });

  static const _ownerName = 'ExtensionTestHarness';

  final ExtensionIsolateConnection _connection;
  final StreamController<StateError> _isolateErrorController;
  final List<StateError> _isolateErrors;
  final StreamController<ExtensionLogMessage> _logController;
  final List<ExtensionLogMessage> _logs;

  /// Capabilities reported by the extension isolate during handshake.
  ToolExtensionCapabilities get capabilities => _connection.capabilities;

  /// Typed client for invoking `diagnostics.*` RPCs on the extension.
  late final diagnosticsClient = ExtensionDiagnosticsRpcClient(_connection);

  /// Typed client for invoking `config.*` RPCs on the extension.
  late final configClient = ExtensionConfigurationRpcClient(_connection);

  /// Typed client for invoking `template.*` RPCs on the extension.
  late final templateClient = ExtensionTemplateRpcClient(_connection);

  /// Typed client for invoking `device.*` RPCs on the extension.
  late final deviceClient = ExtensionDeviceRpcClient(_connection);

  /// Typed client for invoking `build.*` RPCs on the extension.
  late final buildClient = ExtensionBuildRpcClient(_connection);

  /// Typed client for invoking `artifact.*` RPCs on the extension.
  late final artifactClient = ExtensionArtifactRpcClient(_connection);

  /// Typed client for invoking `clean.*` RPCs on the extension.
  late final cleanClient = ExtensionCleanRpcClient(_connection);

  /// Whether this harness has been disposed.
  bool get isDisposed => _connection.isDisposed;

  /// Unmodifiable snapshot of unhandled isolate errors received after handshake.
  List<StateError> get isolateErrors => List<StateError>.unmodifiable(_isolateErrors);

  /// Broadcast stream of unhandled post-handshake isolate errors.
  ///
  /// If a listener is attached, unhandled isolate errors are emitted on this
  /// stream; otherwise they are reported via `Zone.current.handleUncaughtError`.
  Stream<StateError> get onIsolateError => _isolateErrorController.stream;

  /// Unmodifiable snapshot of all `'extension.log'` messages received so far.
  List<ExtensionLogMessage> get logs => List<ExtensionLogMessage>.unmodifiable(_logs);

  /// Broadcast stream of `'extension.log'` messages emitted by the extension.
  ///
  /// Malformed `'extension.log'` payloads are delivered to this stream as
  /// [FormatException] errors when a listener is attached, or reported via
  /// `Zone.current.handleUncaughtError` otherwise.
  Stream<ExtensionLogMessage> get onLog => _logController.stream;

  /// Returns a broadcast stream of JSON-RPC 2.0 notifications sent by the
  /// extension isolate for [method].
  Stream<Map<String, Object?>> onNotification(String method) => _connection.onNotification(method);

  /// Spawns an extension isolate running [entryPoint] and completes the
  /// `extension.getCapabilities` handshake.
  ///
  /// Note that [Isolate.spawn] copies objects captured by [entryPoint] into the
  /// child isolate's heap. In-memory test doubles captured by [entryPoint]
  /// cannot be inspected directly from the parent isolate after an RPC; observe
  /// results through RPC responses or a [SendPort].
  static Future<ExtensionTestHarness> spawn(
    ExtensionIsolateEntryPoint entryPoint, {
    Duration timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) {
    return _create(
      ({
        required void Function() onDisposing,
        required ExtensionIsolateErrorCallback onIsolateError,
        required ExtensionLogMessageCallback onLogMessage,
        required ExtensionMalformedNotificationCallback onMalformedNotification,
      }) => ExtensionIsolateConnection.spawn(
        entryPoint,
        onDisposing: onDisposing,
        onIsolateError: onIsolateError,
        onLogMessage: onLogMessage,
        onMalformedNotification: onMalformedNotification,
        ownerName: _ownerName,
        timeout: timeout,
      ),
    );
  }

  /// Spawns an extension isolate from [entrypointUri] via [Isolate.spawnUri]
  /// and completes the `extension.getCapabilities` handshake.
  static Future<ExtensionTestHarness> spawnUri(
    Uri entrypointUri, {
    List<String> args = const <String>[],
    Uri? packageConfigUri,
    Duration timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) {
    return _create(
      ({
        required void Function() onDisposing,
        required ExtensionIsolateErrorCallback onIsolateError,
        required ExtensionLogMessageCallback onLogMessage,
        required ExtensionMalformedNotificationCallback onMalformedNotification,
      }) => ExtensionIsolateConnection.spawnUri(
        entrypointUri,
        args: args,
        onDisposing: onDisposing,
        onIsolateError: onIsolateError,
        onLogMessage: onLogMessage,
        onMalformedNotification: onMalformedNotification,
        ownerName: _ownerName,
        packageConfigUri: packageConfigUri,
        timeout: timeout,
      ),
    );
  }

  static Future<ExtensionTestHarness> _create(
    Future<ExtensionIsolateConnection> Function({
      required void Function() onDisposing,
      required ExtensionIsolateErrorCallback onIsolateError,
      required ExtensionLogMessageCallback onLogMessage,
      required ExtensionMalformedNotificationCallback onMalformedNotification,
    })
    connector,
  ) async {
    final isolateErrors = <StateError>[];
    final isolateErrorController = StreamController<StateError>.broadcast();
    final logs = <ExtensionLogMessage>[];
    final logController = StreamController<ExtensionLogMessage>.broadcast();

    final ExtensionIsolateConnection connection = await connector(
      onDisposing: () {
        unawaited(logController.close());
        unawaited(isolateErrorController.close());
      },
      onIsolateError: (Object? _, String detail, StackTrace? stackTrace, String _) {
        final isolateError = StateError('Extension isolate unhandled error: $detail');
        isolateErrors.add(isolateError);
        if (!isolateErrorController.isClosed && isolateErrorController.hasListener) {
          isolateErrorController.add(isolateError);
        } else {
          Zone.current.handleUncaughtError(isolateError, stackTrace ?? StackTrace.current);
        }
      },
      onLogMessage: (ExtensionLogMessage message, String _) {
        if (logController.isClosed) {
          return;
        }
        logs.add(message);
        logController.add(message);
      },
      onMalformedNotification:
          (String method, FormatException error, StackTrace stackTrace, String _) {
            if (method == ToolExtensionService.logNotificationMethod &&
                !logController.isClosed &&
                logController.hasListener) {
              logController.addError(error, stackTrace);
              return;
            }
            Zone.current.handleUncaughtError(error, stackTrace);
          },
    );

    return ExtensionTestHarness._(
      connection: connection,
      isolateErrorController: isolateErrorController,
      isolateErrors: isolateErrors,
      logController: logController,
      logs: logs,
    );
  }

  /// Sends a raw JSON-RPC 2.0 request to the extension isolate, unwrapping
  /// domain errors (`-32001`) into [ToolExtensionException].
  Future<Object?> sendRawRequest(
    String method, {
    Map<String, Object?>? params,
    Duration? timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  }) => _connection.sendRequest(method, params: params, timeout: timeout);

  /// Sends a fire-and-forget JSON-RPC 2.0 notification to the extension isolate.
  void sendNotification(String method, {Map<String, Object?>? params}) =>
      _connection.sendNotification(method, params: params);

  /// Sends `extension.shutdown`, closes all open receive ports and streams, and
  /// kills the extension isolate.
  Future<void> dispose() => _connection.dispose();
}
