// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_internals' as internals;

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as mojom;
import 'package:mojo/mojo/shell.mojom.dart' as mojom;

// A replacement for shell.connectToService.  Implementations should return true
// if they handled the request, or false if the request should fall through
// to the default requestService.
typedef bool OverrideConnectToService(String url, Object proxy);

class MojoShell {
  MojoShell._();

  static mojom.ShellProxy _initShellProxy() {
    core.MojoHandle shellHandle = new core.MojoHandle(internals.takeShellProxyHandle());
    if (!shellHandle.isValid)
      return null;
    return new mojom.ShellProxy.fromHandle(shellHandle);
  }
  static final mojom.Shell _shell = _initShellProxy()?.ptr;

  static ApplicationConnection _initEmbedderConnection() {
    core.MojoHandle servicesHandle = new core.MojoHandle(internals.takeServicesProvidedByEmbedder());
    core.MojoHandle exposedServicesHandle = new core.MojoHandle(internals.takeServicesProvidedToEmbedder());
    if (!servicesHandle.isValid || !exposedServicesHandle.isValid)
      return null;
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.fromHandle(servicesHandle);
    mojom.ServiceProviderStub exposedServices = new mojom.ServiceProviderStub.fromHandle(exposedServicesHandle);
    return new ApplicationConnection(exposedServices, services);
  }
  static final ApplicationConnection _embedderConnection = _initEmbedderConnection();

  ApplicationConnection connectToApplication(String url) {
    if (_shell == null)
      return null;
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.unbound();
    mojom.ServiceProviderStub exposedServices = new mojom.ServiceProviderStub.unbound();
    _shell.connectToApplication(url, services, exposedServices);
    return new ApplicationConnection(exposedServices, services);
  }

  // Set this to intercept calls to shell.connectToService and supply an
  // alternative implementation of a service (for example, a mock for testing).
  OverrideConnectToService overrideConnectToService;

  void connectToService(String url, bindings.ProxyBase proxy) {
    if (overrideConnectToService != null && overrideConnectToService(url, proxy))
      return;
    _connectToService(url, proxy);
  }

  void _connectToService(String url, bindings.ProxyBase proxy) {
    if (_shell == null || url == null) {
      // If we don't have a shell or a url, we try to get the services from the
      // embedder directly instead of using the shell to connect.
      _embedderConnection?.requestService(proxy);
      return;
    }
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.unbound();
    _shell.connectToApplication(url, services, null);
    core.MojoMessagePipe pipe = new core.MojoMessagePipe();
    proxy.impl.bind(pipe.endpoints[0]);
    services.ptr.connectToService(proxy.serviceName, pipe.endpoints[1]);
    services.close();
  }
}
final MojoShell shell = new MojoShell._();
