// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//
// Implementation of InternetAddress for Mojo.
//

patch class InternetAddress {
   /* patch */ static InternetAddress get LOOPBACK_IP_V4 {
     return _InternetAddress.LOOPBACK_IP_V4;
   }

   /* patch */ static InternetAddress get LOOPBACK_IP_V6 {
     return _InternetAddress.LOOPBACK_IP_V6;
   }

   /* patch */ static InternetAddress get ANY_IP_V4 {
     return _InternetAddress.ANY_IP_V4;
   }

   /* patch */ static InternetAddress get ANY_IP_V6 {
     return _InternetAddress.ANY_IP_V6;
   }

   /* patch */ factory InternetAddress(String address) {
     return new _InternetAddress.parse(address);
   }

   /* patch */ static Future<List<InternetAddress>> lookup(
      String host, {InternetAddressType type: InternetAddressType.ANY}) {
    return _MojoInternetAddress._lookup(host, type);
  }
}

class _InternetAddress implements InternetAddress {
  static const int _ADDRESS_LOOPBACK_IP_V4 = 0;
  static const int _ADDRESS_LOOPBACK_IP_V6 = 1;
  static const int _ADDRESS_ANY_IP_V4 = 2;
  static const int _ADDRESS_ANY_IP_V6 = 3;
  static const int _IPV4_ADDR_LENGTH = 4;
  static const int _IPV6_ADDR_LENGTH = 16;

  static _InternetAddress LOOPBACK_IP_V4 =
      new _InternetAddress.fixed(_ADDRESS_LOOPBACK_IP_V4);
  static _InternetAddress LOOPBACK_IP_V6 =
      new _InternetAddress.fixed(_ADDRESS_LOOPBACK_IP_V6);
  static _InternetAddress ANY_IP_V4 =
      new _InternetAddress.fixed(_ADDRESS_ANY_IP_V4);
  static _InternetAddress ANY_IP_V6 =
      new _InternetAddress.fixed(_ADDRESS_ANY_IP_V6);

  final String address;
  final String _host;
  final Uint8List _in_addr;

  InternetAddressType get type =>
      _in_addr.length == _IPV4_ADDR_LENGTH ? InternetAddressType.IP_V4
                                           : InternetAddressType.IP_V6;

  String get host => _host != null ? _host : address;

  List<int> get rawAddress => new Uint8List.fromList(_in_addr);

  bool get isLoopback {
    switch (type) {
      case InternetAddressType.IP_V4:
        return _in_addr[0] == 127;

      case InternetAddressType.IP_V6:
        for (int i = 0; i < _IPV6_ADDR_LENGTH - 1; i++) {
          if (_in_addr[i] != 0) return false;
        }
        return _in_addr[_IPV6_ADDR_LENGTH - 1] == 1;
    }
  }

  bool get isLinkLocal {
    switch (type) {
      case InternetAddressType.IP_V4:
        // Checking for 169.254.0.0/16.
        return _in_addr[0] == 169 && _in_addr[1] == 254;

      case InternetAddressType.IP_V6:
        // Checking for fe80::/10.
        return _in_addr[0] == 0xFE && (_in_addr[1] & 0xB0) == 0x80;
    }
  }

  bool get isMulticast {
    switch (type) {
      case InternetAddressType.IP_V4:
        // Checking for 224.0.0.0 through 239.255.255.255.
        return _in_addr[0] >= 224 && _in_addr[0] < 240;

      case InternetAddressType.IP_V6:
        // Checking for ff00::/8.
        return _in_addr[0] == 0xFF;
    }
  }

  Future<InternetAddress> reverse() {
    var result = _reverse(this._in_addr);
    if (result[0] == 0) {
      // Success.
      return new Future.value(
          new _InternetAddress(this.address, result[1], this._in_addr));
    } else {
      // Failure. Throw an error.
      throw new OSError(result[1], result[0]);
    }
  }

  static _reverse(List address) native "InternetAddress_Reverse";

  _InternetAddress(String this.address,
                   String this._host,
                   List<int> this._in_addr);

  factory _InternetAddress.parse(String address) {
    if (address is !String) {
      throw new ArgumentError("Invalid internet address $address");
    }
    var in_addr = _parse(address);
    if (in_addr == null) {
      throw new ArgumentError("Invalid internet address $address");
    }
    return new _InternetAddress(address, null, in_addr);
  }

  factory _InternetAddress.fixed(int id) {
    switch (id) {
      case _ADDRESS_LOOPBACK_IP_V4:
        var in_addr = new Uint8List(_IPV4_ADDR_LENGTH);
        in_addr[0] = 127;
        in_addr[_IPV4_ADDR_LENGTH - 1] = 1;
        return new _InternetAddress("127.0.0.1", null, in_addr);
      case _ADDRESS_LOOPBACK_IP_V6:
        var in_addr = new Uint8List(_IPV6_ADDR_LENGTH);
        in_addr[_IPV6_ADDR_LENGTH - 1] = 1;
        return new _InternetAddress("::1", null, in_addr);
      case _ADDRESS_ANY_IP_V4:
        var in_addr = new Uint8List(_IPV4_ADDR_LENGTH);
        return new _InternetAddress("0.0.0.0", "0.0.0.0", in_addr);
      case _ADDRESS_ANY_IP_V6:
        var in_addr = new Uint8List(_IPV6_ADDR_LENGTH);
        return new _InternetAddress("::", "::", in_addr);
      default:
        assert(false);
        throw new ArgumentError();
    }
  }

  // Create a clone of this _InternetAddress replacing the host.
  _InternetAddress _cloneWithNewHost(String host) {
    return new _InternetAddress(
        address, host, new Uint8List.fromList(_in_addr));
  }

  bool operator ==(other) {
    if (!(other is _InternetAddress)) return false;
    if (other.type != type) return false;
    bool equals = true;
    for (int i = 0; i < _in_addr.length && equals; i++) {
      equals = other._in_addr[i] == _in_addr[i];
    }
    return equals;
  }

  int get hashCode {
    int result = 1;
    for (int i = 0; i < _in_addr.length; i++) {
      result = (result * 31 + _in_addr[i]) & 0x3FFFFFFF;
    }
    return result;
  }

  String toString() {
    return "InternetAddress('$address', ${type.name})";
  }

  // TODO(johnmccutchan): This should be implemented in Dart.
  static Uint8List _parse(String address) native "InternetAddress_Parse";
}

int _internetAddressTypeToAddressFamily(InternetAddressType type) {
  if (type == null) {
    return NetAddressFamily_UNSPECIFIED;
  }
  if (type == InternetAddressType.IP_V4) {
    return NetAddressFamily_IPV4;
  } else if (type == InternetAddressType.IP_V6) {
    return NetAddressFamily_IPV6;
  }
  return NetAddressFamily_UNSPECIFIED;
}

class _MojoInternetAddress {
  static Future _lookup(String host, InternetAddressType type) async {
    HostResolverProxy hostResolver = _getHostResolver();
    var family = _internetAddressTypeToAddressFamily(type);
    var response = await hostResolver.ptr.getHostAddresses(host, family);
    _NetworkService._throwOnError(response.result);
    var numAddresses = response.addresses.length;
    var r = new List(numAddresses);
    for (var i = 0; i < numAddresses; i++) {
      r[i] = _NetworkServiceCodec._fromNetAddress(response.addresses[i]);
    }
    return r;
  }
}
