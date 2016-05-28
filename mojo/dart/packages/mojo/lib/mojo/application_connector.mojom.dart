// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library application_connector_mojom;
import 'dart:async';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/bindings/types/service_describer.mojom.dart' as service_describer;
import 'package:mojo/mojo/service_provider.mojom.dart' as service_provider_mojom;



class _ApplicationConnectorConnectToApplicationParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  String applicationUrl = null;
  service_provider_mojom.ServiceProviderInterfaceRequest services = null;
  service_provider_mojom.ServiceProviderInterface exposedServices = null;

  _ApplicationConnectorConnectToApplicationParams() : super(kVersions.last.size);

  static _ApplicationConnectorConnectToApplicationParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ApplicationConnectorConnectToApplicationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ApplicationConnectorConnectToApplicationParams result = new _ApplicationConnectorConnectToApplicationParams();

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
    try {
      encoder0.encodeString(applicationUrl, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "applicationUrl of struct _ApplicationConnectorConnectToApplicationParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeInterfaceRequest(services, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "services of struct _ApplicationConnectorConnectToApplicationParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeInterface(exposedServices, 20, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "exposedServices of struct _ApplicationConnectorConnectToApplicationParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ApplicationConnectorConnectToApplicationParams("
           "applicationUrl: $applicationUrl" ", "
           "services: $services" ", "
           "exposedServices: $exposedServices" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class _ApplicationConnectorDuplicateParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  ApplicationConnectorInterfaceRequest applicationConnectorRequest = null;

  _ApplicationConnectorDuplicateParams() : super(kVersions.last.size);

  static _ApplicationConnectorDuplicateParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ApplicationConnectorDuplicateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ApplicationConnectorDuplicateParams result = new _ApplicationConnectorDuplicateParams();

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
    try {
      encoder0.encodeInterfaceRequest(applicationConnectorRequest, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "applicationConnectorRequest of struct _ApplicationConnectorDuplicateParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ApplicationConnectorDuplicateParams("
           "applicationConnectorRequest: $applicationConnectorRequest" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}

const int _applicationConnectorMethodConnectToApplicationName = 0;
const int _applicationConnectorMethodDuplicateName = 1;

class _ApplicationConnectorServiceDescription implements service_describer.ServiceDescription {
  dynamic getTopLevelInterface([Function responseFactory]) =>
      responseFactory(null);

  dynamic getTypeDefinition(String typeKey, [Function responseFactory]) =>
      responseFactory(null);

  dynamic getAllTypeDefinitions([Function responseFactory]) =>
      responseFactory(null);
}

abstract class ApplicationConnector {
  static const String serviceName = null;

  static service_describer.ServiceDescription _cachedServiceDescription;
  static service_describer.ServiceDescription get serviceDescription {
    if (_cachedServiceDescription == null) {
      _cachedServiceDescription = new _ApplicationConnectorServiceDescription();
    }
    return _cachedServiceDescription;
  }

  static ApplicationConnectorProxy connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ApplicationConnectorProxy p = new ApplicationConnectorProxy.unbound();
    String name = serviceName ?? ApplicationConnector.serviceName;
    if ((name == null) || name.isEmpty) {
      throw new core.MojoApiError(
          "If an interface has no ServiceName, then one must be provided.");
    }
    s.connectToService(url, p, name);
    return p;
  }
  void connectToApplication(String applicationUrl, service_provider_mojom.ServiceProviderInterfaceRequest services, service_provider_mojom.ServiceProviderInterface exposedServices);
  void duplicate(ApplicationConnectorInterfaceRequest applicationConnectorRequest);
}

abstract class ApplicationConnectorInterface
    implements bindings.MojoInterface<ApplicationConnector>,
               ApplicationConnector {
  factory ApplicationConnectorInterface([ApplicationConnector impl]) =>
      new ApplicationConnectorStub.unbound(impl);
  factory ApplicationConnectorInterface.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint,
      [ApplicationConnector impl]) =>
      new ApplicationConnectorStub.fromEndpoint(endpoint, impl);
}

abstract class ApplicationConnectorInterfaceRequest
    implements bindings.MojoInterface<ApplicationConnector>,
               ApplicationConnector {
  factory ApplicationConnectorInterfaceRequest() =>
      new ApplicationConnectorProxy.unbound();
}

class _ApplicationConnectorProxyControl
    extends bindings.ProxyMessageHandler
    implements bindings.ProxyControl<ApplicationConnector> {
  _ApplicationConnectorProxyControl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  _ApplicationConnectorProxyControl.fromHandle(
      core.MojoHandle handle) : super.fromHandle(handle);

  _ApplicationConnectorProxyControl.unbound() : super.unbound();

  String get serviceName => ApplicationConnector.serviceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        proxyError("Unexpected message type: ${message.header.type}");
        close(immediate: true);
        break;
    }
  }

  ApplicationConnector get impl => null;
  set impl(ApplicationConnector _) {
    throw new core.MojoApiError("The impl of a Proxy cannot be set.");
  }

  @override
  String toString() {
    var superString = super.toString();
    return "_ApplicationConnectorProxyControl($superString)";
  }
}

class ApplicationConnectorProxy
    extends bindings.Proxy<ApplicationConnector>
    implements ApplicationConnector,
               ApplicationConnectorInterface,
               ApplicationConnectorInterfaceRequest {
  ApplicationConnectorProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint)
      : super(new _ApplicationConnectorProxyControl.fromEndpoint(endpoint));

  ApplicationConnectorProxy.fromHandle(core.MojoHandle handle)
      : super(new _ApplicationConnectorProxyControl.fromHandle(handle));

  ApplicationConnectorProxy.unbound()
      : super(new _ApplicationConnectorProxyControl.unbound());

  static ApplicationConnectorProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationConnectorProxy"));
    return new ApplicationConnectorProxy.fromEndpoint(endpoint);
  }


  void connectToApplication(String applicationUrl, service_provider_mojom.ServiceProviderInterfaceRequest services, service_provider_mojom.ServiceProviderInterface exposedServices) {
    if (!ctrl.isBound) {
      ctrl.proxyError("The Proxy is closed.");
      return;
    }
    var params = new _ApplicationConnectorConnectToApplicationParams();
    params.applicationUrl = applicationUrl;
    params.services = services;
    params.exposedServices = exposedServices;
    ctrl.sendMessage(params,
        _applicationConnectorMethodConnectToApplicationName);
  }
  void duplicate(ApplicationConnectorInterfaceRequest applicationConnectorRequest) {
    if (!ctrl.isBound) {
      ctrl.proxyError("The Proxy is closed.");
      return;
    }
    var params = new _ApplicationConnectorDuplicateParams();
    params.applicationConnectorRequest = applicationConnectorRequest;
    ctrl.sendMessage(params,
        _applicationConnectorMethodDuplicateName);
  }
}

class _ApplicationConnectorStubControl
    extends bindings.StubMessageHandler
    implements bindings.StubControl<ApplicationConnector> {
  ApplicationConnector _impl;

  _ApplicationConnectorStubControl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [ApplicationConnector impl])
      : super.fromEndpoint(endpoint, autoBegin: impl != null) {
    _impl = impl;
  }

  _ApplicationConnectorStubControl.fromHandle(
      core.MojoHandle handle, [ApplicationConnector impl])
      : super.fromHandle(handle, autoBegin: impl != null) {
    _impl = impl;
  }

  _ApplicationConnectorStubControl.unbound([this._impl]) : super.unbound();

  String get serviceName => ApplicationConnector.serviceName;



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    if (_impl == null) {
      throw new core.MojoApiError("$this has no implementation set");
    }
    switch (message.header.type) {
      case _applicationConnectorMethodConnectToApplicationName:
        var params = _ApplicationConnectorConnectToApplicationParams.deserialize(
            message.payload);
        _impl.connectToApplication(params.applicationUrl, params.services, params.exposedServices);
        break;
      case _applicationConnectorMethodDuplicateName:
        var params = _ApplicationConnectorDuplicateParams.deserialize(
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
    if (d == null) {
      throw new core.MojoApiError("$this: Cannot set a null implementation");
    }
    if (isBound && (_impl == null)) {
      beginHandlingEvents();
    }
    _impl = d;
  }

  @override
  void bind(core.MojoMessagePipeEndpoint endpoint) {
    super.bind(endpoint);
    if (!isOpen && (_impl != null)) {
      beginHandlingEvents();
    }
  }

  @override
  String toString() {
    var superString = super.toString();
    return "_ApplicationConnectorStubControl($superString)";
  }

  int get version => 0;
}

class ApplicationConnectorStub
    extends bindings.Stub<ApplicationConnector>
    implements ApplicationConnector,
               ApplicationConnectorInterface,
               ApplicationConnectorInterfaceRequest {
  ApplicationConnectorStub.unbound([ApplicationConnector impl])
      : super(new _ApplicationConnectorStubControl.unbound(impl));

  ApplicationConnectorStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [ApplicationConnector impl])
      : super(new _ApplicationConnectorStubControl.fromEndpoint(endpoint, impl));

  ApplicationConnectorStub.fromHandle(
      core.MojoHandle handle, [ApplicationConnector impl])
      : super(new _ApplicationConnectorStubControl.fromHandle(handle, impl));

  static ApplicationConnectorStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ApplicationConnectorStub"));
    return new ApplicationConnectorStub.fromEndpoint(endpoint);
  }


  void connectToApplication(String applicationUrl, service_provider_mojom.ServiceProviderInterfaceRequest services, service_provider_mojom.ServiceProviderInterface exposedServices) {
    return impl.connectToApplication(applicationUrl, services, exposedServices);
  }
  void duplicate(ApplicationConnectorInterfaceRequest applicationConnectorRequest) {
    return impl.duplicate(applicationConnectorRequest);
  }
}



