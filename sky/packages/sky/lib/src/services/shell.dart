// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky.internals' as internals;

import 'package:mojo/application.dart';
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart';

import 'embedder.dart';

ApplicationConnection _initConnection() {
  int rawHandle = internals.takeServicesProvidedByEmbedder();
  core.MojoHandle proxyHandle = new core.MojoHandle(rawHandle);
  ServiceProviderProxy serviceProvider = null;
  if (proxyHandle.isValid) serviceProvider =
      new ServiceProviderProxy.fromHandle(proxyHandle);
  return new ApplicationConnection(null, serviceProvider);
}

// A replacement for requestService.  Implementations should return true
// if they handled the request, or false if the request should fall through
// to the default requestService.
typedef bool OverrideRequestService(String url, Object proxy);

// Set this to intercept calls to requestService and supply an alternative
// implementation of a service (for example, a mock for testing).
OverrideRequestService overrideRequestService;

class _ShellImpl {
  _ShellImpl._();

  final ApplicationConnection _connection = _initConnection();

  void _requestService(String url, Object proxy) {
    if (embedder.shell == null) _connection.requestService(proxy);
    else embedder.connectToService(url, proxy);
  }

  void requestService(String url, Object proxy) {
    if (overrideRequestService != null) {
      if (overrideRequestService(url, proxy))
        return;
    }

    _requestService(url, proxy);
  }
}

final _ShellImpl shell = new _ShellImpl._();
