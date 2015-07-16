// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/services/public/js/service_exchange", [
  "mojo/public/js/bindings",
  "mojo/public/interfaces/application/service_provider.mojom",
  "mojo/public/js/connection",
], function(bindings, spMojom, connection) {

  const ProxyBindings = bindings.ProxyBindings;
  const StubBindings = bindings.StubBindings;
  const ServiceProviderInterface = spMojom.ServiceProvider;

  function checkServiceExchange(exch) {
    if (!exch.providers_)
      throw new Error("Service was closed");
  }

  class ServiceExchange {
    constructor(servicesRequest, exposedServicesProxy) {
      this.proxy = exposedServicesProxy;
      this.providers_ = new Map(); // serviceName => see provideService() below
      this.pendingRequests_ = new Map(); // serviceName => serviceHandle
      if (servicesRequest)
        StubBindings(servicesRequest).delegate = this;
    }

    // Incoming requests
    connectToService(serviceName, serviceHandle) {
      if (!this.providers_) // We're closed.
        return;

      var provider = this.providers_.get(serviceName);
      if (!provider) {
        this.pendingRequests_.set(serviceName, serviceHandle);
        return;
      }

      var stub = connection.bindHandleToStub(serviceHandle, provider.service);
      StubBindings(stub).delegate = new provider.factory();
      provider.connections.push(StubBindings(stub).connection);
    }

    provideService(service, factory) {
      checkServiceExchange(this);

      var provider = {
        service: service, // A JS bindings interface object.
        factory: factory, // factory() => interface implemntation
        connections: [],
      };
      this.providers_.set(service.name, provider);

      if (this.pendingRequests_.has(service.name)) {
        this.connectToService(service.name, pendingRequests_.get(service.name));
        pendingRequests_.delete(service.name);
      }
      return this;
    }

    // Outgoing requests
    requestService(interfaceObject) {
      checkServiceExchange(this);
      if (!interfaceObject.name)
        throw new Error("Invalid service parameter");

      var serviceProxy;
      var serviceHandle = connection.bindProxy(
          function(sp) {serviceProxy = sp;}, interfaceObject);
      this.proxy.connectToService(interfaceObject.name, serviceHandle);
      return serviceProxy;
    };

    close() {
      this.providers_ = null;
      this.pendingRequests_ = null;
    }
  }

  var exports = {};
  exports.ServiceExchange = ServiceExchange;
  return exports;
});
