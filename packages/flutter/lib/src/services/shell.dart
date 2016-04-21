// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as mojom;
import 'package:mojo/mojo/shell.mojom.dart' as mojom;

/// Signature for replacements for [shell.connectToService]. Implementations
/// should return true if they handled the request, or false if the request
/// should fall through to the default requestService.
typedef bool OverrideConnectToService(String url, Object proxy);

/// Manages connections with embedder-provided services.
class MojoShell {
  /// Creates the MojoShell singleton. This constructor can only be called once.
  /// If your application uses bindings, it is called by the [ServicesBinding] binding.
  /// (See [BindingBase] for more details on bindings. Any application using
  /// the Flutter 'rendering' or 'widgets' libraries uses a binding.)
  MojoShell() {
    assert(_instance == null);
    _instance = this;
  }

  /// The unique instance of this class.
  static MojoShell get instance => _instance;
  static MojoShell _instance;

  static mojom.ShellProxy _initShellProxy() {
    core.MojoHandle shellHandle = new core.MojoHandle(ui.MojoServices.takeShell());
    if (!shellHandle.isValid)
      return null;
    return new mojom.ShellProxy.fromHandle(shellHandle);
  }
  final mojom.Shell _shell = _initShellProxy()?.ptr;

  static ApplicationConnection _initEmbedderConnection() {
    core.MojoHandle incomingServicesHandle = new core.MojoHandle(ui.MojoServices.takeIncomingServices());
    core.MojoHandle outgoingServicesHandle = new core.MojoHandle(ui.MojoServices.takeOutgoingServices());
    if (!incomingServicesHandle.isValid || !outgoingServicesHandle.isValid)
      return null;
    mojom.ServiceProviderProxy incomingServices = new mojom.ServiceProviderProxy.fromHandle(incomingServicesHandle);
    mojom.ServiceProviderStub outgoingServices = new mojom.ServiceProviderStub.fromHandle(outgoingServicesHandle);
    return new ApplicationConnection(outgoingServices, incomingServices);
  }
  final ApplicationConnection _embedderConnection = _initEmbedderConnection();

  /// Whether [connectToApplication] is able to connect to other applications.
  bool get canConnectToOtherApplications => _shell != null;

  /// Attempts to connect to an application via the Mojo shell.
  ///
  /// Returns null if [canConnectToOtherApplications] is false.
  ApplicationConnection connectToApplication(String url) {
    if (_shell == null)
      return null;
    mojom.ServiceProviderProxy services = new mojom.ServiceProviderProxy.unbound();
    mojom.ServiceProviderStub exposedServices = new mojom.ServiceProviderStub.unbound();
    _shell.connectToApplication(url, services, exposedServices);
    return new ApplicationConnection(exposedServices, services);
  }

  /// Interceptor for calls to [connectToService] and
  /// [connectToViewAssociatedService] so that tests can supply alternative
  /// implementations of services (for example, a mock for testing).
  OverrideConnectToService overrideConnectToService;

  /// Attempts to connect to a service implementing the interface for the given
  /// proxy. If an application URL is specified and
  /// [canConnectToOtherApplications] is true, the service will be requested
  /// from that application. Otherwise, it will be requested from the embedder
  /// (the Flutter engine).
  ///
  /// For example, suppose there was a service of type `Foo` that was normally
  /// hosted with the URL "mojo:foo" and that was also provided by the Flutter
  /// embedder when there is no shell (i.e. when [canConnectToOtherApplications]
  /// returns false). The following code (assuming the relevant mojom file
  /// declaring `Foo` was imported with the prefix `mojom`) would connect to it,
  /// and then invoke the method `bar()` on it:
  ///
  /// ```dart
  /// mojom.FooProxy foo = new mojom.FooProxy.unbound();
  /// shell.connectToService("mojo:foo", foo);
  /// foo.ptr.bar();
  /// ```
  ///
  /// For examples of mojom files, see the `sky_services` package.
  ///
  /// See also [connectToViewAssociatedService].
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

  static mojom.ServiceProviderProxy _takeViewServices() {
    core.MojoHandle services = new core.MojoHandle(ui.MojoServices.takeViewServices());
    if (!services.isValid)
      return null;
    return new mojom.ServiceProviderProxy.fromHandle(services);
  }
  final mojom.ServiceProviderProxy _viewServices = _takeViewServices();

  /// Attempts to connect to a service provided specifically for the current
  /// view by the embedder or host platform.
  ///
  /// For example, keyboard services are specific to a view; you can only
  /// receive keyboard input when the application's view is the one with focus.
  ///
  /// For example, suppose there was a service of type `Foo` that was provided
  /// on a view-by-view basis by the embedder or host platform. The following
  /// code (assuming the relevant mojom file declaring `Foo` was imported with
  /// the prefix `mojom`) would connect to it, and then invoke the method
  /// `bar()` on it:
  ///
  /// ```dart
  /// mojom.FooProxy foo = new mojom.FooProxy.unbound();
  /// shell.connectToViewAssociatedService(foo);
  /// foo.ptr.bar();
  /// ```
  ///
  /// For examples of mojom files, see the `sky_services` package.
  ///
  /// See also [connectToService].
  void connectToViewAssociatedService(bindings.ProxyBase proxy) {
    if (overrideConnectToService != null && overrideConnectToService(null, proxy))
      return;
    if (_viewServices == null)
      return;
    core.MojoMessagePipe pipe = new core.MojoMessagePipe();
    proxy.impl.bind(pipe.endpoints[0]);
    _viewServices.ptr.connectToService(proxy.serviceName, pipe.endpoints[1]);
  }

  /// Registers a service to expose to the embedder.
  /// 
  /// For example, suppose a Flutter application wanted to provide a service
  /// `Foo` to the embedder, that a mojom file declaring `Foo` was imported with
  /// the prefix `mojom`, that `package:mojo/core.dart` was imported with the
  /// prefix `core`, and that an implementation of the `Foo` service existed in
  /// the class `MyFooImplementation`. The following code, run during the
  /// binding initialization (i.e. during the same call stack as the call to the
  /// [new MojoShell] constructor) would achieve this:
  /// 
  /// ```dart
  /// shell.provideService(mojom.Foo.serviceName, (core.MojoMessagePipeEndpoint endpoint) {
  ///   mojom.FooStub foo = new mojom.FooStub.fromEndpoint(endpoint);
  ///   foo.impl = new MyFooImplementation();
  /// });
  /// ```
  void provideService(String interfaceName, ServiceFactory factory) {
    _embedderConnection?.provideService(interfaceName, factory);
  }
}

/// The singleton object that manages connections with embedder-provided services.
MojoShell get shell => MojoShell.instance;
