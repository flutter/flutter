// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../annotations.dart';
import '../io_impl_js.dart';

String _stringFromIp(Uint8List bytes) {
  switch (bytes.length) {
    case 4:
      return bytes.map((item) => item.toString()).join('.');
    case 16:
      return _stringFromIp6(bytes);
    default:
      throw ArgumentError.value(bytes);
  }
}

String _stringFromIp6(Uint8List bytes) {
  // ---------------------------
  // Find longest span of zeroes
  // ---------------------------

  // Longest seen span
  int? longestStart;
  var longestLength = 0;

  // Current span
  int? start;
  var length = 0;

  // Iterate
  for (var i = 0; i < 16; i++) {
    if (bytes[i] == 0) {
      // Zero byte
      if (start == null) {
        if (i % 2 == 0) {
          // First byte of a span
          start = i;
          length = 1;
        }
      } else {
        length++;
      }
    } else if (start != null) {
      // End of a span
      if (length > longestLength) {
        // Longest so far
        longestStart = start;
        longestLength = length;
      }
      start = null;
    }
  }
  if (start != null && length > longestLength) {
    // End of the longest span
    longestStart = start;
    longestLength = length;
  }

  // Longest length must be a whole group
  longestLength -= longestLength % 2;

  // Ignore longest zero span if it's less than 4 bytes.
  if (longestLength < 4) {
    longestStart = null;
  }

  // ----
  // Print
  // -----
  final sb = StringBuffer();
  var colon = false;
  for (var i = 0; i < 16; i++) {
    if (i == longestStart) {
      sb.write('::');
      i += longestLength - 1;
      colon = false;
      continue;
    }
    final byte = bytes[i];
    if (i % 2 == 0) {
      //
      // First byte of a group
      //
      if (colon) {
        sb.write(':');
      } else {
        colon = true;
      }
      if (byte != 0) {
        sb.write(byte.toRadixString(16));
      }
    } else {
      //
      // Second byte of a group
      //
      // If this is a single-digit number and the previous byte was non-zero,
      // we must add zero
      if (byte < 16 && bytes[i - 1] != 0) {
        sb.write('0');
      }
      sb.write(byte.toRadixString(16));
    }
  }
  return sb.toString();
}

/// Parses IPv4/IPv6 address.
///
Uint8List? _tryParseRawAddress(String source) {
  // Find first '.' or ':'
  for (var i = 0; i < source.length; i++) {
    final c = source.substring(i, i + 1);
    switch (c) {
      case ':':
        return Uri.parseIPv6Address(source) as Uint8List;
      case '.':
        return Uri.parseIPv4Address(source) as Uint8List;
    }
  }
  return null;
}

InternetAddressType _type(String address) {
  for (var i = 0; i < address.length; i++) {
    final c = address.substring(i, i + 1);
    switch (c) {
      case ':':
        return InternetAddressType.IPv6;
      case '.':
        return InternetAddressType.IPv4;
    }
  }
  throw ArgumentError.value(address);
}

/// An internet address or a Unix domain address.
///
/// This object holds an internet address. If this internet address
/// is the result of a DNS lookup, the address also holds the hostname
/// used to make the lookup.
/// An Internet address combined with a port number represents an
/// endpoint to which a socket can connect or a listening socket can
/// bind.
class InternetAddress {
  /// IP version 4 any address. Use this address when listening on
  /// all adapters IP addresses using IP version 4 (IPv4).
  static final InternetAddress anyIPv4 = InternetAddress('0.0.0.0');

  /// IP version 6 any address. Use this address when listening on
  /// all adapters IP addresses using IP version 6 (IPv6).
  static final InternetAddress anyIPv6 = InternetAddress('::');

  /// IP version 4 loopback address. Use this address when listening on
  /// or connecting to the loopback adapter using IP version 4 (IPv4).
  static final InternetAddress loopbackIPv4 = InternetAddress('127.0.0.1');

  /// IP version 6 loopback address. Use this address when listening on
  /// or connecting to the loopback adapter using IP version 6 (IPv6).
  static final InternetAddress loopbackIPv6 = InternetAddress('::1');

  @Deprecated('Use anyIPv4 instead')
  static InternetAddress get ANY_IP_V4 => throw UnimplementedError();

  @Deprecated('Use anyIPv6 instead')
  static InternetAddress get ANY_IP_V6 => throw UnimplementedError();

  @Deprecated('Use loopbackIPv4 instead')
  static InternetAddress get LOOPBACK_IP_V4 => loopbackIPv4;

  @Deprecated('Use loopbackIPv6 instead')
  static InternetAddress get LOOPBACK_IP_V6 => loopbackIPv6;

  /// The numeric address of the host.
  ///
  /// For IPv4 addresses this is using the dotted-decimal notation.
  /// For IPv6 it is using the hexadecimal representation.
  /// For Unix domain addresses, this is a file path.
  final String address;

  /// The raw address of this [InternetAddress].
  ///
  /// For an IP address, the result is either a 4 or 16 byte long list.
  /// For a Unix domain address, UTF-8 encoded byte sequences that represents
  /// [address] is returned.
  ///
  /// The returned list is a fresh copy, making it possible to change the list without
  /// modifying the [InternetAddress].
  final Uint8List rawAddress;

  /// The address family of the [InternetAddress].
  final InternetAddressType type;

  /// Creates a new [InternetAddress] from a numeric address or a file path.
  ///
  /// If [type] is [InternetAddressType.IPv4], [address] must be a numeric IPv4
  /// address (dotted-decimal notation).
  /// If [type] is [InternetAddressType.IPv6], [address] must be a numeric IPv6
  /// address (hexadecimal notation).
  /// If [type] is [InternetAddressType.unix], [address] must be a a valid file
  /// path.
  /// If [type] is omitted, [address] must be either a numeric IPv4 or IPv6
  /// address and the type is inferred from the format.
  ///
  /// To create a Unix domain address, [type] should be
  /// [InternetAddressType.unix] and [address] should be a string.
  factory InternetAddress(String address,
      {@Since('2.8') InternetAddressType? type}) {
    if (type == InternetAddressType.unix) {
      if (!address.startsWith('/')) {
        throw ArgumentError.value(address, 'address');
      }
      return InternetAddress._(
        address: address,
        rawAddress: Uint8List(0),
        type: InternetAddressType.unix,
      );
    }
    final parsed = tryParse(address);
    if (parsed == null) {
      throw ArgumentError.value(address, 'address');
    }
    return parsed;
  }

  /// Creates a new [InternetAddress] from the provided raw address bytes.
  ///
  /// If the [type] is [InternetAddressType.IPv4], the [rawAddress] must have
  /// length 4.
  /// If the [type] is [InternetAddressType.IPv6], the [rawAddress] must have
  /// length 16.
  /// If the [type] is [InternetAddressType.IPv4], the [rawAddress] must be a
  /// valid UTF-8 encoded file path.
  ///
  /// If [type] is omitted, the [rawAddress] must have a length of either 4 or
  /// 16, in which case the type defaults to [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] respectively.
  factory InternetAddress.fromRawAddress(Uint8List rawAddress,
      {@Since('2.8') InternetAddressType? type}) {
    if (type == InternetAddressType.unix) {
      return InternetAddress(utf8.decode(rawAddress), type: type);
    }
    final address = _stringFromIp(rawAddress);
    type = _type(address);
    return InternetAddress._(
      address: address,
      rawAddress: rawAddress,
      type: type,
    );
  }

  InternetAddress._({
    required this.address,
    required this.rawAddress,
    required this.type,
  });

  @override
  int get hashCode => const ListEquality<int>().hash(rawAddress);

  /// The host used to lookup the address.
  ///
  /// If there is no host associated with the address this returns the [address].
  String get host => address;

  /// Returns true if the [InternetAddress]s scope is a link-local.
  bool get isLinkLocal {
    final rawAddress = this.rawAddress;
    if (type == InternetAddressType.IPv6) {
      // First 10 bits is 0xFE80
      return rawAddress[0] == 0xFE && ((0x80 | 0x40) & rawAddress[1]) == 0x80;
    }
    return false;
  }

  /// Returns true if the [InternetAddress] is a loopback address.
  bool get isLoopback => this == loopbackIPv4 || this == loopbackIPv6;

  /// Returns true if the [InternetAddress]s scope is multicast.
  bool get isMulticast => this == anyIPv4 || this == anyIPv6;

  @override
  bool operator ==(other) {
    if (other is InternetAddress) {
      if (type == InternetAddressType.unix) {
        return address == other.address;
      }
      return const ListEquality<int>().equals(rawAddress, other.rawAddress);
    }
    return false;
  }

  /// Perform a reverse DNS lookup on this [address]
  ///
  /// Returns a new [InternetAddress] with the same address, but where the [host]
  /// field set to the result of the lookup.
  ///
  /// If this address is Unix domain addresses, no lookup is performed and this
  /// address is returned directly.
  Future<InternetAddress> reverse() {
    throw UnimplementedError();
  }

  /// Lookup a host, returning a Future of a list of
  /// [InternetAddress]s. If [type] is [InternetAddressType.any], it
  /// will lookup both IP version 4 (IPv4) and IP version 6 (IPv6)
  /// addresses. If [type] is either [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] it will only lookup addresses of the
  /// specified type. The order of the list can, and most likely will,
  /// change over time.
  static Future<List<InternetAddress>> lookup(String host,
          {InternetAddressType type = InternetAddressType.any}) =>
      throw UnimplementedError();

  /// Attempts to parse [address] as a numeric address.
  ///
  /// Returns `null` If [address] is not a numeric IPv4 (dotted-decimal
  /// notation) or IPv6 (hexadecimal representation) address.
  static InternetAddress? tryParse(String address) {
    final rawAddress = _tryParseRawAddress(address);
    if (rawAddress == null) {
      return null;
    }
    final type = _type(address);
    return InternetAddress._(
      address: address,
      rawAddress: rawAddress,
      type: type,
    );
  }
}
