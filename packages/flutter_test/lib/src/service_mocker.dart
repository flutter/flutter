// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:mojo/bindings.dart' as bindings;

// Tests can use ServiceMocker to register replacement implementations
// of Mojo services.
class ServiceMocker {
  ServiceMocker._() {
    shell.overrideConnectToService = _connectToService;
  }

  // Map of interface names to mock implementations.
  Map<String, Object> _interfaceMocks = <String, Object>{};

  bool _connectToService(String url, bindings.ProxyBase proxy) {
    Object mock = _interfaceMocks[proxy.serviceName];
    if (mock != null) {
      // Replace the proxy's implementation of the service interface with the
      // mock. The mojom bindings put the "ptr" field on all proxies.
      (proxy as dynamic).ptr = mock;
      return true;
    } else {
      return false;
    }
  }

  // Provide a mock implementation for a Mojo interface.
  // Make sure you initialise the binding before calling this.
  // For example, by calling `WidgetsFlutterBinding.ensureInitialized();`
  void registerMockService(String interfaceName, Object mock) {
    _interfaceMocks[interfaceName] = mock;
  }
}

final ServiceMocker serviceMocker = new ServiceMocker._();
