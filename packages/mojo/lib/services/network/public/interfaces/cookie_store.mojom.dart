// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library cookie_store.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class CookieStoreGetParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;

  CookieStoreGetParams() : super(kStructSize);

  static CookieStoreGetParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CookieStoreGetParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CookieStoreGetParams result = new CookieStoreGetParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.url = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(url, 8, false);
  }

  String toString() {
    return "CookieStoreGetParams("
           "url: $url" ")";
  }
}

class CookieStoreGetResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String cookies = null;

  CookieStoreGetResponseParams() : super(kStructSize);

  static CookieStoreGetResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CookieStoreGetResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CookieStoreGetResponseParams result = new CookieStoreGetResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.cookies = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(cookies, 8, false);
  }

  String toString() {
    return "CookieStoreGetResponseParams("
           "cookies: $cookies" ")";
  }
}

class CookieStoreSetParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;
  String cookie = null;

  CookieStoreSetParams() : super(kStructSize);

  static CookieStoreSetParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CookieStoreSetParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CookieStoreSetParams result = new CookieStoreSetParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.url = decoder0.decodeString(8, false);
    }
    {
      
      result.cookie = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(url, 8, false);
    
    encoder0.encodeString(cookie, 16, false);
  }

  String toString() {
    return "CookieStoreSetParams("
           "url: $url" ", "
           "cookie: $cookie" ")";
  }
}

class CookieStoreSetResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool success = false;

  CookieStoreSetResponseParams() : super(kStructSize);

  static CookieStoreSetResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CookieStoreSetResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CookieStoreSetResponseParams result = new CookieStoreSetResponseParams();

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
    return "CookieStoreSetResponseParams("
           "success: $success" ")";
  }
}
const int kCookieStore_get_name = 0;
const int kCookieStore_set_name = 1;

const String CookieStoreName =
      'mojo::CookieStore';

abstract class CookieStore {
  Future<CookieStoreGetResponseParams> get(String url,[Function responseFactory = null]);
  Future<CookieStoreSetResponseParams> set(String url,String cookie,[Function responseFactory = null]);

}


class CookieStoreProxyImpl extends bindings.Proxy {
  CookieStoreProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CookieStoreProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CookieStoreProxyImpl.unbound() : super.unbound();

  static CookieStoreProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CookieStoreProxyImpl.fromEndpoint(endpoint);

  String get name => CookieStoreName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kCookieStore_get_name:
        var r = CookieStoreGetResponseParams.deserialize(
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
      case kCookieStore_set_name:
        var r = CookieStoreSetResponseParams.deserialize(
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
    return "CookieStoreProxyImpl($superString)";
  }
}


class _CookieStoreProxyCalls implements CookieStore {
  CookieStoreProxyImpl _proxyImpl;

  _CookieStoreProxyCalls(this._proxyImpl);
    Future<CookieStoreGetResponseParams> get(String url,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CookieStoreGetParams();
      params.url = url;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCookieStore_get_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<CookieStoreSetResponseParams> set(String url,String cookie,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CookieStoreSetParams();
      params.url = url;
      params.cookie = cookie;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCookieStore_set_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class CookieStoreProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CookieStore ptr;
  final String name = CookieStoreName;

  CookieStoreProxy(CookieStoreProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CookieStoreProxyCalls(proxyImpl);

  CookieStoreProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CookieStoreProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CookieStoreProxyCalls(impl);
  }

  CookieStoreProxy.fromHandle(core.MojoHandle handle) :
      impl = new CookieStoreProxyImpl.fromHandle(handle) {
    ptr = new _CookieStoreProxyCalls(impl);
  }

  CookieStoreProxy.unbound() :
      impl = new CookieStoreProxyImpl.unbound() {
    ptr = new _CookieStoreProxyCalls(impl);
  }

  static CookieStoreProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CookieStoreProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "CookieStoreProxy($impl)";
  }
}


class CookieStoreStub extends bindings.Stub {
  CookieStore _impl = null;

  CookieStoreStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CookieStoreStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CookieStoreStub.unbound() : super.unbound();

  static CookieStoreStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CookieStoreStub.fromEndpoint(endpoint);

  static const String name = CookieStoreName;


  CookieStoreGetResponseParams _CookieStoreGetResponseParamsFactory(String cookies) {
    var result = new CookieStoreGetResponseParams();
    result.cookies = cookies;
    return result;
  }
  CookieStoreSetResponseParams _CookieStoreSetResponseParamsFactory(bool success) {
    var result = new CookieStoreSetResponseParams();
    result.success = success;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCookieStore_get_name:
        var params = CookieStoreGetParams.deserialize(
            message.payload);
        return _impl.get(params.url,_CookieStoreGetResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCookieStore_get_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kCookieStore_set_name:
        var params = CookieStoreSetParams.deserialize(
            message.payload);
        return _impl.set(params.url,params.cookie,_CookieStoreSetResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCookieStore_set_name,
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

  CookieStore get impl => _impl;
      set impl(CookieStore d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CookieStoreStub($superString)";
  }
}


