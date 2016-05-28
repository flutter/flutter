// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:mojo/bindings.dart' as bindings;

import 'binding.dart';

class _MockServiceConnector extends bindings.ServiceConnector {
  String serviceName;

  @override
  void connectToService(String url, bindings.Proxy<dynamic> proxy, [String serviceName]) {
    this.serviceName = serviceName;
  }
}

/// Tests can use [ServiceMocker] to register replacement implementations
/// of Mojo services.
class ServiceMocker {
  ServiceMocker._() {
    TestWidgetsFlutterBinding.ensureInitialized();
    shell.overrideConnectToService = _connectToService;
  }

  // Map of interface names to mock implementations.
  Map<String, bindings.Proxy<dynamic>> _interfaceMocks = <String, bindings.Proxy<dynamic>>{};

  bindings.Proxy<dynamic> _connectToService(String url, ServiceConnectionCallback callback) {
    // TODO(abarth): This is quite awkward. See <https://github.com/domokit/mojo/issues/786>.
    _MockServiceConnector connector = new _MockServiceConnector();
    callback(connector, url);
    return _interfaceMocks[connector.serviceName];
  }

  /// Provide a mock implementation for a Mojo interface.
  void registerMockService(bindings.Proxy<dynamic> mock) {
    _interfaceMocks[mock.ctrl.serviceName] = mock;
  }
}

/// Instance of the utility class for providing mocks for tests.
///
/// The first time this variable is accessed, it will initialize the
/// [TestWidgetsFlutterBinding] if necessary.
final ServiceMocker serviceMocker = new ServiceMocker._();
