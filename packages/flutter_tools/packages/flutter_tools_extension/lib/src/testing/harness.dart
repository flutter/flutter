// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../protocol_base/provider.dart';
import '../protocol_base/service.dart';
import 'clients.dart';

/// Typedef for an extension isolate entrypoint function accepted by
/// [ExtensionTestHarness.spawn].
typedef ExtensionTestEntryPoint = FutureOr<void> Function(SendPort sendPort);

/// In-process Isolate and JSON-RPC 2.0 test harness for Flutter tool extensions.
///
/// Spawns an extension isolate via [spawn] or [spawnUri], completes the
/// `extension.getCapabilities` handshake, and exposes typed protocol clients
/// ([diagnosticsClient], [configClient], [templateClient], [deviceClient],
/// [buildClient], [artifactClient], [cleanClient]) along with notification
/// streams ([onLog], [onNotification]) and raw JSON-RPC helpers
/// ([sendRawRequest], [sendNotification]).
// TODO(bkonyi): Share connection and client proxy implementations between
// package:flutter_tools and package:flutter_tools_extension/testing.dart,
// https://github.com/flutter/flutter/issues/190755.
final class ExtensionTestHarness {
  ExtensionTestHarness._({
    required this.capabilities,
    required this._errorPort,
    required this._exitPort,
    required Isolate this._isolate,
    required this._isolateErrors,
    required this._logController,
    required this._logs,
    required this._peer,
    required this._receivePort,
  });

  /// Capabilities reported by the extension isolate during handshake.
  final ToolExtensionCapabilities capabilities;

  final ReceivePort _errorPort;
  final ReceivePort _exitPort;
  Isolate? _isolate;
  final List<StateError> _isolateErrors;
  final StreamController<ExtensionLogMessage> _logController;
  final List<ExtensionLogMessage> _logs;
  final _notificationControllers = <String, StreamController<Map<String, Object?>>>{};
  final json_rpc.Peer _peer;
  final ReceivePort _receivePort;

  /// Typed client for invoking `diagnostics.*` RPCs on the extension.
  late final diagnosticsClient = ExtensionTestDiagnosticsClient(this);

  /// Typed client for invoking `config.*` RPCs on the extension.
  late final configClient = ExtensionTestConfigurationClient(this);

  /// Typed client for invoking `template.*` RPCs on the extension.
  late final templateClient = ExtensionTestTemplateClient(this);

  /// Typed client for invoking `device.*` RPCs on the extension.
  late final deviceClient = ExtensionTestDeviceClient(this);

  /// Typed client for invoking `build.*` RPCs on the extension.
  late final buildClient = ExtensionTestBuildClient(this);

  /// Typed client for invoking `artifact.*` RPCs on the extension.
  late final artifactClient = ExtensionTestArtifactClient(this);

  /// Typed client for invoking `clean.*` RPCs on the extension.
  late final cleanClient = ExtensionTestCleanClient(this);

  bool _isDisposed = false;

  /// Whether this harness has been disposed.
  bool get isDisposed => _isDisposed;

  /// Unmodifiable snapshot of unhandled isolate errors received after handshake.
  List<StateError> get isolateErrors => List<StateError>.unmodifiable(_isolateErrors);

  /// Unmodifiable snapshot of all `'extension.log'` messages received so far.
  List<ExtensionLogMessage> get logs => List<ExtensionLogMessage>.unmodifiable(_logs);

  /// Broadcast stream of `'extension.log'` messages emitted by the extension.
  Stream<ExtensionLogMessage> get onLog => _logController.stream;

  /// Returns a broadcast stream of JSON-RPC 2.0 notifications sent by the
  /// extension isolate for [method].
  ///
  /// For `'extension.log'` notifications, use [onLog] or [logs] instead.
  /// If the extension emits a non-map notification payload for [method], a
  /// [FormatException] is delivered to the returned stream (or to the active
  /// zone's uncaught error handler if no listener is attached).
  Stream<Map<String, Object?>> onNotification(String method) {
    if (_isDisposed) {
      throw StateError('ExtensionTestHarness has been disposed.');
    }
    if (method == ToolExtensionService.logNotificationMethod) {
      throw ArgumentError.value(
        method,
        'method',
        'Use ExtensionTestHarness.onLog or logs to observe '
            '"${ToolExtensionService.logNotificationMethod}" notifications.',
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
            if (newController.hasListener) {
              newController.addError(error, StackTrace.current);
            } else {
              Zone.current.handleUncaughtError(error, StackTrace.current);
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

  /// Spawns an extension isolate running [entryPoint] and completes the
  /// `extension.getCapabilities` handshake.
  ///
  /// Note that [Isolate.spawn] copies objects captured by [entryPoint] into the
  /// child isolate's heap. In-memory test doubles captured by [entryPoint]
  /// cannot be inspected directly from the parent isolate after an RPC; observe
  /// results through RPC responses or a [SendPort].
  static Future<ExtensionTestHarness> spawn(
    ExtensionTestEntryPoint entryPoint, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _spawnWith(
      (SendPort sendPort, SendPort onError, SendPort onExit) =>
          Isolate.spawn(entryPoint, sendPort, onError: onError, onExit: onExit),
      timeout: timeout,
    );
  }

  /// Spawns an extension isolate from [entrypointUri] via [Isolate.spawnUri]
  /// and completes the `extension.getCapabilities` handshake.
  static Future<ExtensionTestHarness> spawnUri(
    Uri entrypointUri, {
    List<String> args = const <String>[],
    Uri? packageConfigUri,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _spawnWith((SendPort sendPort, SendPort onError, SendPort onExit) async {
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
    }, timeout: timeout);
  }

  static Future<ExtensionTestHarness> _spawnWith(
    Future<Isolate> Function(SendPort sendPort, SendPort onError, SendPort onExit) isolateSpawner, {
    required Duration timeout,
  }) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final errorCompleter = Completer<Never>();
    final isolateErrors = <StateError>[];
    final logs = <ExtensionLogMessage>[];
    final logController = StreamController<ExtensionLogMessage>.broadcast();

    Isolate? isolate;
    ExtensionTestHarness? harness;

    errorPort.listen((Object? error) {
      final (String detail, StackTrace stackTrace) = switch (error) {
        [final Object? description, final String trace] when trace.isNotEmpty => (
          '$description',
          StackTrace.fromString(trace),
        ),
        [final Object? description, _] => ('$description', StackTrace.current),
        _ => ('$error', StackTrace.current),
      };
      if (harness case final ExtensionTestHarness activeHarness) {
        final isolateError = StateError('Extension isolate unhandled error: $detail');
        activeHarness._isolateErrors.add(isolateError);
        if (!activeHarness._logController.isClosed && activeHarness._logController.hasListener) {
          activeHarness._logController.addError(isolateError, stackTrace);
        } else {
          Zone.current.handleUncaughtError(isolateError, stackTrace);
        }
        unawaited(activeHarness.dispose());
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(StateError('Extension isolate error: $detail'), stackTrace);
      }
    });

    exitPort.listen((Object? _) {
      if (harness case final ExtensionTestHarness activeHarness) {
        unawaited(activeHarness.dispose());
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.completeError(
          StateError('Extension isolate exited unexpectedly before handshake completed.'),
        );
      }
    });

    try {
      isolate = await isolateSpawner(
        receivePort.sendPort,
        errorPort.sendPort,
        exitPort.sendPort,
      ).timeout(timeout);

      final channel = IsolateChannel<Object?>.connectReceive(receivePort);
      final peer = json_rpc.Peer.withoutJson(channel);

      peer.registerMethod(ToolExtensionService.logNotificationMethod, (json_rpc.Parameters params) {
        if (logController.isClosed) {
          return;
        }
        final Object? rawValue = params.value;
        if (rawValue is! Map<String, Object?>) {
          final error = FormatException(
            'Invalid notification payload for "${ToolExtensionService.logNotificationMethod}": '
            'expected Map<String, Object?>, got ${rawValue.runtimeType}.',
          );
          if (logController.hasListener) {
            logController.addError(error, StackTrace.current);
          } else {
            Zone.current.handleUncaughtError(error, StackTrace.current);
          }
          return;
        }
        try {
          final logMessage = ExtensionLogMessage.fromJson(rawValue);
          logs.add(logMessage);
          logController.add(logMessage);
        } on FormatException catch (error, stackTrace) {
          if (logController.hasListener) {
            logController.addError(error, stackTrace);
          } else {
            Zone.current.handleUncaughtError(error, stackTrace);
          }
        }
      });

      unawaited(peer.listen());

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
      return harness = ExtensionTestHarness._(
        capabilities: capabilities,
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        isolateErrors: isolateErrors,
        logController: logController,
        logs: logs,
        peer: peer,
        receivePort: receivePort,
      );
    } on TimeoutException {
      await _cleanupFailedSpawn(
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logController: logController,
        receivePort: receivePort,
      );
      throw TimeoutException('Handshake with tool extension isolate timed out.');
    } on Object {
      await _cleanupFailedSpawn(
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logController: logController,
        receivePort: receivePort,
      );
      rethrow;
    }
  }

  static Future<void> _cleanupFailedSpawn({
    required ReceivePort errorPort,
    required ReceivePort exitPort,
    required Isolate? isolate,
    required StreamController<ExtensionLogMessage> logController,
    required ReceivePort receivePort,
  }) async {
    errorPort.close();
    exitPort.close();
    receivePort.close();
    isolate?.kill(priority: Isolate.immediate);
    await logController.close();
  }

  /// Sends a raw JSON-RPC 2.0 request to the extension isolate.
  ///
  /// Pass `timeout: null` for long-running RPCs that should wait until
  /// completion or isolate termination.
  Future<Object?> sendRawRequest(
    String method, {
    Map<String, Object?>? params,
    Duration? timeout = const Duration(seconds: 5),
  }) async {
    if (_isDisposed) {
      throw StateError('ExtensionTestHarness has been disposed.');
    }
    final Future<Object?> request = _peer.sendRequest(method, params);
    return timeout != null ? request.timeout(timeout) : request;
  }

  /// Sends a fire-and-forget JSON-RPC 2.0 notification to the extension isolate.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    if (_isDisposed) {
      throw StateError('ExtensionTestHarness has been disposed.');
    }
    _peer.sendNotification(method, params);
  }

  /// Disposes the JSON-RPC peer, kills the extension isolate, and closes all
  /// open receive ports and notification streams.
  ///
  /// Idempotent: calling [dispose] multiple times is a no-op.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _errorPort.close();
    _exitPort.close();
    _receivePort.close();
    for (final StreamController<Map<String, Object?>> controller
        in _notificationControllers.values) {
      await controller.close();
    }
    _notificationControllers.clear();
    await _logController.close();
    try {
      await _peer.close();
    } on Object {
      // Ignore peer closure errors during teardown.
    } finally {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }
}
