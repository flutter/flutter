// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library shell_mojom;

import 'dart:async';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/application_connector.mojom.dart' as application_connector_mojom;
import 'package:mojo/mojo/service_provider.mojom.dart' as service_provider_mojom;



class ShellConnectToApplicationParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  String applicationUrl = null;
  Object services = null;
  Object exposedServices = null;

  ShellConnectToApplicationParams() : super(kVersions.last.size);

  static ShellConnectToApplicationParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ShellConnectToApplicationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ShellConnectToApplicationParams result = new ShellConnectToApplicationParams();

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
    return "ShellConnectToApplicationParams("
           "applicationUrl: $applicationUrl" ", "
           "services: $services" ", "
           "exposedServices: $exposedServices" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class ShellCreateApplicationConnectorParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object applicationConnectorRequest = null;

  ShellCreateApplicationConnectorParams() : super(kVersions.last.size);

  static ShellCreateApplicationConnectorParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ShellCreateApplicationConnectorParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ShellCreateApplicationConnectorParams result = new ShellCreateApplicationConnectorParams();

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
      
      result.applicationConnectorRequest = decoder0.decodeInterfaceRequest(8, false, application_connector_mojom.ApplicationConnectorStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(applicationConnectorRequest, 8, false);
  }

  String toString() {
    return "ShellCreateApplicationConnectorParams("
           "applicationConnectorRequest: $applicationConnectorRequest" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}

const int kShell_connectToApplication_name = 0;
const int kShell_createApplicationConnector_name = 1;
const String ShellName = null;

abstract class Shell {
  void connectToApplication(String applicationUrl, Object services, Object exposedServices);
  void createApplicationConnector(Object applicationConnectorRequest);

}


class ShellProxyImpl extends bindings.Proxy {
  ShellProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ShellProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ShellProxyImpl.unbound() : super.unbound();

  static ShellProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ShellProxyImpl"));
    return new ShellProxyImpl.fromEndpoint(endpoint);
  }

  String get name => ShellName;

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
    return "ShellProxyImpl($superString)";
  }
}


class _ShellProxyCalls implements Shell {
  ShellProxyImpl _proxyImpl;

  _ShellProxyCalls(this._proxyImpl);
    void connectToApplication(String applicationUrl, Object services, Object exposedServices) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ShellConnectToApplicationParams();
      params.applicationUrl = applicationUrl;
      params.services = services;
      params.exposedServices = exposedServices;
      _proxyImpl.sendMessage(params, kShell_connectToApplication_name);
    }
  
    void createApplicationConnector(Object applicationConnectorRequest) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ShellCreateApplicationConnectorParams();
      params.applicationConnectorRequest = applicationConnectorRequest;
      _proxyImpl.sendMessage(params, kShell_createApplicationConnector_name);
    }
  
}


class ShellProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Shell ptr;
  final String name = ShellName;

  ShellProxy(ShellProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ShellProxyCalls(proxyImpl);

  ShellProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ShellProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ShellProxyCalls(impl);
  }

  ShellProxy.fromHandle(core.MojoHandle handle) :
      impl = new ShellProxyImpl.fromHandle(handle) {
    ptr = new _ShellProxyCalls(impl);
  }

  ShellProxy.unbound() :
      impl = new ShellProxyImpl.unbound() {
    ptr = new _ShellProxyCalls(impl);
  }

  factory ShellProxy.connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ShellProxy p = new ShellProxy.unbound();
    s.connectToService(url, p, serviceName);
    return p;
  }

  static ShellProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ShellProxy"));
    return new ShellProxy.fromEndpoint(endpoint);
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
    return "ShellProxy($impl)";
  }
}


class ShellStub extends bindings.Stub {
  Shell _impl = null;

  ShellStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ShellStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ShellStub.unbound() : super.unbound();

  static ShellStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ShellStub"));
    return new ShellStub.fromEndpoint(endpoint);
  }

  static const String name = ShellName;



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case kShell_connectToApplication_name:
        var params = ShellConnectToApplicationParams.deserialize(
            message.payload);
        _impl.connectToApplication(params.applicationUrl, params.services, params.exposedServices);
        break;
      case kShell_createApplicationConnector_name:
        var params = ShellCreateApplicationConnectorParams.deserialize(
            message.payload);
        _impl.createApplicationConnector(params.applicationConnectorRequest);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Shell get impl => _impl;
  set impl(Shell d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ShellStub($superString)";
  }

  int get version => 0;
}


