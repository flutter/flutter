// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library location_service.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/location/public/interfaces/location.mojom.dart' as location_mojom;


class LocationServiceGetNextLocationParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int priority = 0;

  LocationServiceGetNextLocationParams() : super(kVersions.last.size);

  static LocationServiceGetNextLocationParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static LocationServiceGetNextLocationParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    LocationServiceGetNextLocationParams result = new LocationServiceGetNextLocationParams();

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
      
      result.priority = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(priority, 8);
  }

  String toString() {
    return "LocationServiceGetNextLocationParams("
           "priority: $priority" ")";
  }
}

class LocationServiceGetNextLocationResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  location_mojom.Location location = null;

  LocationServiceGetNextLocationResponseParams() : super(kVersions.last.size);

  static LocationServiceGetNextLocationResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static LocationServiceGetNextLocationResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    LocationServiceGetNextLocationResponseParams result = new LocationServiceGetNextLocationResponseParams();

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
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.location = location_mojom.Location.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(location, 8, true);
  }

  String toString() {
    return "LocationServiceGetNextLocationResponseParams("
           "location: $location" ")";
  }
}
const int kLocationService_getNextLocation_name = 0;

const String LocationServiceName =
      'mojo::LocationService';

abstract class LocationService {
  Future<LocationServiceGetNextLocationResponseParams> getNextLocation(int priority,[Function responseFactory = null]);

  
  static final int UpdatePriority_PRIORITY_BALANCED_POWER_ACCURACY = 0;
  static final int UpdatePriority_PRIORITY_HIGH_ACCURACY = UpdatePriority_PRIORITY_BALANCED_POWER_ACCURACY + 1;
  static final int UpdatePriority_PRIORITY_LOW_POWER = UpdatePriority_PRIORITY_HIGH_ACCURACY + 1;
  static final int UpdatePriority_PRIORITY_NO_POWER = UpdatePriority_PRIORITY_LOW_POWER + 1;
}


class LocationServiceProxyImpl extends bindings.Proxy {
  LocationServiceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  LocationServiceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  LocationServiceProxyImpl.unbound() : super.unbound();

  static LocationServiceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new LocationServiceProxyImpl.fromEndpoint(endpoint);

  String get name => LocationServiceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kLocationService_getNextLocation_name:
        var r = LocationServiceGetNextLocationResponseParams.deserialize(
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
    return "LocationServiceProxyImpl($superString)";
  }
}


class _LocationServiceProxyCalls implements LocationService {
  LocationServiceProxyImpl _proxyImpl;

  _LocationServiceProxyCalls(this._proxyImpl);
    Future<LocationServiceGetNextLocationResponseParams> getNextLocation(int priority,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new LocationServiceGetNextLocationParams();
      params.priority = priority;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kLocationService_getNextLocation_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class LocationServiceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  LocationService ptr;
  final String name = LocationServiceName;

  LocationServiceProxy(LocationServiceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _LocationServiceProxyCalls(proxyImpl);

  LocationServiceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new LocationServiceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _LocationServiceProxyCalls(impl);
  }

  LocationServiceProxy.fromHandle(core.MojoHandle handle) :
      impl = new LocationServiceProxyImpl.fromHandle(handle) {
    ptr = new _LocationServiceProxyCalls(impl);
  }

  LocationServiceProxy.unbound() :
      impl = new LocationServiceProxyImpl.unbound() {
    ptr = new _LocationServiceProxyCalls(impl);
  }

  static LocationServiceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new LocationServiceProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "LocationServiceProxy($impl)";
  }
}


class LocationServiceStub extends bindings.Stub {
  LocationService _impl = null;

  LocationServiceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  LocationServiceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  LocationServiceStub.unbound() : super.unbound();

  static LocationServiceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new LocationServiceStub.fromEndpoint(endpoint);

  static const String name = LocationServiceName;


  LocationServiceGetNextLocationResponseParams _LocationServiceGetNextLocationResponseParamsFactory(location_mojom.Location location) {
    var result = new LocationServiceGetNextLocationResponseParams();
    result.location = location;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kLocationService_getNextLocation_name:
        var params = LocationServiceGetNextLocationParams.deserialize(
            message.payload);
        return _impl.getNextLocation(params.priority,_LocationServiceGetNextLocationResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kLocationService_getNextLocation_name,
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

  LocationService get impl => _impl;
      set impl(LocationService d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "LocationServiceStub($superString)";
  }
}


