// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library navigation.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/network/public/interfaces/url_loader.mojom.dart' as url_loader_mojom;

final int Target_DEFAULT = 0;
final int Target_SOURCE_NODE = Target_DEFAULT + 1;
final int Target_NEW_NODE = Target_SOURCE_NODE + 1;


class NavigatorHostRequestNavigateParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int target = 0;
  url_loader_mojom.UrlRequest request = null;

  NavigatorHostRequestNavigateParams() : super(kStructSize);

  static NavigatorHostRequestNavigateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NavigatorHostRequestNavigateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NavigatorHostRequestNavigateParams result = new NavigatorHostRequestNavigateParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.target = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.request = url_loader_mojom.UrlRequest.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(target, 8);
    
    encoder0.encodeStruct(request, 16, false);
  }

  String toString() {
    return "NavigatorHostRequestNavigateParams("
           "target: $target" ", "
           "request: $request" ")";
  }
}

class NavigatorHostRequestNavigateHistoryParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int delta = 0;

  NavigatorHostRequestNavigateHistoryParams() : super(kStructSize);

  static NavigatorHostRequestNavigateHistoryParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NavigatorHostRequestNavigateHistoryParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NavigatorHostRequestNavigateHistoryParams result = new NavigatorHostRequestNavigateHistoryParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.delta = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(delta, 8);
  }

  String toString() {
    return "NavigatorHostRequestNavigateHistoryParams("
           "delta: $delta" ")";
  }
}

class NavigatorHostDidNavigateLocallyParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;

  NavigatorHostDidNavigateLocallyParams() : super(kStructSize);

  static NavigatorHostDidNavigateLocallyParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NavigatorHostDidNavigateLocallyParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NavigatorHostDidNavigateLocallyParams result = new NavigatorHostDidNavigateLocallyParams();

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
    return "NavigatorHostDidNavigateLocallyParams("
           "url: $url" ")";
  }
}
const int kNavigatorHost_requestNavigate_name = 0;
const int kNavigatorHost_requestNavigateHistory_name = 1;
const int kNavigatorHost_didNavigateLocally_name = 2;

const String NavigatorHostName =
      'mojo::NavigatorHost';

abstract class NavigatorHost {
  void requestNavigate(int target, url_loader_mojom.UrlRequest request);
  void requestNavigateHistory(int delta);
  void didNavigateLocally(String url);

}


class NavigatorHostProxyImpl extends bindings.Proxy {
  NavigatorHostProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  NavigatorHostProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  NavigatorHostProxyImpl.unbound() : super.unbound();

  static NavigatorHostProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new NavigatorHostProxyImpl.fromEndpoint(endpoint);

  String get name => NavigatorHostName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "NavigatorHostProxyImpl($superString)";
  }
}


class _NavigatorHostProxyCalls implements NavigatorHost {
  NavigatorHostProxyImpl _proxyImpl;

  _NavigatorHostProxyCalls(this._proxyImpl);
    void requestNavigate(int target, url_loader_mojom.UrlRequest request) {
      assert(_proxyImpl.isBound);
      var params = new NavigatorHostRequestNavigateParams();
      params.target = target;
      params.request = request;
      _proxyImpl.sendMessage(params, kNavigatorHost_requestNavigate_name);
    }
  
    void requestNavigateHistory(int delta) {
      assert(_proxyImpl.isBound);
      var params = new NavigatorHostRequestNavigateHistoryParams();
      params.delta = delta;
      _proxyImpl.sendMessage(params, kNavigatorHost_requestNavigateHistory_name);
    }
  
    void didNavigateLocally(String url) {
      assert(_proxyImpl.isBound);
      var params = new NavigatorHostDidNavigateLocallyParams();
      params.url = url;
      _proxyImpl.sendMessage(params, kNavigatorHost_didNavigateLocally_name);
    }
  
}


class NavigatorHostProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  NavigatorHost ptr;
  final String name = NavigatorHostName;

  NavigatorHostProxy(NavigatorHostProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _NavigatorHostProxyCalls(proxyImpl);

  NavigatorHostProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new NavigatorHostProxyImpl.fromEndpoint(endpoint) {
    ptr = new _NavigatorHostProxyCalls(impl);
  }

  NavigatorHostProxy.fromHandle(core.MojoHandle handle) :
      impl = new NavigatorHostProxyImpl.fromHandle(handle) {
    ptr = new _NavigatorHostProxyCalls(impl);
  }

  NavigatorHostProxy.unbound() :
      impl = new NavigatorHostProxyImpl.unbound() {
    ptr = new _NavigatorHostProxyCalls(impl);
  }

  static NavigatorHostProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new NavigatorHostProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "NavigatorHostProxy($impl)";
  }
}


class NavigatorHostStub extends bindings.Stub {
  NavigatorHost _impl = null;

  NavigatorHostStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  NavigatorHostStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  NavigatorHostStub.unbound() : super.unbound();

  static NavigatorHostStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new NavigatorHostStub.fromEndpoint(endpoint);

  static const String name = NavigatorHostName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kNavigatorHost_requestNavigate_name:
        var params = NavigatorHostRequestNavigateParams.deserialize(
            message.payload);
        _impl.requestNavigate(params.target, params.request);
        break;
      case kNavigatorHost_requestNavigateHistory_name:
        var params = NavigatorHostRequestNavigateHistoryParams.deserialize(
            message.payload);
        _impl.requestNavigateHistory(params.delta);
        break;
      case kNavigatorHost_didNavigateLocally_name:
        var params = NavigatorHostDidNavigateLocallyParams.deserialize(
            message.payload);
        _impl.didNavigateLocally(params.url);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  NavigatorHost get impl => _impl;
      set impl(NavigatorHost d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "NavigatorHostStub($superString)";
  }
}


