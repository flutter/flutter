// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library http_server_factory.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/http_server/public/interfaces/http_server.mojom.dart' as http_server_mojom;
import 'package:mojo/services/network/public/interfaces/net_address.mojom.dart' as net_address_mojom;


class HttpServerFactoryCreateHttpServerParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  Object serverRequest = null;
  net_address_mojom.NetAddress localAddress = null;

  HttpServerFactoryCreateHttpServerParams() : super(kVersions.last.size);

  static HttpServerFactoryCreateHttpServerParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpServerFactoryCreateHttpServerParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpServerFactoryCreateHttpServerParams result = new HttpServerFactoryCreateHttpServerParams();

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
      
      result.serverRequest = decoder0.decodeInterfaceRequest(8, false, http_server_mojom.HttpServerStub.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.localAddress = net_address_mojom.NetAddress.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(serverRequest, 8, false);
    
    encoder0.encodeStruct(localAddress, 16, true);
  }

  String toString() {
    return "HttpServerFactoryCreateHttpServerParams("
           "serverRequest: $serverRequest" ", "
           "localAddress: $localAddress" ")";
  }
}
const int kHttpServerFactory_createHttpServer_name = 0;

const String HttpServerFactoryName =
      'http_server::HttpServerFactory';

abstract class HttpServerFactory {
  void createHttpServer(Object serverRequest, net_address_mojom.NetAddress localAddress);

}


class HttpServerFactoryProxyImpl extends bindings.Proxy {
  HttpServerFactoryProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  HttpServerFactoryProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  HttpServerFactoryProxyImpl.unbound() : super.unbound();

  static HttpServerFactoryProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerFactoryProxyImpl.fromEndpoint(endpoint);

  String get name => HttpServerFactoryName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "HttpServerFactoryProxyImpl($superString)";
  }
}


class _HttpServerFactoryProxyCalls implements HttpServerFactory {
  HttpServerFactoryProxyImpl _proxyImpl;

  _HttpServerFactoryProxyCalls(this._proxyImpl);
    void createHttpServer(Object serverRequest, net_address_mojom.NetAddress localAddress) {
      assert(_proxyImpl.isBound);
      var params = new HttpServerFactoryCreateHttpServerParams();
      params.serverRequest = serverRequest;
      params.localAddress = localAddress;
      _proxyImpl.sendMessage(params, kHttpServerFactory_createHttpServer_name);
    }
  
}


class HttpServerFactoryProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  HttpServerFactory ptr;
  final String name = HttpServerFactoryName;

  HttpServerFactoryProxy(HttpServerFactoryProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _HttpServerFactoryProxyCalls(proxyImpl);

  HttpServerFactoryProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new HttpServerFactoryProxyImpl.fromEndpoint(endpoint) {
    ptr = new _HttpServerFactoryProxyCalls(impl);
  }

  HttpServerFactoryProxy.fromHandle(core.MojoHandle handle) :
      impl = new HttpServerFactoryProxyImpl.fromHandle(handle) {
    ptr = new _HttpServerFactoryProxyCalls(impl);
  }

  HttpServerFactoryProxy.unbound() :
      impl = new HttpServerFactoryProxyImpl.unbound() {
    ptr = new _HttpServerFactoryProxyCalls(impl);
  }

  static HttpServerFactoryProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerFactoryProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "HttpServerFactoryProxy($impl)";
  }
}


class HttpServerFactoryStub extends bindings.Stub {
  HttpServerFactory _impl = null;

  HttpServerFactoryStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  HttpServerFactoryStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  HttpServerFactoryStub.unbound() : super.unbound();

  static HttpServerFactoryStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new HttpServerFactoryStub.fromEndpoint(endpoint);

  static const String name = HttpServerFactoryName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kHttpServerFactory_createHttpServer_name:
        var params = HttpServerFactoryCreateHttpServerParams.deserialize(
            message.payload);
        _impl.createHttpServer(params.serverRequest, params.localAddress);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  HttpServerFactory get impl => _impl;
      set impl(HttpServerFactory d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "HttpServerFactoryStub($superString)";
  }
}


