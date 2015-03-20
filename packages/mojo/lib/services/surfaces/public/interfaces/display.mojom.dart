// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library display.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/gpu/public/interfaces/context_provider.mojom.dart' as context_provider_mojom;
import 'package:mojo/services/gpu/public/interfaces/viewport_parameter_listener.mojom.dart' as viewport_parameter_listener_mojom;
import 'package:mojo/services/surfaces/public/interfaces/surfaces.mojom.dart' as surfaces_mojom;


class DisplaySubmitFrameParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  surfaces_mojom.Frame frame = null;

  DisplaySubmitFrameParams() : super(kStructSize);

  static DisplaySubmitFrameParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DisplaySubmitFrameParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DisplaySubmitFrameParams result = new DisplaySubmitFrameParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.frame = surfaces_mojom.Frame.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(frame, 8, false);
  }

  String toString() {
    return "DisplaySubmitFrameParams("
           "frame: $frame" ")";
  }
}

class DisplaySubmitFrameResponseParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  DisplaySubmitFrameResponseParams() : super(kStructSize);

  static DisplaySubmitFrameResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DisplaySubmitFrameResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DisplaySubmitFrameResponseParams result = new DisplaySubmitFrameResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "DisplaySubmitFrameResponseParams("")";
  }
}

class DisplayFactoryCreateParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object contextProvider = null;
  Object returner = null;
  Object displayRequest = null;

  DisplayFactoryCreateParams() : super(kStructSize);

  static DisplayFactoryCreateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DisplayFactoryCreateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DisplayFactoryCreateParams result = new DisplayFactoryCreateParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.contextProvider = decoder0.decodeServiceInterface(8, false, context_provider_mojom.ContextProviderProxy.newFromEndpoint);
    }
    {
      
      result.returner = decoder0.decodeServiceInterface(12, true, surfaces_mojom.ResourceReturnerProxy.newFromEndpoint);
    }
    {
      
      result.displayRequest = decoder0.decodeInterfaceRequest(16, false, DisplayStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(contextProvider, 8, false);
    
    encoder0.encodeInterface(returner, 12, true);
    
    encoder0.encodeInterfaceRequest(displayRequest, 16, false);
  }

  String toString() {
    return "DisplayFactoryCreateParams("
           "contextProvider: $contextProvider" ", "
           "returner: $returner" ", "
           "displayRequest: $displayRequest" ")";
  }
}
const int kDisplay_submitFrame_name = 0;

const String DisplayName =
      'mojo::Display';

abstract class Display {
  Future<DisplaySubmitFrameResponseParams> submitFrame(surfaces_mojom.Frame frame,[Function responseFactory = null]);

}


class DisplayProxyImpl extends bindings.Proxy {
  DisplayProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  DisplayProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  DisplayProxyImpl.unbound() : super.unbound();

  static DisplayProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayProxyImpl.fromEndpoint(endpoint);

  String get name => DisplayName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kDisplay_submitFrame_name:
        var r = DisplaySubmitFrameResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "DisplayProxyImpl($superString)";
  }
}


class _DisplayProxyCalls implements Display {
  DisplayProxyImpl _proxyImpl;

  _DisplayProxyCalls(this._proxyImpl);
    Future<DisplaySubmitFrameResponseParams> submitFrame(surfaces_mojom.Frame frame,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DisplaySubmitFrameParams();
      params.frame = frame;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDisplay_submitFrame_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class DisplayProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Display ptr;
  final String name = DisplayName;

  DisplayProxy(DisplayProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _DisplayProxyCalls(proxyImpl);

  DisplayProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new DisplayProxyImpl.fromEndpoint(endpoint) {
    ptr = new _DisplayProxyCalls(impl);
  }

  DisplayProxy.fromHandle(core.MojoHandle handle) :
      impl = new DisplayProxyImpl.fromHandle(handle) {
    ptr = new _DisplayProxyCalls(impl);
  }

  DisplayProxy.unbound() :
      impl = new DisplayProxyImpl.unbound() {
    ptr = new _DisplayProxyCalls(impl);
  }

  static DisplayProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "DisplayProxy($impl)";
  }
}


class DisplayStub extends bindings.Stub {
  Display _impl = null;

  DisplayStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  DisplayStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  DisplayStub.unbound() : super.unbound();

  static DisplayStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayStub.fromEndpoint(endpoint);

  static const String name = DisplayName;


  DisplaySubmitFrameResponseParams _DisplaySubmitFrameResponseParamsFactory() {
    var result = new DisplaySubmitFrameResponseParams();
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kDisplay_submitFrame_name:
        var params = DisplaySubmitFrameParams.deserialize(
            message.payload);
        return _impl.submitFrame(params.frame,_DisplaySubmitFrameResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDisplay_submitFrame_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Display get impl => _impl;
      set impl(Display d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "DisplayStub($superString)";
  }
}

const int kDisplayFactory_create_name = 0;

const String DisplayFactoryName =
      'mojo::DisplayFactory';

abstract class DisplayFactory {
  void create(Object contextProvider, Object returner, Object displayRequest);

}


class DisplayFactoryProxyImpl extends bindings.Proxy {
  DisplayFactoryProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  DisplayFactoryProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  DisplayFactoryProxyImpl.unbound() : super.unbound();

  static DisplayFactoryProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayFactoryProxyImpl.fromEndpoint(endpoint);

  String get name => DisplayFactoryName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "DisplayFactoryProxyImpl($superString)";
  }
}


class _DisplayFactoryProxyCalls implements DisplayFactory {
  DisplayFactoryProxyImpl _proxyImpl;

  _DisplayFactoryProxyCalls(this._proxyImpl);
    void create(Object contextProvider, Object returner, Object displayRequest) {
      assert(_proxyImpl.isBound);
      var params = new DisplayFactoryCreateParams();
      params.contextProvider = contextProvider;
      params.returner = returner;
      params.displayRequest = displayRequest;
      _proxyImpl.sendMessage(params, kDisplayFactory_create_name);
    }
  
}


class DisplayFactoryProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  DisplayFactory ptr;
  final String name = DisplayFactoryName;

  DisplayFactoryProxy(DisplayFactoryProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _DisplayFactoryProxyCalls(proxyImpl);

  DisplayFactoryProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new DisplayFactoryProxyImpl.fromEndpoint(endpoint) {
    ptr = new _DisplayFactoryProxyCalls(impl);
  }

  DisplayFactoryProxy.fromHandle(core.MojoHandle handle) :
      impl = new DisplayFactoryProxyImpl.fromHandle(handle) {
    ptr = new _DisplayFactoryProxyCalls(impl);
  }

  DisplayFactoryProxy.unbound() :
      impl = new DisplayFactoryProxyImpl.unbound() {
    ptr = new _DisplayFactoryProxyCalls(impl);
  }

  static DisplayFactoryProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayFactoryProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "DisplayFactoryProxy($impl)";
  }
}


class DisplayFactoryStub extends bindings.Stub {
  DisplayFactory _impl = null;

  DisplayFactoryStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  DisplayFactoryStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  DisplayFactoryStub.unbound() : super.unbound();

  static DisplayFactoryStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DisplayFactoryStub.fromEndpoint(endpoint);

  static const String name = DisplayFactoryName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kDisplayFactory_create_name:
        var params = DisplayFactoryCreateParams.deserialize(
            message.payload);
        _impl.create(params.contextProvider, params.returner, params.displayRequest);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  DisplayFactory get impl => _impl;
      set impl(DisplayFactory d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "DisplayFactoryStub($superString)";
  }
}


