// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Manages connections with embedder-provided services.
library shell;

import 'dart:ui' as ui;

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as mojom;
import 'package:mojo/mojo/shell.mojom.dart' as mojom;

/// A replacement for shell.connectToService.  Implementations should return true
/// if they handled the request, or false if the request should fall through
/// to the default requestService.
typedef bool OverrideConnectToService(String url, Object proxy);

/// Manages connections with embedder-provided services.
class MojoShell {
  MojoShell() {
    assert(_instance == null);
    _instance = this;
  }

  /// The unique instance of this class.
  static MojoShell get instance => _instance;
  static MojoShell _instance;

  static mojom.ShellProxy _initShellProxy() {
    core.MojoHandle shellHandle = new core.MojoHandle(ui.takeShellProxyHandle());
    if (!shellHandle.isValid)
      return null;
    return new mojom.ShellProxy.fromHandle(shellHandle);
  }
  final mojom.Shell _shell = _initShellProxy()?.ptr;

  static ApplicationConnection _initEmbedderConnection() {
    core.MojoHandle servicesHandle = new core.MojoHandle(ui.takeServicesProvidedByEmbedder());
    core.MojoHandle exposedServicesHandle = new core.MojoHandle(ui.takeServicesProvidedToEmbedder());
    if (!servicesHandle.isValid || !exposedServicesHandle.isValid)
      return null;
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.fromHandle(servicesHandle);
    mojom.ServiceProviderStub exposedServices = new mojom.ServiceProviderStub.fromHandle(exposedServicesHandle);
    return new ApplicationConnection(exposedServices, services);
  }
  final ApplicationConnection _embedderConnection = _initEmbedderConnection();

  /// Whether [connectToApplication] is able to connect to other applications.
  bool get canConnectToOtherApplications => _shell != null;

  /// Attempts to connect to an application via the Mojo shell.
  ApplicationConnection connectToApplication(String url) {
    if (_shell == null)
      return null;
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.unbound();
    mojom.ServiceProviderStub exposedServices = new mojom.ServiceProviderStub.unbound();
    _shell.connectToApplication(url, services, exposedServices);
    return new ApplicationConnection(exposedServices, services);
  }

  /// Set this to intercept calls to [connectToService()] and supply an
  /// alternative implementation of a service (for example, a mock for testing).
  OverrideConnectToService overrideConnectToService;

  /// Attempts to connect to a service implementing the interface for the given proxy.
  /// If an application URL is specified, the service will be requested from that application.
  /// Otherwise, it will be requested from the embedder (the Flutter engine).
  void connectToService(String url, bindings.ProxyBase proxy) {
    if (overrideConnectToService != null && overrideConnectToService(url, proxy))
      return;
    if (url == null || _shell == null) {
      // If the application URL is null, it means the service to connect
      // to is one provided by the embedder.
      // If the applircation URL isn't null but there's no shell, then
      // ask the embedder in case it provides it. (For example, if you're
      // running on Android without the Mojo shell, then you can obtain
      // the media service from the embedder directly, instead of having
      // to ask the media application for it.)
      // This makes it easier to write an application that works both
      // with and without a Mojo environment.
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

  /// Registers a service to expose to the embedder.
  void provideService(String interfaceName, ServiceFactory factory) {
    _embedderConnection?.provideService(interfaceName, factory);
  }
}

/// The singleton object that manages connections with embedder-provided services.
MojoShell get shell => MojoShell.instance;
