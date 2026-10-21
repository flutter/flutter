// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../device.dart';
import 'service.dart';

/// Entrypoint runner for a Flutter Tool Extension running in an Isolate.
///
/// Extension packages invoke [ToolExtensionEntryPoint.run] in their isolate
/// entrypoint function, passing the initial Isolate send port and list of supported
/// extension services.
class ToolExtensionEntryPoint {
  /// The reserved JSON-RPC method name used to query extension capabilities.
  static const String getCapabilitiesMethod = 'extension.getCapabilities';

  static const _reservedMethods = <String>{
    getCapabilitiesMethod,
    ToolExtensionService.logNotificationMethod,
    DeviceService.logEntryNotificationMethod,
  };

  /// Standard `main(List<String> args, Object? message)` adapter for spawning
  /// an extension isolate via [Isolate.spawnUri].
  static Future<void> runMain(
    List<String> _,
    Object? message,
    FutureOr<void> Function(SendPort sendPort) entryPoint,
  ) async {
    if (message is! SendPort) {
      throw ArgumentError.value(
        message,
        'message',
        'Expected a SendPort when spawning a tool extension isolate.',
      );
    }
    await entryPoint(message);
  }

  /// Entrypoint function to serve [services] over the Isolate [sendPort].
  ///
  /// If provided, [extensionName] should be the name of the extension package
  /// and is surfaced by the host tool in error messages and artifact cache
  /// directories.
  static Future<void> run(
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
        if (_reservedMethods.contains(fullMethod)) {
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
      supportedPlatforms: supportedPlatforms ?? ExtensionPackageConfig.defaultSupportedPlatforms,
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

    peer.registerMethod(getCapabilitiesMethod, () {
      logger?.call('[ToolExtensionIsolate] Handling extension.getCapabilities query.');
      return capabilities.toMap();
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
