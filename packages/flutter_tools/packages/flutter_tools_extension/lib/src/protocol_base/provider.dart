// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show Encoding;
import 'dart:io' show Directory, IOOverrides, Stdin, systemEncoding;
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import 'service.dart';

/// Entrypoint runner for a Flutter Tool Extension running in an Isolate.
///
/// Extension packages invoke [ToolExtensionEntryPoint.run] in their isolate
/// entrypoint function, passing the initial Isolate send port and list of
/// supported extension services.
abstract final class ToolExtensionEntryPoint {
  /// The reserved JSON-RPC method name used to query extension capabilities.
  static const String getCapabilitiesMethod = 'extension.getCapabilities';

  /// The reserved JSON-RPC method name used to request graceful extension shutdown.
  static const String shutdownMethod = 'extension.shutdown';

  static const String _acknowledgedKey = 'acknowledged';
  static const _emptyStdin = _EmptyStdin();

  /// Entrypoint function to serve [services] over the Isolate [sendPort].
  ///
  /// Validates that [sendPort] is a [SendPort] (throwing an [ArgumentError]
  /// otherwise). If provided, [extensionName] should be the name of the
  /// extension package and is surfaced by the host tool in error messages and
  /// artifact cache directories.
  static Future<void> run(
    Object? sendPort,
    List<ToolExtensionService> services, {
    Set<String>? supportedPlatforms,
    void Function(String message)? logger,
    String? extensionName,
  }) async {
    if (sendPort is! SendPort) {
      throw ArgumentError.value(
        sendPort,
        'sendPort',
        'Expected a SendPort as the initial isolate message.',
      );
    }
    final Directory initialCurrentDirectory = Directory.current;
    await IOOverrides.runZoned(
      () => _runInZone(
        sendPort,
        services,
        supportedPlatforms: supportedPlatforms,
        logger: logger,
        extensionName: extensionName,
      ),
      getCurrentDirectory: () => initialCurrentDirectory,
      setCurrentDirectory: (String _) => throw StateError(
        'Tool extensions must not modify Directory.current; '
        'resolve paths against project URIs or pass an explicit workingDirectory instead.',
      ),
      stdin: () => _emptyStdin,
      exit: (int code) => throw UnsupportedError(
        'Tool extensions must not call exit($code); throw ToolExtensionException instead.',
      ),
    );
  }

  static Future<void> _runInZone(
    SendPort sendPort,
    List<ToolExtensionService> services, {
    Set<String>? supportedPlatforms,
    void Function(String message)? logger,
    String? extensionName,
  }) async {
    final rpcHandlers = <String, ExtensionRpcHandler>{};

    for (final service in services) {
      logger?.call(
        '[ToolExtensionIsolate] Initializing service namespace "${service.namespace}"...',
      );
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      handlers.forEach((String method, ExtensionRpcHandler handler) {
        final fullMethod = '${service.namespace}.$method';
        if (fullMethod == getCapabilitiesMethod || fullMethod == shutdownMethod) {
          throw StateError('Reserved RPC method registered: "$fullMethod"');
        }
        if (rpcHandlers.containsKey(fullMethod)) {
          throw StateError('Duplicate RPC method registered: "$fullMethod"');
        }
        rpcHandlers[fullMethod] = handler;
        logger?.call('[ToolExtensionIsolate] Registered RPC method handler: "$fullMethod"');
      });
    }

    final capabilities = ToolExtensionCapabilities(
      extensionName: extensionName,
      supportedPlatforms: supportedPlatforms ?? const <String>{'linux', 'macos', 'windows'},
      services: services.map((ToolExtensionService s) => s.namespace).toList(),
    );

    logger?.call('[ToolExtensionIsolate] Initializing isolate channel...');
    // Connect the channel only after all fallible setup; connectSend opens a
    // ReceivePort that keeps the isolate alive.
    final channel = IsolateChannel<Object?>.connectSend(sendPort);
    final peer = json_rpc.Peer.withoutJson(channel);

    for (final service in services) {
      service.notificationSender = peer.sendNotification;
    }

    peer.registerMethod(getCapabilitiesMethod, (json_rpc.Parameters _) {
      logger?.call('[ToolExtensionIsolate] Handling extension.getCapabilities query.');
      return capabilities.toMap();
    });

    peer.registerMethod(shutdownMethod, () async {
      logger?.call('[ToolExtensionIsolate] Handling extension.shutdown request.');
      await Future.wait<void>(
        services.map((ToolExtensionService service) async {
          try {
            await service.shutdown();
          } on Object catch (error, stackTrace) {
            logger?.call(
              '[ToolExtensionIsolate] Error shutting down service "${service.namespace}": '
              '$error\n$stackTrace',
            );
          }
        }),
      );
      return <String, Object?>{_acknowledgedKey: true};
    });

    rpcHandlers.forEach((String fullMethod, ExtensionRpcHandler handler) {
      peer.registerMethod(fullMethod, (json_rpc.Parameters params) async {
        logger?.call('[ToolExtensionIsolate] Handling RPC request "$fullMethod"...');
        final Object? rawValue = params.value;
        final Map<String, Object?> paramMap = rawValue is Map
            ? rawValue.cast<String, Object?>()
            : <String, Object?>{};
        try {
          final Object? result = await handler(paramMap);
          logger?.call('[ToolExtensionIsolate] RPC request "$fullMethod" completed.');
          return result;
        } on ToolExtensionException catch (error) {
          logger?.call(
            '[ToolExtensionIsolate] RPC request "$fullMethod" threw ToolExtensionException: '
            '${error.message}',
          );
          throw json_rpc.RpcException(ToolExtensionException.domainErrorCode, error.message);
        } on Object catch (error, stackTrace) {
          logger?.call(
            '[ToolExtensionIsolate] RPC request "$fullMethod" failed: $error\n$stackTrace',
          );
          rethrow;
        }
      });
    });

    logger?.call('[ToolExtensionIsolate] Isolate peer listening for RPC requests.');
    await peer.listen();
  }
}

final class _EmptyStdin extends Stream<List<int>> implements Stdin {
  const _EmptyStdin();

  static const _terminalMutationError =
      'Tool extensions must not modify stdin terminal settings; '
      'use host-mediated prompt RPCs instead.';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<List<int>>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  bool get echoMode => false;

  @override
  set echoMode(bool value) => throw StateError(_terminalMutationError);

  @override
  bool get echoNewlineMode => false;

  @override
  set echoNewlineMode(bool value) => throw StateError(_terminalMutationError);

  @override
  bool get hasTerminal => false;

  @override
  bool get lineMode => true;

  @override
  set lineMode(bool value) => throw StateError(_terminalMutationError);

  @override
  int readByteSync() => -1;

  @override
  String? readLineSync({Encoding encoding = systemEncoding, bool retainNewlines = false}) => null;

  @override
  bool get supportsAnsiEscapes => false;
}
