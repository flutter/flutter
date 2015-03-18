// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_to_cpp.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class EchoArgs extends bindings.Struct {
  static const int kStructSize = 104;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int si64 = 0;
  int si32 = 0;
  int si16 = 0;
  int si8 = 0;
  int ui8 = 0;
  int ui64 = 0;
  int ui32 = 0;
  int ui16 = 0;
  double floatVal = 0.0;
  double floatInf = 0.0;
  double floatNan = 0.0;
  core.MojoMessagePipeEndpoint messageHandle = null;
  double doubleVal = 0.0;
  double doubleInf = 0.0;
  double doubleNan = 0.0;
  String name = null;
  List<String> stringArray = null;
  core.MojoDataPipeConsumer dataHandle = null;

  EchoArgs() : super(kStructSize);

  static EchoArgs deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EchoArgs decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EchoArgs result = new EchoArgs();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.si64 = decoder0.decodeInt64(8);
    }
    {
      
      result.si32 = decoder0.decodeInt32(16);
    }
    {
      
      result.si16 = decoder0.decodeInt16(20);
    }
    {
      
      result.si8 = decoder0.decodeInt8(22);
    }
    {
      
      result.ui8 = decoder0.decodeUint8(23);
    }
    {
      
      result.ui64 = decoder0.decodeUint64(24);
    }
    {
      
      result.ui32 = decoder0.decodeUint32(32);
    }
    {
      
      result.ui16 = decoder0.decodeUint16(36);
    }
    {
      
      result.floatVal = decoder0.decodeFloat(40);
    }
    {
      
      result.floatInf = decoder0.decodeFloat(44);
    }
    {
      
      result.floatNan = decoder0.decodeFloat(48);
    }
    {
      
      result.messageHandle = decoder0.decodeMessagePipeHandle(52, true);
    }
    {
      
      result.doubleVal = decoder0.decodeDouble(56);
    }
    {
      
      result.doubleInf = decoder0.decodeDouble(64);
    }
    {
      
      result.doubleNan = decoder0.decodeDouble(72);
    }
    {
      
      result.name = decoder0.decodeString(80, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(88, true);
      if (decoder1 == null) {
        result.stringArray = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.stringArray = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.stringArray[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      result.dataHandle = decoder0.decodeConsumerHandle(96, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt64(si64, 8);
    
    encoder0.encodeInt32(si32, 16);
    
    encoder0.encodeInt16(si16, 20);
    
    encoder0.encodeInt8(si8, 22);
    
    encoder0.encodeUint8(ui8, 23);
    
    encoder0.encodeUint64(ui64, 24);
    
    encoder0.encodeUint32(ui32, 32);
    
    encoder0.encodeUint16(ui16, 36);
    
    encoder0.encodeFloat(floatVal, 40);
    
    encoder0.encodeFloat(floatInf, 44);
    
    encoder0.encodeFloat(floatNan, 48);
    
    encoder0.encodeMessagePipeHandle(messageHandle, 52, true);
    
    encoder0.encodeDouble(doubleVal, 56);
    
    encoder0.encodeDouble(doubleInf, 64);
    
    encoder0.encodeDouble(doubleNan, 72);
    
    encoder0.encodeString(name, 80, true);
    
    if (stringArray == null) {
      encoder0.encodeNullPointer(88, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(stringArray.length, 88, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < stringArray.length; ++i0) {
        
        encoder1.encodeString(stringArray[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeConsumerHandle(dataHandle, 96, true);
  }

  String toString() {
    return "EchoArgs("
           "si64: $si64" ", "
           "si32: $si32" ", "
           "si16: $si16" ", "
           "si8: $si8" ", "
           "ui8: $ui8" ", "
           "ui64: $ui64" ", "
           "ui32: $ui32" ", "
           "ui16: $ui16" ", "
           "floatVal: $floatVal" ", "
           "floatInf: $floatInf" ", "
           "floatNan: $floatNan" ", "
           "messageHandle: $messageHandle" ", "
           "doubleVal: $doubleVal" ", "
           "doubleInf: $doubleInf" ", "
           "doubleNan: $doubleNan" ", "
           "name: $name" ", "
           "stringArray: $stringArray" ", "
           "dataHandle: $dataHandle" ")";
  }
}

class EchoArgsList extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  EchoArgsList next = null;
  EchoArgs item = null;

  EchoArgsList() : super(kStructSize);

  static EchoArgsList deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EchoArgsList decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EchoArgsList result = new EchoArgsList();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.next = EchoArgsList.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.item = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(next, 8, true);
    
    encoder0.encodeStruct(item, 16, true);
  }

  String toString() {
    return "EchoArgsList("
           "next: $next" ", "
           "item: $item" ")";
  }
}

class CppSideStartTestParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CppSideStartTestParams() : super(kStructSize);

  static CppSideStartTestParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideStartTestParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideStartTestParams result = new CppSideStartTestParams();

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
    return "CppSideStartTestParams("")";
  }
}

class CppSideTestFinishedParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CppSideTestFinishedParams() : super(kStructSize);

  static CppSideTestFinishedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideTestFinishedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideTestFinishedParams result = new CppSideTestFinishedParams();

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
    return "CppSideTestFinishedParams("")";
  }
}

class CppSidePingResponseParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CppSidePingResponseParams() : super(kStructSize);

  static CppSidePingResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSidePingResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSidePingResponseParams result = new CppSidePingResponseParams();

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
    return "CppSidePingResponseParams("")";
  }
}

class CppSideEchoResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  EchoArgsList list = null;

  CppSideEchoResponseParams() : super(kStructSize);

  static CppSideEchoResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideEchoResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideEchoResponseParams result = new CppSideEchoResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.list = EchoArgsList.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(list, 8, false);
  }

  String toString() {
    return "CppSideEchoResponseParams("
           "list: $list" ")";
  }
}

class DartSideSetClientParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object cppSide = null;

  DartSideSetClientParams() : super(kStructSize);

  static DartSideSetClientParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DartSideSetClientParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DartSideSetClientParams result = new DartSideSetClientParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.cppSide = decoder0.decodeServiceInterface(8, false, CppSideProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(cppSide, 8, false);
  }

  String toString() {
    return "DartSideSetClientParams("
           "cppSide: $cppSide" ")";
  }
}

class DartSidePingParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  DartSidePingParams() : super(kStructSize);

  static DartSidePingParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DartSidePingParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DartSidePingParams result = new DartSidePingParams();

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
    return "DartSidePingParams("")";
  }
}

class DartSideEchoParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int numIterations = 0;
  EchoArgs arg = null;

  DartSideEchoParams() : super(kStructSize);

  static DartSideEchoParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DartSideEchoParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DartSideEchoParams result = new DartSideEchoParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.numIterations = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.arg = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(numIterations, 8);
    
    encoder0.encodeStruct(arg, 16, false);
  }

  String toString() {
    return "DartSideEchoParams("
           "numIterations: $numIterations" ", "
           "arg: $arg" ")";
  }
}
const int kCppSide_startTest_name = 88888888;
const int kCppSide_testFinished_name = 99999999;
const int kCppSide_pingResponse_name = 100000000;
const int kCppSide_echoResponse_name = 100000001;

const String CppSideName =
      'dart_to_cpp::CppSide';

abstract class CppSide {
  void startTest();
  void testFinished();
  void pingResponse();
  void echoResponse(EchoArgsList list);

}


class CppSideProxyImpl extends bindings.Proxy {
  CppSideProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CppSideProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CppSideProxyImpl.unbound() : super.unbound();

  static CppSideProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideProxyImpl.fromEndpoint(endpoint);

  String get name => CppSideName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CppSideProxyImpl($superString)";
  }
}


class _CppSideProxyCalls implements CppSide {
  CppSideProxyImpl _proxyImpl;

  _CppSideProxyCalls(this._proxyImpl);
    void startTest() {
      assert(_proxyImpl.isBound);
      var params = new CppSideStartTestParams();
      _proxyImpl.sendMessage(params, kCppSide_startTest_name);
    }
  
    void testFinished() {
      assert(_proxyImpl.isBound);
      var params = new CppSideTestFinishedParams();
      _proxyImpl.sendMessage(params, kCppSide_testFinished_name);
    }
  
    void pingResponse() {
      assert(_proxyImpl.isBound);
      var params = new CppSidePingResponseParams();
      _proxyImpl.sendMessage(params, kCppSide_pingResponse_name);
    }
  
    void echoResponse(EchoArgsList list) {
      assert(_proxyImpl.isBound);
      var params = new CppSideEchoResponseParams();
      params.list = list;
      _proxyImpl.sendMessage(params, kCppSide_echoResponse_name);
    }
  
}


class CppSideProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CppSide ptr;
  final String name = CppSideName;

  CppSideProxy(CppSideProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CppSideProxyCalls(proxyImpl);

  CppSideProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CppSideProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CppSideProxyCalls(impl);
  }

  CppSideProxy.fromHandle(core.MojoHandle handle) :
      impl = new CppSideProxyImpl.fromHandle(handle) {
    ptr = new _CppSideProxyCalls(impl);
  }

  CppSideProxy.unbound() :
      impl = new CppSideProxyImpl.unbound() {
    ptr = new _CppSideProxyCalls(impl);
  }

  static CppSideProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "CppSideProxy($impl)";
  }
}


class CppSideStub extends bindings.Stub {
  CppSide _impl = null;

  CppSideStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CppSideStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CppSideStub.unbound() : super.unbound();

  static CppSideStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideStub.fromEndpoint(endpoint);

  static const String name = CppSideName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCppSide_startTest_name:
        var params = CppSideStartTestParams.deserialize(
            message.payload);
        _impl.startTest();
        break;
      case kCppSide_testFinished_name:
        var params = CppSideTestFinishedParams.deserialize(
            message.payload);
        _impl.testFinished();
        break;
      case kCppSide_pingResponse_name:
        var params = CppSidePingResponseParams.deserialize(
            message.payload);
        _impl.pingResponse();
        break;
      case kCppSide_echoResponse_name:
        var params = CppSideEchoResponseParams.deserialize(
            message.payload);
        _impl.echoResponse(params.list);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CppSide get impl => _impl;
      set impl(CppSide d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CppSideStub($superString)";
  }
}

const int kDartSide_setClient_name = 0;
const int kDartSide_ping_name = 1;
const int kDartSide_echo_name = 2;

const String DartSideName =
      'dart_to_cpp::DartSide';

abstract class DartSide {
  void setClient(Object cppSide);
  void ping();
  void echo(int numIterations, EchoArgs arg);

}


class DartSideProxyImpl extends bindings.Proxy {
  DartSideProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  DartSideProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  DartSideProxyImpl.unbound() : super.unbound();

  static DartSideProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DartSideProxyImpl.fromEndpoint(endpoint);

  String get name => DartSideName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "DartSideProxyImpl($superString)";
  }
}


class _DartSideProxyCalls implements DartSide {
  DartSideProxyImpl _proxyImpl;

  _DartSideProxyCalls(this._proxyImpl);
    void setClient(Object cppSide) {
      assert(_proxyImpl.isBound);
      var params = new DartSideSetClientParams();
      params.cppSide = cppSide;
      _proxyImpl.sendMessage(params, kDartSide_setClient_name);
    }
  
    void ping() {
      assert(_proxyImpl.isBound);
      var params = new DartSidePingParams();
      _proxyImpl.sendMessage(params, kDartSide_ping_name);
    }
  
    void echo(int numIterations, EchoArgs arg) {
      assert(_proxyImpl.isBound);
      var params = new DartSideEchoParams();
      params.numIterations = numIterations;
      params.arg = arg;
      _proxyImpl.sendMessage(params, kDartSide_echo_name);
    }
  
}


class DartSideProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  DartSide ptr;
  final String name = DartSideName;

  DartSideProxy(DartSideProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _DartSideProxyCalls(proxyImpl);

  DartSideProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new DartSideProxyImpl.fromEndpoint(endpoint) {
    ptr = new _DartSideProxyCalls(impl);
  }

  DartSideProxy.fromHandle(core.MojoHandle handle) :
      impl = new DartSideProxyImpl.fromHandle(handle) {
    ptr = new _DartSideProxyCalls(impl);
  }

  DartSideProxy.unbound() :
      impl = new DartSideProxyImpl.unbound() {
    ptr = new _DartSideProxyCalls(impl);
  }

  static DartSideProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DartSideProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "DartSideProxy($impl)";
  }
}


class DartSideStub extends bindings.Stub {
  DartSide _impl = null;

  DartSideStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  DartSideStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  DartSideStub.unbound() : super.unbound();

  static DartSideStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new DartSideStub.fromEndpoint(endpoint);

  static const String name = DartSideName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kDartSide_setClient_name:
        var params = DartSideSetClientParams.deserialize(
            message.payload);
        _impl.setClient(params.cppSide);
        break;
      case kDartSide_ping_name:
        var params = DartSidePingParams.deserialize(
            message.payload);
        _impl.ping();
        break;
      case kDartSide_echo_name:
        var params = DartSideEchoParams.deserialize(
            message.payload);
        _impl.echo(params.numIterations, params.arg);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  DartSide get impl => _impl;
      set impl(DartSide d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "DartSideStub($superString)";
  }
}


