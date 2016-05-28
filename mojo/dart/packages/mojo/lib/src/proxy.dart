// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

/// The object that [ProxyMessageHandler.errorFuture] completes with when there
/// is an error.
class ProxyError {
  final String message;
  ProxyError(this.message);
  String toString() => "ProxyError: $message";
}

/// Generated ProxyControl classes implement this interface.
/// ProxyControl objects are accessible through the [ctrl] field on Proxies.
abstract class ProxyControl<T> implements ProxyMessageHandler {
  // TODO(zra): This is only used by ApplicationConnection.requestService(), so
  // try to remove when/after ApplicationConnection is removed/refactored.
  String get serviceName;

  // Currently we don't have impl hooked up to anything for Proxies, but we have
  // the field here so that there is a consistent interface with Stubs. By
  // having the field here we can also retain the option of hooking a proxy
  // up to something other than the remote implementation in the future.
  T impl;
}

/// Generated Proxy classes extend this base class.
class Proxy<T> implements MojoInterface<T> {
  // In general it's probalby better to avoid adding fields and methods to this
  // class. Names added to this class have to be mangled by Mojo bindings
  // generation to avoid name conflicts.

  /// Proxies control the ProxyMessageHandler by way of this [ProxyControl]
  /// object.
  final ProxyControl<T> ctrl;

  Proxy(this.ctrl);

  /// This is a convenience method that simply forwards to ctrl.close().
  /// If a Mojo interface has a method 'close', its name will be mangled to be
  /// 'close_'.
  Future close({bool immediate: false}) => ctrl.close(immediate: immediate);

  /// This is a convenience method that simply forwards to
  /// ctrl.responseOrError(). If a Mojo interface has a method
  /// 'responseOrError', its name will be mangled to be 'responseOrError_'.
  Future responseOrError(Future f) => ctrl.responseOrError(f);

  /// This getter and setter pair is for convenience and simply forwards to
  /// ctrl.impl. If a Mojo interface has a method 'close', its name will be
  /// mangled to be 'impl_'.
  T get impl => ctrl.impl;
  set impl(T impl) {
    ctrl.impl = impl;
  }
}

/// Generated Proxy classes have a factory Proxy.connectToService which takes
/// a ServiceConnector, a url, and optionally a service name and returns a
/// bound Proxy. For example, every class extending the Application base class
/// in package:mojo/application.dart inherits an implementation of the
/// ServiceConnector interface.
abstract class ServiceConnector {
  /// Connects [proxy] to the service called [serviceName] that lives at [url].
  void connectToService(String url, Proxy proxy, [String serviceName]);
}

abstract class ProxyMessageHandler extends core.MojoEventHandler
                                   implements MojoInterfaceControl {
  HashMap<int, Completer> _completerMap = new HashMap<int, Completer>();
  Completer _errorCompleter = new Completer();
  Set<Completer> _errorCompleters;
  int _nextId = 0;
  int _version = 0;
  int _pendingCount = 0;

  ProxyMessageHandler.fromEndpoint(core.MojoMessagePipeEndpoint endpoint)
      : super.fromEndpoint(endpoint);

  ProxyMessageHandler.fromHandle(core.MojoHandle handle)
      : super.fromHandle(handle);

  ProxyMessageHandler.unbound() : super.unbound();

  /// The function that handles responses to sent proxy message. It should be
  /// implemented by the generated ProxyControl classes that extend
  /// [ProxyMessageHandler].
  void handleResponse(ServiceMessage msg);

  /// If there is an error in using this proxy, this future completes with
  /// a ProxyError.
  Future get errorFuture => _errorCompleter.future;

  /// Version of this interface that the remote side supports. Updated when a
  /// call to [queryVersion] or [requireVersion] is made.
  int get version => _version;

  /// Returns a service description, which exposes the mojom type information
  /// of the service being proxied.
  /// Note: The description is null or incomplete if type info is unavailable.
  service_describer.ServiceDescription get description => null;

  @override
  void handleRead() {
    var result = endpoint.queryAndRead();
    if ((result.data == null) || (result.dataLength == 0)) {
      proxyError("Read from message pipe endpoint failed");
      return;
    }
    try {
      var message = new ServiceMessage.fromMessage(new Message(result.data,
          result.handles, result.dataLength, result.handlesLength));
      _pendingCount--;
      if (ControlMessageHandler.isControlMessage(message)) {
        _handleControlMessageResponse(message);
        return;
      }
      handleResponse(message);
    } on MojoCodecError catch (e) {
      proxyError(e.toString());
      close(immediate: true);
    }
  }

  @override
  void handleWrite() {
    proxyError("Unexpected writable signal");
  }

  @override
  Future close({bool immediate: false}) {
    // Drop the completers for outstanding calls. The Futures will never
    // complete.
    _completerMap.clear();

    // Signal to any pending calls that the ProxyMessageHandler is closed.
    if (_pendingCount > 0) {
      proxyError("The ProxyMessageHandler is closed.");
    }

    return super.close(immediate: immediate);
  }

  void sendMessage(Struct message, int name) {
    if (!isBound) {
      proxyError("The ProxyMessageHandler is closed.");
      return;
    }
    if (!isOpen) {
      beginHandlingEvents();
    }
    var header = new MessageHeader(name);
    var serviceMessage = message.serializeWithHeader(header);
    endpoint.write(serviceMessage.buffer, serviceMessage.buffer.lengthInBytes,
        serviceMessage.handles);
    if (endpoint.status != core.MojoResult.kOk) {
      proxyError("Write to message pipe endpoint failed.");
    }
  }

  Future sendMessageWithRequestId(Struct message, int name, int id, int flags) {
    var completer = new Completer();
    if (!isBound) {
      proxyError("The ProxyMessageHandler is closed.");
      return completer.future;
    }
    if (!isOpen) {
      beginHandlingEvents();
    }
    if (id == -1) {
      id = _nextId++;
    }

    var header = new MessageHeader.withRequestId(name, flags, id);
    var serviceMessage = message.serializeWithHeader(header);
    endpoint.write(serviceMessage.buffer, serviceMessage.buffer.lengthInBytes,
        serviceMessage.handles);

    if (endpoint.status == core.MojoResult.kOk) {
      _completerMap[id] = completer;
      _pendingCount++;
    } else {
      proxyError("Write to message pipe endpoint failed: ${endpoint}");
    }
    return completer.future;
  }

  // Need a getter for this for access in subclasses.
  HashMap<int, Completer> get completerMap => _completerMap;

  @override
  String toString() {
    var superString = super.toString();
    return "ProxyMessageHandler(${superString})";
  }

  /// Queries the max version that the remote side supports.
  /// Updates [version].
  Future<int> queryVersion() async {
    var params = new icm.RunMessageParams();
    params.reserved0 = 16;
    params.reserved1 = 0;
    params.queryVersion = new icm.QueryVersion();
    var response = await sendMessageWithRequestId(
        params, icm.kRunMessageId, -1, MessageHeader.kMessageExpectsResponse);
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
    // fails we may not have sent the RunOrClose message. Should
    // we reset _version in that case?
    sendMessage(params, icm.kRunOrClosePipeMessageId);
  }

  void proxyError(String msg) {
    if (!_errorCompleter.isCompleted) {
      errorFuture.whenComplete(() {
        _errorCompleter = new Completer();
      });
      _errorCompleter.complete(new ProxyError(msg));
    }
  }

  /// [responseOrError] returns a [Future] that completes to whatever [f]
  /// completes to unless [errorFuture] completes first. When [errorFuture]
  /// completes first, the [Future] returned by [responseOrError] completes with
  /// an error using the object that [errorFuture] completed with.
  ///
  /// Example usage:
  ///
  /// try {
  ///   result = await myProxy.responseOrError(myProxy.call(a,b,c));
  /// } catch (e) {
  ///   ...
  /// }
  Future responseOrError(Future f) {
    assert(f != null);
    if (_errorCompleters == null) {
      _errorCompleters = new Set<Completer>();
      errorFuture.then((e) {
        for (var completer in _errorCompleters) {
          assert(!completer.isCompleted);
          completer.completeError(e);
        }
        _errorCompleters.clear();
        _errorCompleters = null;
      });
    }

    Completer callCompleter = new Completer();
    f.then((callResult) {
      if (!callCompleter.isCompleted) {
        _errorCompleters.remove(callCompleter);
        callCompleter.complete(callResult);
      }
    });
    _errorCompleters.add(callCompleter);
    return callCompleter.future;
  }

  _handleControlMessageResponse(ServiceMessage message) {
    // We only expect to see Run messages.
    if (message.header.type != icm.kRunMessageId) {
      proxyError("Unexpected header type in control message response: "
          "${message.header.type}");
      return;
    }

    var response = icm.RunResponseMessageParams.deserialize(message.payload);
    if (!message.header.hasRequestId) {
      proxyError("Expected a message with a valid request Id.");
      return;
    }
    Completer c = completerMap[message.header.requestId];
    if (c == null) {
      proxyError("Message had unknown request Id: ${message.header.requestId}");
      return;
    }
    completerMap.remove(message.header.requestId);
    if (c.isCompleted) {
      proxyError("Control message response completer already completed");
      return;
    }
    c.complete(response);
  }
}
