import 'package:flutter/src/services/shell.dart';
import 'package:mojo/bindings.dart' as bindings;

// Tests can use ServiceMocker to register replacement implementations
// of Mojo services.
class _ServiceMocker {
  _ServiceMocker() {
    shell.overrideConnectToService = _connectToService;
  }

  // Map of interface names to mock implementations.
  Map<String, Object> _interfaceMock = new Map<String, Object>();

  bool _connectToService(String url, bindings.ProxyBase proxy) {
    Object mock = _interfaceMock[proxy.serviceName];
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
  void registerMockService(String interfaceName, Object mock) {
    _interfaceMock[interfaceName] = mock;
  }
}

final _ServiceMocker serviceMocker = new _ServiceMocker();
