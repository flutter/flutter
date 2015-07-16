// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/public/js/connection", [
  "mojo/public/js/bindings",
  "mojo/public/js/connector",
  "mojo/public/js/core",
  "mojo/public/js/router",
], function(bindings, connector, core, router) {

  var Router = router.Router;
  var EmptyProxy = bindings.EmptyProxy;
  var EmptyStub = bindings.EmptyStub;
  var ProxyBindings = bindings.ProxyBindings;
  var StubBindings = bindings.StubBindings;
  var TestConnector = connector.TestConnector;
  var TestRouter = router.TestRouter;

  // TODO(hansmuller): the proxy receiver_ property should be receiver$

  function BaseConnection(localStub, remoteProxy, router) {
    this.router_ = router;
    this.local = localStub;
    this.remote = remoteProxy;

    this.router_.setIncomingReceiver(localStub);
    if (this.remote)
      this.remote.receiver_ = router;

    // Validate incoming messages: remote responses and local requests.
    var validateRequest = localStub && localStub.validator;
    var validateResponse = remoteProxy && remoteProxy.validator;
    var payloadValidators = [];
    if (validateRequest)
      payloadValidators.push(validateRequest);
    if (validateResponse)
      payloadValidators.push(validateResponse);
    this.router_.setPayloadValidators(payloadValidators);
  }

  BaseConnection.prototype.close = function() {
    this.router_.close();
    this.router_ = null;
    this.local = null;
    this.remote = null;
  };

  BaseConnection.prototype.encounteredError = function() {
    return this.router_.encounteredError();
  };

  function Connection(
      handle, localFactory, remoteFactory, routerFactory, connectorFactory) {
    var routerClass = routerFactory || Router;
    var router = new routerClass(handle, connectorFactory);
    var remoteProxy = remoteFactory && new remoteFactory(router);
    var localStub = localFactory && new localFactory(remoteProxy);
    BaseConnection.call(this, localStub, remoteProxy, router);
  }

  Connection.prototype = Object.create(BaseConnection.prototype);

  // The TestConnection subclass is only intended to be used in unit tests.
  function TestConnection(handle, localFactory, remoteFactory) {
    Connection.call(this,
                    handle,
                    localFactory,
                    remoteFactory,
                    TestRouter,
                    TestConnector);
  }

  TestConnection.prototype = Object.create(Connection.prototype);

  // Return a handle for a message pipe that's connected to a proxy
  // for remoteInterface. Used by generated code for outgoing interface&
  // (request) parameters: the caller is given the generated proxy via
  // |proxyCallback(proxy)| and the generated code sends the handle
  // returned by this function.
  function bindProxy(proxyCallback, remoteInterface) {
    var messagePipe = core.createMessagePipe();
    if (messagePipe.result != core.RESULT_OK)
      throw new Error("createMessagePipe failed " + messagePipe.result);

    var proxy = new remoteInterface.proxyClass;
    var router = new Router(messagePipe.handle0);
    var connection = new BaseConnection(undefined, proxy, router);
    ProxyBindings(proxy).connection = connection;
    if (proxyCallback)
      proxyCallback(proxy);

    return messagePipe.handle1;
  }

  // Return a handle for a message pipe that's connected to a stub for
  // localInterface. Used by generated code for outgoing interface
  // parameters: the caller  is given the generated stub via
  // |stubCallback(stub)| and the generated code sends the handle
  // returned by this function. The caller is responsible for managing
  // the lifetime of the stub and for setting it's implementation
  // delegate with: StubBindings(stub).delegate = myImpl;
  function bindImpl(stubCallback, localInterface) {
    var messagePipe = core.createMessagePipe();
    if (messagePipe.result != core.RESULT_OK)
      throw new Error("createMessagePipe failed " + messagePipe.result);

    var stub = new localInterface.stubClass;
    var router = new Router(messagePipe.handle0);
    var connection = new BaseConnection(stub, undefined, router);
    StubBindings(stub).connection = connection;
    if (stubCallback)
      stubCallback(stub);

    return messagePipe.handle1;
  }

  // Return a remoteInterface proxy for handle. Used by generated code
  // for converting incoming interface parameters to proxies.
  function bindHandleToProxy(handle, remoteInterface) {
    if (!core.isHandle(handle))
      throw new Error("Not a handle " + handle);

    var proxy = new remoteInterface.proxyClass;
    var router = new Router(handle);
    var connection = new BaseConnection(undefined, proxy, router);
    ProxyBindings(proxy).connection = connection;
    return proxy;
  }

  // Return a localInterface stub for handle. Used by generated code
  // for converting incoming interface& request parameters to localInterface
  // stubs. The caller can specify the stub's implementation of localInterface
  // like this: StubBindings(stub).delegate = myStubImpl.
  function bindHandleToStub(handle, localInterface) {
    if (!core.isHandle(handle))
      throw new Error("Not a handle " + handle);

    var stub = new localInterface.stubClass;
    var router = new Router(handle);
    var connection = new BaseConnection(stub, undefined, router);
    StubBindings(stub).connection = connection;
    return stub;
  }

  var exports = {};
  exports.Connection = Connection;
  exports.TestConnection = TestConnection;

  exports.bindProxy = bindProxy;
  exports.bindImpl = bindImpl;
  exports.bindHandleToProxy = bindHandleToProxy;
  exports.bindHandleToStub = bindHandleToStub;
  return exports;
});
