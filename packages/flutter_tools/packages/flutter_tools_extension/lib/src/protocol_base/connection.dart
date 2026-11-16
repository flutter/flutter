// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import 'provider.dart';
import 'service.dart';

/// Typedef for an extension isolate entrypoint function accepted by
/// [ExtensionIsolateConnection.spawn].
typedef ExtensionIsolateEntryPoint = FutureOr<void> Function(SendPort sendPort);

/// Callback invoked when a valid `'extension.log'` notification is received.
typedef ExtensionLogMessageCallback = void Function(
  ExtensionLogMessage message,
  String extensionName,
);

/// Callback invoked when an `'extension.log'` notification or an unlistened
/// custom notification payload fails schema validation.
typedef ExtensionMalformedNotificationCallback = void Function(
  String method,
  FormatException error,
  StackTrace stackTrace,
  String extensionName,
);

/// Callback invoked when an unhandled post-handshake error is reported on an
/// extension isolate's error port.
typedef ExtensionIsolateErrorCallback = void Function(
  Object? rawError,
  String detail,
  StackTrace? stackTrace,
  String extensionName,
);

/// Minimal JSON-RPC 2.0 request and notification channel implemented by
/// [ExtensionIsolateConnection] and host connection wrappers.
abstract interface class ExtensionRpcChannel {
  /// Returns a broadcast stream of JSON-RPC 2.0 notifications sent by the
  /// extension isolate for [method].
  Stream<Map<String, Object?>> onNotification(String method);

  /// Sends a JSON-RPC 2.0 request to the extension isolate.
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = ExtensionIsolateConnection.defaultRpcTimeout,
  });
}

/// Shared Isolate and JSON-RPC 2.0 connection managing handshake, notifications,
/// domain error unwrapping, liveness ports, and bounded `extension.shutdown`
/// teardown for both `package:flutter_tools` and `ExtensionTestHarness`.
final class ExtensionIsolateConnection implements ExtensionRpcChannel {
  ExtensionIsolateConnection._({
    required this.capabilities,
    required this._errorPort,
    required this._exitPort,
    required this.extensionName,
    required Isolate this._isolate,
    required this.ownerName,
    required this._peer,
    required this._receivePort,
    this._onDisposing,
    this._onIsolateError,
    this._onIsolateExit,
    this._onMalformedNotification,
    this._onTrace,
  });

  /// Fallback extension name used when an extension does not report one in its capabilities.
  static const defaultExtensionName = 'unknown_extension';

  /// Default timeout applied to handshake and fast metadata JSON-RPC requests.
  static const defaultRpcTimeout = Duration(seconds: 5);

  static const _shutdownTimeout = Duration(seconds: 2);

  /// Capabilities reported by the extension isolate during handshake.
  final ToolExtensionCapabilities capabilities;

  /// Resolved package or extension name of the connected extension.
  final String extensionName;

  /// Owner label included in post-disposal [StateError] and diagnostic trace messages.
  final String ownerName;

  final ReceivePort _errorPort;
  final ReceivePort _exitPort;
  Isolate? _isolate;
  final void Function()? _onDisposing;
  final ExtensionIsolateErrorCallback? _onIsolateError;
  final void Function(String extensionName)? _onIsolateExit;
  final ExtensionMalformedNotificationCallback? _onMalformedNotification;
  final void Function(String message)? _onTrace;
  final _notificationControllers = <String, StreamController<Map<String, Object?>>>{};
  final json_rpc.Peer _peer;
  final ReceivePort _receivePort;

  Future<void>? _disposeFuture;
  bool _isolateExited = false;

  /// Whether this connection has begun or completed disposal.
  bool get isDisposed => _disposeFuture != null;

  void _handleIsolateError(Object? rawError, String detail, StackTrace? stackTrace) {
    _onIsolateError?.call(rawError, detail, stackTrace, extensionName);
  }

  void _handleIsolateExit() {
    _isolateExited = true;
    _receivePort.close();
    _onIsolateExit?.call(extensionName);
    unawaited(dispose());
  }

  @override
  Stream<Map<String, Object?>> onNotification(String method) {
    if (isDisposed) {
      throw StateError('$ownerName has been disposed.');
    }
    if (method == ToolExtensionService.logNotificationMethod) {
      throw ArgumentError.value(
        method,
        'method',
        '"${ToolExtensionService.logNotificationMethod}" notifications are handled directly by $ownerName.',
      );
    }
    final StreamController<Map<String, Object?>> controller = _notificationControllers.putIfAbsent(
      method,
      () {
        final newController = StreamController<Map<String, Object?>>.broadcast();
        _peer.registerMethod(method, (json_rpc.Parameters params) {
          if (newController.isClosed) {
            return;
          }
          final Object? rawValue = params.value;
          if (rawValue is! Map<String, Object?>) {
            final error = FormatException(
              'Invalid notification payload for "$method": '
              'expected Map<String, Object?>, got ${rawValue.runtimeType}.',
            );
            final StackTrace stackTrace = StackTrace.current;
            if (newController.hasListener) {
              newController.addError(error, stackTrace);
            } else {
              _onMalformedNotification?.call(method, error, stackTrace, extensionName);
            }
            return;
          }
          newController.add(rawValue);
        });
        return newController;
      },
    );
    return controller.stream;
  }

  @override
  Future<Object?> sendRequest(
    String method, {
    Object? params,
    Duration? timeout = defaultRpcTimeout,
  }) async {
    if (isDisposed) {
      throw StateError('$ownerName has been disposed.');
    }
    _onTrace?.call('$ownerName sending RPC request "$method"...');
    try {
      final Future<Object?> request = _peer.sendRequest(method, params);
      final Object? result = await (timeout != null ? request.timeout(timeout) : request);
      _onTrace?.call('$ownerName received response for RPC request "$method".');
      return result;
    } on json_rpc.RpcException catch (error) {
      if (error.code == ToolExtensionException.domainErrorCode) {
        throw ToolExtensionException(error.message);
      }
      _onTrace?.call('$ownerName RPC request "$method" failed with error: $error');
      rethrow;
    } on Object catch (error) {
      _onTrace?.call('$ownerName RPC request "$method" failed with error: $error');
      rethrow;
    }
  }

  /// Sends a fire-and-forget JSON-RPC 2.0 notification to the extension isolate.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    if (isDisposed) {
      throw StateError('$ownerName has been disposed.');
    }
    _peer.sendNotification(method, params);
  }

  /// Spawns an in-process extension isolate from [entryPoint] and completes the
  /// `extension.getCapabilities` handshake.
  static Future<ExtensionIsolateConnection> spawn(
    ExtensionIsolateEntryPoint entryPoint, {
    String? extensionName,
    void Function()? onDisposing,
    ExtensionIsolateErrorCallback? onIsolateError,
    void Function(String extensionName)? onIsolateExit,
    ExtensionLogMessageCallback? onLogMessage,
    ExtensionMalformedNotificationCallback? onMalformedNotification,
    void Function(String message)? onTrace,
    String ownerName = 'ExtensionIsolateConnection',
    Duration timeout = defaultRpcTimeout,
  }) {
    onTrace?.call('$ownerName spawning extension isolate...');
    return _spawnAndHandshake(
      extensionName: extensionName,
      isolateLauncher: (SendPort sendPort, SendPort onError, SendPort onExit) =>
          Isolate.spawn(entryPoint, sendPort, onError: onError, onExit: onExit),
      onDisposing: onDisposing,
      onIsolateError: onIsolateError,
      onIsolateExit: onIsolateExit,
      onLogMessage: onLogMessage,
      onMalformedNotification: onMalformedNotification,
      onTrace: onTrace,
      ownerName: ownerName,
      timeout: timeout,
    );
  }

  /// Spawns an extension isolate from [entrypointUri] via [Isolate.spawnUri]
  /// and completes the `extension.getCapabilities` handshake.
  static Future<ExtensionIsolateConnection> spawnUri(
    Uri entrypointUri, {
    List<String> args = const <String>[],
    String? extensionName,
    void Function()? onDisposing,
    ExtensionIsolateErrorCallback? onIsolateError,
    void Function(String extensionName)? onIsolateExit,
    ExtensionLogMessageCallback? onLogMessage,
    ExtensionMalformedNotificationCallback? onMalformedNotification,
    void Function(String message)? onTrace,
    String ownerName = 'ExtensionIsolateConnection',
    Uri? packageConfigUri,
    Duration timeout = defaultRpcTimeout,
  }) {
    onTrace?.call('$ownerName spawning extension isolate from URI "$entrypointUri"...');
    return _spawnAndHandshake(
      extensionName: extensionName,
      isolateLauncher: (SendPort sendPort, SendPort onError, SendPort onExit) async {
        final Uri? resolvedPackageConfig = packageConfigUri ?? await Isolate.packageConfig;
        return Isolate.spawnUri(
          entrypointUri,
          args,
          sendPort,
          packageConfig: resolvedPackageConfig,
          automaticPackageResolution: resolvedPackageConfig == null,
          onError: onError,
          onExit: onExit,
        );
      },
      onDisposing: onDisposing,
      onIsolateError: onIsolateError,
      onIsolateExit: onIsolateExit,
      onLogMessage: onLogMessage,
      onMalformedNotification: onMalformedNotification,
      onTrace: onTrace,
      ownerName: ownerName,
      timeout: timeout,
    );
  }

  static Future<ExtensionIsolateConnection> _spawnAndHandshake({
    required Future<Isolate> Function(SendPort sendPort, SendPort onError, SendPort onExit)
    isolateLauncher,
    required String ownerName,
    required Duration timeout,
    String? extensionName,
    void Function()? onDisposing,
    ExtensionIsolateErrorCallback? onIsolateError,
    void Function(String extensionName)? onIsolateExit,
    ExtensionLogMessageCallback? onLogMessage,
    ExtensionMalformedNotificationCallback? onMalformedNotification,
    void Function(String message)? onTrace,
  }) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final errorCompleter = Completer<Never>();
    ExtensionIsolateConnection? connection;

    errorPort.listen((Object? error) {
      final (String detail, StackTrace? parsedStackTrace) = switch (error) {
        [final Object? description, final String trace] when trace.isNotEmpty => (
          '$description',
          StackTrace.fromString(trace),
        ),
        [final Object? description, final Object? trace] when trace != null => (
          '$description',
          StackTrace.fromString('$trace'),
        ),
        [final Object? description, _] => ('$description', null),
        _ => ('$error', null),
      };
      if (connection case final ExtensionIsolateConnection activeConnection) {
        activeConnection._handleIsolateError(error, detail, parsedStackTrace);
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate error: $detail'),
          parsedStackTrace ?? StackTrace.current,
        );
      }
    });

    exitPort.listen((Object? _) {
      if (connection case final ExtensionIsolateConnection activeConnection) {
        activeConnection._handleIsolateExit();
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate exited unexpectedly before handshake completed.'),
        );
      }
    });

    Isolate? isolate;

    try {
      isolate = await isolateLauncher(
        receivePort.sendPort,
        errorPort.sendPort,
        exitPort.sendPort,
      ).timeout(timeout);
      onTrace?.call('$ownerName isolate spawned; connecting IsolateChannel...');

      final channel = IsolateChannel<Object?>.connectReceive(receivePort);
      final peer = json_rpc.Peer.withoutJson(channel);

      peer.registerMethod(ToolExtensionService.logNotificationMethod, (json_rpc.Parameters params) {
        final String currentExtensionName =
            connection?.extensionName ?? extensionName ?? defaultExtensionName;
        final Object? rawValue = params.value;
        if (rawValue is! Map<String, Object?>) {
          onMalformedNotification?.call(
            ToolExtensionService.logNotificationMethod,
            FormatException(
              'Invalid notification payload for "${ToolExtensionService.logNotificationMethod}": '
              'expected Map<String, Object?>, got ${rawValue.runtimeType}.',
            ),
            StackTrace.current,
            currentExtensionName,
          );
          return;
        }
        try {
          final logMessage = ExtensionLogMessage.fromJson(rawValue);
          onLogMessage?.call(logMessage, currentExtensionName);
        } on FormatException catch (error, stackTrace) {
          onMalformedNotification?.call(
            ToolExtensionService.logNotificationMethod,
            error,
            stackTrace,
            currentExtensionName,
          );
        }
      });

      unawaited(peer.listen());

      onTrace?.call('$ownerName querying extension.getCapabilities...');
      final Object? responseObj = await Future.any<Object?>(<Future<Object?>>[
        peer.sendRequest(ToolExtensionEntryPoint.getCapabilitiesMethod),
        errorCompleter.future,
      ]).timeout(timeout);
      if (responseObj is! Map<String, Object?>) {
        throw StateError(
          'Extension handshake failed: extension.getCapabilities did not return a Map.',
        );
      }
      final capabilities = ToolExtensionCapabilities.fromJson(responseObj);
      onTrace?.call('$ownerName handshake complete. Capabilities: ${capabilities.services}');

      return connection = ExtensionIsolateConnection._(
        capabilities: capabilities,
        errorPort: errorPort,
        exitPort: exitPort,
        extensionName: extensionName ?? capabilities.extensionName ?? defaultExtensionName,
        isolate: isolate,
        onDisposing: onDisposing,
        onIsolateError: onIsolateError,
        onIsolateExit: onIsolateExit,
        onMalformedNotification: onMalformedNotification,
        onTrace: onTrace,
        ownerName: ownerName,
        peer: peer,
        receivePort: receivePort,
      );
    } on TimeoutException {
      onTrace?.call('$ownerName handshake timed out.');
      receivePort.close();
      errorPort.close();
      exitPort.close();
      isolate?.kill(priority: Isolate.immediate);
      onDisposing?.call();
      throw TimeoutException('Handshake with tool extension isolate timed out.');
    } on Object catch (error) {
      onTrace?.call('$ownerName spawn failed with error: $error');
      receivePort.close();
      errorPort.close();
      exitPort.close();
      isolate?.kill(priority: Isolate.immediate);
      onDisposing?.call();
      rethrow;
    }
  }

  /// Sends `extension.shutdown`, closes all open ports and streams, and kills
  /// the extension isolate.
  ///
  /// Concurrent calls share the same in-flight disposal future.
  Future<void> dispose() => _disposeFuture ??= _doDispose();

  Future<void> _doDispose() async {
    _onTrace?.call('$ownerName disposing isolate connection.');
    if (!_isolateExited && !_peer.isClosed) {
      try {
        await _peer.sendRequest(ToolExtensionEntryPoint.shutdownMethod).timeout(_shutdownTimeout);
      } on Object catch (error) {
        _onTrace?.call('Extension "$extensionName" shutdown RPC did not complete cleanly: $error');
      }
    }
    _errorPort.close();
    _exitPort.close();
    _receivePort.close();
    for (final StreamController<Map<String, Object?>> controller
        in _notificationControllers.values) {
      await controller.close();
    }
    _notificationControllers.clear();
    _onDisposing?.call();
    try {
      await _peer.close();
    } on Object catch (error) {
      _onTrace?.call('Error closing extension connection peer: $error');
    } finally {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }
}
