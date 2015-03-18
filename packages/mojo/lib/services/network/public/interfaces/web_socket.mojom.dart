// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library web_socket.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/network/public/interfaces/network_error.mojom.dart' as network_error_mojom;


class WebSocketConnectParams extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;
  List<String> protocols = null;
  String origin = null;
  core.MojoDataPipeConsumer sendStream = null;
  Object client = null;

  WebSocketConnectParams() : super(kStructSize);

  static WebSocketConnectParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketConnectParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketConnectParams result = new WebSocketConnectParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.url = decoder0.decodeString(8, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.protocols = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.protocols[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      result.origin = decoder0.decodeString(24, false);
    }
    {
      
      result.sendStream = decoder0.decodeConsumerHandle(32, false);
    }
    {
      
      result.client = decoder0.decodeServiceInterface(36, false, WebSocketClientProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(url, 8, false);
    
    if (protocols == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(protocols.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < protocols.length; ++i0) {
        
        encoder1.encodeString(protocols[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeString(origin, 24, false);
    
    encoder0.encodeConsumerHandle(sendStream, 32, false);
    
    encoder0.encodeInterface(client, 36, false);
  }

  String toString() {
    return "WebSocketConnectParams("
           "url: $url" ", "
           "protocols: $protocols" ", "
           "origin: $origin" ", "
           "sendStream: $sendStream" ", "
           "client: $client" ")";
  }
}

class WebSocketSendParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool fin = false;
  int type = 0;
  int numBytes = 0;

  WebSocketSendParams() : super(kStructSize);

  static WebSocketSendParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketSendParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketSendParams result = new WebSocketSendParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fin = decoder0.decodeBool(8, 0);
    }
    {
      
      result.type = decoder0.decodeInt32(12);
    }
    {
      
      result.numBytes = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(fin, 8, 0);
    
    encoder0.encodeInt32(type, 12);
    
    encoder0.encodeUint32(numBytes, 16);
  }

  String toString() {
    return "WebSocketSendParams("
           "fin: $fin" ", "
           "type: $type" ", "
           "numBytes: $numBytes" ")";
  }
}

class WebSocketFlowControlParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int quota = 0;

  WebSocketFlowControlParams() : super(kStructSize);

  static WebSocketFlowControlParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketFlowControlParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketFlowControlParams result = new WebSocketFlowControlParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.quota = decoder0.decodeInt64(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt64(quota, 8);
  }

  String toString() {
    return "WebSocketFlowControlParams("
           "quota: $quota" ")";
  }
}

class WebSocketCloseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int code = 0;
  String reason = null;

  WebSocketCloseParams() : super(kStructSize);

  static WebSocketCloseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketCloseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketCloseParams result = new WebSocketCloseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.code = decoder0.decodeUint16(8);
    }
    {
      
      result.reason = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint16(code, 8);
    
    encoder0.encodeString(reason, 16, false);
  }

  String toString() {
    return "WebSocketCloseParams("
           "code: $code" ", "
           "reason: $reason" ")";
  }
}

class WebSocketClientDidConnectParams extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String selectedSubprotocol = null;
  String extensions = null;
  core.MojoDataPipeConsumer receiveStream = null;

  WebSocketClientDidConnectParams() : super(kStructSize);

  static WebSocketClientDidConnectParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketClientDidConnectParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketClientDidConnectParams result = new WebSocketClientDidConnectParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.selectedSubprotocol = decoder0.decodeString(8, false);
    }
    {
      
      result.extensions = decoder0.decodeString(16, false);
    }
    {
      
      result.receiveStream = decoder0.decodeConsumerHandle(24, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(selectedSubprotocol, 8, false);
    
    encoder0.encodeString(extensions, 16, false);
    
    encoder0.encodeConsumerHandle(receiveStream, 24, false);
  }

  String toString() {
    return "WebSocketClientDidConnectParams("
           "selectedSubprotocol: $selectedSubprotocol" ", "
           "extensions: $extensions" ", "
           "receiveStream: $receiveStream" ")";
  }
}

class WebSocketClientDidReceiveDataParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool fin = false;
  int type = 0;
  int numBytes = 0;

  WebSocketClientDidReceiveDataParams() : super(kStructSize);

  static WebSocketClientDidReceiveDataParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketClientDidReceiveDataParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketClientDidReceiveDataParams result = new WebSocketClientDidReceiveDataParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fin = decoder0.decodeBool(8, 0);
    }
    {
      
      result.type = decoder0.decodeInt32(12);
    }
    {
      
      result.numBytes = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(fin, 8, 0);
    
    encoder0.encodeInt32(type, 12);
    
    encoder0.encodeUint32(numBytes, 16);
  }

  String toString() {
    return "WebSocketClientDidReceiveDataParams("
           "fin: $fin" ", "
           "type: $type" ", "
           "numBytes: $numBytes" ")";
  }
}

class WebSocketClientDidReceiveFlowControlParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int quota = 0;

  WebSocketClientDidReceiveFlowControlParams() : super(kStructSize);

  static WebSocketClientDidReceiveFlowControlParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketClientDidReceiveFlowControlParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketClientDidReceiveFlowControlParams result = new WebSocketClientDidReceiveFlowControlParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.quota = decoder0.decodeInt64(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt64(quota, 8);
  }

  String toString() {
    return "WebSocketClientDidReceiveFlowControlParams("
           "quota: $quota" ")";
  }
}

class WebSocketClientDidFailParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String message = null;

  WebSocketClientDidFailParams() : super(kStructSize);

  static WebSocketClientDidFailParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketClientDidFailParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketClientDidFailParams result = new WebSocketClientDidFailParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.message = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(message, 8, false);
  }

  String toString() {
    return "WebSocketClientDidFailParams("
           "message: $message" ")";
  }
}

class WebSocketClientDidCloseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool wasClean = false;
  int code = 0;
  String reason = null;

  WebSocketClientDidCloseParams() : super(kStructSize);

  static WebSocketClientDidCloseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WebSocketClientDidCloseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WebSocketClientDidCloseParams result = new WebSocketClientDidCloseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.wasClean = decoder0.decodeBool(8, 0);
    }
    {
      
      result.code = decoder0.decodeUint16(10);
    }
    {
      
      result.reason = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(wasClean, 8, 0);
    
    encoder0.encodeUint16(code, 10);
    
    encoder0.encodeString(reason, 16, false);
  }

  String toString() {
    return "WebSocketClientDidCloseParams("
           "wasClean: $wasClean" ", "
           "code: $code" ", "
           "reason: $reason" ")";
  }
}
const int kWebSocket_connect_name = 0;
const int kWebSocket_send_name = 1;
const int kWebSocket_flowControl_name = 2;
const int kWebSocket_close_name = 3;

const String WebSocketName =
      'mojo::WebSocket';

abstract class WebSocket {
  void connect(String url, List<String> protocols, String origin, core.MojoDataPipeConsumer sendStream, Object client);
  void send(bool fin, int type, int numBytes);
  void flowControl(int quota);
  void close(int code, String reason);

  static final ABNORMAL_CLOSE_CODE = 1006;
  
  static final int MessageType_CONTINUATION = 0;
  static final int MessageType_TEXT = MessageType_CONTINUATION + 1;
  static final int MessageType_BINARY = MessageType_TEXT + 1;
}


class WebSocketProxyImpl extends bindings.Proxy {
  WebSocketProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WebSocketProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WebSocketProxyImpl.unbound() : super.unbound();

  static WebSocketProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketProxyImpl.fromEndpoint(endpoint);

  String get name => WebSocketName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WebSocketProxyImpl($superString)";
  }
}


class _WebSocketProxyCalls implements WebSocket {
  WebSocketProxyImpl _proxyImpl;

  _WebSocketProxyCalls(this._proxyImpl);
    void connect(String url, List<String> protocols, String origin, core.MojoDataPipeConsumer sendStream, Object client) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketConnectParams();
      params.url = url;
      params.protocols = protocols;
      params.origin = origin;
      params.sendStream = sendStream;
      params.client = client;
      _proxyImpl.sendMessage(params, kWebSocket_connect_name);
    }
  
    void send(bool fin, int type, int numBytes) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketSendParams();
      params.fin = fin;
      params.type = type;
      params.numBytes = numBytes;
      _proxyImpl.sendMessage(params, kWebSocket_send_name);
    }
  
    void flowControl(int quota) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketFlowControlParams();
      params.quota = quota;
      _proxyImpl.sendMessage(params, kWebSocket_flowControl_name);
    }
  
    void close(int code, String reason) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketCloseParams();
      params.code = code;
      params.reason = reason;
      _proxyImpl.sendMessage(params, kWebSocket_close_name);
    }
  
}


class WebSocketProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WebSocket ptr;
  final String name = WebSocketName;

  WebSocketProxy(WebSocketProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WebSocketProxyCalls(proxyImpl);

  WebSocketProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WebSocketProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WebSocketProxyCalls(impl);
  }

  WebSocketProxy.fromHandle(core.MojoHandle handle) :
      impl = new WebSocketProxyImpl.fromHandle(handle) {
    ptr = new _WebSocketProxyCalls(impl);
  }

  WebSocketProxy.unbound() :
      impl = new WebSocketProxyImpl.unbound() {
    ptr = new _WebSocketProxyCalls(impl);
  }

  static WebSocketProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "WebSocketProxy($impl)";
  }
}


class WebSocketStub extends bindings.Stub {
  WebSocket _impl = null;

  WebSocketStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WebSocketStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WebSocketStub.unbound() : super.unbound();

  static WebSocketStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketStub.fromEndpoint(endpoint);

  static const String name = WebSocketName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWebSocket_connect_name:
        var params = WebSocketConnectParams.deserialize(
            message.payload);
        _impl.connect(params.url, params.protocols, params.origin, params.sendStream, params.client);
        break;
      case kWebSocket_send_name:
        var params = WebSocketSendParams.deserialize(
            message.payload);
        _impl.send(params.fin, params.type, params.numBytes);
        break;
      case kWebSocket_flowControl_name:
        var params = WebSocketFlowControlParams.deserialize(
            message.payload);
        _impl.flowControl(params.quota);
        break;
      case kWebSocket_close_name:
        var params = WebSocketCloseParams.deserialize(
            message.payload);
        _impl.close(params.code, params.reason);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WebSocket get impl => _impl;
      set impl(WebSocket d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WebSocketStub($superString)";
  }
}

const int kWebSocketClient_didConnect_name = 0;
const int kWebSocketClient_didReceiveData_name = 1;
const int kWebSocketClient_didReceiveFlowControl_name = 2;
const int kWebSocketClient_didFail_name = 3;
const int kWebSocketClient_didClose_name = 4;

const String WebSocketClientName =
      'mojo::WebSocketClient';

abstract class WebSocketClient {
  void didConnect(String selectedSubprotocol, String extensions, core.MojoDataPipeConsumer receiveStream);
  void didReceiveData(bool fin, int type, int numBytes);
  void didReceiveFlowControl(int quota);
  void didFail(String message);
  void didClose(bool wasClean, int code, String reason);

}


class WebSocketClientProxyImpl extends bindings.Proxy {
  WebSocketClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WebSocketClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WebSocketClientProxyImpl.unbound() : super.unbound();

  static WebSocketClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketClientProxyImpl.fromEndpoint(endpoint);

  String get name => WebSocketClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WebSocketClientProxyImpl($superString)";
  }
}


class _WebSocketClientProxyCalls implements WebSocketClient {
  WebSocketClientProxyImpl _proxyImpl;

  _WebSocketClientProxyCalls(this._proxyImpl);
    void didConnect(String selectedSubprotocol, String extensions, core.MojoDataPipeConsumer receiveStream) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketClientDidConnectParams();
      params.selectedSubprotocol = selectedSubprotocol;
      params.extensions = extensions;
      params.receiveStream = receiveStream;
      _proxyImpl.sendMessage(params, kWebSocketClient_didConnect_name);
    }
  
    void didReceiveData(bool fin, int type, int numBytes) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketClientDidReceiveDataParams();
      params.fin = fin;
      params.type = type;
      params.numBytes = numBytes;
      _proxyImpl.sendMessage(params, kWebSocketClient_didReceiveData_name);
    }
  
    void didReceiveFlowControl(int quota) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketClientDidReceiveFlowControlParams();
      params.quota = quota;
      _proxyImpl.sendMessage(params, kWebSocketClient_didReceiveFlowControl_name);
    }
  
    void didFail(String message) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketClientDidFailParams();
      params.message = message;
      _proxyImpl.sendMessage(params, kWebSocketClient_didFail_name);
    }
  
    void didClose(bool wasClean, int code, String reason) {
      assert(_proxyImpl.isBound);
      var params = new WebSocketClientDidCloseParams();
      params.wasClean = wasClean;
      params.code = code;
      params.reason = reason;
      _proxyImpl.sendMessage(params, kWebSocketClient_didClose_name);
    }
  
}


class WebSocketClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WebSocketClient ptr;
  final String name = WebSocketClientName;

  WebSocketClientProxy(WebSocketClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WebSocketClientProxyCalls(proxyImpl);

  WebSocketClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WebSocketClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WebSocketClientProxyCalls(impl);
  }

  WebSocketClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new WebSocketClientProxyImpl.fromHandle(handle) {
    ptr = new _WebSocketClientProxyCalls(impl);
  }

  WebSocketClientProxy.unbound() :
      impl = new WebSocketClientProxyImpl.unbound() {
    ptr = new _WebSocketClientProxyCalls(impl);
  }

  static WebSocketClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketClientProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "WebSocketClientProxy($impl)";
  }
}


class WebSocketClientStub extends bindings.Stub {
  WebSocketClient _impl = null;

  WebSocketClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WebSocketClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WebSocketClientStub.unbound() : super.unbound();

  static WebSocketClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WebSocketClientStub.fromEndpoint(endpoint);

  static const String name = WebSocketClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWebSocketClient_didConnect_name:
        var params = WebSocketClientDidConnectParams.deserialize(
            message.payload);
        _impl.didConnect(params.selectedSubprotocol, params.extensions, params.receiveStream);
        break;
      case kWebSocketClient_didReceiveData_name:
        var params = WebSocketClientDidReceiveDataParams.deserialize(
            message.payload);
        _impl.didReceiveData(params.fin, params.type, params.numBytes);
        break;
      case kWebSocketClient_didReceiveFlowControl_name:
        var params = WebSocketClientDidReceiveFlowControlParams.deserialize(
            message.payload);
        _impl.didReceiveFlowControl(params.quota);
        break;
      case kWebSocketClient_didFail_name:
        var params = WebSocketClientDidFailParams.deserialize(
            message.payload);
        _impl.didFail(params.message);
        break;
      case kWebSocketClient_didClose_name:
        var params = WebSocketClientDidCloseParams.deserialize(
            message.payload);
        _impl.didClose(params.wasClean, params.code, params.reason);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WebSocketClient get impl => _impl;
      set impl(WebSocketClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WebSocketClientStub($superString)";
  }
}


