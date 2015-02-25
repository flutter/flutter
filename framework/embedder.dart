// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "/mojo/public/dart/application.dart";
import "dart:sky.internals" as internals;
import "mojo:bindings" as bindings;
import "mojo:core" as core;
import "package:mojo/public/interfaces/application/service_provider.mojom.dart";
import "package:mojo/public/interfaces/application/shell.mojom.dart";

final _EmbedderImpl embedder = new _EmbedderImpl();

class _EmbedderImpl {
  ApplicationConnection _connection;

  final ShellProxy shell = new ShellProxy.fromHandle(
      new core.MojoHandle(internals.takeShellProxyHandle()));

  ApplicationConnection get connection {
    if (_connection == null) {
      var stubHandle = new core.MojoHandle(
          internals.takeServicesProvidedToEmbedder());
      var proxyHandle = new core.MojoHandle(
          internals.takeServicesProvidedByEmbedder());
      _connection = new ApplicationConection(
         stubHandle.isValid ? ServiceProviderStub.fromHandle(stubHandle)
             : null;
         proxyHandle.isValid ? ServiceProviderProxy.fromHandle(proxyHandle)
             : null;
      );
    }
    return _connection;
  }

  ApplicationConnection connectToApplication(String url) {
    var proxy = new ServiceProviderProxy.unbound();
    var stub = new ServiceProviderStub.unbound();
    shell.connectToApplication(url, proxy, stub);
    return new ApplicationConnection(stub, proxy);
  }

  void connectToService(String url, bindings.Proxy proxy) {
    var appSp = new ServiceProviderProxy.unbound();
    shell.connectToApplication(url, appSp, null);
    var pipe = new core.MojoMessagePipe();
    proxy.bind(pipe.endpoints[0]);
    appSp.connectToService(proxy.name, pipe.endpoints[1]);
    appSp.close();
  }
}

