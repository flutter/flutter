// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library tcp_bound_socket.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/network/public/interfaces/net_address.mojom.dart' as net_address_mojom;
import 'package:mojo/services/network/public/interfaces/network_error.mojom.dart' as network_error_mojom;
import 'package:mojo/services/network/public/interfaces/tcp_connected_socket.mojom.dart' as tcp_connected_socket_mojom;
import 'package:mojo/services/network/public/interfaces/tcp_server_socket.mojom.dart' as tcp_server_socket_mojom;


class TcpBoundSocketStartListeningParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object server = null;

  TcpBoundSocketStartListeningParams() : super(kVersions.last.size);

  static TcpBoundSocketStartListeningParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TcpBoundSocketStartListeningParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TcpBoundSocketStartListeningParams result = new TcpBoundSocketStartListeningParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.server = decoder0.decodeInterfaceRequest(8, false, tcp_server_socket_mojom.TcpServerSocketStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(server, 8, false);
  }

  String toString() {
    return "TcpBoundSocketStartListeningParams("
           "server: $server" ")";
  }
}

class TcpBoundSocketStartListeningResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  network_error_mojom.NetworkError result = null;

  TcpBoundSocketStartListeningResponseParams() : super(kVersions.last.size);

  static TcpBoundSocketStartListeningResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TcpBoundSocketStartListeningResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TcpBoundSocketStartListeningResponseParams result = new TcpBoundSocketStartListeningResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "TcpBoundSocketStartListeningResponseParams("
           "result: $result" ")";
  }
}

class TcpBoundSocketConnectParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  net_address_mojom.NetAddress remoteAddress = null;
  core.MojoDataPipeConsumer sendStream = null;
  core.MojoDataPipeProducer receiveStream = null;
  Object clientSocket = null;

  TcpBoundSocketConnectParams() : super(kVersions.last.size);

  static TcpBoundSocketConnectParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TcpBoundSocketConnectParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TcpBoundSocketConnectParams result = new TcpBoundSocketConnectParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.remoteAddress = net_address_mojom.NetAddress.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.sendStream = decoder0.decodeConsumerHandle(16, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.receiveStream = decoder0.decodeProducerHandle(20, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.clientSocket = decoder0.decodeInterfaceRequest(24, false, tcp_connected_socket_mojom.TcpConnectedSocketStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(remoteAddress, 8, false);
    
    encoder0.encodeConsumerHandle(sendStream, 16, false);
    
    encoder0.encodeProducerHandle(receiveStream, 20, false);
    
    encoder0.encodeInterfaceRequest(clientSocket, 24, false);
  }

  String toString() {
    return "TcpBoundSocketConnectParams("
           "remoteAddress: $remoteAddress" ", "
           "sendStream: $sendStream" ", "
           "receiveStream: $receiveStream" ", "
           "clientSocket: $clientSocket" ")";
  }
}

class TcpBoundSocketConnectResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  network_error_mojom.NetworkError result = null;

  TcpBoundSocketConnectResponseParams() : super(kVersions.last.size);

  static TcpBoundSocketConnectResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TcpBoundSocketConnectResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TcpBoundSocketConnectResponseParams result = new TcpBoundSocketConnectResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.result = network_error_mojom.NetworkError.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(result, 8, false);
  }

  String toString() {
    return "TcpBoundSocketConnectResponseParams("
           "result: $result" ")";
  }
}
const int kTcpBoundSocket_startListening_name = 0;
const int kTcpBoundSocket_connect_name = 1;

const String TcpBoundSocketName =
      'mojo::TcpBoundSocket';

abstract class TcpBoundSocket {
  Future<TcpBoundSocketStartListeningResponseParams> startListening(Object server,[Function responseFactory = null]);
  Future<TcpBoundSocketConnectResponseParams> connect(net_address_mojom.NetAddress remoteAddress,core.MojoDataPipeConsumer sendStream,core.MojoDataPipeProducer receiveStream,Object clientSocket,[Function responseFactory = null]);

}


class TcpBoundSocketProxyImpl extends bindings.Proxy {
  TcpBoundSocketProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  TcpBoundSocketProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  TcpBoundSocketProxyImpl.unbound() : super.unbound();

  static TcpBoundSocketProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TcpBoundSocketProxyImpl.fromEndpoint(endpoint);

  String get name => TcpBoundSocketName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kTcpBoundSocket_startListening_name:
        var r = TcpBoundSocketStartListeningResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      case kTcpBoundSocket_connect_name:
        var r = TcpBoundSocketConnectResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "TcpBoundSocketProxyImpl($superString)";
  }
}


class _TcpBoundSocketProxyCalls implements TcpBoundSocket {
  TcpBoundSocketProxyImpl _proxyImpl;

  _TcpBoundSocketProxyCalls(this._proxyImpl);
    Future<TcpBoundSocketStartListeningResponseParams> startListening(Object server,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new TcpBoundSocketStartListeningParams();
      params.server = server;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kTcpBoundSocket_startListening_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<TcpBoundSocketConnectResponseParams> connect(net_address_mojom.NetAddress remoteAddress,core.MojoDataPipeConsumer sendStream,core.MojoDataPipeProducer receiveStream,Object clientSocket,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new TcpBoundSocketConnectParams();
      params.remoteAddress = remoteAddress;
      params.sendStream = sendStream;
      params.receiveStream = receiveStream;
      params.clientSocket = clientSocket;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kTcpBoundSocket_connect_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class TcpBoundSocketProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  TcpBoundSocket ptr;
  final String name = TcpBoundSocketName;

  TcpBoundSocketProxy(TcpBoundSocketProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _TcpBoundSocketProxyCalls(proxyImpl);

  TcpBoundSocketProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new TcpBoundSocketProxyImpl.fromEndpoint(endpoint) {
    ptr = new _TcpBoundSocketProxyCalls(impl);
  }

  TcpBoundSocketProxy.fromHandle(core.MojoHandle handle) :
      impl = new TcpBoundSocketProxyImpl.fromHandle(handle) {
    ptr = new _TcpBoundSocketProxyCalls(impl);
  }

  TcpBoundSocketProxy.unbound() :
      impl = new TcpBoundSocketProxyImpl.unbound() {
    ptr = new _TcpBoundSocketProxyCalls(impl);
  }

  static TcpBoundSocketProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TcpBoundSocketProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "TcpBoundSocketProxy($impl)";
  }
}


class TcpBoundSocketStub extends bindings.Stub {
  TcpBoundSocket _impl = null;

  TcpBoundSocketStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  TcpBoundSocketStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  TcpBoundSocketStub.unbound() : super.unbound();

  static TcpBoundSocketStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TcpBoundSocketStub.fromEndpoint(endpoint);

  static const String name = TcpBoundSocketName;


  TcpBoundSocketStartListeningResponseParams _TcpBoundSocketStartListeningResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new TcpBoundSocketStartListeningResponseParams();
    result.result = result;
    return result;
  }
  TcpBoundSocketConnectResponseParams _TcpBoundSocketConnectResponseParamsFactory(network_error_mojom.NetworkError result) {
    var result = new TcpBoundSocketConnectResponseParams();
    result.result = result;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kTcpBoundSocket_startListening_name:
        var params = TcpBoundSocketStartListeningParams.deserialize(
            message.payload);
        return _impl.startListening(params.server,_TcpBoundSocketStartListeningResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kTcpBoundSocket_startListening_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kTcpBoundSocket_connect_name:
        var params = TcpBoundSocketConnectParams.deserialize(
            message.payload);
        return _impl.connect(params.remoteAddress,params.sendStream,params.receiveStream,params.clientSocket,_TcpBoundSocketConnectResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kTcpBoundSocket_connect_name,
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

  TcpBoundSocket get impl => _impl;
      set impl(TcpBoundSocket d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "TcpBoundSocketStub($superString)";
  }
}


