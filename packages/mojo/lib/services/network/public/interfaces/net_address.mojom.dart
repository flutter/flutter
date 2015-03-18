// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library net_address.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;

final int NetAddressFamily_UNSPECIFIED = 0;
final int NetAddressFamily_IPV4 = NetAddressFamily_UNSPECIFIED + 1;
final int NetAddressFamily_IPV6 = NetAddressFamily_IPV4 + 1;


class NetAddressIPv4 extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int port = 0;
  List<int> addr = null;

  NetAddressIPv4() : super(kStructSize);

  static NetAddressIPv4 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NetAddressIPv4 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NetAddressIPv4 result = new NetAddressIPv4();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.port = decoder0.decodeUint16(8);
    }
    {
      
      result.addr = decoder0.decodeUint8Array(16, bindings.kNothingNullable, 4);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint16(port, 8);
    
    encoder0.encodeUint8Array(addr, 16, bindings.kNothingNullable, 4);
  }

  String toString() {
    return "NetAddressIPv4("
           "port: $port" ", "
           "addr: $addr" ")";
  }
}

class NetAddressIPv6 extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int port = 0;
  List<int> addr = null;

  NetAddressIPv6() : super(kStructSize);

  static NetAddressIPv6 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NetAddressIPv6 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NetAddressIPv6 result = new NetAddressIPv6();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.port = decoder0.decodeUint16(8);
    }
    {
      
      result.addr = decoder0.decodeUint8Array(16, bindings.kNothingNullable, 16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint16(port, 8);
    
    encoder0.encodeUint8Array(addr, 16, bindings.kNothingNullable, 16);
  }

  String toString() {
    return "NetAddressIPv6("
           "port: $port" ", "
           "addr: $addr" ")";
  }
}

class NetAddress extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int family = NetAddressFamily_UNSPECIFIED;
  NetAddressIPv4 ipv4 = null;
  NetAddressIPv6 ipv6 = null;

  NetAddress() : super(kStructSize);

  static NetAddress deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NetAddress decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NetAddress result = new NetAddress();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.family = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.ipv4 = NetAddressIPv4.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.ipv6 = NetAddressIPv6.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(family, 8);
    
    encoder0.encodeStruct(ipv4, 16, true);
    
    encoder0.encodeStruct(ipv6, 24, true);
  }

  String toString() {
    return "NetAddress("
           "family: $family" ", "
           "ipv4: $ipv4" ", "
           "ipv6: $ipv6" ")";
  }
}

