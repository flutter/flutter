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

  /// By default, a Proxy's calls are "implemented" by a remote service. Before
  /// binding, this field can be set to an alternate implementation of the
  /// service that may be local.
  T impl;
}

/// Generated Proxy classes extend this base class.
class Proxy<T> implements MojoInterface<T> {
  // In general it's probalby better to avoid adding fields and methods to this
  // class. Names added to this class have to be mangled by Mojo bindings
  // generation to avoid name conflicts.

  /// Proxies control the ProxyMessageHandler by way of this [ProxyControl]
  /// object. If a Mojo interface has a method 'ctrl', its name will be
  /// mangled to be 'ctrl_'.
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
  /// ctrl.impl. If a Mojo interface has a method 'impl', its name will be
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
  HashMap<int, Function> _callbackMap = new HashMap<int, Function>();
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
    // Drop the callbacks for outstanding calls. They will never be called.
    _callbackMap.clear();

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

  void sendMessageWithRequestId(
      Struct message, int name, int id, int flags, Function callback) {
    if (!isBound) {
      proxyError("The Proxy is closed.");
      return;
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
      _callbackMap[id] = callback;
      _pendingCount++;
    } else {
      proxyError("Write to message pipe endpoint failed: ${endpoint}");
    }
  }

  Function getCallback(ServiceMessage message) {
    if (!message.header.hasRequestId) {
      proxyError("Expected a message with a valid request Id.");
      return null;
    }
    int requestId = message.header.requestId;
    if (!_callbackMap.containsKey(requestId)) {
      proxyError("Message had unknown request Id: $requestId");
      return null;
    }
    Function callback = _callbackMap[requestId];
    _callbackMap.remove(requestId);
    return callback;
  }

  @override
  String toString() {
    var superString = super.toString();
    return "ProxyMessageHandler(${superString})";
  }

  /// Queries the max version that the remote side supports.
  /// Updates [version].
  Future<int> queryVersion() {
    Completer<int> completer = new Completer<int>();
    var params = new icm.RunMessageParams();
    params.reserved0 = 16;
    params.reserved1 = 0;
    params.queryVersion = new icm.QueryVersion();
    sendMessageWithRequestId(
        params, icm.kRunMessageId, -1, MessageHeader.kMessageExpectsResponse,
        (r0, r1, queryResult) {
      _version = queryResult.version;
      completer.complete(_version);
    });
    return completer.future;
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
    Function callback = _callbackMap[message.header.requestId];
    if (callback == null) {
      proxyError("Message had unknown request Id: ${message.header.requestId}");
      return;
    }
    _callbackMap.remove(message.header.requestId);
    callback(
        response.reserved0, response.reserved1, response.queryVersionResult);
    return;
  }
}

// The interface implemented by a class that can implement a function with up
// to 20 unnamed arguments.
abstract class _GenericFunction implements Function {
  const _GenericFunction();

  // Work-around to avoid checked-mode only having grudging support for
  // Function implemented with noSuchMethod. See:
  // https://github.com/dart-lang/sdk/issues/26528
  dynamic call([
      dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5,
      dynamic a6, dynamic a7, dynamic a8, dynamic a9, dynamic a10,
      dynamic a11, dynamic a12, dynamic a13, dynamic a14, dynamic a15,
      dynamic a16, dynamic a17, dynamic a18, dynamic a19, dynamic a20]);
}

// A class that acts like a function, but which completes a completer with the
// the result of the function rather than returning the result. E.g.:
//
// Completer c = new Completer();
// var completerator = new Completerator._(c, f);
// completerator(a, b);
// await c.future;
//
// This completes the future c with the result of passing a and b to f.
//
// More usefully for Mojo, e.g.:
// await _Completerator.completerate(
//     proxy.method, argList, MethodResponseParams#init);
class _Completerator extends _GenericFunction {
  final Completer _c;
  final Function _toComplete;

  _Completerator._(this._c, this._toComplete);

  static Future completerate(Function f, List args, Function ctor) {
    Completer c = new Completer();
    var newArgs = new List.from(args);
    newArgs.add(new _Completerator._(c, ctor));
    Function.apply(f, newArgs);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      (invocation.memberName == #call)
      ? _c.complete(Function.apply(_toComplete, invocation.positionalArguments))
      : super.noSuchMethod(invocation);
}

/// Base class for Proxy class Futurizing wrappers. It turns callback-based
/// methods on the Proxy into Future based methods in derived classes. E.g.:
///
/// class FuturizedHostResolverProxy extends FuturizedProxy<HostResolverProxy> {
///   Map<Symbol, Function> _mojoMethods;
///
///   FuturizedHostResolverProxy(HostResolverProxy proxy) : super(proxy) {
///     _mojoMethods = <Symbol, Function>{
///       #getHostAddresses: proxy.getHostAddresses,
///     };
///   }
///   Map<Symbol, Function> get mojoMethods => _mojoMethods;
///
///   FuturizedHostResolverProxy.unbound() :
///       this(new HostResolverProxy.unbound());
///
///   static final Map<Symbol, Function> _mojoResponses = {
///     #getHostAddresses: new HostResolverGetHostAddressesResponseParams#init,
///   };
///   Map<Symbol, Function> get mojoResponses => _mojoResponses;
/// }
///
/// Then:
///
/// HostResolveProxy proxy = ...
/// var futurizedProxy = new FuturizedHostResolverProxy(proxy);
/// var response = await futurizedProxy.getHostAddresses(host, family);
/// // etc.
///
/// Warning 1: The list of methods and return object constructors in
/// FuturizedHostResolverProxy has to be kept up-do-date by hand with changes
/// to the Mojo interface.
///
/// Warning 2: The recommended API to use is the generated callback-based API.
/// This wrapper class is exposed only for convenience during development,
/// and has no guarantee of optimal performance.
abstract class FuturizedProxy<T extends Proxy> {
  final T _proxy;
  Map<Symbol, Function> get mojoMethods;
  Map<Symbol, Function> get mojoResponses;

  FuturizedProxy(T this._proxy);

  T get proxy => _proxy;
  Future responseOrError(Future f) => _proxy.responseOrError(f);
  Future close({immediate: false}) => _proxy.close(immediate: immediate);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      mojoMethods.containsKey(invocation.memberName)
          ? _Completerator.completerate(
              mojoMethods[invocation.memberName],
              invocation.positionalArguments,
              mojoResponses[invocation.memberName])
          : super.noSuchMethod(invocation);
}

/// A class that acts like a function that can take up to 20 arguments, and
/// does nothing.
///
/// This class is used in the generated bindings to allow null to be passed for
/// the callback to interface methods implemented by mock services where the
/// result of the method is not needed.
class DoNothingFunction extends _GenericFunction {
  // TODO(zra): DoNothingFunction could rather be implemented just by a function
  // taking some large number of dynamic arguments as we're doing already in
  // _GenericFunction. However, instead of duplicating that hack, we should
  // keep it in once place, and extend from _GenericFunction when we need to
  // use it. Then, if/when there's better support for this sort of thing, we
  // can replace _GenericFunction and propagate any changes needed to things
  // that use it.

  const DoNothingFunction();

  static const DoNothingFunction fn = const DoNothingFunction();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #call) {
      return super.noSuchMethod(invocation);
    }
    return null;
  }
}
