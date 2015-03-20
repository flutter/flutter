// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sensors.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;

final int SensorType_ACCELEROMETER = 0;
final int SensorType_AMBIENT_TEMPERATURE = SensorType_ACCELEROMETER + 1;
final int SensorType_GAME_ROTATION_VECTOR = SensorType_AMBIENT_TEMPERATURE + 1;
final int SensorType_GEOMAGNETIC_ROTATION_VECTOR = SensorType_GAME_ROTATION_VECTOR + 1;
final int SensorType_GRAVITY = SensorType_GEOMAGNETIC_ROTATION_VECTOR + 1;
final int SensorType_GYROSCOPE = SensorType_GRAVITY + 1;
final int SensorType_GYROSCOPE_UNCALIBRATED = SensorType_GYROSCOPE + 1;
final int SensorType_HEART_RATE = SensorType_GYROSCOPE_UNCALIBRATED + 1;
final int SensorType_LIGHT = SensorType_HEART_RATE + 1;
final int SensorType_LINEAR_ACCELERATION = SensorType_LIGHT + 1;
final int SensorType_MAGNETIC_FIELD = SensorType_LINEAR_ACCELERATION + 1;
final int SensorType_MAGNETIC_FIELD_UNCALIBRATED = SensorType_MAGNETIC_FIELD + 1;
final int SensorType_PRESSURE = SensorType_MAGNETIC_FIELD_UNCALIBRATED + 1;
final int SensorType_PROXIMITY = SensorType_PRESSURE + 1;
final int SensorType_RELATIVE_HUMIDITY = SensorType_PROXIMITY + 1;
final int SensorType_ROTATION_VECTOR = SensorType_RELATIVE_HUMIDITY + 1;
final int SensorType_SIGNIFICANT_MOTION = SensorType_ROTATION_VECTOR + 1;
final int SensorType_STEP_COUNTER = SensorType_SIGNIFICANT_MOTION + 1;
final int SensorType_STEP_DETECTOR = SensorType_STEP_COUNTER + 1;


class SensorData extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int accuracy = 0;
  int timeStamp = 0;
  List<double> values = null;

  SensorData() : super(kStructSize);

  static SensorData deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SensorData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SensorData result = new SensorData();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.accuracy = decoder0.decodeInt32(8);
    }
    {
      
      result.timeStamp = decoder0.decodeInt64(16);
    }
    {
      
      result.values = decoder0.decodeFloatArray(24, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(accuracy, 8);
    
    encoder0.encodeInt64(timeStamp, 16);
    
    encoder0.encodeFloatArray(values, 24, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "SensorData("
           "accuracy: $accuracy" ", "
           "timeStamp: $timeStamp" ", "
           "values: $values" ")";
  }
}

class SensorListenerOnAccuracyChangedParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int accuracy = 0;

  SensorListenerOnAccuracyChangedParams() : super(kStructSize);

  static SensorListenerOnAccuracyChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SensorListenerOnAccuracyChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SensorListenerOnAccuracyChangedParams result = new SensorListenerOnAccuracyChangedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.accuracy = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(accuracy, 8);
  }

  String toString() {
    return "SensorListenerOnAccuracyChangedParams("
           "accuracy: $accuracy" ")";
  }
}

class SensorListenerOnSensorChangedParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  SensorData data = null;

  SensorListenerOnSensorChangedParams() : super(kStructSize);

  static SensorListenerOnSensorChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SensorListenerOnSensorChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SensorListenerOnSensorChangedParams result = new SensorListenerOnSensorChangedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.data = SensorData.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(data, 8, false);
  }

  String toString() {
    return "SensorListenerOnSensorChangedParams("
           "data: $data" ")";
  }
}

class SensorServiceAddListenerParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int type = 0;
  Object listener = null;

  SensorServiceAddListenerParams() : super(kStructSize);

  static SensorServiceAddListenerParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SensorServiceAddListenerParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SensorServiceAddListenerParams result = new SensorServiceAddListenerParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.type = decoder0.decodeInt32(8);
    }
    {
      
      result.listener = decoder0.decodeServiceInterface(12, false, SensorListenerProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(type, 8);
    
    encoder0.encodeInterface(listener, 12, false);
  }

  String toString() {
    return "SensorServiceAddListenerParams("
           "type: $type" ", "
           "listener: $listener" ")";
  }
}
const int kSensorListener_onAccuracyChanged_name = 0;
const int kSensorListener_onSensorChanged_name = 1;

const String SensorListenerName =
      'sensors::SensorListener';

abstract class SensorListener {
  void onAccuracyChanged(int accuracy);
  void onSensorChanged(SensorData data);

}


class SensorListenerProxyImpl extends bindings.Proxy {
  SensorListenerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  SensorListenerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  SensorListenerProxyImpl.unbound() : super.unbound();

  static SensorListenerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorListenerProxyImpl.fromEndpoint(endpoint);

  String get name => SensorListenerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "SensorListenerProxyImpl($superString)";
  }
}


class _SensorListenerProxyCalls implements SensorListener {
  SensorListenerProxyImpl _proxyImpl;

  _SensorListenerProxyCalls(this._proxyImpl);
    void onAccuracyChanged(int accuracy) {
      assert(_proxyImpl.isBound);
      var params = new SensorListenerOnAccuracyChangedParams();
      params.accuracy = accuracy;
      _proxyImpl.sendMessage(params, kSensorListener_onAccuracyChanged_name);
    }
  
    void onSensorChanged(SensorData data) {
      assert(_proxyImpl.isBound);
      var params = new SensorListenerOnSensorChangedParams();
      params.data = data;
      _proxyImpl.sendMessage(params, kSensorListener_onSensorChanged_name);
    }
  
}


class SensorListenerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  SensorListener ptr;
  final String name = SensorListenerName;

  SensorListenerProxy(SensorListenerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _SensorListenerProxyCalls(proxyImpl);

  SensorListenerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new SensorListenerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _SensorListenerProxyCalls(impl);
  }

  SensorListenerProxy.fromHandle(core.MojoHandle handle) :
      impl = new SensorListenerProxyImpl.fromHandle(handle) {
    ptr = new _SensorListenerProxyCalls(impl);
  }

  SensorListenerProxy.unbound() :
      impl = new SensorListenerProxyImpl.unbound() {
    ptr = new _SensorListenerProxyCalls(impl);
  }

  static SensorListenerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorListenerProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "SensorListenerProxy($impl)";
  }
}


class SensorListenerStub extends bindings.Stub {
  SensorListener _impl = null;

  SensorListenerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  SensorListenerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  SensorListenerStub.unbound() : super.unbound();

  static SensorListenerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorListenerStub.fromEndpoint(endpoint);

  static const String name = SensorListenerName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kSensorListener_onAccuracyChanged_name:
        var params = SensorListenerOnAccuracyChangedParams.deserialize(
            message.payload);
        _impl.onAccuracyChanged(params.accuracy);
        break;
      case kSensorListener_onSensorChanged_name:
        var params = SensorListenerOnSensorChangedParams.deserialize(
            message.payload);
        _impl.onSensorChanged(params.data);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  SensorListener get impl => _impl;
      set impl(SensorListener d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "SensorListenerStub($superString)";
  }
}

const int kSensorService_addListener_name = 0;

const String SensorServiceName =
      'sensors::SensorService';

abstract class SensorService {
  void addListener(int type, Object listener);

}


class SensorServiceProxyImpl extends bindings.Proxy {
  SensorServiceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  SensorServiceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  SensorServiceProxyImpl.unbound() : super.unbound();

  static SensorServiceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorServiceProxyImpl.fromEndpoint(endpoint);

  String get name => SensorServiceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "SensorServiceProxyImpl($superString)";
  }
}


class _SensorServiceProxyCalls implements SensorService {
  SensorServiceProxyImpl _proxyImpl;

  _SensorServiceProxyCalls(this._proxyImpl);
    void addListener(int type, Object listener) {
      assert(_proxyImpl.isBound);
      var params = new SensorServiceAddListenerParams();
      params.type = type;
      params.listener = listener;
      _proxyImpl.sendMessage(params, kSensorService_addListener_name);
    }
  
}


class SensorServiceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  SensorService ptr;
  final String name = SensorServiceName;

  SensorServiceProxy(SensorServiceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _SensorServiceProxyCalls(proxyImpl);

  SensorServiceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new SensorServiceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _SensorServiceProxyCalls(impl);
  }

  SensorServiceProxy.fromHandle(core.MojoHandle handle) :
      impl = new SensorServiceProxyImpl.fromHandle(handle) {
    ptr = new _SensorServiceProxyCalls(impl);
  }

  SensorServiceProxy.unbound() :
      impl = new SensorServiceProxyImpl.unbound() {
    ptr = new _SensorServiceProxyCalls(impl);
  }

  static SensorServiceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorServiceProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "SensorServiceProxy($impl)";
  }
}


class SensorServiceStub extends bindings.Stub {
  SensorService _impl = null;

  SensorServiceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  SensorServiceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  SensorServiceStub.unbound() : super.unbound();

  static SensorServiceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SensorServiceStub.fromEndpoint(endpoint);

  static const String name = SensorServiceName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kSensorService_addListener_name:
        var params = SensorServiceAddListenerParams.deserialize(
            message.payload);
        _impl.addListener(params.type, params.listener);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  SensorService get impl => _impl;
      set impl(SensorService d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "SensorServiceStub($superString)";
  }
}


