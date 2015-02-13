// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "/mojo/public/dart/application.dart";
import "dart:mojo_bindings" as bindings;
import "dart:mojo_core" as core;
import "dart:sky.internals" as internals;
import "package:mojo/public/interfaces/application/service_provider.mojom.dart";
import "package:mojo/public/interfaces/application/shell.mojom.dart";

final ShellProxy _shell = new ShellProxy.fromHandle(
    new core.MojoHandle(internals.passShellProxyHandle()));

ApplicationConnection connectToApplication(String url) {
  var serviceProviderProxy = new ServiceProviderProxy.unbound();
  _shell.connectToApplication(url, serviceProviderProxy, null);
  return new ApplicationConnection(serviceProviderProxy);
}

void connectToService(String url, bindings.Proxy proxy) {
  connectToApplication(url).connectToService(proxy);
}
