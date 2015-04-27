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
}

// Generated Proxy classes implement this interface.
abstract class ProxyBase {
  final Proxy impl = null;
  final String name = null;
}
