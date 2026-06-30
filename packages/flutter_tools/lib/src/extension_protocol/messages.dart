// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents a message in the Flutter Extension Protocol.
///
/// Messages are structured similarly to JSON-RPC 2.0.
sealed class Message {
  /// Creates a [Message] with the given [id].
  const Message({required this.id});

  /// The message identifier.
  ///
  /// For requests and responses, this is typically an integer or string.
  /// For notifications, this is null.
  final Object? id;

  /// Converts this message to a JSON-compatible map.
  Map<String, Object?> toMap();

  /// Parses a message from a JSON-compatible map.
  ///
  /// Throws a [FormatException] if the map is not a valid message.
  static Message fromMap(Map<String, Object?> map) {
    if (map case {'method': String _}) {
      if (map.containsKey('id')) {
        return Request.fromMap(map);
      }
      return Notification.fromMap(map);
    }
    if (map.containsKey('id')) {
      return Response.fromMap(map);
    }
    throw FormatException('Unknown message type: $map');
  }
}

/// Represents a request sent to or from an extension.
///
/// A request expects a response with the same [id].
class Request extends Message {
  /// Creates a [Request] message.
  Request({required Object id, required this.method, this.params}) : super(id: id);

  /// Parses a [Request] from a JSON-compatible map.
  ///
  /// Throws a [FormatException] if the map does not represent a valid request.
  factory Request.fromMap(Map<String, Object?> map) {
    if (map case {'id': final Object id, 'method': final String method}) {
      final Object? params = map['params'];
      if (params != null && params is! Map<String, Object?>) {
        throw const FormatException("Request message 'params' must be a Map<String, Object?>");
      }
      return Request(id: id, method: method, params: params as Map<String, Object?>?);
    }
    if (!map.containsKey('id') || map['id'] == null) {
      throw const FormatException("Request message is missing non-null 'id'");
    }
    if (map['method'] is! String) {
      throw const FormatException("Request message 'method' must be a String");
    }
    throw const FormatException('Invalid Request message');
  }

  /// The method to invoke.
  final String method;

  /// The parameters for the method, if any.
  final Map<String, Object?>? params;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{'id': id, 'method': method, if (params != null) 'params': params};
  }
}

/// Represents a one-way notification that does not expect a response.
class Notification extends Message {
  /// Creates a [Notification] message.
  Notification({required this.method, this.params}) : super(id: null);

  /// Parses a [Notification] from a JSON-compatible map.
  ///
  /// Throws a [FormatException] if the map does not represent a valid notification.
  factory Notification.fromMap(Map<String, Object?> map) {
    if (map case {'method': final String method}) {
      final Object? params = map['params'];
      if (params != null && params is! Map<String, Object?>) {
        throw const FormatException("Notification message 'params' must be a Map<String, Object?>");
      }
      return Notification(method: method, params: params as Map<String, Object?>?);
    }
    throw const FormatException("Notification message 'method' must be a String");
  }

  /// The method associated with the notification.
  final String method;

  /// The parameters for the notification, if any.
  final Map<String, Object?>? params;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{'method': method, if (params != null) 'params': params};
  }
}

/// Represents a response to a [Request].
class Response extends Message {
  /// Creates a successful [Response] with the given [result].
  const Response.result({super.id, required this.result}) : error = null;

  /// Creates an error [Response] with the given [error].
  const Response.error({required this.error, super.id}) : result = null;

  /// Parses a [Response] from a JSON-compatible map.
  ///
  /// Throws a [FormatException] if the map does not represent a valid response.
  factory Response.fromMap(Map<String, Object?> map) {
    final Object? id = map['id'];
    if (id == null) {
      throw const FormatException("Response message is missing non-null 'id'");
    }

    final bool hasResult = map.containsKey('result');
    final bool hasError = map.containsKey('error');

    if (hasResult && hasError) {
      throw const FormatException("Response message cannot contain both 'result' and 'error'");
    }

    if (!hasResult && !hasError) {
      throw const FormatException("Response message must contain either 'result' or 'error'");
    }

    if (hasError) {
      final Object? errorMap = map['error'];
      if (errorMap is! Map<String, Object?>) {
        throw const FormatException("Response message 'error' must be a Map<String, Object?>");
      }
      return Response.error(id: id, error: RpcError.fromMap(errorMap));
    }

    return Response.result(id: id, result: map['result']);
  }

  /// The error, if the request failed.
  final RpcError? error;

  /// The result, if the request succeeded.
  final Object? result;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      if (error != null) 'error': error!.toMap() else 'result': result,
    };
  }
}

/// Represents an error returned in a [Response].
class RpcError {
  /// Creates an [RpcError] with the given [code] and [message].
  const RpcError({required this.code, required this.message, this.data});

  /// Parses an [RpcError] from a JSON-compatible map.
  ///
  /// Throws a [FormatException] if the map does not represent a valid error.
  factory RpcError.fromMap(Map<String, Object?> map) {
    if (map case {'code': final int code, 'message': final String message}) {
      return RpcError(code: code, message: message, data: map['data']);
    }
    if (map['code'] is! int) {
      throw const FormatException("RpcError 'code' must be an int");
    }
    if (map['message'] is! String) {
      throw const FormatException("RpcError 'message' must be a String");
    }
    throw const FormatException('Invalid RpcError message');
  }

  /// Creates a parse error [RpcError].
  const RpcError.parse({required Object error, Object? data})
    : this(code: parseErrorCode, message: 'Parse error: $error', data: data);

  /// Creates an invalid request [RpcError].
  const RpcError.invalidRequest({required String details, Object? data})
    : this(code: invalidRequestCode, message: 'Invalid request: $details', data: data);

  /// Creates a method not found [RpcError].
  const RpcError.methodNotFound({required String method, Object? data})
    : this(code: methodNotFoundCode, message: 'Method not found: $method', data: data);

  /// Creates an invalid params [RpcError].
  const RpcError.invalidParams({required String parameter, Object? data})
    : this(code: invalidParamsCode, message: 'Invalid params: $parameter', data: data);

  /// Creates an internal error [RpcError].
  const RpcError.internal({required Object error, Object? data})
    : this(code: internalErrorCode, message: 'Internal error: $error', data: data);

  /// The error code.
  final int code;

  /// Additional data about the error, if any.
  final Object? data;

  /// A message describing the error.
  final String message;

  // Standard JSON-RPC 2.0 error codes.
  static const int parseErrorCode = -32700;
  static const int invalidRequestCode = -32600;
  static const int methodNotFoundCode = -32601;
  static const int invalidParamsCode = -32602;
  static const int internalErrorCode = -32603;

  /// Converts this error to a JSON-compatible map.
  Map<String, Object?> toMap() {
    return <String, Object?>{'code': code, 'message': message, 'data': ?data};
  }
}
