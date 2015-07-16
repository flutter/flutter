// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/services/public/js/application", [
  "mojo/public/js/bindings",
  "mojo/public/js/core",
  "mojo/public/js/connection",
  "mojo/public/js/threading",
  "mojo/public/interfaces/application/application.mojom",
  "mojo/services/public/js/service_exchange",
  "mojo/services/public/js/shell",
], function(bindings, core, connection, threading, applicationMojom, serviceExchange, shell) {

  const ApplicationInterface = applicationMojom.Application;
  const ProxyBindings = bindings.ProxyBindings;
  const ServiceExchange = serviceExchange.ServiceExchange;
  const Shell = shell.Shell;

  class Application {
    constructor(appRequestHandle, url) {
      this.url = url;
      this.serviceExchanges = [];
      this.appRequestHandle_ = appRequestHandle;
      this.appStub_ =
          connection.bindHandleToStub(appRequestHandle, ApplicationInterface);
      bindings.StubBindings(this.appStub_).delegate = {
          initialize: this.doInitialize.bind(this),
          acceptConnection: this.doAcceptConnection.bind(this),
      };
    }

    doInitialize(shellProxy, args, url) {
      this.shellProxy_ = shellProxy;
      this.shell = new Shell(shellProxy);
      this.initialize(args);
    }

    initialize(args) {
    }

    // Implements AcceptConnection() from Application.mojom. Calls
    // this.acceptConnection() with a JS ServiceExchange instead of a pair
    // of Mojo ServiceProviders.
    doAcceptConnection(requestorUrl, servicesRequest, exposedServicesProxy) {
      var serviceExchange =
        new ServiceExchange(servicesRequest, exposedServicesProxy);
      this.serviceExchanges.push(serviceExchange);
      this.acceptConnection(requestorUrl, serviceExchange);
    }

    // Subclasses override this method to request or provide services for
    // ConnectToApplication() calls from requestorURL.
    acceptConnection(requestorUrl, serviceExchange) {
    }

    quit() {
      this.serviceExchanges.forEach(function(exch) {
        exch.close();
      });
      this.shell.close();
      core.close(this.appRequestHandle_);
      threading.quit();
    }
  }

  var exports = {};
  exports.Application = Application;
  return exports;
});
