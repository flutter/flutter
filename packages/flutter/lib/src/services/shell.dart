// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_internals' as internals;

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart';
import 'package:mojo/mojo/shell.mojom.dart';

// A replacement for shell.connectToService.  Implementations should return true
// if they handled the request, or false if the request should fall through
// to the default requestService.
typedef bool OverrideConnectToService(String url, Object proxy);

// Set this to intercept calls to shell.connectToService and supply an
// alternative implementation of a service (for example, a mock for testing).
OverrideConnectToService overrideConnectToService;

ShellProxy _initShellProxy() {
  core.MojoHandle shellHandle = new core.MojoHandle(internals.takeShellProxyHandle());
  if (!shellHandle.isValid)
    return null;
  return new ShellProxy.fromHandle(shellHandle);
}

ApplicationConnection _initEmbedderConnection() {
  core.MojoHandle servicesHandle = new core.MojoHandle(internals.takeServicesProvidedByEmbedder());
  core.MojoHandle exposedServicesHandle = new core.MojoHandle(internals.takeServicesProvidedToEmbedder());
  if (!servicesHandle.isValid || !exposedServicesHandle.isValid)
    return null;
  ServiceProviderProxy services = new ServiceProviderProxy.fromHandle(servicesHandle);
  ServiceProviderStub exposedServices = new ServiceProviderStub.fromHandle(exposedServicesHandle);
  return new ApplicationConnection(exposedServices, services);
}

final ShellProxy _shellProxy = _initShellProxy();
final Shell _shell = _shellProxy?.ptr;
final ApplicationConnection _embedderConnection = _initEmbedderConnection();

class _Shell {
  _Shell._();

  ApplicationConnection connectToApplication(String url) {
    if (_shell == null)
      return null;
    ServiceProviderProxy services = new ServiceProviderProxy.unbound();
    ServiceProviderStub exposedServices = new ServiceProviderStub.unbound();
    _shell.connectToApplication(url, services, exposedServices);
    return new ApplicationConnection(exposedServices, services);
  }

  void _connectToService(String url, bindings.ProxyBase proxy) {
    if (_shell == null || url == null) {
      // If we don't have a shell or a url, we try to get the services from the
      // embedder directly instead of using the shell to connect.
      _embedderConnection?.requestService(proxy);
      return;
    }

    ServiceProviderProxy services = new ServiceProviderProxy.unbound();
    _shell.connectToApplication(url, services, null);
    var pipe = new core.MojoMessagePipe();
    proxy.impl.bind(pipe.endpoints[0]);
    services.ptr.connectToService(proxy.name, pipe.endpoints[1]);
    services.close();
  }

  void connectToService(String url, Object proxy) {
    if (overrideConnectToService != null && overrideConnectToService(url, proxy))
      return;
    _connectToService(url, proxy);
  }
}

final _Shell shell = new _Shell._();
