// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library application_mojom;
import 'dart:async';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/bindings/types/service_describer.mojom.dart' as service_describer;
import 'package:mojo/mojo/service_provider.mojom.dart' as service_provider_mojom;
import 'package:mojo/mojo/shell.mojom.dart' as shell_mojom;



class _ApplicationInitializeParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  Object shell = null;
  List<String> args = null;
  String url = null;

  _ApplicationInitializeParams() : super(kVersions.last.size);

  static _ApplicationInitializeParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ApplicationInitializeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ApplicationInitializeParams result = new _ApplicationInitializeParams();

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
    try {
      encoder0.encodeInterface(shell, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "shell of struct _ApplicationInitializeParams: $e";
      rethrow;
    }
    try {
      if (args == null) {
        encoder0.encodeNullPointer(16, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(args.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < args.length; ++i0) {
          encoder1.encodeString(args[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "args of struct _ApplicationInitializeParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(url, 24, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "url of struct _ApplicationInitializeParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ApplicationInitializeParams("
           "shell: $shell" ", "
           "args: $args" ", "
           "url: $url" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}




class _ApplicationAcceptConnectionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  String requestorUrl = null;
  Object services = null;
  Object exposedServices = null;
  String resolvedUrl = null;

  _ApplicationAcceptConnectionParams() : super(kVersions.last.size);

  static _ApplicationAcceptConnectionParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ApplicationAcceptConnectionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ApplicationAcceptConnectionParams result = new _ApplicationAcceptConnectionParams();

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
    try {
      encoder0.encodeString(requestorUrl, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "requestorUrl of struct _ApplicationAcceptConnectionParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeInterfaceRequest(services, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "services of struct _ApplicationAcceptConnectionParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeInterface(exposedServices, 20, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "exposedServices of struct _ApplicationAcceptConnectionParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(resolvedUrl, 32, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "resolvedUrl of struct _ApplicationAcceptConnectionParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ApplicationAcceptConnectionParams("
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




class _ApplicationRequestQuitParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  _ApplicationRequestQuitParams() : super(kVersions.last.size);

  static _ApplicationRequestQuitParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ApplicationRequestQuitParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ApplicationRequestQuitParams result = new _ApplicationRequestQuitParams();

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
    return "_ApplicationRequestQuitParams("")";
  }

  Map toJson() {
    Map map = new Map();
    return map;
  }
}




const int _Application_initializeName = 0;
const int _Application_acceptConnectionName = 1;
const int _Application_requestQuitName = 2;



class _ApplicationServiceDescription implements service_describer.ServiceDescription {
  dynamic getTopLevelInterface([Function responseFactory]) =>
      responseFactory(null);

  dynamic getTypeDefinition(String typeKey, [Function responseFactory]) =>
      responseFactory(null);

  dynamic getAllTypeDefinitions([Function responseFactory]) =>
      responseFactory(null);
}

abstract class Application {
  static const String serviceName = null;
  void initialize(Object shell, List<String> args, String url);
  void acceptConnection(String requestorUrl, Object services, Object exposedServices, String resolvedUrl);
  void requestQuit();
}


class _ApplicationProxyImpl extends bindings.Proxy {
  _ApplicationProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  _ApplicationProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  _ApplicationProxyImpl.unbound() : super.unbound();

  static _ApplicationProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For _ApplicationProxyImpl"));
    return new _ApplicationProxyImpl.fromEndpoint(endpoint);
  }

  service_describer.ServiceDescription get serviceDescription =>
    new _ApplicationServiceDescription();

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
    return "_ApplicationProxyImpl($superString)";
  }
}


class _ApplicationProxyCalls implements Application {
  _ApplicationProxyImpl _proxyImpl;

  _ApplicationProxyCalls(this._proxyImpl);
    void initialize(Object shell, List<String> args, String url) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new _ApplicationInitializeParams();
      params.shell = shell;
      params.args = args;
      params.url = url;
      _proxyImpl.sendMessage(params, _Application_initializeName);
    }
    void acceptConnection(String requestorUrl, Object services, Object exposedServices, String resolvedUrl) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new _ApplicationAcceptConnectionParams();
      params.requestorUrl = requestorUrl;
      params.services = services;
      params.exposedServices = exposedServices;
      params.resolvedUrl = resolvedUrl;
      _proxyImpl.sendMessage(params, _Application_acceptConnectionName);
    }
    void requestQuit() {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new _ApplicationRequestQuitParams();
      _proxyImpl.sendMessage(params, _Application_requestQuitName);
    }
}


class ApplicationProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Application ptr;

  ApplicationProxy(_ApplicationProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ApplicationProxyCalls(proxyImpl);

  ApplicationProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new _ApplicationProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ApplicationProxyCalls(impl);
  }

  ApplicationProxy.fromHandle(core.MojoHandle handle) :
      impl = new _ApplicationProxyImpl.fromHandle(handle) {
    ptr = new _ApplicationProxyCalls(impl);
  }

  ApplicationProxy.unbound() :
      impl = new _ApplicationProxyImpl.unbound() {
    ptr = new _ApplicationProxyCalls(impl);
  }

  factory ApplicationProxy.connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ApplicationProxy p = new ApplicationProxy.unbound();
    s.connectToService(url, p, serviceName);
    return p;
  }

  static ApplicationProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationProxy"));
    return new ApplicationProxy.fromEndpoint(endpoint);
  }

  String get serviceName => Application.serviceName;

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



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case _Application_initializeName:
        var params = _ApplicationInitializeParams.deserialize(
            message.payload);
        _impl.initialize(params.shell, params.args, params.url);
        break;
      case _Application_acceptConnectionName:
        var params = _ApplicationAcceptConnectionParams.deserialize(
            message.payload);
        _impl.acceptConnection(params.requestorUrl, params.services, params.exposedServices, params.resolvedUrl);
        break;
      case _Application_requestQuitName:
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

  static service_describer.ServiceDescription _cachedServiceDescription;
  static service_describer.ServiceDescription get serviceDescription {
    if (_cachedServiceDescription == null) {
      _cachedServiceDescription = new _ApplicationServiceDescription();
    }
    return _cachedServiceDescription;
  }
}



