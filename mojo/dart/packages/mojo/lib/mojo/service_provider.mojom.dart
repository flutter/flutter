// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library service_provider_mojom;
import 'dart:async';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/bindings/types/service_describer.mojom.dart' as service_describer;



class _ServiceProviderConnectToServiceParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String interfaceName = null;
  core.MojoMessagePipeEndpoint pipe = null;

  _ServiceProviderConnectToServiceParams() : super(kVersions.last.size);

  static _ServiceProviderConnectToServiceParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ServiceProviderConnectToServiceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ServiceProviderConnectToServiceParams result = new _ServiceProviderConnectToServiceParams();

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
      
      result.interfaceName = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.pipe = decoder0.decodeMessagePipeHandle(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(interfaceName, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "interfaceName of struct _ServiceProviderConnectToServiceParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeMessagePipeHandle(pipe, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "pipe of struct _ServiceProviderConnectToServiceParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ServiceProviderConnectToServiceParams("
           "interfaceName: $interfaceName" ", "
           "pipe: $pipe" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}

const int _serviceProviderMethodConnectToServiceName = 0;

class _ServiceProviderServiceDescription implements service_describer.ServiceDescription {
  dynamic getTopLevelInterface([Function responseFactory]) =>
      responseFactory(null);

  dynamic getTypeDefinition(String typeKey, [Function responseFactory]) =>
      responseFactory(null);

  dynamic getAllTypeDefinitions([Function responseFactory]) =>
      responseFactory(null);
}

abstract class ServiceProvider {
  static const String serviceName = null;

  static service_describer.ServiceDescription _cachedServiceDescription;
  static service_describer.ServiceDescription get serviceDescription {
    if (_cachedServiceDescription == null) {
      _cachedServiceDescription = new _ServiceProviderServiceDescription();
    }
    return _cachedServiceDescription;
  }

  static ServiceProviderProxy connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ServiceProviderProxy p = new ServiceProviderProxy.unbound();
    String name = serviceName ?? ServiceProvider.serviceName;
    if ((name == null) || name.isEmpty) {
      throw new core.MojoApiError(
          "If an interface has no ServiceName, then one must be provided.");
    }
    s.connectToService(url, p, name);
    return p;
  }
  void connectToService_(String interfaceName, core.MojoMessagePipeEndpoint pipe);
}

abstract class ServiceProviderInterface
    implements bindings.MojoInterface<ServiceProvider>,
               ServiceProvider {
  factory ServiceProviderInterface([ServiceProvider impl]) =>
      new ServiceProviderStub.unbound(impl);
  factory ServiceProviderInterface.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint,
      [ServiceProvider impl]) =>
      new ServiceProviderStub.fromEndpoint(endpoint, impl);
}

abstract class ServiceProviderInterfaceRequest
    implements bindings.MojoInterface<ServiceProvider>,
               ServiceProvider {
  factory ServiceProviderInterfaceRequest() =>
      new ServiceProviderProxy.unbound();
}

class _ServiceProviderProxyControl
    extends bindings.ProxyMessageHandler
    implements bindings.ProxyControl<ServiceProvider> {
  _ServiceProviderProxyControl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  _ServiceProviderProxyControl.fromHandle(
      core.MojoHandle handle) : super.fromHandle(handle);

  _ServiceProviderProxyControl.unbound() : super.unbound();

  String get serviceName => ServiceProvider.serviceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        proxyError("Unexpected message type: ${message.header.type}");
        close(immediate: true);
        break;
    }
  }

  ServiceProvider get impl => null;
  set impl(ServiceProvider _) {
    throw new core.MojoApiError("The impl of a Proxy cannot be set.");
  }

  @override
  String toString() {
    var superString = super.toString();
    return "_ServiceProviderProxyControl($superString)";
  }
}

class ServiceProviderProxy
    extends bindings.Proxy<ServiceProvider>
    implements ServiceProvider,
               ServiceProviderInterface,
               ServiceProviderInterfaceRequest {
  ServiceProviderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint)
      : super(new _ServiceProviderProxyControl.fromEndpoint(endpoint));

  ServiceProviderProxy.fromHandle(core.MojoHandle handle)
      : super(new _ServiceProviderProxyControl.fromHandle(handle));

  ServiceProviderProxy.unbound()
      : super(new _ServiceProviderProxyControl.unbound());

  static ServiceProviderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceProviderProxy"));
    return new ServiceProviderProxy.fromEndpoint(endpoint);
  }


  void connectToService_(String interfaceName, core.MojoMessagePipeEndpoint pipe) {
    if (!ctrl.isBound) {
      ctrl.proxyError("The Proxy is closed.");
      return;
    }
    var params = new _ServiceProviderConnectToServiceParams();
    params.interfaceName = interfaceName;
    params.pipe = pipe;
    ctrl.sendMessage(params,
        _serviceProviderMethodConnectToServiceName);
  }
}

class _ServiceProviderStubControl
    extends bindings.StubMessageHandler
    implements bindings.StubControl<ServiceProvider> {
  ServiceProvider _impl;

  _ServiceProviderStubControl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [ServiceProvider impl])
      : super.fromEndpoint(endpoint, autoBegin: impl != null) {
    _impl = impl;
  }

  _ServiceProviderStubControl.fromHandle(
      core.MojoHandle handle, [ServiceProvider impl])
      : super.fromHandle(handle, autoBegin: impl != null) {
    _impl = impl;
  }

  _ServiceProviderStubControl.unbound([this._impl]) : super.unbound();

  String get serviceName => ServiceProvider.serviceName;



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
      case _serviceProviderMethodConnectToServiceName:
        var params = _ServiceProviderConnectToServiceParams.deserialize(
            message.payload);
        _impl.connectToService_(params.interfaceName, params.pipe);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ServiceProvider get impl => _impl;
  set impl(ServiceProvider d) {
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
    return "_ServiceProviderStubControl($superString)";
  }

  int get version => 0;
}

class ServiceProviderStub
    extends bindings.Stub<ServiceProvider>
    implements ServiceProvider,
               ServiceProviderInterface,
               ServiceProviderInterfaceRequest {
  ServiceProviderStub.unbound([ServiceProvider impl])
      : super(new _ServiceProviderStubControl.unbound(impl));

  ServiceProviderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [ServiceProvider impl])
      : super(new _ServiceProviderStubControl.fromEndpoint(endpoint, impl));

  ServiceProviderStub.fromHandle(
      core.MojoHandle handle, [ServiceProvider impl])
      : super(new _ServiceProviderStubControl.fromHandle(handle, impl));

  static ServiceProviderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceProviderStub"));
    return new ServiceProviderStub.fromEndpoint(endpoint);
  }


  void connectToService_(String interfaceName, core.MojoMessagePipeEndpoint pipe) {
    return impl.connectToService_(interfaceName, pipe);
  }
}



