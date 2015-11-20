// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library application_mojom;

import 'dart:async';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/service_provider.mojom.dart' as service_provider_mojom;
import 'package:mojo/mojo/shell.mojom.dart' as shell_mojom;



class ApplicationInitializeParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  Object shell = null;
  List<String> args = null;
  String url = null;

  ApplicationInitializeParams() : super(kVersions.last.size);

  static ApplicationInitializeParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ApplicationInitializeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ApplicationInitializeParams result = new ApplicationInitializeParams();

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
      
      result.shell = decoder0.decodeServiceInterface(8, false, shell_mojom.ShellProxy.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.args = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.args = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.args[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.url = decoder0.decodeString(24, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterface(shell, 8, false);
    
    if (args == null) {
      encoder0.encodeNullPointer(16, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(args.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < args.length; ++i0) {
        
        encoder1.encodeString(args[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeString(url, 24, false);
  }

  String toString() {
    return "ApplicationInitializeParams("
           "shell: $shell" ", "
           "args: $args" ", "
           "url: $url" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class ApplicationAcceptConnectionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  String requestorUrl = null;
  Object services = null;
  Object exposedServices = null;
  String resolvedUrl = null;

  ApplicationAcceptConnectionParams() : super(kVersions.last.size);

  static ApplicationAcceptConnectionParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ApplicationAcceptConnectionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ApplicationAcceptConnectionParams result = new ApplicationAcceptConnectionParams();

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
      
      result.requestorUrl = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.services = decoder0.decodeInterfaceRequest(16, true, service_provider_mojom.ServiceProviderStub.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      result.exposedServices = decoder0.decodeServiceInterface(20, true, service_provider_mojom.ServiceProviderProxy.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      result.resolvedUrl = decoder0.decodeString(32, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(requestorUrl, 8, false);
    
    encoder0.encodeInterfaceRequest(services, 16, true);
    
    encoder0.encodeInterface(exposedServices, 20, true);
    
    encoder0.encodeString(resolvedUrl, 32, false);
  }

  String toString() {
    return "ApplicationAcceptConnectionParams("
           "requestorUrl: $requestorUrl" ", "
           "services: $services" ", "
           "exposedServices: $exposedServices" ", "
           "resolvedUrl: $resolvedUrl" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class ApplicationRequestQuitParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  ApplicationRequestQuitParams() : super(kVersions.last.size);

  static ApplicationRequestQuitParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ApplicationRequestQuitParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ApplicationRequestQuitParams result = new ApplicationRequestQuitParams();

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
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kVersions.last);
  }

  String toString() {
    return "ApplicationRequestQuitParams("")";
  }

  Map toJson() {
    Map map = new Map();
    return map;
  }
}

const int kApplication_initialize_name = 0;
const int kApplication_acceptConnection_name = 1;
const int kApplication_requestQuit_name = 2;

const String ApplicationName =
      'mojo::Application';

abstract class Application {
  void initialize(Object shell, List<String> args, String url);
  void acceptConnection(String requestorUrl, Object services, Object exposedServices, String resolvedUrl);
  void requestQuit();

}


class ApplicationProxyImpl extends bindings.Proxy {
  ApplicationProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ApplicationProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ApplicationProxyImpl.unbound() : super.unbound();

  static ApplicationProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationProxyImpl"));
    return new ApplicationProxyImpl.fromEndpoint(endpoint);
  }

  String get name => ApplicationName;

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
    return "ApplicationProxyImpl($superString)";
  }
}


class _ApplicationProxyCalls implements Application {
  ApplicationProxyImpl _proxyImpl;

  _ApplicationProxyCalls(this._proxyImpl);
    void initialize(Object shell, List<String> args, String url) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ApplicationInitializeParams();
      params.shell = shell;
      params.args = args;
      params.url = url;
      _proxyImpl.sendMessage(params, kApplication_initialize_name);
    }
  
    void acceptConnection(String requestorUrl, Object services, Object exposedServices, String resolvedUrl) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ApplicationAcceptConnectionParams();
      params.requestorUrl = requestorUrl;
      params.services = services;
      params.exposedServices = exposedServices;
      params.resolvedUrl = resolvedUrl;
      _proxyImpl.sendMessage(params, kApplication_acceptConnection_name);
    }
  
    void requestQuit() {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new ApplicationRequestQuitParams();
      _proxyImpl.sendMessage(params, kApplication_requestQuit_name);
    }
  
}


class ApplicationProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Application ptr;
  final String name = ApplicationName;

  ApplicationProxy(ApplicationProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ApplicationProxyCalls(proxyImpl);

  ApplicationProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ApplicationProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ApplicationProxyCalls(impl);
  }

  ApplicationProxy.fromHandle(core.MojoHandle handle) :
      impl = new ApplicationProxyImpl.fromHandle(handle) {
    ptr = new _ApplicationProxyCalls(impl);
  }

  ApplicationProxy.unbound() :
      impl = new ApplicationProxyImpl.unbound() {
    ptr = new _ApplicationProxyCalls(impl);
  }

  factory ApplicationProxy.connectToService(
      bindings.ServiceConnector s, String url) {
    ApplicationProxy p = new ApplicationProxy.unbound();
    s.connectToService(url, p);
    return p;
  }

  static ApplicationProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationProxy"));
    return new ApplicationProxy.fromEndpoint(endpoint);
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
    return "ApplicationProxy($impl)";
  }
}


class ApplicationStub extends bindings.Stub {
  Application _impl = null;

  ApplicationStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ApplicationStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ApplicationStub.unbound() : super.unbound();

  static ApplicationStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationStub"));
    return new ApplicationStub.fromEndpoint(endpoint);
  }

  static const String name = ApplicationName;



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case kApplication_initialize_name:
        var params = ApplicationInitializeParams.deserialize(
            message.payload);
        _impl.initialize(params.shell, params.args, params.url);
        break;
      case kApplication_acceptConnection_name:
        var params = ApplicationAcceptConnectionParams.deserialize(
            message.payload);
        _impl.acceptConnection(params.requestorUrl, params.services, params.exposedServices, params.resolvedUrl);
        break;
      case kApplication_requestQuit_name:
        var params = ApplicationRequestQuitParams.deserialize(
            message.payload);
        _impl.requestQuit();
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Application get impl => _impl;
  set impl(Application d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ApplicationStub($superString)";
  }

  int get version => 0;
}


