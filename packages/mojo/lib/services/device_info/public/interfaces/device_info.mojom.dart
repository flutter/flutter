// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library device_info.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class DeviceInfoGetDeviceTypeParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  DeviceInfoGetDeviceTypeParams() : super(kVersions.last.size);

  static DeviceInfoGetDeviceTypeParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static DeviceInfoGetDeviceTypeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DeviceInfoGetDeviceTypeParams result = new DeviceInfoGetDeviceTypeParams();

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
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kVersions.last);
  }

  String toString() {
    return "DeviceInfoGetDeviceTypeParams("")";
  }
}

class DeviceInfoGetDeviceTypeResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int deviceType = 0;

  DeviceInfoGetDeviceTypeResponseParams() : super(kVersions.last.size);

  static DeviceInfoGetDeviceTypeResponseParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static DeviceInfoGetDeviceTypeResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DeviceInfoGetDeviceTypeResponseParams result = new DeviceInfoGetDeviceTypeResponseParams();

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
      
      result.deviceType = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(deviceType, 8);
  }

  String toString() {
    return "DeviceInfoGetDeviceTypeResponseParams("
           "deviceType: $deviceType" ")";
  }
}
const int kDeviceInfo_getDeviceType_name = 0;

const String DeviceInfoName =
      'mojo::DeviceInfo';

abstract class DeviceInfo {
  Future<DeviceInfoGetDeviceTypeResponseParams> getDeviceType([Function responseFactory = null]);

  
  static const int DeviceType_UNKNOWN = 0;
  static const int DeviceType_HEADLESS = 1;
  static const int DeviceType_WATCH = 2;
  static const int DeviceType_PHONE = 3;
  static const int DeviceType_TABLET = 4;
  static const int DeviceType_DESKTOP = 5;
  static const int DeviceType_TV = 6;
}


class DeviceInfoProxyImpl extends bindings.Proxy {
  DeviceInfoProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  DeviceInfoProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  DeviceInfoProxyImpl.unbound() : super.unbound();

  static DeviceInfoProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DeviceInfoProxyImpl.fromEndpoint(endpoint);

  String get name => DeviceInfoName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kDeviceInfo_getDeviceType_name:
        var r = DeviceInfoGetDeviceTypeResponseParams.deserialize(
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
    return "DeviceInfoProxyImpl($superString)";
  }
}


class _DeviceInfoProxyCalls implements DeviceInfo {
  DeviceInfoProxyImpl _proxyImpl;

  _DeviceInfoProxyCalls(this._proxyImpl);
    Future<DeviceInfoGetDeviceTypeResponseParams> getDeviceType([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new DeviceInfoGetDeviceTypeParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kDeviceInfo_getDeviceType_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class DeviceInfoProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  DeviceInfo ptr;
  final String name = DeviceInfoName;

  DeviceInfoProxy(DeviceInfoProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _DeviceInfoProxyCalls(proxyImpl);

  DeviceInfoProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new DeviceInfoProxyImpl.fromEndpoint(endpoint) {
    ptr = new _DeviceInfoProxyCalls(impl);
  }

  DeviceInfoProxy.fromHandle(core.MojoHandle handle) :
      impl = new DeviceInfoProxyImpl.fromHandle(handle) {
    ptr = new _DeviceInfoProxyCalls(impl);
  }

  DeviceInfoProxy.unbound() :
      impl = new DeviceInfoProxyImpl.unbound() {
    ptr = new _DeviceInfoProxyCalls(impl);
  }

  static DeviceInfoProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DeviceInfoProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "DeviceInfoProxy($impl)";
  }
}


class DeviceInfoStub extends bindings.Stub {
  DeviceInfo _impl = null;

  DeviceInfoStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  DeviceInfoStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  DeviceInfoStub.unbound() : super.unbound();

  static DeviceInfoStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DeviceInfoStub.fromEndpoint(endpoint);

  static const String name = DeviceInfoName;


  DeviceInfoGetDeviceTypeResponseParams _DeviceInfoGetDeviceTypeResponseParamsFactory(int deviceType) {
    var result = new DeviceInfoGetDeviceTypeResponseParams();
    result.deviceType = deviceType;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kDeviceInfo_getDeviceType_name:
        var params = DeviceInfoGetDeviceTypeParams.deserialize(
            message.payload);
        return _impl.getDeviceType(_DeviceInfoGetDeviceTypeResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kDeviceInfo_getDeviceType_name,
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

  DeviceInfo get impl => _impl;
      set impl(DeviceInfo d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "DeviceInfoStub($superString)";
  }
}


