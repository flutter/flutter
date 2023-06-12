// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../error_code.dart' as error_code;

/// An exception from a JSON-RPC server that can be translated into an error
/// response.
class RpcException implements Exception {
  /// The error code.
  ///
  /// All non-negative error codes are available for use by application
  /// developers.
  final int code;

  /// The error message.
  ///
  /// This should be limited to a concise single sentence. Further information
  /// should be supplied via [data].
  final String message;

  /// Extra application-defined information about the error.
  ///
  /// This must be a JSON-serializable object. If it's a [Map] without a
  /// `"request"` key, a copy of the request that caused the error will
  /// automatically be injected.
  final Object? data;

  RpcException(this.code, this.message, {this.data});

  /// An exception indicating that the method named [methodName] was not found.
  ///
  /// This should usually be used only by fallback handlers.
  RpcException.methodNotFound(String methodName)
      : this(error_code.METHOD_NOT_FOUND, 'Unknown method "$methodName".');

  /// An exception indicating that the parameters for the requested method were
  /// invalid.
  ///
  /// Methods can use this to reject requests with invalid parameters.
  RpcException.invalidParams(String message)
      : this(error_code.INVALID_PARAMS, message);

  /// Converts this exception into a JSON-serializable object that's a valid
  /// JSON-RPC 2.0 error response.
  Map<String, dynamic> serialize(request) {
    dynamic modifiedData;
    if (data is Map && !(data as Map).containsKey('request')) {
      modifiedData = Map.from(data as Map);
      modifiedData['request'] = request;
    } else if (data == null) {
      modifiedData = {'request': request};
    } else {
      modifiedData = data;
    }

    var id = request is Map ? request['id'] : null;
    if (id is! String && id is! num) id = null;
    return {
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message, 'data': modifiedData},
      'id': id
    };
  }

  @override
  String toString() {
    var prefix = 'JSON-RPC error $code';
    var errorName = error_code.name(code);
    if (errorName != null) prefix += ' ($errorName)';
    return '$prefix: $message';
  }
}
