// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library http_server.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/http_server/public/interfaces/http_request.mojom.dart' as http_request_mojom;
import 'package:mojo/services/http_server/public/interfaces/http_response.mojom.dart' as http_response_mojom;


class HttpServerSetHandlerParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String pattern = null;
  Object handler = null;

  HttpServerSetHandlerParams() : super(kStructSize);

  static HttpServerSetHandlerParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpServerSetHandlerParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpServerSetHandlerParams result = new HttpServerSetHandlerParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.pattern = decoder0.decodeString(8, false);
    }
    {
      
      result.handler = decoder0.decodeServiceInterface(16, false, HttpHandlerProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(pattern, 8, false);
    
    encoder0.encodeInterface(handler, 16, false);
  }

  String toString() {
    return "HttpServerSetHandlerParams("
           "pattern: $pattern" ", "
           "handler: $handler" ")";
  }
}

class HttpServerSetHandlerResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool success = false;

  HttpServerSetHandlerResponseParams() : super(kStructSize);

  static HttpServerSetHandlerResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpServerSetHandlerResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpServerSetHandlerResponseParams result = new HttpServerSetHandlerResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(success, 8, 0);
  }

  String toString() {
    return "HttpServerSetHandlerResponseParams("
           "success: $success" ")";
  }
}

class HttpServerGetPortParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  HttpServerGetPortParams() : super(kStructSize);

  static HttpServerGetPortParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpServerGetPortParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpServerGetPortParams result = new HttpServerGetPortParams();

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
    return "HttpServerGetPortParams("")";
  }
}

class HttpServerGetPortResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int port = 0;

  HttpServerGetPortResponseParams() : super(kStructSize);

  static HttpServerGetPortResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpServerGetPortResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpServerGetPortResponseParams result = new HttpServerGetPortResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.port = decoder0.decodeUint16(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint16(port, 8);
  }

  String toString() {
    return "HttpServerGetPortResponseParams("
           "port: $port" ")";
  }
}

class HttpHandlerHandleRequestParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  http_request_mojom.HttpRequest request = null;

  HttpHandlerHandleRequestParams() : super(kStructSize);

  static HttpHandlerHandleRequestParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpHandlerHandleRequestParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpHandlerHandleRequestParams result = new HttpHandlerHandleRequestParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.request = http_request_mojom.HttpRequest.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(request, 8, false);
  }

  String toString() {
    return "HttpHandlerHandleRequestParams("
           "request: $request" ")";
  }
}

class HttpHandlerHandleRequestResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  http_response_mojom.HttpResponse response = null;

  HttpHandlerHandleRequestResponseParams() : super(kStructSize);

  static HttpHandlerHandleRequestResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpHandlerHandleRequestResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpHandlerHandleRequestResponseParams result = new HttpHandlerHandleRequestResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.response = http_response_mojom.HttpResponse.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(response, 8, false);
  }

  String toString() {
    return "HttpHandlerHandleRequestResponseParams("
           "response: $response" ")";
  }
}
const int kHttpServer_setHandler_name = 0;
const int kHttpServer_getPort_name = 1;

const String HttpServerName =
      'http_server::HttpServer';

abstract class HttpServer {
  Future<HttpServerSetHandlerResponseParams> setHandler(String pattern,Object handler,[Function responseFactory = null]);
  Future<HttpServerGetPortResponseParams> getPort([Function responseFactory = null]);

}


class HttpServerProxyImpl extends bindings.Proxy {
  HttpServerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  HttpServerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  HttpServerProxyImpl.unbound() : super.unbound();

  static HttpServerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerProxyImpl.fromEndpoint(endpoint);

  String get name => HttpServerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kHttpServer_setHandler_name:
        var r = HttpServerSetHandlerResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kHttpServer_getPort_name:
        var r = HttpServerGetPortResponseParams.deserialize(
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
    return "HttpServerProxyImpl($superString)";
  }
}


class _HttpServerProxyCalls implements HttpServer {
  HttpServerProxyImpl _proxyImpl;

  _HttpServerProxyCalls(this._proxyImpl);
    Future<HttpServerSetHandlerResponseParams> setHandler(String pattern,Object handler,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new HttpServerSetHandlerParams();
      params.pattern = pattern;
      params.handler = handler;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kHttpServer_setHandler_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<HttpServerGetPortResponseParams> getPort([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new HttpServerGetPortParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kHttpServer_getPort_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class HttpServerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  HttpServer ptr;
  final String name = HttpServerName;

  HttpServerProxy(HttpServerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _HttpServerProxyCalls(proxyImpl);

  HttpServerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new HttpServerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _HttpServerProxyCalls(impl);
  }

  HttpServerProxy.fromHandle(core.MojoHandle handle) :
      impl = new HttpServerProxyImpl.fromHandle(handle) {
    ptr = new _HttpServerProxyCalls(impl);
  }

  HttpServerProxy.unbound() :
      impl = new HttpServerProxyImpl.unbound() {
    ptr = new _HttpServerProxyCalls(impl);
  }

  static HttpServerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "HttpServerProxy($impl)";
  }
}


class HttpServerStub extends bindings.Stub {
  HttpServer _impl = null;

  HttpServerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  HttpServerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  HttpServerStub.unbound() : super.unbound();

  static HttpServerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerStub.fromEndpoint(endpoint);

  static const String name = HttpServerName;


  HttpServerSetHandlerResponseParams _HttpServerSetHandlerResponseParamsFactory(bool success) {
    var result = new HttpServerSetHandlerResponseParams();
    result.success = success;
    return result;
  }
  HttpServerGetPortResponseParams _HttpServerGetPortResponseParamsFactory(int port) {
    var result = new HttpServerGetPortResponseParams();
    result.port = port;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kHttpServer_setHandler_name:
        var params = HttpServerSetHandlerParams.deserialize(
            message.payload);
        return _impl.setHandler(params.pattern,params.handler,_HttpServerSetHandlerResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kHttpServer_setHandler_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kHttpServer_getPort_name:
        var params = HttpServerGetPortParams.deserialize(
            message.payload);
        return _impl.getPort(_HttpServerGetPortResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kHttpServer_getPort_name,
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

  HttpServer get impl => _impl;
      set impl(HttpServer d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "HttpServerStub($superString)";
  }
}

const int kHttpHandler_handleRequest_name = 0;

const String HttpHandlerName =
      'http_server::HttpHandler';

abstract class HttpHandler {
  Future<HttpHandlerHandleRequestResponseParams> handleRequest(http_request_mojom.HttpRequest request,[Function responseFactory = null]);

}


class HttpHandlerProxyImpl extends bindings.Proxy {
  HttpHandlerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  HttpHandlerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  HttpHandlerProxyImpl.unbound() : super.unbound();

  static HttpHandlerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpHandlerProxyImpl.fromEndpoint(endpoint);

  String get name => HttpHandlerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kHttpHandler_handleRequest_name:
        var r = HttpHandlerHandleRequestResponseParams.deserialize(
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
    return "HttpHandlerProxyImpl($superString)";
  }
}


class _HttpHandlerProxyCalls implements HttpHandler {
  HttpHandlerProxyImpl _proxyImpl;

  _HttpHandlerProxyCalls(this._proxyImpl);
    Future<HttpHandlerHandleRequestResponseParams> handleRequest(http_request_mojom.HttpRequest request,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new HttpHandlerHandleRequestParams();
      params.request = request;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kHttpHandler_handleRequest_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class HttpHandlerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  HttpHandler ptr;
  final String name = HttpHandlerName;

  HttpHandlerProxy(HttpHandlerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _HttpHandlerProxyCalls(proxyImpl);

  HttpHandlerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new HttpHandlerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _HttpHandlerProxyCalls(impl);
  }

  HttpHandlerProxy.fromHandle(core.MojoHandle handle) :
      impl = new HttpHandlerProxyImpl.fromHandle(handle) {
    ptr = new _HttpHandlerProxyCalls(impl);
  }

  HttpHandlerProxy.unbound() :
      impl = new HttpHandlerProxyImpl.unbound() {
    ptr = new _HttpHandlerProxyCalls(impl);
  }

  static HttpHandlerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpHandlerProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "HttpHandlerProxy($impl)";
  }
}


class HttpHandlerStub extends bindings.Stub {
  HttpHandler _impl = null;

  HttpHandlerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  HttpHandlerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  HttpHandlerStub.unbound() : super.unbound();

  static HttpHandlerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpHandlerStub.fromEndpoint(endpoint);

  static const String name = HttpHandlerName;


  HttpHandlerHandleRequestResponseParams _HttpHandlerHandleRequestResponseParamsFactory(http_response_mojom.HttpResponse response) {
    var result = new HttpHandlerHandleRequestResponseParams();
    result.response = response;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kHttpHandler_handleRequest_name:
        var params = HttpHandlerHandleRequestParams.deserialize(
            message.payload);
        return _impl.handleRequest(params.request,_HttpHandlerHandleRequestResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kHttpHandler_handleRequest_name,
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

  HttpHandler get impl => _impl;
      set impl(HttpHandler d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "HttpHandlerStub($superString)";
  }
}


