// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library service_provider.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class ServiceProviderConnectToServiceParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String interfaceName = null;
  core.MojoMessagePipeEndpoint pipe = null;

  ServiceProviderConnectToServiceParams() : super(kVersions.last.size);

  static ServiceProviderConnectToServiceParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ServiceProviderConnectToServiceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceProviderConnectToServiceParams result = new ServiceProviderConnectToServiceParams();

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
      
      result.interfaceName = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.pipe = decoder0.decodeMessagePipeHandle(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(interfaceName, 8, false);
    
    encoder0.encodeMessagePipeHandle(pipe, 16, false);
  }

  String toString() {
    return "ServiceProviderConnectToServiceParams("
           "interfaceName: $interfaceName" ", "
           "pipe: $pipe" ")";
  }
}
const int kServiceProvider_connectToService_name = 0;

const String ServiceProviderName =
      'mojo::ServiceProvider';

abstract class ServiceProvider {
  void connectToService(String interfaceName, core.MojoMessagePipeEndpoint pipe);

}


class ServiceProviderProxyImpl extends bindings.Proxy {
  ServiceProviderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ServiceProviderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ServiceProviderProxyImpl.unbound() : super.unbound();

  static ServiceProviderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceProviderProxyImpl.fromEndpoint(endpoint);

  String get name => ServiceProviderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ServiceProviderProxyImpl($superString)";
  }
}


class _ServiceProviderProxyCalls implements ServiceProvider {
  ServiceProviderProxyImpl _proxyImpl;

  _ServiceProviderProxyCalls(this._proxyImpl);
    void connectToService(String interfaceName, core.MojoMessagePipeEndpoint pipe) {
      assert(_proxyImpl.isBound);
      var params = new ServiceProviderConnectToServiceParams();
      params.interfaceName = interfaceName;
      params.pipe = pipe;
      _proxyImpl.sendMessage(params, kServiceProvider_connectToService_name);
    }
  
}


class ServiceProviderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ServiceProvider ptr;
  final String name = ServiceProviderName;

  ServiceProviderProxy(ServiceProviderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ServiceProviderProxyCalls(proxyImpl);

  ServiceProviderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ServiceProviderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ServiceProviderProxyCalls(impl);
  }

  ServiceProviderProxy.fromHandle(core.MojoHandle handle) :
      impl = new ServiceProviderProxyImpl.fromHandle(handle) {
    ptr = new _ServiceProviderProxyCalls(impl);
  }

  ServiceProviderProxy.unbound() :
      impl = new ServiceProviderProxyImpl.unbound() {
    ptr = new _ServiceProviderProxyCalls(impl);
  }

  static ServiceProviderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceProviderProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "ServiceProviderProxy($impl)";
  }
}


class ServiceProviderStub extends bindings.Stub {
  ServiceProvider _impl = null;

  ServiceProviderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ServiceProviderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ServiceProviderStub.unbound() : super.unbound();

  static ServiceProviderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceProviderStub.fromEndpoint(endpoint);

  static const String name = ServiceProviderName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kServiceProvider_connectToService_name:
        var params = ServiceProviderConnectToServiceParams.deserialize(
            message.payload);
        _impl.connectToService(params.interfaceName, params.pipe);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ServiceProvider get impl => _impl;
      set impl(ServiceProvider d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ServiceProviderStub($superString)";
  }
}


