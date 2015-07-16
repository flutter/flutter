// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:_mojo/application.dart';
import 'dart:_mojo/bindings.dart';
import 'dart:_mojo/core.dart';
import 'dart:_mojom/mojo/host_resolver.mojom.dart';
import 'dart:_mojom/mojo/net_address.mojom.dart';
import 'dart:_mojom/mojo/network_error.mojom.dart';
import 'dart:_mojom/mojo/network_service.mojom.dart';
import 'dart:_mojom/mojo/tcp_bound_socket.mojom.dart';
import 'dart:_mojom/mojo/tcp_connected_socket.mojom.dart';
import 'dart:_mojom/mojo/tcp_server_socket.mojom.dart';

//
// Mojo objects and helper functions used by the 'dart:io' library.
//
int _networkServiceHandle;
NetworkServiceProxy _networkService;
HostResolverProxy _hostResolver;

void _initialize(int h) {
  _networkServiceHandle = h;
}

void _shutdown() {
  if (_networkServiceHandle != null) {
    // Network service proxies were never initialized. Create a handle
    // and close it.
    var handle = new MojoHandle(_networkServiceHandle);
    _networkServiceHandle = null;
    handle.close();
    return;
  }
  _closeProxies();
}

/// Close any active proxies.
_closeProxies() {
  if (_networkService != null) {
    _networkService.close(immediate: true);
    _networkService = null;
  }
  if (_hostResolver != null) {
    _hostResolver.close(immediate: true);
    _hostResolver = null;
  }
}

/// Get the singleton NetworkServiceProxy.
NetworkServiceProxy _getNetworkService() {
  if (_networkService != null) {
    return _networkService;
  }
  _networkService = new NetworkServiceProxy.fromHandle(
      new MojoHandle(_networkServiceHandle).pass());
  _networkServiceHandle = null;
  return _networkService;
}

/// Get the singleton HostResolverProxy.
HostResolverProxy _getHostResolver() {
  if (_hostResolver != null) {
    return _hostResolver;
  }
  var networkService = _getNetworkService();
  if (networkService == null) {
    return null;
  }
  _hostResolver = new HostResolverProxy.unbound();
  networkService.ptr.createHostResolver(_hostResolver);
  return _hostResolver;
}

/// Static utility methods for converting between 'dart:io' and
/// 'mojo:network_service' structs.
class _NetworkServiceCodec {
  /// Returns a string representation of an ip address encoded in [address].
  /// Supports both IPv4 and IPv6.
  static String _addressToString(List<int> address) {
    String r = '';
    if (address == null) {
      return r;
    }
    bool ipv4 = address.length == 4;
    if (ipv4) {
      for (var i = 0; i < 4; i++) {
        var digit = address[i].toString();
        var divider = (i != 3) ? '.' : '';
        r += '${digit}${divider}';
      }
    } else {
      for (var i = 0; i < 16; i++) {
        var digit = address[i].toRadixString(16);
        var divider = (i != 15) ? ':' : '';
        r += '${digit}${divider}';
      }
    }
    return r;
  }

  /// Convert from [NetAddress] to [InternetAddress].
  static InternetAddress _fromNetAddress(NetAddress netAddress) {
    if (netAddress == null) {
      return null;
    }
    var address;
    if (netAddress.family == NetAddressFamily_IPV4) {
      address = netAddress.ipv4.addr;
    } else if (netAddress.family == NetAddressFamily_IPV6) {
      address = netAddress.ipv6.addr;
    } else {
      return null;
    }
    assert(address != null);
    var addressString = _addressToString(address);
    return new InternetAddress(addressString);
  }

  static int _portFromNetAddress(NetAddress netAddress) {
    if (netAddress == null) {
      return null;
    }
    if (netAddress.family == NetAddressFamily_IPV4) {
      return netAddress.ipv4.port;
    } else if (netAddress.family == NetAddressFamily_IPV6) {
      return netAddress.ipv6.port;
    } else {
      return null;
    }
  }

  /// Convert from [InternetAddress] to [NetAddress].
  static NetAddress _fromInternetAddress(InternetAddress internetAddress,
                                         [port]) {
    if (internetAddress == null) {
      return null;
    }
    var netAddress = new NetAddress();
    var rawAddress = internetAddress.rawAddress;
    if (rawAddress.length == 4) {
      netAddress.family = NetAddressFamily_IPV4;
      netAddress.ipv4 = new NetAddressIPv4();
      netAddress.ipv4.addr = new List.from(rawAddress, growable: false);
      if (port != null) {
        netAddress.ipv4.port = port;
      }
    } else {
      assert(rawAddress.length == 16);
      netAddress.family = NetAddressFamily_IPV6;
      netAddress.ipv6 = new NetAddressIPv6();
      netAddress.ipv6.addr = new List.from(rawAddress, growable: false);
      if (port != null) {
        netAddress.ipv6.port = port;
      }
    }
    return netAddress;
  }
}

/// Static utility methods for dealing with 'mojo:network_service'.
class _NetworkService {
  /// Return a [NetAddress] for localhost:port.
  static NetAddress _localhostIpv4([int port = 0]) {
    var addr = new NetAddress();
    addr.family = NetAddressFamily_IPV4;
    addr.ipv4 = new NetAddressIPv4();
    addr.ipv4.addr = [127, 0, 0, 1];
    addr.ipv4.port = port;
    return addr;
  }

  /// Return a [NetAddress] for localhost:port.
  static NetAddress _localHostIpv6([int port = 0]) {
    var addr = new NetAddress();
    addr.family = NetAddressFamily_IPV6;
    addr.ipv6 = new NetAddressIPv6();
    addr.ipv6.addr = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];
    addr.ipv6.port = port;
    return addr;
  }

  static bool _okay(NetworkError error) {
    if (error == null) {
      return true;
    }
    return error.code == 0;
  }

  static _throwOnError(NetworkError error) {
    if (_okay(error)) {
      return;
    }
    throw new OSError(error.description, error.code);
  }
}

