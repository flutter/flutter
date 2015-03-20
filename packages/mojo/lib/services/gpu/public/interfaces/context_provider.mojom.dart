// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library context_provider.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/gpu/public/interfaces/command_buffer.mojom.dart' as command_buffer_mojom;
import 'package:mojo/services/gpu/public/interfaces/viewport_parameter_listener.mojom.dart' as viewport_parameter_listener_mojom;


class ContextProviderCreateParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object viewportParameterListener = null;

  ContextProviderCreateParams() : super(kStructSize);

  static ContextProviderCreateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ContextProviderCreateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ContextProviderCreateParams result = new ContextProviderCreateParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.viewportParameterListener = decoder0.decodeServiceInterface(8, true, viewport_parameter_listener_mojom.ViewportParameterListenerProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(viewportParameterListener, 8, true);
  }

  String toString() {
    return "ContextProviderCreateParams("
           "viewportParameterListener: $viewportParameterListener" ")";
  }
}

class ContextProviderCreateResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object gles2Client = null;

  ContextProviderCreateResponseParams() : super(kStructSize);

  static ContextProviderCreateResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ContextProviderCreateResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ContextProviderCreateResponseParams result = new ContextProviderCreateResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.gles2Client = decoder0.decodeServiceInterface(8, true, command_buffer_mojom.CommandBufferProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(gles2Client, 8, true);
  }

  String toString() {
    return "ContextProviderCreateResponseParams("
           "gles2Client: $gles2Client" ")";
  }
}
const int kContextProvider_create_name = 0;

const String ContextProviderName =
      'mojo::ContextProvider';

abstract class ContextProvider {
  Future<ContextProviderCreateResponseParams> create(Object viewportParameterListener,[Function responseFactory = null]);

}


class ContextProviderProxyImpl extends bindings.Proxy {
  ContextProviderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ContextProviderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ContextProviderProxyImpl.unbound() : super.unbound();

  static ContextProviderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContextProviderProxyImpl.fromEndpoint(endpoint);

  String get name => ContextProviderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kContextProvider_create_name:
        var r = ContextProviderCreateResponseParams.deserialize(
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
    return "ContextProviderProxyImpl($superString)";
  }
}


class _ContextProviderProxyCalls implements ContextProvider {
  ContextProviderProxyImpl _proxyImpl;

  _ContextProviderProxyCalls(this._proxyImpl);
    Future<ContextProviderCreateResponseParams> create(Object viewportParameterListener,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ContextProviderCreateParams();
      params.viewportParameterListener = viewportParameterListener;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kContextProvider_create_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class ContextProviderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ContextProvider ptr;
  final String name = ContextProviderName;

  ContextProviderProxy(ContextProviderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ContextProviderProxyCalls(proxyImpl);

  ContextProviderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ContextProviderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ContextProviderProxyCalls(impl);
  }

  ContextProviderProxy.fromHandle(core.MojoHandle handle) :
      impl = new ContextProviderProxyImpl.fromHandle(handle) {
    ptr = new _ContextProviderProxyCalls(impl);
  }

  ContextProviderProxy.unbound() :
      impl = new ContextProviderProxyImpl.unbound() {
    ptr = new _ContextProviderProxyCalls(impl);
  }

  static ContextProviderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContextProviderProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "ContextProviderProxy($impl)";
  }
}


class ContextProviderStub extends bindings.Stub {
  ContextProvider _impl = null;

  ContextProviderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ContextProviderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ContextProviderStub.unbound() : super.unbound();

  static ContextProviderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ContextProviderStub.fromEndpoint(endpoint);

  static const String name = ContextProviderName;


  ContextProviderCreateResponseParams _ContextProviderCreateResponseParamsFactory(Object gles2Client) {
    var result = new ContextProviderCreateResponseParams();
    result.gles2Client = gles2Client;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kContextProvider_create_name:
        var params = ContextProviderCreateParams.deserialize(
            message.payload);
        return _impl.create(params.viewportParameterListener,_ContextProviderCreateResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kContextProvider_create_name,
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

  ContextProvider get impl => _impl;
      set impl(ContextProvider d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ContextProviderStub($superString)";
  }
}


