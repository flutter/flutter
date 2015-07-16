// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

class ProxyCloseException {
  final String message;
  ProxyCloseException(this.message);
  String toString() => message;
}

abstract class Proxy extends core.MojoEventStreamListener {
  Map<int, Completer> _completerMap;
  int _nextId = 0;
  int _version = 0;
  /// Version of this interface that the remote side supports. Updated when a
  /// call to [queryVersion] or [requireVersion] is made.
  int get version => _version;

  Proxy.fromEndpoint(core.MojoMessagePipeEndpoint endpoint)
      : _completerMap = {},
        super.fromEndpoint(endpoint);

  Proxy.fromHandle(core.MojoHandle handle)
      : _completerMap = {},
        super.fromHandle(handle);

  Proxy.unbound()
      : _completerMap = {},
        super.unbound();

  void handleResponse(ServiceMessage reader);

  void handleRead() {
    // Query how many bytes are available.
    var result = endpoint.query();
    assert(result.status.isOk || result.status.isResourceExhausted);

    // Read the data.
    var bytes = new ByteData(result.bytesRead);
    var handles = new List<core.MojoHandle>(result.handlesRead);
    result = endpoint.read(bytes, result.bytesRead, handles);
    assert(result.status.isOk || result.status.isResourceExhausted);
    var message = new ServiceMessage.fromMessage(new Message(bytes, handles));
    if (ControlMessageHandler.isControlMessage(message)) {
      _handleControlMessageResponse(message);
      return;
    }
    handleResponse(message);
  }

  void handleWrite() {
    throw 'Unexpected write signal in proxy.';
  }

  @override
  Future close({bool immediate: false}) {
    for (var completer in _completerMap.values) {
      completer.completeError(new ProxyCloseException('Proxy closed'));
    }
    _completerMap.clear();
    return super.close(immediate: immediate);
  }

  void sendMessage(Struct message, int name) {
    if (!isOpen) {
      listen();
    }
    var header = new MessageHeader(name);
    var serviceMessage = message.serializeWithHeader(header);
    endpoint.write(serviceMessage.buffer,
        serviceMessage.buffer.lengthInBytes, serviceMessage.handles);
    if (!endpoint.status.isOk) {
      throw "message pipe write failed - ${endpoint.status}";
    }
  }

  Future sendMessageWithRequestId(Struct message, int name, int id, int flags) {
    if (!isOpen) {
      listen();
    }
    if (id == -1) {
      id = _nextId++;
    }

    var header = new MessageHeader.withRequestId(name, flags, id);
    var serviceMessage = message.serializeWithHeader(header);
    endpoint.write(serviceMessage.buffer,
        serviceMessage.buffer.lengthInBytes, serviceMessage.handles);
    if (!endpoint.status.isOk) {
      throw "message pipe write failed - ${endpoint.status}";
    }

    var completer = new Completer();
    _completerMap[id] = completer;
    return completer.future;
  }

  // Need a getter for this for access in subclasses.
  Map<int, Completer> get completerMap => _completerMap;

  String toString() {
    var superString = super.toString();
    return "Proxy(${superString})";
  }

  /// Queries the max version that the remote side supports.
  /// Updates [version].
  Future<int> queryVersion() async {
    var params = new icm.RunMessageParams();
    params.reserved0 = 16;
    params.reserved1 = 0;
    params.queryVersion = new icm.QueryVersion();
    var response = await
        sendMessageWithRequestId(params,
                                 icm.kRunMessageId,
                                 -1,
                                 MessageHeader.kMessageExpectsResponse);
    _version = response.queryVersionResult.version;
    return _version;
  }

  /// If the remote side doesn't support the [requiredVersion], it will close
  /// its end of the message pipe asynchronously. This does nothing if it's
  /// already known that the remote side supports [requiredVersion].
  /// Updates [version].
  void requireVersion(int requiredVersion) {
    if (requiredVersion <= _version) {
      // Already supported.
      return;
    }

    // If the remote end doesn't close the pipe, we know that it supports
    // required version.
    _version = requiredVersion;

    var params = new icm.RunOrClosePipeMessageParams();
    params.reserved0 = 16;
    params.reserved1 = 0;
    params.requireVersion = new icm.RequireVersion();
    params.requireVersion.version = requiredVersion;
    // TODO(johnmccutchan): We've set _version above but if this sendMessage
    // throws an exception we may not have sent the RunOrClose message. Should
    // we reset _version in that case?
    sendMessage(params, icm.kRunOrClosePipeMessageId);
  }

  _handleControlMessageResponse(ServiceMessage message) {
    // We only expect to see Run messages.
    assert(message.header.type == icm.kRunMessageId);
    var response = icm.RunResponseMessageParams.deserialize(message.payload);
    if (!message.header.hasRequestId) {
      throw 'Expected a message with a valid request Id.';
    }
    Completer c = completerMap[message.header.requestId];
    if (c == null) {
      throw 'Message had unknown request Id: ${message.header.requestId}';
    }
    completerMap.remove(message.header.requestId);
    assert(!c.isCompleted);
    c.complete(response);
  }
}

// Generated Proxy classes implement this interface.
abstract class ProxyBase {
  final Proxy impl = null;
  final String name = null;
}
