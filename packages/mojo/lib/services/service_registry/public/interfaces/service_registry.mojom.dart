// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library service_registry.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/public/interfaces/application/service_provider.mojom.dart' as service_provider_mojom;


class ServiceRegistryAddServicesParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  List<String> interfaceNames = null;
  Object serviceProvider = null;

  ServiceRegistryAddServicesParams() : super(kVersions.last.size);

  static ServiceRegistryAddServicesParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ServiceRegistryAddServicesParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceRegistryAddServicesParams result = new ServiceRegistryAddServicesParams();

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
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.interfaceNames = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.interfaceNames[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.serviceProvider = decoder0.decodeServiceInterface(16, false, service_provider_mojom.ServiceProviderProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    if (interfaceNames == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(interfaceNames.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < interfaceNames.length; ++i0) {
        
        encoder1.encodeString(interfaceNames[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeInterface(serviceProvider, 16, false);
  }

  String toString() {
    return "ServiceRegistryAddServicesParams("
           "interfaceNames: $interfaceNames" ", "
           "serviceProvider: $serviceProvider" ")";
  }
}
const int kServiceRegistry_addServices_name = 0;

const String ServiceRegistryName =
      'mojo::ServiceRegistry';

abstract class ServiceRegistry {
  void addServices(List<String> interfaceNames, Object serviceProvider);

}


class ServiceRegistryProxyImpl extends bindings.Proxy {
  ServiceRegistryProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ServiceRegistryProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ServiceRegistryProxyImpl.unbound() : super.unbound();

  static ServiceRegistryProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceRegistryProxyImpl.fromEndpoint(endpoint);

  String get name => ServiceRegistryName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ServiceRegistryProxyImpl($superString)";
  }
}


class _ServiceRegistryProxyCalls implements ServiceRegistry {
  ServiceRegistryProxyImpl _proxyImpl;

  _ServiceRegistryProxyCalls(this._proxyImpl);
    void addServices(List<String> interfaceNames, Object serviceProvider) {
      assert(_proxyImpl.isBound);
      var params = new ServiceRegistryAddServicesParams();
      params.interfaceNames = interfaceNames;
      params.serviceProvider = serviceProvider;
      _proxyImpl.sendMessage(params, kServiceRegistry_addServices_name);
    }
  
}


class ServiceRegistryProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ServiceRegistry ptr;
  final String name = ServiceRegistryName;

  ServiceRegistryProxy(ServiceRegistryProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ServiceRegistryProxyCalls(proxyImpl);

  ServiceRegistryProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ServiceRegistryProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ServiceRegistryProxyCalls(impl);
  }

  ServiceRegistryProxy.fromHandle(core.MojoHandle handle) :
      impl = new ServiceRegistryProxyImpl.fromHandle(handle) {
    ptr = new _ServiceRegistryProxyCalls(impl);
  }

  ServiceRegistryProxy.unbound() :
      impl = new ServiceRegistryProxyImpl.unbound() {
    ptr = new _ServiceRegistryProxyCalls(impl);
  }

  static ServiceRegistryProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceRegistryProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "ServiceRegistryProxy($impl)";
  }
}


class ServiceRegistryStub extends bindings.Stub {
  ServiceRegistry _impl = null;

  ServiceRegistryStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ServiceRegistryStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ServiceRegistryStub.unbound() : super.unbound();

  static ServiceRegistryStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceRegistryStub.fromEndpoint(endpoint);

  static const String name = ServiceRegistryName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kServiceRegistry_addServices_name:
        var params = ServiceRegistryAddServicesParams.deserialize(
            message.payload);
        _impl.addServices(params.interfaceNames, params.serviceProvider);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ServiceRegistry get impl => _impl;
      set impl(ServiceRegistry d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ServiceRegistryStub($superString)";
  }
}


