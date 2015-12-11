// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library application_connector_mojom;

import 'dart:async';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as service_provider_mojom;



class ApplicationConnectorConnectToApplicationParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  String applicationUrl = null;
  Object services = null;
  Object exposedServices = null;

  ApplicationConnectorConnectToApplicationParams() : super(kVersions.last.size);

  static ApplicationConnectorConnectToApplicationParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ApplicationConnectorConnectToApplicationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ApplicationConnectorConnectToApplicationParams result = new ApplicationConnectorConnectToApplicationParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.applicationUrl = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.services = decoder0.decodeInterfaceRequest(16, true, service_provider_mojom.ServiceProviderStub.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      result.exposedServices = decoder0.decodeServiceInterface(20, true, service_provider_mojom.ServiceProviderProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(applicationUrl, 8, false);
    
    encoder0.encodeInterfaceRequest(services, 16, true);
    
    encoder0.encodeInterface(exposedServices, 20, true);
  }

  String toString() {
    return "ApplicationConnectorConnectToApplicationParams("
           "applicationUrl: $applicationUrl" ", "
           "services: $services" ", "
           "exposedServices: $exposedServices" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class ApplicationConnectorDuplicateParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object applicationConnectorRequest = null;

  ApplicationConnectorDuplicateParams() : super(kVersions.last.size);

  static ApplicationConnectorDuplicateParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ApplicationConnectorDuplicateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ApplicationConnectorDuplicateParams result = new ApplicationConnectorDuplicateParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.applicationConnectorRequest = decoder0.decodeInterfaceRequest(8, false, ApplicationConnectorStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(applicationConnectorRequest, 8, false);
  }

  String toString() {
    return "ApplicationConnectorDuplicateParams("
           "applicationConnectorRequest: $applicationConnectorRequest" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}

const int kApplicationConnector_connectToApplication_name = 0;
const int kApplicationConnector_duplicate_name = 1;
const String ApplicationConnectorName = null;

abstract class ApplicationConnector {
  void connectToApplication(String applicationUrl, Object services, Object exposedServices);
  void duplicate(Object applicationConnectorRequest);

}


class ApplicationConnectorProxyImpl extends bindings.Proxy {
  ApplicationConnectorProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ApplicationConnectorProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ApplicationConnectorProxyImpl.unbound() : super.unbound();

  static ApplicationConnectorProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationConnectorProxyImpl"));
    return new ApplicationConnectorProxyImpl.fromEndpoint(endpoint);
  }

  String get name => ApplicationConnectorName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        proxyError("Unexpected message type: ${message.header.type}");
        close(immediate: true);
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ApplicationConnectorProxyImpl($superString)";
  }
}


class _ApplicationConnectorProxyCalls implements ApplicationConnector {
  ApplicationConnectorProxyImpl _proxyImpl;

  _ApplicationConnectorProxyCalls(this._proxyImpl);
    void connectToApplication(String applicationUrl, Object services, Object exposedServices) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ApplicationConnectorConnectToApplicationParams();
      params.applicationUrl = applicationUrl;
      params.services = services;
      params.exposedServices = exposedServices;
      _proxyImpl.sendMessage(params, kApplicationConnector_connectToApplication_name);
    }
  
    void duplicate(Object applicationConnectorRequest) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ApplicationConnectorDuplicateParams();
      params.applicationConnectorRequest = applicationConnectorRequest;
      _proxyImpl.sendMessage(params, kApplicationConnector_duplicate_name);
    }
  
}


class ApplicationConnectorProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ApplicationConnector ptr;
  final String name = ApplicationConnectorName;

  ApplicationConnectorProxy(ApplicationConnectorProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ApplicationConnectorProxyCalls(proxyImpl);

  ApplicationConnectorProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ApplicationConnectorProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ApplicationConnectorProxyCalls(impl);
  }

  ApplicationConnectorProxy.fromHandle(core.MojoHandle handle) :
      impl = new ApplicationConnectorProxyImpl.fromHandle(handle) {
    ptr = new _ApplicationConnectorProxyCalls(impl);
  }

  ApplicationConnectorProxy.unbound() :
      impl = new ApplicationConnectorProxyImpl.unbound() {
    ptr = new _ApplicationConnectorProxyCalls(impl);
  }

  factory ApplicationConnectorProxy.connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ApplicationConnectorProxy p = new ApplicationConnectorProxy.unbound();
    s.connectToService(url, p, serviceName);
    return p;
  }

  static ApplicationConnectorProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationConnectorProxy"));
    return new ApplicationConnectorProxy.fromEndpoint(endpoint);
  }

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  Future responseOrError(Future f) => impl.responseOrError(f);

  Future get errorFuture => impl.errorFuture;

  int get version => impl.version;

  Future<int> queryVersion() => impl.queryVersion();

  void requireVersion(int requiredVersion) {
    impl.requireVersion(requiredVersion);
  }

  String toString() {
    return "ApplicationConnectorProxy($impl)";
  }
}


class ApplicationConnectorStub extends bindings.Stub {
  ApplicationConnector _impl = null;

  ApplicationConnectorStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ApplicationConnectorStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ApplicationConnectorStub.unbound() : super.unbound();

  static ApplicationConnectorStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationConnectorStub"));
    return new ApplicationConnectorStub.fromEndpoint(endpoint);
  }

  static const String name = ApplicationConnectorName;



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case kApplicationConnector_connectToApplication_name:
        var params = ApplicationConnectorConnectToApplicationParams.deserialize(
            message.payload);
        _impl.connectToApplication(params.applicationUrl, params.services, params.exposedServices);
        break;
      case kApplicationConnector_duplicate_name:
        var params = ApplicationConnectorDuplicateParams.deserialize(
            message.payload);
        _impl.duplicate(params.applicationConnectorRequest);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ApplicationConnector get impl => _impl;
  set impl(ApplicationConnector d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ApplicationConnectorStub($superString)";
  }

  int get version => 0;
}


