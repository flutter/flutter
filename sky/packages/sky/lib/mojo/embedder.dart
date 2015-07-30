// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:sky.internals" as internals;

import "package:mojo/application.dart";
import "package:mojo/bindings.dart" as bindings;
import "package:mojo/core.dart" as core;
import "package:mojom/mojo/service_provider.mojom.dart";
import "package:mojom/mojo/service_registry.mojom.dart";
import "package:mojom/mojo/shell.mojom.dart";

final _EmbedderImpl embedder = new _EmbedderImpl();

class _EmbedderImpl {
  ApplicationConnection _connection;
  ServiceRegistryProxy _serviceRegistry;
  ShellProxy _shell;
  bool _internalsHasNoShell = false;

  ShellProxy get shell {
    if (_internalsHasNoShell || _shell != null) return _shell;

    try {
      _shell = new ShellProxy.fromHandle(
          new core.MojoHandle(internals.takeShellProxyHandle()));
    } catch (e) {
      _internalsHasNoShell = true;
    }
    return _shell;
  }

  ApplicationConnection get connection {
    if (_connection == null) {
      var stubHandle =
          new core.MojoHandle(internals.takeServicesProvidedToEmbedder());
      var proxyHandle =
          new core.MojoHandle(internals.takeServicesProvidedByEmbedder());
      _connection = new ApplicationConnection(stubHandle.isValid
          ? new ServiceProviderStub.fromHandle(stubHandle)
          : null, proxyHandle.isValid
          ? new ServiceProviderProxy.fromHandle(proxyHandle)
          : null);
    }
    return _connection;
  }

  ApplicationConnection connectToApplication(String url) {
    var proxy = new ServiceProviderProxy.unbound();
    var stub = new ServiceProviderStub.unbound();
    shell.ptr.connectToApplication(url, proxy, stub);
    return new ApplicationConnection(stub, proxy);
  }

  void connectToService(String url, bindings.ProxyBase proxy) {
    var appSp = new ServiceProviderProxy.unbound();
    shell.ptr.connectToApplication(url, appSp, null);
    var pipe = new core.MojoMessagePipe();
    proxy.impl.bind(pipe.endpoints[0]);
    appSp.ptr.connectToService(proxy.name, pipe.endpoints[1]);
    appSp.close();
  }

  ServiceRegistryProxy get serviceRegistry {
    if (_serviceRegistry == null) {
      _serviceRegistry = new ServiceRegistryProxy.fromHandle(
          new core.MojoHandle(internals.takeServiceRegistry()));
    }
    return _serviceRegistry;
  }
}
