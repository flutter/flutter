// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core message and service definitions for the tool extension protocol.
///
/// This library defines the base message types (Request, Response, Notification),
/// error structures, and the service interface for tool extensions.
library generic_extension_protocol.service;

/// A registrar interface used by extension services to register their RPC handlers.
abstract interface class RpcRegistrar {
  /// Registers an RPC handler for the given [method].
  ///
  /// The [handler] must be a [Function] that takes either zero arguments or one
  /// argument of type `Parameters` from `package:json_rpc_2`.
  void registerRpc(String method, Function handler);
}

/// The base for all messages in the Tool Extension Protocol.
///
/// All protocol messages (requests, responses, notifications) extend this class
/// and have an optional identifier [id].
abstract class Message {
  /// Creates a [Message] with the given [id].
  const Message(this.id);

  /// The message identifier. Can be null for notifications.
  final Object? id;

  /// Serializes the message to a map.
  Map<String, Object?> toMap() => <String, Object?>{'id': id};
}

/// Represents an RPC request sent from the host tool to the extension.
///
/// Contains the [method] name to invoke and optional [params].
class Request extends Message {
  /// Creates a [Request] with the given [id], [method], and [params].
  const Request({required Object? id, required this.method, this.params}) : super(id);

  /// The name of the method to invoke.
  final String method;

  /// The parameters associated with the request.
  final Map<String, Object?>? params;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ...super.toMap(),
    'method': method,
    'params': params ?? <String, Object?>{},
  };
}

/// Represents a one-way notification sent between the host tool and the extension.
///
/// Notifications do not have an identifier and do not expect a response.
class Notification extends Message {
  /// Creates a [Notification] with the given [method] and [params].
  const Notification({required this.method, this.params}) : super(null);

  /// The name of the method/event.
  final String method;

  /// The parameters associated with the notification, if any.
  final Map<String, Object?>? params;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ...super.toMap(),
    'method': method,
    'params': params ?? <String, Object?>{},
  };
}

/// Represents an RPC response sent from the extension back to the host tool.
///
/// Contains either a [result] (for success) or an [error] (for failure).
class Response extends Message {
  /// Creates a successful [Response] or an error [Response].
  const Response({required Object? id, this.result, this.error}) : super(id);

  /// The result of a successful request.
  final Object? result;

  /// The error details if the request failed.
  final RpcError? error;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ...super.toMap(),
    if (result != null) 'result': result,
    if (error != null) 'error': error!.toMap(),
  };
}

/// Represents details of an RPC error response.
///
/// Contains an error [code], a [message] description, and optional extra [data].
class RpcError {
  /// Creates an [RpcError] with the given [code], [message], and optional [data].
  const RpcError({required this.code, required this.message, this.data});

  /// The error code.
  final int code;

  /// A description of the error.
  final String message;

  /// Optional error details.
  final Object? data;

  /// Serializes the error to a map.
  Map<String, Object?> toMap() => <String, Object?>{
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
}

/// Represents a logical service exposed by a Tool Extension.
///
/// Extensions implement this class to group related RPC methods under a [namespace]
/// (e.g., `build`, `device`, `diagnostics`).
abstract class ToolExtensionService {
  /// The name of the service.
  String get namespace;

  /// Initializes state needed by the service and returns its RPC handlers.
  ///
  /// The returned map maps method names (without namespace prefix) to their
  /// corresponding handler functions.
  Future<Map<String, Function>> initialize();

  /// Cleans up any state held by the service when the extension shuts down.
  Future<void> shutdown();
}

/// Represents the capabilities (i.e. supported services) reported by an extension.
class ToolExtensionCapabilities {
  /// Creates [ToolExtensionCapabilities] with the list of supported service [services].
  const ToolExtensionCapabilities({required this.services});

  /// Creates [ToolExtensionCapabilities] from a JSON map.
  factory ToolExtensionCapabilities.fromJson(Map<String, Object?> json) {
    final servicesJson = json['services'] as List<Object?>?;
    final List<String> services = servicesJson?.cast<String>() ?? <String>[];
    return ToolExtensionCapabilities(services: services);
  }

  /// The list of namespaces of services supported by the extension.
  final List<String> services;

  /// Serializes the capabilities to a map.
  Map<String, Object?> toMap() => <String, Object?>{'services': services};
}
