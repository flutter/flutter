// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library gpu.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/gpu/public/interfaces/command_buffer.mojom.dart' as command_buffer_mojom;


class GpuCreateOffscreenGleS2ContextParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object gles2Client = null;

  GpuCreateOffscreenGleS2ContextParams() : super(kVersions.last.size);

  static GpuCreateOffscreenGleS2ContextParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GpuCreateOffscreenGleS2ContextParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GpuCreateOffscreenGleS2ContextParams result = new GpuCreateOffscreenGleS2ContextParams();

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
      
      result.gles2Client = decoder0.decodeInterfaceRequest(8, false, command_buffer_mojom.CommandBufferStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(gles2Client, 8, false);
  }

  String toString() {
    return "GpuCreateOffscreenGleS2ContextParams("
           "gles2Client: $gles2Client" ")";
  }
}
const int kGpu_createOffscreenGleS2Context_name = 0;

const String GpuName =
      'mojo::Gpu';

abstract class Gpu {
  void createOffscreenGleS2Context(Object gles2Client);

}


class GpuProxyImpl extends bindings.Proxy {
  GpuProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  GpuProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  GpuProxyImpl.unbound() : super.unbound();

  static GpuProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GpuProxyImpl.fromEndpoint(endpoint);

  String get name => GpuName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "GpuProxyImpl($superString)";
  }
}


class _GpuProxyCalls implements Gpu {
  GpuProxyImpl _proxyImpl;

  _GpuProxyCalls(this._proxyImpl);
    void createOffscreenGleS2Context(Object gles2Client) {
      assert(_proxyImpl.isBound);
      var params = new GpuCreateOffscreenGleS2ContextParams();
      params.gles2Client = gles2Client;
      _proxyImpl.sendMessage(params, kGpu_createOffscreenGleS2Context_name);
    }
  
}


class GpuProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Gpu ptr;
  final String name = GpuName;

  GpuProxy(GpuProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _GpuProxyCalls(proxyImpl);

  GpuProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new GpuProxyImpl.fromEndpoint(endpoint) {
    ptr = new _GpuProxyCalls(impl);
  }

  GpuProxy.fromHandle(core.MojoHandle handle) :
      impl = new GpuProxyImpl.fromHandle(handle) {
    ptr = new _GpuProxyCalls(impl);
  }

  GpuProxy.unbound() :
      impl = new GpuProxyImpl.unbound() {
    ptr = new _GpuProxyCalls(impl);
  }

  static GpuProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GpuProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "GpuProxy($impl)";
  }
}


class GpuStub extends bindings.Stub {
  Gpu _impl = null;

  GpuStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  GpuStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  GpuStub.unbound() : super.unbound();

  static GpuStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new GpuStub.fromEndpoint(endpoint);

  static const String name = GpuName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kGpu_createOffscreenGleS2Context_name:
        var params = GpuCreateOffscreenGleS2ContextParams.deserialize(
            message.payload);
        _impl.createOffscreenGleS2Context(params.gles2Client);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Gpu get impl => _impl;
      set impl(Gpu d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "GpuStub($superString)";
  }
}


