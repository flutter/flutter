// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

/// Error codes defined in the [JSON-RPC 2.0 specificiation][spec].
///
/// These codes are generally used for protocol-level communication. Most of
/// them shouldn't be used by the application. Those that should have
/// convenience constructors in [RpcException].
///
/// [spec]: http://www.jsonrpc.org/specification#error_object
/// An error code indicating that invalid JSON was received by the server.
const PARSE_ERROR = -32700;

/// An error code indicating that the request JSON was invalid according to the
/// JSON-RPC 2.0 spec.
const INVALID_REQUEST = -32600;

/// An error code indicating that the requested method does not exist or is
/// unavailable.
const METHOD_NOT_FOUND = -32601;

/// An error code indicating that the request parameters are invalid for the
/// requested method.
const INVALID_PARAMS = -32602;

/// An internal JSON-RPC error.
const INTERNAL_ERROR = -32603;

/// An unexpected error occurred on the server.
///
/// The spec reserves the range from -32000 to -32099 for implementation-defined
/// server exceptions, but for now we only use one of those values.
const SERVER_ERROR = -32000;

/// Returns a human-readable name for [errorCode] if it's one specified by the
/// JSON-RPC 2.0 spec.
///
/// If [errorCode] isn't defined in the JSON-RPC 2.0 spec, returns null.
String? name(int errorCode) {
  switch (errorCode) {
    case PARSE_ERROR:
      return 'parse error';
    case INVALID_REQUEST:
      return 'invalid request';
    case METHOD_NOT_FOUND:
      return 'method not found';
    case INVALID_PARAMS:
      return 'invalid parameters';
    case INTERNAL_ERROR:
      return 'internal error';
    default:
      return null;
  }
}
