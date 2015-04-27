// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library window_manager.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/geometry.mojom.dart' as geometry_mojom;


class IWindowManagerCloseWindowParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int nodeId = 0;

  IWindowManagerCloseWindowParams() : super(kVersions.last.size);

  static IWindowManagerCloseWindowParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static IWindowManagerCloseWindowParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    IWindowManagerCloseWindowParams result = new IWindowManagerCloseWindowParams();

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
      
      result.nodeId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(nodeId, 8);
  }

  String toString() {
    return "IWindowManagerCloseWindowParams("
           "nodeId: $nodeId" ")";
  }
}
const int kIWindowManager_closeWindow_name = 0;

const String IWindowManagerName =
      'mojo::IWindowManager';

abstract class IWindowManager {
  void closeWindow(int nodeId);

}


class IWindowManagerProxyImpl extends bindings.Proxy {
  IWindowManagerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  IWindowManagerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  IWindowManagerProxyImpl.unbound() : super.unbound();

  static IWindowManagerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IWindowManagerProxyImpl.fromEndpoint(endpoint);

  String get name => IWindowManagerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "IWindowManagerProxyImpl($superString)";
  }
}


class _IWindowManagerProxyCalls implements IWindowManager {
  IWindowManagerProxyImpl _proxyImpl;

  _IWindowManagerProxyCalls(this._proxyImpl);
    void closeWindow(int nodeId) {
      assert(_proxyImpl.isBound);
      var params = new IWindowManagerCloseWindowParams();
      params.nodeId = nodeId;
      _proxyImpl.sendMessage(params, kIWindowManager_closeWindow_name);
    }
  
}


class IWindowManagerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  IWindowManager ptr;
  final String name = IWindowManagerName;

  IWindowManagerProxy(IWindowManagerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _IWindowManagerProxyCalls(proxyImpl);

  IWindowManagerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new IWindowManagerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _IWindowManagerProxyCalls(impl);
  }

  IWindowManagerProxy.fromHandle(core.MojoHandle handle) :
      impl = new IWindowManagerProxyImpl.fromHandle(handle) {
    ptr = new _IWindowManagerProxyCalls(impl);
  }

  IWindowManagerProxy.unbound() :
      impl = new IWindowManagerProxyImpl.unbound() {
    ptr = new _IWindowManagerProxyCalls(impl);
  }

  static IWindowManagerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IWindowManagerProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "IWindowManagerProxy($impl)";
  }
}


class IWindowManagerStub extends bindings.Stub {
  IWindowManager _impl = null;

  IWindowManagerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  IWindowManagerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  IWindowManagerStub.unbound() : super.unbound();

  static IWindowManagerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IWindowManagerStub.fromEndpoint(endpoint);

  static const String name = IWindowManagerName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kIWindowManager_closeWindow_name:
        var params = IWindowManagerCloseWindowParams.deserialize(
            message.payload);
        _impl.closeWindow(params.nodeId);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  IWindowManager get impl => _impl;
      set impl(IWindowManager d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "IWindowManagerStub($superString)";
  }
}


