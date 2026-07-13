// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import 'service.dart';

/// Entrypoint runner for a Flutter Tool Extension running in an Isolate.
///
/// Extension packages invoke [ToolExtensionEntryPoint.run] in their isolate
/// entrypoint function, passing the initial Isolate send port and list of supported
/// extension services.
class ToolExtensionEntryPoint {
  /// Entrypoint function to serve [services] over the Isolate [sendPort].
  static Future<void> run(
    SendPort sendPort,
    List<ToolExtensionService> services, {
    List<String>? supportedPlatforms,
    void Function(String message)? logger,
  }) async {
    logger?.call('[ToolExtensionIsolate] Initializing isolate channel...');
    final channel = IsolateChannel<Object?>.connectSend(sendPort);
    final peer = json_rpc.Peer.withoutJson(channel);

    final rpcHandlers = <String, ExtensionRpcHandler>{};

    for (final service in services) {
      logger?.call(
        '[ToolExtensionIsolate] Initializing service namespace "${service.namespace}"...',
      );
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      handlers.forEach((String method, ExtensionRpcHandler handler) {
        final fullMethod = '${service.namespace}.$method';
        rpcHandlers[fullMethod] = handler;
        logger?.call('[ToolExtensionIsolate] Registered RPC method handler: "$fullMethod"');
      });
    }

    final capabilities = ToolExtensionCapabilities(
      supportedPlatforms: supportedPlatforms ?? const <String>['linux', 'macos', 'windows'],
      services: services.map((ToolExtensionService s) => s.namespace).toList(),
    );

    peer.registerMethod('extension.getCapabilities', () {
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
        final Object? result = await handler(paramMap);
        logger?.call('[ToolExtensionIsolate] RPC request "$fullMethod" completed.');
        return result;
      });
    });

    logger?.call('[ToolExtensionIsolate] Isolate peer listening for RPC requests.');
    await peer.listen();
  }
}
