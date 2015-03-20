// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library url_loader.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/network/public/interfaces/network_error.mojom.dart' as network_error_mojom;


class UrlRequest extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;
  String method = "GET";
  List<String> headers = null;
  List<core.MojoDataPipeConsumer> body = null;
  int responseBodyBufferSize = 0;
  bool autoFollowRedirects = false;
  bool bypassCache = false;

  UrlRequest() : super(kStructSize);

  static UrlRequest deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlRequest decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlRequest result = new UrlRequest();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.url = decoder0.decodeString(8, false);
    }
    {
      
      result.method = decoder0.decodeString(16, false);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, true);
      if (decoder1 == null) {
        result.headers = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.headers = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.headers[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      result.body = decoder0.decodeConsumerHandleArray(32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.responseBodyBufferSize = decoder0.decodeUint32(40);
    }
    {
      
      result.autoFollowRedirects = decoder0.decodeBool(44, 0);
    }
    {
      
      result.bypassCache = decoder0.decodeBool(44, 1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(url, 8, false);
    
    encoder0.encodeString(method, 16, false);
    
    if (headers == null) {
      encoder0.encodeNullPointer(24, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(headers.length, 24, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < headers.length; ++i0) {
        
        encoder1.encodeString(headers[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeConsumerHandleArray(body, 32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeUint32(responseBodyBufferSize, 40);
    
    encoder0.encodeBool(autoFollowRedirects, 44, 0);
    
    encoder0.encodeBool(bypassCache, 44, 1);
  }

  String toString() {
    return "UrlRequest("
           "url: $url" ", "
           "method: $method" ", "
           "headers: $headers" ", "
           "body: $body" ", "
           "responseBodyBufferSize: $responseBodyBufferSize" ", "
           "autoFollowRedirects: $autoFollowRedirects" ", "
           "bypassCache: $bypassCache" ")";
  }
}

class UrlResponse extends bindings.Struct {
  static const int kStructSize = 80;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError error = null;
  core.MojoDataPipeConsumer body = null;
  int statusCode = 0;
  String url = null;
  String statusLine = null;
  List<String> headers = null;
  String mimeType = null;
  String charset = null;
  String redirectMethod = null;
  String redirectUrl = null;

  UrlResponse() : super(kStructSize);

  static UrlResponse deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlResponse decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlResponse result = new UrlResponse();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.error = network_error_mojom.NetworkError.decode(decoder1);
    }
    {
      
      result.body = decoder0.decodeConsumerHandle(16, true);
    }
    {
      
      result.statusCode = decoder0.decodeUint32(20);
    }
    {
      
      result.url = decoder0.decodeString(24, true);
    }
    {
      
      result.statusLine = decoder0.decodeString(32, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.headers = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.headers = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.headers[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      result.mimeType = decoder0.decodeString(48, true);
    }
    {
      
      result.charset = decoder0.decodeString(56, true);
    }
    {
      
      result.redirectMethod = decoder0.decodeString(64, true);
    }
    {
      
      result.redirectUrl = decoder0.decodeString(72, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(error, 8, true);
    
    encoder0.encodeConsumerHandle(body, 16, true);
    
    encoder0.encodeUint32(statusCode, 20);
    
    encoder0.encodeString(url, 24, true);
    
    encoder0.encodeString(statusLine, 32, true);
    
    if (headers == null) {
      encoder0.encodeNullPointer(40, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(headers.length, 40, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < headers.length; ++i0) {
        
        encoder1.encodeString(headers[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeString(mimeType, 48, true);
    
    encoder0.encodeString(charset, 56, true);
    
    encoder0.encodeString(redirectMethod, 64, true);
    
    encoder0.encodeString(redirectUrl, 72, true);
  }

  String toString() {
    return "UrlResponse("
           "error: $error" ", "
           "body: $body" ", "
           "statusCode: $statusCode" ", "
           "url: $url" ", "
           "statusLine: $statusLine" ", "
           "headers: $headers" ", "
           "mimeType: $mimeType" ", "
           "charset: $charset" ", "
           "redirectMethod: $redirectMethod" ", "
           "redirectUrl: $redirectUrl" ")";
  }
}

class UrlLoaderStatus extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  network_error_mojom.NetworkError error = null;
  bool isLoading = false;

  UrlLoaderStatus() : super(kStructSize);

  static UrlLoaderStatus deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderStatus decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderStatus result = new UrlLoaderStatus();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.error = network_error_mojom.NetworkError.decode(decoder1);
    }
    {
      
      result.isLoading = decoder0.decodeBool(16, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(error, 8, true);
    
    encoder0.encodeBool(isLoading, 16, 0);
  }

  String toString() {
    return "UrlLoaderStatus("
           "error: $error" ", "
           "isLoading: $isLoading" ")";
  }
}

class UrlLoaderStartParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  UrlRequest request = null;

  UrlLoaderStartParams() : super(kStructSize);

  static UrlLoaderStartParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderStartParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderStartParams result = new UrlLoaderStartParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.request = UrlRequest.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(request, 8, false);
  }

  String toString() {
    return "UrlLoaderStartParams("
           "request: $request" ")";
  }
}

class UrlLoaderStartResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  UrlResponse response = null;

  UrlLoaderStartResponseParams() : super(kStructSize);

  static UrlLoaderStartResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderStartResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderStartResponseParams result = new UrlLoaderStartResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.response = UrlResponse.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(response, 8, false);
  }

  String toString() {
    return "UrlLoaderStartResponseParams("
           "response: $response" ")";
  }
}

class UrlLoaderFollowRedirectParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  UrlLoaderFollowRedirectParams() : super(kStructSize);

  static UrlLoaderFollowRedirectParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderFollowRedirectParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderFollowRedirectParams result = new UrlLoaderFollowRedirectParams();

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
    return "UrlLoaderFollowRedirectParams("")";
  }
}

class UrlLoaderFollowRedirectResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  UrlResponse response = null;

  UrlLoaderFollowRedirectResponseParams() : super(kStructSize);

  static UrlLoaderFollowRedirectResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderFollowRedirectResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderFollowRedirectResponseParams result = new UrlLoaderFollowRedirectResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.response = UrlResponse.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(response, 8, false);
  }

  String toString() {
    return "UrlLoaderFollowRedirectResponseParams("
           "response: $response" ")";
  }
}

class UrlLoaderQueryStatusParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  UrlLoaderQueryStatusParams() : super(kStructSize);

  static UrlLoaderQueryStatusParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderQueryStatusParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderQueryStatusParams result = new UrlLoaderQueryStatusParams();

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
    return "UrlLoaderQueryStatusParams("")";
  }
}

class UrlLoaderQueryStatusResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  UrlLoaderStatus status = null;

  UrlLoaderQueryStatusResponseParams() : super(kStructSize);

  static UrlLoaderQueryStatusResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UrlLoaderQueryStatusResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlLoaderQueryStatusResponseParams result = new UrlLoaderQueryStatusResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.status = UrlLoaderStatus.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(status, 8, false);
  }

  String toString() {
    return "UrlLoaderQueryStatusResponseParams("
           "status: $status" ")";
  }
}
const int kUrlLoader_start_name = 0;
const int kUrlLoader_followRedirect_name = 1;
const int kUrlLoader_queryStatus_name = 2;

const String UrlLoaderName =
      'mojo::UrlLoader';

abstract class UrlLoader {
  Future<UrlLoaderStartResponseParams> start(UrlRequest request,[Function responseFactory = null]);
  Future<UrlLoaderFollowRedirectResponseParams> followRedirect([Function responseFactory = null]);
  Future<UrlLoaderQueryStatusResponseParams> queryStatus([Function responseFactory = null]);

}


class UrlLoaderProxyImpl extends bindings.Proxy {
  UrlLoaderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  UrlLoaderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  UrlLoaderProxyImpl.unbound() : super.unbound();

  static UrlLoaderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UrlLoaderProxyImpl.fromEndpoint(endpoint);

  String get name => UrlLoaderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kUrlLoader_start_name:
        var r = UrlLoaderStartResponseParams.deserialize(
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
      case kUrlLoader_followRedirect_name:
        var r = UrlLoaderFollowRedirectResponseParams.deserialize(
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
      case kUrlLoader_queryStatus_name:
        var r = UrlLoaderQueryStatusResponseParams.deserialize(
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
    return "UrlLoaderProxyImpl($superString)";
  }
}


class _UrlLoaderProxyCalls implements UrlLoader {
  UrlLoaderProxyImpl _proxyImpl;

  _UrlLoaderProxyCalls(this._proxyImpl);
    Future<UrlLoaderStartResponseParams> start(UrlRequest request,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UrlLoaderStartParams();
      params.request = request;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUrlLoader_start_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UrlLoaderFollowRedirectResponseParams> followRedirect([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UrlLoaderFollowRedirectParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUrlLoader_followRedirect_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<UrlLoaderQueryStatusResponseParams> queryStatus([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new UrlLoaderQueryStatusParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kUrlLoader_queryStatus_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class UrlLoaderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  UrlLoader ptr;
  final String name = UrlLoaderName;

  UrlLoaderProxy(UrlLoaderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _UrlLoaderProxyCalls(proxyImpl);

  UrlLoaderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new UrlLoaderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _UrlLoaderProxyCalls(impl);
  }

  UrlLoaderProxy.fromHandle(core.MojoHandle handle) :
      impl = new UrlLoaderProxyImpl.fromHandle(handle) {
    ptr = new _UrlLoaderProxyCalls(impl);
  }

  UrlLoaderProxy.unbound() :
      impl = new UrlLoaderProxyImpl.unbound() {
    ptr = new _UrlLoaderProxyCalls(impl);
  }

  static UrlLoaderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UrlLoaderProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "UrlLoaderProxy($impl)";
  }
}


class UrlLoaderStub extends bindings.Stub {
  UrlLoader _impl = null;

  UrlLoaderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  UrlLoaderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  UrlLoaderStub.unbound() : super.unbound();

  static UrlLoaderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new UrlLoaderStub.fromEndpoint(endpoint);

  static const String name = UrlLoaderName;


  UrlLoaderStartResponseParams _UrlLoaderStartResponseParamsFactory(UrlResponse response) {
    var result = new UrlLoaderStartResponseParams();
    result.response = response;
    return result;
  }
  UrlLoaderFollowRedirectResponseParams _UrlLoaderFollowRedirectResponseParamsFactory(UrlResponse response) {
    var result = new UrlLoaderFollowRedirectResponseParams();
    result.response = response;
    return result;
  }
  UrlLoaderQueryStatusResponseParams _UrlLoaderQueryStatusResponseParamsFactory(UrlLoaderStatus status) {
    var result = new UrlLoaderQueryStatusResponseParams();
    result.status = status;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kUrlLoader_start_name:
        var params = UrlLoaderStartParams.deserialize(
            message.payload);
        return _impl.start(params.request,_UrlLoaderStartResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUrlLoader_start_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUrlLoader_followRedirect_name:
        var params = UrlLoaderFollowRedirectParams.deserialize(
            message.payload);
        return _impl.followRedirect(_UrlLoaderFollowRedirectResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUrlLoader_followRedirect_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kUrlLoader_queryStatus_name:
        var params = UrlLoaderQueryStatusParams.deserialize(
            message.payload);
        return _impl.queryStatus(_UrlLoaderQueryStatusResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kUrlLoader_queryStatus_name,
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

  UrlLoader get impl => _impl;
      set impl(UrlLoader d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "UrlLoaderStub($superString)";
  }
}


