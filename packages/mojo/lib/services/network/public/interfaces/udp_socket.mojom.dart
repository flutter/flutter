// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library udp_socket.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/network/public/interfaces/net_address.mojom.dart' as net_address_mojom;
import 'package:mojo/services/network/public/interfaces/network_error.mojom.dart' as network_error_mojom;


class UdpSocketAllowAddressReuseParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  UdpSocketAllowAddressReuseParams() : super(kStructSize);

  static UdpSocketAllowAddressReuseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketAllowAddressReuseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketAllowAddressReuseParams result = new UdpSocketAllowAddressReuseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "UdpSocketAllowAddressReuseParams("")";
  }
}

class UdpSocketAllowAddressReuseResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;

  UdpSocketAllowAddressReuseResponseParams() : super(kStructSize);

  static UdpSocketAllowAddressReuseResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketAllowAddressReuseResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketAllowAddressReuseResponseParams result = new UdpSocketAllowAddressReuseResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "UdpSocketAllowAddressReuseResponseParams("
           "result: $result" ")";
  }
}

class UdpSocketBindParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  net_address_mojom.NetAddress addr = null;

  UdpSocketBindParams() : super(kStructSize);

  static UdpSocketBindParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketBindParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketBindParams result = new UdpSocketBindParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.addr = net_address_mojom.NetAddress.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(addr, 8, false);
  }

  String toString() {
    return "UdpSocketBindParams("
           "addr: $addr" ")";
  }
}

class UdpSocketBindResponseParams extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;
  net_address_mojom.NetAddress boundAddr = null;
  Object receiver = null;

  UdpSocketBindResponseParams() : super(kStructSize);

  static UdpSocketBindResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketBindResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketBindResponseParams result = new UdpSocketBindResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.boundAddr = net_address_mojom.NetAddress.decode(decoder1);
    }
    {
      
      result.receiver = decoder0.decodeInterfaceRequest(24, true, UdpSocketReceiverStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
    
    encoder0.encodeStruct(boundAddr, 16, true);
    
    encoder0.encodeInterfaceRequest(receiver, 24, true);
  }

  String toString() {
    return "UdpSocketBindResponseParams("
           "result: $result" ", "
           "boundAddr: $boundAddr" ", "
           "receiver: $receiver" ")";
  }
}

class UdpSocketConnectParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  net_address_mojom.NetAddress remoteAddr = null;

  UdpSocketConnectParams() : super(kStructSize);

  static UdpSocketConnectParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketConnectParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketConnectParams result = new UdpSocketConnectParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.remoteAddr = net_address_mojom.NetAddress.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(remoteAddr, 8, false);
  }

  String toString() {
    return "UdpSocketConnectParams("
           "remoteAddr: $remoteAddr" ")";
  }
}

class UdpSocketConnectResponseParams extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;
  net_address_mojom.NetAddress localAddr = null;
  Object receiver = null;

  UdpSocketConnectResponseParams() : super(kStructSize);

  static UdpSocketConnectResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketConnectResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketConnectResponseParams result = new UdpSocketConnectResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.localAddr = net_address_mojom.NetAddress.decode(decoder1);
    }
    {
      
      result.receiver = decoder0.decodeInterfaceRequest(24, true, UdpSocketReceiverStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
    
    encoder0.encodeStruct(localAddr, 16, true);
    
    encoder0.encodeInterfaceRequest(receiver, 24, true);
  }

  String toString() {
    return "UdpSocketConnectResponseParams("
           "result: $result" ", "
           "localAddr: $localAddr" ", "
           "receiver: $receiver" ")";
  }
}

class UdpSocketSetSendBufferSizeParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int size = 0;

  UdpSocketSetSendBufferSizeParams() : super(kStructSize);

  static UdpSocketSetSendBufferSizeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSetSendBufferSizeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSetSendBufferSizeParams result = new UdpSocketSetSendBufferSizeParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.size = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(size, 8);
  }

  String toString() {
    return "UdpSocketSetSendBufferSizeParams("
           "size: $size" ")";
  }
}

class UdpSocketSetSendBufferSizeResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;

  UdpSocketSetSendBufferSizeResponseParams() : super(kStructSize);

  static UdpSocketSetSendBufferSizeResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSetSendBufferSizeResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSetSendBufferSizeResponseParams result = new UdpSocketSetSendBufferSizeResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "UdpSocketSetSendBufferSizeResponseParams("
           "result: $result" ")";
  }
}

class UdpSocketSetReceiveBufferSizeParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int size = 0;

  UdpSocketSetReceiveBufferSizeParams() : super(kStructSize);

  static UdpSocketSetReceiveBufferSizeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSetReceiveBufferSizeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSetReceiveBufferSizeParams result = new UdpSocketSetReceiveBufferSizeParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.size = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(size, 8);
  }

  String toString() {
    return "UdpSocketSetReceiveBufferSizeParams("
           "size: $size" ")";
  }
}

class UdpSocketSetReceiveBufferSizeResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;

  UdpSocketSetReceiveBufferSizeResponseParams() : super(kStructSize);

  static UdpSocketSetReceiveBufferSizeResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSetReceiveBufferSizeResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSetReceiveBufferSizeResponseParams result = new UdpSocketSetReceiveBufferSizeResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "UdpSocketSetReceiveBufferSizeResponseParams("
           "result: $result" ")";
  }
}

class UdpSocketNegotiateMaxPendingSendRequestsParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int requestedSize = 0;

  UdpSocketNegotiateMaxPendingSendRequestsParams() : super(kStructSize);

  static UdpSocketNegotiateMaxPendingSendRequestsParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketNegotiateMaxPendingSendRequestsParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketNegotiateMaxPendingSendRequestsParams result = new UdpSocketNegotiateMaxPendingSendRequestsParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.requestedSize = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(requestedSize, 8);
  }

  String toString() {
    return "UdpSocketNegotiateMaxPendingSendRequestsParams("
           "requestedSize: $requestedSize" ")";
  }
}

class UdpSocketNegotiateMaxPendingSendRequestsResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int actualSize = 0;

  UdpSocketNegotiateMaxPendingSendRequestsResponseParams() : super(kStructSize);

  static UdpSocketNegotiateMaxPendingSendRequestsResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketNegotiateMaxPendingSendRequestsResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketNegotiateMaxPendingSendRequestsResponseParams result = new UdpSocketNegotiateMaxPendingSendRequestsResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.actualSize = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(actualSize, 8);
  }

  String toString() {
    return "UdpSocketNegotiateMaxPendingSendRequestsResponseParams("
           "actualSize: $actualSize" ")";
  }
}

class UdpSocketReceiveMoreParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int datagramNumber = 0;

  UdpSocketReceiveMoreParams() : super(kStructSize);

  static UdpSocketReceiveMoreParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketReceiveMoreParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketReceiveMoreParams result = new UdpSocketReceiveMoreParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.datagramNumber = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(datagramNumber, 8);
  }

  String toString() {
    return "UdpSocketReceiveMoreParams("
           "datagramNumber: $datagramNumber" ")";
  }
}

class UdpSocketSendToParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  net_address_mojom.NetAddress destAddr = null;
  List<int> data = null;

  UdpSocketSendToParams() : super(kStructSize);

  static UdpSocketSendToParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSendToParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSendToParams result = new UdpSocketSendToParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.destAddr = net_address_mojom.NetAddress.decode(decoder1);
    }
    {
      
      result.data = decoder0.decodeUint8Array(16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(destAddr, 8, true);
    
    encoder0.encodeUint8Array(data, 16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "UdpSocketSendToParams("
           "destAddr: $destAddr" ", "
           "data: $data" ")";
  }
}

class UdpSocketSendToResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;

  UdpSocketSendToResponseParams() : super(kStructSize);

  static UdpSocketSendToResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketSendToResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketSendToResponseParams result = new UdpSocketSendToResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "UdpSocketSendToResponseParams("
           "result: $result" ")";
  }
}

class UdpSocketReceiverOnReceivedParams extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError result = null;
  net_address_mojom.NetAddress srcAddr = null;
  List<int> data = null;

  UdpSocketReceiverOnReceivedParams() : super(kStructSize);

  static UdpSocketReceiverOnReceivedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UdpSocketReceiverOnReceivedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UdpSocketReceiverOnReceivedParams result = new UdpSocketReceiverOnReceivedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.srcAddr = net_address_mojom.NetAddress.decode(decoder1);
    }
    {
      
      result.data = decoder0.decodeUint8Array(24, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(result, 8, false);
    
    encoder0.encodeStruct(srcAddr, 16, true);
    
    encoder0.encodeUint8Array(data, 24, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "UdpSocketReceiverOnReceivedParams("
           "result: $result" ", "
           "srcAddr: $srcAddr" ", "
           "data: $data" ")";
  }
}
const int kUdpSocket_allowAddressReuse_name = 0;
const int kUdpSocket_bind_name = 1;
const int kUdpSocket_connect_name = 2;
const int kUdpSocket_setSendBufferSize_name = 3;
const int kUdpSocket_setReceiveBufferSize_name = 4;
const int kUdpSocket_negotiateMaxPendingSendRequests_name = 5;
const int kUdpSocket_receiveMore_name = 6;
const int kUdpSocket_sendTo_name = 7;

const String UdpSocketName =
      'mojo::UdpSocket';

abstract class UdpSocket {
  Future<UdpSocketAllowAddressReuseResponseParams> allowAddressReuse([Function responseFactory = null]);
  Future<UdpSocketBindResponseParams> bind(net_address_mojom.NetAddress addr,[Function responseFactory = null]);
  Future<UdpSocketConnectResponseParams> connect(net_address_mojom.NetAddress remoteAddr,[Function responseFactory = null]);
  Future<UdpSocketSetSendBufferSizeResponseParams> setSendBufferSize(int size,[Function responseFactory = null]);
  Future<UdpSocketSetReceiveBufferSizeResponseParams> setReceiveBufferSize(int size,[Function responseFactory = null]);
  Future<UdpSocketNegotiateMaxPendingSendRequestsResponseParams> negotiateMaxPendingSendRequests(int requestedSize,[Function responseFactory = null]);
  void receiveMore(int datagramNumber);
  Future<UdpSocketSendToResponseParams> sendTo(net_address_mojom.NetAddress destAddr,List<int> data,[Function responseFactory = null]);

}


class UdpSocketProxyImpl extends bindings.Proxy {
  UdpSocketProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  UdpSocketProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  UdpSocketProxyImpl.unbound() : super.unbound();

  static UdpSocketProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketProxyImpl.fromEndpoint(endpoint);

  String get name => UdpSocketName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kUdpSocket_allowAddressReuse_name:
        var r = UdpSocketAllowAddressReuseResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_bind_name:
        var r = UdpSocketBindResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_connect_name:
        var r = UdpSocketConnectResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_setSendBufferSize_name:
        var r = UdpSocketSetSendBufferSizeResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_setReceiveBufferSize_name:
        var r = UdpSocketSetReceiveBufferSizeResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_negotiateMaxPendingSendRequests_name:
        var r = UdpSocketNegotiateMaxPendingSendRequestsResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kUdpSocket_sendTo_name:
        var r = UdpSocketSendToResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "UdpSocketProxyImpl($superString)";
  }
}


class _UdpSocketProxyCalls implements UdpSocket {
  UdpSocketProxyImpl _proxyImpl;

  _UdpSocketProxyCalls(this._proxyImpl);
    Future<UdpSocketAllowAddressReuseResponseParams> allowAddressReuse([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketAllowAddressReuseParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_allowAddressReuse_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UdpSocketBindResponseParams> bind(net_address_mojom.NetAddress addr,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketBindParams();
      params.addr = addr;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_bind_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UdpSocketConnectResponseParams> connect(net_address_mojom.NetAddress remoteAddr,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketConnectParams();
      params.remoteAddr = remoteAddr;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_connect_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UdpSocketSetSendBufferSizeResponseParams> setSendBufferSize(int size,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketSetSendBufferSizeParams();
      params.size = size;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_setSendBufferSize_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UdpSocketSetReceiveBufferSizeResponseParams> setReceiveBufferSize(int size,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketSetReceiveBufferSizeParams();
      params.size = size;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_setReceiveBufferSize_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UdpSocketNegotiateMaxPendingSendRequestsResponseParams> negotiateMaxPendingSendRequests(int requestedSize,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketNegotiateMaxPendingSendRequestsParams();
      params.requestedSize = requestedSize;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_negotiateMaxPendingSendRequests_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    void receiveMore(int datagramNumber) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketReceiveMoreParams();
      params.datagramNumber = datagramNumber;
      _proxyImpl.sendMessage(params, kUdpSocket_receiveMore_name);
    }
  
    Future<UdpSocketSendToResponseParams> sendTo(net_address_mojom.NetAddress destAddr,List<int> data,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketSendToParams();
      params.destAddr = destAddr;
      params.data = data;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUdpSocket_sendTo_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class UdpSocketProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  UdpSocket ptr;
  final String name = UdpSocketName;

  UdpSocketProxy(UdpSocketProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _UdpSocketProxyCalls(proxyImpl);

  UdpSocketProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new UdpSocketProxyImpl.fromEndpoint(endpoint) {
    ptr = new _UdpSocketProxyCalls(impl);
  }

  UdpSocketProxy.fromHandle(core.MojoHandle handle) :
      impl = new UdpSocketProxyImpl.fromHandle(handle) {
    ptr = new _UdpSocketProxyCalls(impl);
  }

  UdpSocketProxy.unbound() :
      impl = new UdpSocketProxyImpl.unbound() {
    ptr = new _UdpSocketProxyCalls(impl);
  }

  static UdpSocketProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "UdpSocketProxy($impl)";
  }
}


class UdpSocketStub extends bindings.Stub {
  UdpSocket _impl = null;

  UdpSocketStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  UdpSocketStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  UdpSocketStub.unbound() : super.unbound();

  static UdpSocketStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketStub.fromEndpoint(endpoint);

  static const String name = UdpSocketName;


  UdpSocketAllowAddressReuseResponseParams _UdpSocketAllowAddressReuseResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new UdpSocketAllowAddressReuseResponseParams();
    result.result = result;
    return result;
  }
  UdpSocketBindResponseParams _UdpSocketBindResponseParamsFactory(network_error_mojom.NetworkError result, net_address_mojom.NetAddress boundAddr, Object receiver) {
    var result = new UdpSocketBindResponseParams();
    result.result = result;
    result.boundAddr = boundAddr;
    result.receiver = receiver;
    return result;
  }
  UdpSocketConnectResponseParams _UdpSocketConnectResponseParamsFactory(network_error_mojom.NetworkError result, net_address_mojom.NetAddress localAddr, Object receiver) {
    var result = new UdpSocketConnectResponseParams();
    result.result = result;
    result.localAddr = localAddr;
    result.receiver = receiver;
    return result;
  }
  UdpSocketSetSendBufferSizeResponseParams _UdpSocketSetSendBufferSizeResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new UdpSocketSetSendBufferSizeResponseParams();
    result.result = result;
    return result;
  }
  UdpSocketSetReceiveBufferSizeResponseParams _UdpSocketSetReceiveBufferSizeResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new UdpSocketSetReceiveBufferSizeResponseParams();
    result.result = result;
    return result;
  }
  UdpSocketNegotiateMaxPendingSendRequestsResponseParams _UdpSocketNegotiateMaxPendingSendRequestsResponseParamsFactory(int actualSize) {
    var result = new UdpSocketNegotiateMaxPendingSendRequestsResponseParams();
    result.actualSize = actualSize;
    return result;
  }
  UdpSocketSendToResponseParams _UdpSocketSendToResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new UdpSocketSendToResponseParams();
    result.result = result;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kUdpSocket_allowAddressReuse_name:
        var params = UdpSocketAllowAddressReuseParams.deserialize(
            message.payload);
        return _impl.allowAddressReuse(_UdpSocketAllowAddressReuseResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_allowAddressReuse_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_bind_name:
        var params = UdpSocketBindParams.deserialize(
            message.payload);
        return _impl.bind(params.addr,_UdpSocketBindResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_bind_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_connect_name:
        var params = UdpSocketConnectParams.deserialize(
            message.payload);
        return _impl.connect(params.remoteAddr,_UdpSocketConnectResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_connect_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_setSendBufferSize_name:
        var params = UdpSocketSetSendBufferSizeParams.deserialize(
            message.payload);
        return _impl.setSendBufferSize(params.size,_UdpSocketSetSendBufferSizeResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_setSendBufferSize_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_setReceiveBufferSize_name:
        var params = UdpSocketSetReceiveBufferSizeParams.deserialize(
            message.payload);
        return _impl.setReceiveBufferSize(params.size,_UdpSocketSetReceiveBufferSizeResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_setReceiveBufferSize_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_negotiateMaxPendingSendRequests_name:
        var params = UdpSocketNegotiateMaxPendingSendRequestsParams.deserialize(
            message.payload);
        return _impl.negotiateMaxPendingSendRequests(params.requestedSize,_UdpSocketNegotiateMaxPendingSendRequestsResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_negotiateMaxPendingSendRequests_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUdpSocket_receiveMore_name:
        var params = UdpSocketReceiveMoreParams.deserialize(
            message.payload);
        _impl.receiveMore(params.datagramNumber);
        break;
      case kUdpSocket_sendTo_name:
        var params = UdpSocketSendToParams.deserialize(
            message.payload);
        return _impl.sendTo(params.destAddr,params.data,_UdpSocketSendToResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUdpSocket_sendTo_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  UdpSocket get impl => _impl;
      set impl(UdpSocket d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "UdpSocketStub($superString)";
  }
}

const int kUdpSocketReceiver_onReceived_name = 0;

const String UdpSocketReceiverName =
      'mojo::UdpSocketReceiver';

abstract class UdpSocketReceiver {
  void onReceived(network_error_mojom.NetworkError result, net_address_mojom.NetAddress srcAddr, List<int> data);

}


class UdpSocketReceiverProxyImpl extends bindings.Proxy {
  UdpSocketReceiverProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  UdpSocketReceiverProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  UdpSocketReceiverProxyImpl.unbound() : super.unbound();

  static UdpSocketReceiverProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketReceiverProxyImpl.fromEndpoint(endpoint);

  String get name => UdpSocketReceiverName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "UdpSocketReceiverProxyImpl($superString)";
  }
}


class _UdpSocketReceiverProxyCalls implements UdpSocketReceiver {
  UdpSocketReceiverProxyImpl _proxyImpl;

  _UdpSocketReceiverProxyCalls(this._proxyImpl);
    void onReceived(network_error_mojom.NetworkError result, net_address_mojom.NetAddress srcAddr, List<int> data) {
      assert(_proxyImpl.isBound);
      var params = new UdpSocketReceiverOnReceivedParams();
      params.result = result;
      params.srcAddr = srcAddr;
      params.data = data;
      _proxyImpl.sendMessage(params, kUdpSocketReceiver_onReceived_name);
    }
  
}


class UdpSocketReceiverProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  UdpSocketReceiver ptr;
  final String name = UdpSocketReceiverName;

  UdpSocketReceiverProxy(UdpSocketReceiverProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _UdpSocketReceiverProxyCalls(proxyImpl);

  UdpSocketReceiverProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new UdpSocketReceiverProxyImpl.fromEndpoint(endpoint) {
    ptr = new _UdpSocketReceiverProxyCalls(impl);
  }

  UdpSocketReceiverProxy.fromHandle(core.MojoHandle handle) :
      impl = new UdpSocketReceiverProxyImpl.fromHandle(handle) {
    ptr = new _UdpSocketReceiverProxyCalls(impl);
  }

  UdpSocketReceiverProxy.unbound() :
      impl = new UdpSocketReceiverProxyImpl.unbound() {
    ptr = new _UdpSocketReceiverProxyCalls(impl);
  }

  static UdpSocketReceiverProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketReceiverProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "UdpSocketReceiverProxy($impl)";
  }
}


class UdpSocketReceiverStub extends bindings.Stub {
  UdpSocketReceiver _impl = null;

  UdpSocketReceiverStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  UdpSocketReceiverStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  UdpSocketReceiverStub.unbound() : super.unbound();

  static UdpSocketReceiverStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UdpSocketReceiverStub.fromEndpoint(endpoint);

  static const String name = UdpSocketReceiverName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kUdpSocketReceiver_onReceived_name:
        var params = UdpSocketReceiverOnReceivedParams.deserialize(
            message.payload);
        _impl.onReceived(params.result, params.srcAddr, params.data);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  UdpSocketReceiver get impl => _impl;
      set impl(UdpSocketReceiver d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "UdpSocketReceiverStub($superString)";
  }
}


