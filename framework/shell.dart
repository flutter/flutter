// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "package:mojo/public/dart/application.dart";
import "dart:sky.internals" as internals;
import "dart:mojo.core" as core;
import "package:mojo/public/interfaces/application/service_provider.mojom.dart";

ApplicationConnection _initConnection() {
  int rawHandle = internals.takeServicesProvidedByEmbedder();
  core.MojoHandle proxyHandle = new core.MojoHandle(rawHandle);
  ServiceProviderProxy serviceProvider = null;
  if (proxyHandle.isValid)
    serviceProvider = new ServiceProviderProxy.fromHandle(proxyHandle);
  return new ApplicationConnection(null, serviceProvider);
}

final ApplicationConnection _connection = _initConnection();

void requestService(Object proxy) {
  _connection.requestService(proxy);
}
