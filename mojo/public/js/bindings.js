// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/public/js/bindings", [
  "mojo/public/js/router",
  "mojo/public/js/core",
], function(router, core) {

  var Router = router.Router;

  var kProxyProperties = Symbol("proxyProperties");
  var kStubProperties = Symbol("stubProperties");

  // Public proxy class properties that are managed at runtime by the JS
  // bindings. See ProxyBindings below.
  function ProxyProperties(receiver) {
    this.receiver = receiver;
  }

  // TODO(hansmuller): remove then after 'Client=' has been removed from Mojom.
  ProxyProperties.prototype.getLocalDelegate = function() {
    return this.local && StubBindings(this.local).delegate;
  }

  // TODO(hansmuller): remove then after 'Client=' has been removed from Mojom.
  ProxyProperties.prototype.setLocalDelegate = function(impl) {
    if (this.local)
      StubBindings(this.local).delegate = impl;
    else
      throw new Error("no stub object");
  }

  function connectionHandle(connection) {
    return connection &&
        connection.router &&
        connection.router.connector_ &&
        connection.router.connector_.handle_;
  }

  ProxyProperties.prototype.close = function() {
    var handle = connectionHandle(this.connection);
    if (handle)
      core.close(handle);
  }

  // Public stub class properties that are managed at runtime by the JS
  // bindings. See StubBindings below.
  function StubProperties(delegate) {
    this.delegate = delegate;
  }

  StubProperties.prototype.close = function() {
    var handle = connectionHandle(this.connection);
    if (handle)
      core.close(handle);
  }

  // The base class for generated proxy classes.
  function ProxyBase(receiver) {
    this[kProxyProperties] = new ProxyProperties(receiver);

    // TODO(hansmuller): Temporary, for Chrome backwards compatibility.
    if (receiver instanceof Router)
      this.receiver_ = receiver;
  }

  // The base class for generated stub classes.
  function StubBase(delegate) {
    this[kStubProperties] = new StubProperties(delegate);
  }

  // TODO(hansmuller): remove everything except the connection property doc
  // after 'Client=' has been removed from Mojom.

  // Provides access to properties added to a proxy object without risking
  // Mojo interface name collisions. Unless otherwise specified, the initial
  // value of all properties is undefined.
  //
  // ProxyBindings(proxy).connection - The Connection object that links the
  //   proxy for a remote Mojo service to an optional local stub for a local
  //   service. The value of ProxyBindings(proxy).connection.remote == proxy.
  //
  // ProxyBindings(proxy).local  - The "local" stub object whose delegate
  //   implements the proxy's Mojo client interface.
  //
  // ProxyBindings(proxy).setLocalDelegate(impl) - Sets the implementation
  //   delegate of the proxy's client stub object. This is just shorthand
  //   for |StubBindings(ProxyBindings(proxy).local).delegate = impl|.
  //
  // ProxyBindings(proxy).getLocalDelegate() - Returns the implementation
  //   delegate of the proxy's client stub object. This is just shorthand
  //   for |StubBindings(ProxyBindings(proxy).local).delegate|.

  function ProxyBindings(proxy) {
    return (proxy instanceof ProxyBase) ? proxy[kProxyProperties] : proxy;
  }

  // TODO(hansmuller): remove the remote doc after 'Client=' has been
  // removed from Mojom.

  // Provides access to properties added to a stub object without risking
  // Mojo interface name collisions. Unless otherwise specified, the initial
  // value of all properties is undefined.
  //
  // StubBindings(stub).delegate - The optional implementation delegate for
  //  the Mojo interface stub.
  //
  // StubBindings(stub).connection - The Connection object that links an
  //   optional proxy for a remote service to this stub. The value of
  //   StubBindings(stub).connection.local == stub.
  //
  // StubBindings(stub).remote - A proxy for the the stub's Mojo client
  //   service.

  function StubBindings(stub) {
    return stub instanceof StubBase ?  stub[kStubProperties] : stub;
  }

  var exports = {};
  exports.EmptyProxy = ProxyBase;
  exports.EmptyStub = StubBase;
  exports.ProxyBase = ProxyBase;
  exports.ProxyBindings = ProxyBindings;
  exports.StubBase = StubBase;
  exports.StubBindings = StubBindings;
  return exports;
});