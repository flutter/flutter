// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library window_manager_internal.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;
import 'package:mojo/services/input_events/public/interfaces/input_events.mojom.dart' as input_events_mojom;


class WindowManagerInternalCreateWindowManagerForViewManagerClientParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int connectionId = 0;
  core.MojoMessagePipeEndpoint windowManagerPipe = null;

  WindowManagerInternalCreateWindowManagerForViewManagerClientParams() : super(kVersions.last.size);

  static WindowManagerInternalCreateWindowManagerForViewManagerClientParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerInternalCreateWindowManagerForViewManagerClientParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerInternalCreateWindowManagerForViewManagerClientParams result = new WindowManagerInternalCreateWindowManagerForViewManagerClientParams();

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
      
      result.connectionId = decoder0.decodeUint16(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.windowManagerPipe = decoder0.decodeMessagePipeHandle(12, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint16(connectionId, 8);
    
    encoder0.encodeMessagePipeHandle(windowManagerPipe, 12, false);
  }

  String toString() {
    return "WindowManagerInternalCreateWindowManagerForViewManagerClientParams("
           "connectionId: $connectionId" ", "
           "windowManagerPipe: $windowManagerPipe" ")";
  }
}

class WindowManagerInternalSetViewManagerClientParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  core.MojoMessagePipeEndpoint viewManagerClientRequest = null;

  WindowManagerInternalSetViewManagerClientParams() : super(kVersions.last.size);

  static WindowManagerInternalSetViewManagerClientParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerInternalSetViewManagerClientParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerInternalSetViewManagerClientParams result = new WindowManagerInternalSetViewManagerClientParams();

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
      
      result.viewManagerClientRequest = decoder0.decodeMessagePipeHandle(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeMessagePipeHandle(viewManagerClientRequest, 8, false);
  }

  String toString() {
    return "WindowManagerInternalSetViewManagerClientParams("
           "viewManagerClientRequest: $viewManagerClientRequest" ")";
  }
}

class WindowManagerInternalClientDispatchInputEventToViewParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int viewId = 0;
  input_events_mojom.Event event = null;

  WindowManagerInternalClientDispatchInputEventToViewParams() : super(kVersions.last.size);

  static WindowManagerInternalClientDispatchInputEventToViewParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerInternalClientDispatchInputEventToViewParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerInternalClientDispatchInputEventToViewParams result = new WindowManagerInternalClientDispatchInputEventToViewParams();

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
      
      result.viewId = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.event = input_events_mojom.Event.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
    
    encoder0.encodeStruct(event, 16, false);
  }

  String toString() {
    return "WindowManagerInternalClientDispatchInputEventToViewParams("
           "viewId: $viewId" ", "
           "event: $event" ")";
  }
}

class WindowManagerInternalClientSetViewportSizeParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  geometry_mojom.Size size = null;

  WindowManagerInternalClientSetViewportSizeParams() : super(kVersions.last.size);

  static WindowManagerInternalClientSetViewportSizeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerInternalClientSetViewportSizeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerInternalClientSetViewportSizeParams result = new WindowManagerInternalClientSetViewportSizeParams();

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
      result.size = geometry_mojom.Size.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(size, 8, false);
  }

  String toString() {
    return "WindowManagerInternalClientSetViewportSizeParams("
           "size: $size" ")";
  }
}

class WindowManagerInternalClientCloneAndAnimateParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int viewId = 0;

  WindowManagerInternalClientCloneAndAnimateParams() : super(kVersions.last.size);

  static WindowManagerInternalClientCloneAndAnimateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerInternalClientCloneAndAnimateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerInternalClientCloneAndAnimateParams result = new WindowManagerInternalClientCloneAndAnimateParams();

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
      
      result.viewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
  }

  String toString() {
    return "WindowManagerInternalClientCloneAndAnimateParams("
           "viewId: $viewId" ")";
  }
}
const int kWindowManagerInternal_createWindowManagerForViewManagerClient_name = 0;
const int kWindowManagerInternal_setViewManagerClient_name = 1;

const String WindowManagerInternalName =
      'mojo::WindowManagerInternal';

abstract class WindowManagerInternal {
  void createWindowManagerForViewManagerClient(int connectionId, core.MojoMessagePipeEndpoint windowManagerPipe);
  void setViewManagerClient(core.MojoMessagePipeEndpoint viewManagerClientRequest);

}


class WindowManagerInternalProxyImpl extends bindings.Proxy {
  WindowManagerInternalProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WindowManagerInternalProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WindowManagerInternalProxyImpl.unbound() : super.unbound();

  static WindowManagerInternalProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalProxyImpl.fromEndpoint(endpoint);

  String get name => WindowManagerInternalName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerInternalProxyImpl($superString)";
  }
}


class _WindowManagerInternalProxyCalls implements WindowManagerInternal {
  WindowManagerInternalProxyImpl _proxyImpl;

  _WindowManagerInternalProxyCalls(this._proxyImpl);
    void createWindowManagerForViewManagerClient(int connectionId, core.MojoMessagePipeEndpoint windowManagerPipe) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerInternalCreateWindowManagerForViewManagerClientParams();
      params.connectionId = connectionId;
      params.windowManagerPipe = windowManagerPipe;
      _proxyImpl.sendMessage(params, kWindowManagerInternal_createWindowManagerForViewManagerClient_name);
    }
  
    void setViewManagerClient(core.MojoMessagePipeEndpoint viewManagerClientRequest) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerInternalSetViewManagerClientParams();
      params.viewManagerClientRequest = viewManagerClientRequest;
      _proxyImpl.sendMessage(params, kWindowManagerInternal_setViewManagerClient_name);
    }
  
}


class WindowManagerInternalProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WindowManagerInternal ptr;
  final String name = WindowManagerInternalName;

  WindowManagerInternalProxy(WindowManagerInternalProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WindowManagerInternalProxyCalls(proxyImpl);

  WindowManagerInternalProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WindowManagerInternalProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WindowManagerInternalProxyCalls(impl);
  }

  WindowManagerInternalProxy.fromHandle(core.MojoHandle handle) :
      impl = new WindowManagerInternalProxyImpl.fromHandle(handle) {
    ptr = new _WindowManagerInternalProxyCalls(impl);
  }

  WindowManagerInternalProxy.unbound() :
      impl = new WindowManagerInternalProxyImpl.unbound() {
    ptr = new _WindowManagerInternalProxyCalls(impl);
  }

  static WindowManagerInternalProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "WindowManagerInternalProxy($impl)";
  }
}


class WindowManagerInternalStub extends bindings.Stub {
  WindowManagerInternal _impl = null;

  WindowManagerInternalStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WindowManagerInternalStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WindowManagerInternalStub.unbound() : super.unbound();

  static WindowManagerInternalStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalStub.fromEndpoint(endpoint);

  static const String name = WindowManagerInternalName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWindowManagerInternal_createWindowManagerForViewManagerClient_name:
        var params = WindowManagerInternalCreateWindowManagerForViewManagerClientParams.deserialize(
            message.payload);
        _impl.createWindowManagerForViewManagerClient(params.connectionId, params.windowManagerPipe);
        break;
      case kWindowManagerInternal_setViewManagerClient_name:
        var params = WindowManagerInternalSetViewManagerClientParams.deserialize(
            message.payload);
        _impl.setViewManagerClient(params.viewManagerClientRequest);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WindowManagerInternal get impl => _impl;
      set impl(WindowManagerInternal d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerInternalStub($superString)";
  }
}

const int kWindowManagerInternalClient_dispatchInputEventToView_name = 0;
const int kWindowManagerInternalClient_setViewportSize_name = 1;
const int kWindowManagerInternalClient_cloneAndAnimate_name = 2;

const String WindowManagerInternalClientName =
      'mojo::WindowManagerInternalClient';

abstract class WindowManagerInternalClient {
  void dispatchInputEventToView(int viewId, input_events_mojom.Event event);
  void setViewportSize(geometry_mojom.Size size);
  void cloneAndAnimate(int viewId);

}


class WindowManagerInternalClientProxyImpl extends bindings.Proxy {
  WindowManagerInternalClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WindowManagerInternalClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WindowManagerInternalClientProxyImpl.unbound() : super.unbound();

  static WindowManagerInternalClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalClientProxyImpl.fromEndpoint(endpoint);

  String get name => WindowManagerInternalClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerInternalClientProxyImpl($superString)";
  }
}


class _WindowManagerInternalClientProxyCalls implements WindowManagerInternalClient {
  WindowManagerInternalClientProxyImpl _proxyImpl;

  _WindowManagerInternalClientProxyCalls(this._proxyImpl);
    void dispatchInputEventToView(int viewId, input_events_mojom.Event event) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerInternalClientDispatchInputEventToViewParams();
      params.viewId = viewId;
      params.event = event;
      _proxyImpl.sendMessage(params, kWindowManagerInternalClient_dispatchInputEventToView_name);
    }
  
    void setViewportSize(geometry_mojom.Size size) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerInternalClientSetViewportSizeParams();
      params.size = size;
      _proxyImpl.sendMessage(params, kWindowManagerInternalClient_setViewportSize_name);
    }
  
    void cloneAndAnimate(int viewId) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerInternalClientCloneAndAnimateParams();
      params.viewId = viewId;
      _proxyImpl.sendMessage(params, kWindowManagerInternalClient_cloneAndAnimate_name);
    }
  
}


class WindowManagerInternalClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WindowManagerInternalClient ptr;
  final String name = WindowManagerInternalClientName;

  WindowManagerInternalClientProxy(WindowManagerInternalClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WindowManagerInternalClientProxyCalls(proxyImpl);

  WindowManagerInternalClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WindowManagerInternalClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WindowManagerInternalClientProxyCalls(impl);
  }

  WindowManagerInternalClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new WindowManagerInternalClientProxyImpl.fromHandle(handle) {
    ptr = new _WindowManagerInternalClientProxyCalls(impl);
  }

  WindowManagerInternalClientProxy.unbound() :
      impl = new WindowManagerInternalClientProxyImpl.unbound() {
    ptr = new _WindowManagerInternalClientProxyCalls(impl);
  }

  static WindowManagerInternalClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalClientProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "WindowManagerInternalClientProxy($impl)";
  }
}


class WindowManagerInternalClientStub extends bindings.Stub {
  WindowManagerInternalClient _impl = null;

  WindowManagerInternalClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WindowManagerInternalClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WindowManagerInternalClientStub.unbound() : super.unbound();

  static WindowManagerInternalClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerInternalClientStub.fromEndpoint(endpoint);

  static const String name = WindowManagerInternalClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWindowManagerInternalClient_dispatchInputEventToView_name:
        var params = WindowManagerInternalClientDispatchInputEventToViewParams.deserialize(
            message.payload);
        _impl.dispatchInputEventToView(params.viewId, params.event);
        break;
      case kWindowManagerInternalClient_setViewportSize_name:
        var params = WindowManagerInternalClientSetViewportSizeParams.deserialize(
            message.payload);
        _impl.setViewportSize(params.size);
        break;
      case kWindowManagerInternalClient_cloneAndAnimate_name:
        var params = WindowManagerInternalClientCloneAndAnimateParams.deserialize(
            message.payload);
        _impl.cloneAndAnimate(params.viewId);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WindowManagerInternalClient get impl => _impl;
      set impl(WindowManagerInternalClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerInternalClientStub($superString)";
  }
}


