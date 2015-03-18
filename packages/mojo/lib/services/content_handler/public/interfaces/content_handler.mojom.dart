// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library content_handler.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/public/interfaces/application/application.mojom.dart' as application_mojom;
import 'package:mojo/services/network/public/interfaces/url_loader.mojom.dart' as url_loader_mojom;


class ContentHandlerStartApplicationParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object application = null;
  url_loader_mojom.UrlResponse response = null;

  ContentHandlerStartApplicationParams() : super(kStructSize);

  static ContentHandlerStartApplicationParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ContentHandlerStartApplicationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ContentHandlerStartApplicationParams result = new ContentHandlerStartApplicationParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.application = decoder0.decodeInterfaceRequest(8, false, application_mojom.ApplicationStub.newFromEndpoint);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.response = url_loader_mojom.UrlResponse.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterfaceRequest(application, 8, false);
    
    encoder0.encodeStruct(response, 16, false);
  }

  String toString() {
    return "ContentHandlerStartApplicationParams("
           "application: $application" ", "
           "response: $response" ")";
  }
}
const int kContentHandler_startApplication_name = 0;

const String ContentHandlerName =
      'mojo::ContentHandler';

abstract class ContentHandler {
  void startApplication(Object application, url_loader_mojom.UrlResponse response);

}


class ContentHandlerProxyImpl extends bindings.Proxy {
  ContentHandlerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ContentHandlerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ContentHandlerProxyImpl.unbound() : super.unbound();

  static ContentHandlerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContentHandlerProxyImpl.fromEndpoint(endpoint);

  String get name => ContentHandlerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ContentHandlerProxyImpl($superString)";
  }
}


class _ContentHandlerProxyCalls implements ContentHandler {
  ContentHandlerProxyImpl _proxyImpl;

  _ContentHandlerProxyCalls(this._proxyImpl);
    void startApplication(Object application, url_loader_mojom.UrlResponse response) {
      assert(_proxyImpl.isBound);
      var params = new ContentHandlerStartApplicationParams();
      params.application = application;
      params.response = response;
      _proxyImpl.sendMessage(params, kContentHandler_startApplication_name);
    }
  
}


class ContentHandlerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ContentHandler ptr;
  final String name = ContentHandlerName;

  ContentHandlerProxy(ContentHandlerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ContentHandlerProxyCalls(proxyImpl);

  ContentHandlerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ContentHandlerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ContentHandlerProxyCalls(impl);
  }

  ContentHandlerProxy.fromHandle(core.MojoHandle handle) :
      impl = new ContentHandlerProxyImpl.fromHandle(handle) {
    ptr = new _ContentHandlerProxyCalls(impl);
  }

  ContentHandlerProxy.unbound() :
      impl = new ContentHandlerProxyImpl.unbound() {
    ptr = new _ContentHandlerProxyCalls(impl);
  }

  static ContentHandlerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContentHandlerProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "ContentHandlerProxy($impl)";
  }
}


class ContentHandlerStub extends bindings.Stub {
  ContentHandler _impl = null;

  ContentHandlerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ContentHandlerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ContentHandlerStub.unbound() : super.unbound();

  static ContentHandlerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContentHandlerStub.fromEndpoint(endpoint);

  static const String name = ContentHandlerName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kContentHandler_startApplication_name:
        var params = ContentHandlerStartApplicationParams.deserialize(
            message.payload);
        _impl.startApplication(params.application, params.response);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ContentHandler get impl => _impl;
      set impl(ContentHandler d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ContentHandlerStub($superString)";
  }
}


