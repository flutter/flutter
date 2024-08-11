// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// A response to a service protocol extension RPC.
///
/// If the RPC was successful, use [ServiceExtensionResponse.result], otherwise
/// use [ServiceExtensionResponse.error].
final class ServiceExtensionResponse {
  /// The result of a successful service protocol extension RPC.
  final String? result;

  /// The error code associated with a failed service protocol extension RPC.
  final int? errorCode;

  /// The details of a failed service protocol extension RPC.
  final String? errorDetail;

  /// Creates a successful response to a service protocol extension RPC.
  ///
  /// Requires [result] to be a JSON object encoded as a string. When forming
  /// the JSON-RPC message [result] will be inlined directly.
  ServiceExtensionResponse.result(String result)
      : result = result,
        errorCode = null,
        errorDetail = null {
    // TODO: When NNBD is complete, delete the following line.
    checkNotNullable(result, "result");
  }

  /// Creates an error response to a service protocol extension RPC.
  ///
  /// Requires [errorCode] to be [invalidParams] or between [extensionErrorMin]
  /// and [extensionErrorMax]. Requires [errorDetail] to be a JSON object
  /// encoded as a string. When forming the JSON-RPC message [errorDetail] will
  /// be inlined directly.
  ServiceExtensionResponse.error(int errorCode, String errorDetail)
      : result = null,
        errorCode = errorCode,
        errorDetail = errorDetail {
    _validateErrorCode(errorCode);
    // TODO: When NNBD is complete, delete the following line.
    checkNotNullable(errorDetail, "errorDetail");
  }

  /// Invalid method parameter(s) error code.
  static const invalidParams = -32602;

  /// Generic extension error code.
  static const extensionError = -32000;

  /// Maximum extension provided error code.
  static const extensionErrorMax = -32000;

  /// Minimum extension provided error code.
  static const extensionErrorMin = -32016;

  static String _errorCodeMessage(int errorCode) {
    _validateErrorCode(errorCode);
    if (errorCode == invalidParams) {
      return "Invalid params";
    }
    return "Server error";
  }

  static _validateErrorCode(int errorCode) {
    // TODO: When NNBD is complete, delete the following line.
    checkNotNullable(errorCode, "errorCode");
    if (errorCode == invalidParams) return;
    if ((errorCode >= extensionErrorMin) && (errorCode <= extensionErrorMax)) {
      return;
    }
    throw new ArgumentError.value(errorCode, "errorCode", "Out of range");
  }

  /// Determines if this response represents an error.
  bool isError() => (errorCode != null) && (errorDetail != null);

  // ignore: unused_element, called from runtime/lib/developer.dart
  String _toString() {
    return result ??
        json.encode({
          'code': errorCode!,
          'message': _errorCodeMessage(errorCode!),
          'data': {'details': errorDetail!}
        });
  }
}

/// A service protocol extension handler. Registered with [registerExtension].
///
/// Must complete to a [ServiceExtensionResponse]. [method] is the method name
/// of the service protocol request, and [parameters] is a map holding the
/// parameters to the service protocol request.
///
/// *NOTE*: all parameter names and values are encoded as strings.
typedef Future<ServiceExtensionResponse> ServiceExtensionHandler(
    String method, Map<String, String> parameters);

/// Register a [ServiceExtensionHandler] that will be invoked in this isolate
/// for [method]. *NOTE*: Service protocol extensions must be registered
/// in each isolate.
///
/// *NOTE*: [method] must begin with 'ext.' and you should use the following
/// structure to avoid conflicts with other packages: 'ext.package.command'.
/// That is, immediately following the 'ext.' prefix, should be the registering
/// package name followed by another period ('.') and then the command name.
/// For example: 'ext.dart.io.getOpenFiles'.
///
/// Because service extensions are isolate specific, clients using extensions
/// must always include an 'isolateId' parameter with each RPC.
void registerExtension(String method, ServiceExtensionHandler handler) {
  // TODO: When NNBD is complete, delete the following line.
  checkNotNullable(method, 'method');
  if (!method.startsWith('ext.')) {
    throw new ArgumentError.value(method, 'method', 'Must begin with ext.');
  }
  if (_lookupExtension(method) != null) {
    throw new ArgumentError('Extension already registered: $method');
  }
  // TODO: When NNBD is complete, delete the following line.
  checkNotNullable(handler, 'handler');
  final zoneHandler = Zone.current.bindBinaryCallback(handler);
  _registerExtension(method, zoneHandler);
}

/// Whether the "Extension" stream currently has at least one listener.
///
/// A client of the VM service can register as a listener
/// on the extension stream using `listenStream` method.
/// The extension stream has a listener while at least one such
/// client has registered as a listener, and has not yet disconnected
/// again.
///
/// Calling [postEvent] while the stream has listeners will attempt to
/// deliver that event to all current listeners,
/// although a listener can disconnect before the event is delivered.
/// Calling [postEvent] when the stream has no listener means that
/// no-one will receive the event, and the call is effectively a no-op.
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
@pragma("vm:idempotent")
@Since('2.18')
external bool get extensionStreamHasListener;

/// Post an event of [eventKind] with payload of [eventData] to the "Extension"
/// event stream.
///
/// If [extensionStreamHasListener] is false, this method is a no-op.
/// Override [stream] to set the destination stream that the event should be
/// posted to. The [stream] may not start with an underscore or be a core VM
/// Service stream.
void postEvent(String eventKind, Map eventData,
    {@Since('3.0 ') String stream = 'Extension'}) {
  const destinationStreamKey = '__destinationStream';
  // Keep protected streams in sync with `streams_` in runtime/vm/service.cc
  // `Extension` is the only stream that should not be protected here.
  final protectedStreams = <String>[
    'VM',
    'Isolate',
    'Debug',
    'GC',
    '_Echo',
    'HeapSnapshot',
    'Logging',
    'Timeline',
    'Profiler',
  ];

  if (protectedStreams.contains(stream)) {
    throw ArgumentError.value(
        stream, 'stream', 'Cannot be a protected stream.');
  } else if (stream.startsWith('_')) {
    throw ArgumentError.value(
        stream, 'stream', 'Cannot start with an underscore.');
  }

  if (!extensionStreamHasListener) {
    return;
  }
  // TODO: When NNBD is complete, delete the following two lines.
  checkNotNullable(eventKind, 'eventKind');
  checkNotNullable(eventData, 'eventData');
  checkNotNullable(stream, 'stream');
  Map mutableEventData = Map.from(eventData); // Shallow copy.
  mutableEventData[destinationStreamKey] = stream;
  String eventDataAsString = json.encode(mutableEventData);
  _postEvent(eventKind, eventDataAsString);
}

external void _postEvent(String eventKind, String eventData);

// Both of these functions are written inside C++ to avoid updating the data
// structures in Dart, getting an OOB, and observing stale state. Do not move
// these into Dart code unless you can ensure that the operations will can be
// done atomically. Native code lives in vm/isolate.cc-
// LookupServiceExtensionHandler and RegisterServiceExtensionHandler.
external ServiceExtensionHandler? _lookupExtension(String method);
external _registerExtension(String method, ServiceExtensionHandler handler);
