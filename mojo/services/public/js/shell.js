// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define("mojo/services/public/js/shell", [
  "mojo/public/js/bindings",
  "mojo/public/js/core",
  "mojo/public/js/connection",
  "mojo/public/interfaces/application/shell.mojom",
  "mojo/public/interfaces/application/service_provider.mojom",
  "mojo/services/public/js/service_exchange",
], function(bindings, core, connection, shellMojom, spMojom, serviceExchange) {

  const ProxyBindings = bindings.ProxyBindings;
  const StubBindings = bindings.StubBindings;
  const ServiceExchange = serviceExchange.ServiceExchange;
  const ServiceProviderInterface = spMojom.ServiceProvider;
  const ShellInterface = shellMojom.Shell;

  class Shell {
    constructor(shellProxy) {
      this.shellProxy = shellProxy;
      this.applications_ = new Map();
    }

    connectToApplication(url) {
      var application = this.applications_.get(url);
      if (application)
        return application;

      var application = new ServiceExchange();
      this.shellProxy.connectToApplication(url,
          function(servicesProxy) {
            application.proxy = servicesProxy;
          },
          function(exposedServicesStub) {
            application.stub = exposedServicesStub;
            StubBindings(exposedServicesStub).delegate = application;
          });
      this.applications_.set(url, application);
      return application;
    }

    connectToService(url, service) {
      return this.connectToApplication(url).requestService(service);
    };

    close() {
      this.applications_.forEach(function(application, url) {
        application.close();
      });
      ProxyBindings(this.shellProxy).close();
      this.applications_.clear();
    }
  }

  var exports = {};
  exports.Shell = Shell;
  return exports;
});
