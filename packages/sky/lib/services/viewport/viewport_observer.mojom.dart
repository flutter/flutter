// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library viewport_observer.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:sky/services/viewport/input_event.mojom.dart' as input_event_mojom;


class ViewportObserverOnViewportMetricsChangedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int width = 0;
  int height = 0;
  double devicePixelRatio = 0.0;

  ViewportObserverOnViewportMetricsChangedParams() : super(kVersions.last.size);

  static ViewportObserverOnViewportMetricsChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ViewportObserverOnViewportMetricsChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ViewportObserverOnViewportMetricsChangedParams result = new ViewportObserverOnViewportMetricsChangedParams();

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
      
      result.width = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.height = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.devicePixelRatio = decoder0.decodeFloat(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(width, 8);
    
    encoder0.encodeInt32(height, 12);
    
    encoder0.encodeFloat(devicePixelRatio, 16);
  }

  String toString() {
    return "ViewportObserverOnViewportMetricsChangedParams("
           "width: $width" ", "
           "height: $height" ", "
           "devicePixelRatio: $devicePixelRatio" ")";
  }
}

class ViewportObserverOnInputEventParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  input_event_mojom.InputEvent event = null;

  ViewportObserverOnInputEventParams() : super(kVersions.last.size);

  static ViewportObserverOnInputEventParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ViewportObserverOnInputEventParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ViewportObserverOnInputEventParams result = new ViewportObserverOnInputEventParams();

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
      result.event = input_event_mojom.InputEvent.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(event, 8, false);
  }

  String toString() {
    return "ViewportObserverOnInputEventParams("
           "event: $event" ")";
  }
}

class ViewportObserverLoadUrlParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  String url = null;

  ViewportObserverLoadUrlParams() : super(kVersions.last.size);

  static ViewportObserverLoadUrlParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ViewportObserverLoadUrlParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ViewportObserverLoadUrlParams result = new ViewportObserverLoadUrlParams();

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
      
      result.url = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(url, 8, false);
  }

  String toString() {
    return "ViewportObserverLoadUrlParams("
           "url: $url" ")";
  }
}
const int kViewportObserver_onViewportMetricsChanged_name = 0;
const int kViewportObserver_onInputEvent_name = 1;
const int kViewportObserver_loadUrl_name = 2;

const String ViewportObserverName =
      'sky::ViewportObserver';

abstract class ViewportObserver {
  void onViewportMetricsChanged(int width, int height, double devicePixelRatio);
  void onInputEvent(input_event_mojom.InputEvent event);
  void loadUrl(String url);

}


class ViewportObserverProxyImpl extends bindings.Proxy {
  ViewportObserverProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ViewportObserverProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ViewportObserverProxyImpl.unbound() : super.unbound();

  static ViewportObserverProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportObserverProxyImpl.fromEndpoint(endpoint);

  String get name => ViewportObserverName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ViewportObserverProxyImpl($superString)";
  }
}


class _ViewportObserverProxyCalls implements ViewportObserver {
  ViewportObserverProxyImpl _proxyImpl;

  _ViewportObserverProxyCalls(this._proxyImpl);
    void onViewportMetricsChanged(int width, int height, double devicePixelRatio) {
      assert(_proxyImpl.isBound);
      var params = new ViewportObserverOnViewportMetricsChangedParams();
      params.width = width;
      params.height = height;
      params.devicePixelRatio = devicePixelRatio;
      _proxyImpl.sendMessage(params, kViewportObserver_onViewportMetricsChanged_name);
    }
  
    void onInputEvent(input_event_mojom.InputEvent event) {
      assert(_proxyImpl.isBound);
      var params = new ViewportObserverOnInputEventParams();
      params.event = event;
      _proxyImpl.sendMessage(params, kViewportObserver_onInputEvent_name);
    }
  
    void loadUrl(String url) {
      assert(_proxyImpl.isBound);
      var params = new ViewportObserverLoadUrlParams();
      params.url = url;
      _proxyImpl.sendMessage(params, kViewportObserver_loadUrl_name);
    }
  
}


class ViewportObserverProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ViewportObserver ptr;
  final String name = ViewportObserverName;

  ViewportObserverProxy(ViewportObserverProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ViewportObserverProxyCalls(proxyImpl);

  ViewportObserverProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ViewportObserverProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ViewportObserverProxyCalls(impl);
  }

  ViewportObserverProxy.fromHandle(core.MojoHandle handle) :
      impl = new ViewportObserverProxyImpl.fromHandle(handle) {
    ptr = new _ViewportObserverProxyCalls(impl);
  }

  ViewportObserverProxy.unbound() :
      impl = new ViewportObserverProxyImpl.unbound() {
    ptr = new _ViewportObserverProxyCalls(impl);
  }

  static ViewportObserverProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportObserverProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "ViewportObserverProxy($impl)";
  }
}


class ViewportObserverStub extends bindings.Stub {
  ViewportObserver _impl = null;

  ViewportObserverStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ViewportObserverStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ViewportObserverStub.unbound() : super.unbound();

  static ViewportObserverStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ViewportObserverStub.fromEndpoint(endpoint);

  static const String name = ViewportObserverName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kViewportObserver_onViewportMetricsChanged_name:
        var params = ViewportObserverOnViewportMetricsChangedParams.deserialize(
            message.payload);
        _impl.onViewportMetricsChanged(params.width, params.height, params.devicePixelRatio);
        break;
      case kViewportObserver_onInputEvent_name:
        var params = ViewportObserverOnInputEventParams.deserialize(
            message.payload);
        _impl.onInputEvent(params.event);
        break;
      case kViewportObserver_loadUrl_name:
        var params = ViewportObserverLoadUrlParams.deserialize(
            message.payload);
        _impl.loadUrl(params.url);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ViewportObserver get impl => _impl;
      set impl(ViewportObserver d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ViewportObserverStub($superString)";
  }
}


