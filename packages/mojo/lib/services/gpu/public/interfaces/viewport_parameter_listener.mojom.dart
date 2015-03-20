// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library viewport_parameter_listener.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class ViewportParameterListenerOnVSyncParametersUpdatedParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int timebase = 0;
  int interval = 0;

  ViewportParameterListenerOnVSyncParametersUpdatedParams() : super(kStructSize);

  static ViewportParameterListenerOnVSyncParametersUpdatedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ViewportParameterListenerOnVSyncParametersUpdatedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ViewportParameterListenerOnVSyncParametersUpdatedParams result = new ViewportParameterListenerOnVSyncParametersUpdatedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.timebase = decoder0.decodeInt64(8);
    }
    {
      
      result.interval = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt64(timebase, 8);
    
    encoder0.encodeInt64(interval, 16);
  }

  String toString() {
    return "ViewportParameterListenerOnVSyncParametersUpdatedParams("
           "timebase: $timebase" ", "
           "interval: $interval" ")";
  }
}
const int kViewportParameterListener_onVSyncParametersUpdated_name = 0;

const String ViewportParameterListenerName =
      'mojo::ViewportParameterListener';

abstract class ViewportParameterListener {
  void onVSyncParametersUpdated(int timebase, int interval);

}


class ViewportParameterListenerProxyImpl extends bindings.Proxy {
  ViewportParameterListenerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ViewportParameterListenerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ViewportParameterListenerProxyImpl.unbound() : super.unbound();

  static ViewportParameterListenerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportParameterListenerProxyImpl.fromEndpoint(endpoint);

  String get name => ViewportParameterListenerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ViewportParameterListenerProxyImpl($superString)";
  }
}


class _ViewportParameterListenerProxyCalls implements ViewportParameterListener {
  ViewportParameterListenerProxyImpl _proxyImpl;

  _ViewportParameterListenerProxyCalls(this._proxyImpl);
    void onVSyncParametersUpdated(int timebase, int interval) {
      assert(_proxyImpl.isBound);
      var params = new ViewportParameterListenerOnVSyncParametersUpdatedParams();
      params.timebase = timebase;
      params.interval = interval;
      _proxyImpl.sendMessage(params, kViewportParameterListener_onVSyncParametersUpdated_name);
    }
  
}


class ViewportParameterListenerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ViewportParameterListener ptr;
  final String name = ViewportParameterListenerName;

  ViewportParameterListenerProxy(ViewportParameterListenerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ViewportParameterListenerProxyCalls(proxyImpl);

  ViewportParameterListenerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ViewportParameterListenerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ViewportParameterListenerProxyCalls(impl);
  }

  ViewportParameterListenerProxy.fromHandle(core.MojoHandle handle) :
      impl = new ViewportParameterListenerProxyImpl.fromHandle(handle) {
    ptr = new _ViewportParameterListenerProxyCalls(impl);
  }

  ViewportParameterListenerProxy.unbound() :
      impl = new ViewportParameterListenerProxyImpl.unbound() {
    ptr = new _ViewportParameterListenerProxyCalls(impl);
  }

  static ViewportParameterListenerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportParameterListenerProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "ViewportParameterListenerProxy($impl)";
  }
}


class ViewportParameterListenerStub extends bindings.Stub {
  ViewportParameterListener _impl = null;

  ViewportParameterListenerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ViewportParameterListenerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ViewportParameterListenerStub.unbound() : super.unbound();

  static ViewportParameterListenerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportParameterListenerStub.fromEndpoint(endpoint);

  static const String name = ViewportParameterListenerName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kViewportParameterListener_onVSyncParametersUpdated_name:
        var params = ViewportParameterListenerOnVSyncParametersUpdatedParams.deserialize(
            message.payload);
        _impl.onVSyncParametersUpdated(params.timebase, params.interval);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ViewportParameterListener get impl => _impl;
      set impl(ViewportParameterListener d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ViewportParameterListenerStub($superString)";
  }
}


