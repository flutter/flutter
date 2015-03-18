// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library math_calculator.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class CalculatorClearParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CalculatorClearParams() : super(kStructSize);

  static CalculatorClearParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorClearParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorClearParams result = new CalculatorClearParams();

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
    return "CalculatorClearParams("")";
  }
}

class CalculatorClearResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double value = 0.0;

  CalculatorClearResponseParams() : super(kStructSize);

  static CalculatorClearResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorClearResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorClearResponseParams result = new CalculatorClearResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.value = decoder0.decodeDouble(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(value, 8);
  }

  String toString() {
    return "CalculatorClearResponseParams("
           "value: $value" ")";
  }
}

class CalculatorAddParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double value = 0.0;

  CalculatorAddParams() : super(kStructSize);

  static CalculatorAddParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorAddParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorAddParams result = new CalculatorAddParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.value = decoder0.decodeDouble(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(value, 8);
  }

  String toString() {
    return "CalculatorAddParams("
           "value: $value" ")";
  }
}

class CalculatorAddResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double value = 0.0;

  CalculatorAddResponseParams() : super(kStructSize);

  static CalculatorAddResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorAddResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorAddResponseParams result = new CalculatorAddResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.value = decoder0.decodeDouble(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(value, 8);
  }

  String toString() {
    return "CalculatorAddResponseParams("
           "value: $value" ")";
  }
}

class CalculatorMultiplyParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double value = 0.0;

  CalculatorMultiplyParams() : super(kStructSize);

  static CalculatorMultiplyParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorMultiplyParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorMultiplyParams result = new CalculatorMultiplyParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.value = decoder0.decodeDouble(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(value, 8);
  }

  String toString() {
    return "CalculatorMultiplyParams("
           "value: $value" ")";
  }
}

class CalculatorMultiplyResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double value = 0.0;

  CalculatorMultiplyResponseParams() : super(kStructSize);

  static CalculatorMultiplyResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CalculatorMultiplyResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CalculatorMultiplyResponseParams result = new CalculatorMultiplyResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.value = decoder0.decodeDouble(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(value, 8);
  }

  String toString() {
    return "CalculatorMultiplyResponseParams("
           "value: $value" ")";
  }
}
const int kCalculator_clear_name = 0;
const int kCalculator_add_name = 1;
const int kCalculator_multiply_name = 2;

const String CalculatorName =
      'math::Calculator';

abstract class Calculator {
  Future<CalculatorClearResponseParams> clear([Function responseFactory = null]);
  Future<CalculatorAddResponseParams> add(double value,[Function responseFactory = null]);
  Future<CalculatorMultiplyResponseParams> multiply(double value,[Function responseFactory = null]);

}


class CalculatorProxyImpl extends bindings.Proxy {
  CalculatorProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CalculatorProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CalculatorProxyImpl.unbound() : super.unbound();

  static CalculatorProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CalculatorProxyImpl.fromEndpoint(endpoint);

  String get name => CalculatorName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kCalculator_clear_name:
        var r = CalculatorClearResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kCalculator_add_name:
        var r = CalculatorAddResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kCalculator_multiply_name:
        var r = CalculatorMultiplyResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CalculatorProxyImpl($superString)";
  }
}


class _CalculatorProxyCalls implements Calculator {
  CalculatorProxyImpl _proxyImpl;

  _CalculatorProxyCalls(this._proxyImpl);
    Future<CalculatorClearResponseParams> clear([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CalculatorClearParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCalculator_clear_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<CalculatorAddResponseParams> add(double value,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CalculatorAddParams();
      params.value = value;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCalculator_add_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<CalculatorMultiplyResponseParams> multiply(double value,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CalculatorMultiplyParams();
      params.value = value;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCalculator_multiply_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class CalculatorProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Calculator ptr;
  final String name = CalculatorName;

  CalculatorProxy(CalculatorProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CalculatorProxyCalls(proxyImpl);

  CalculatorProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CalculatorProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CalculatorProxyCalls(impl);
  }

  CalculatorProxy.fromHandle(core.MojoHandle handle) :
      impl = new CalculatorProxyImpl.fromHandle(handle) {
    ptr = new _CalculatorProxyCalls(impl);
  }

  CalculatorProxy.unbound() :
      impl = new CalculatorProxyImpl.unbound() {
    ptr = new _CalculatorProxyCalls(impl);
  }

  static CalculatorProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CalculatorProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "CalculatorProxy($impl)";
  }
}


class CalculatorStub extends bindings.Stub {
  Calculator _impl = null;

  CalculatorStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CalculatorStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CalculatorStub.unbound() : super.unbound();

  static CalculatorStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CalculatorStub.fromEndpoint(endpoint);

  static const String name = CalculatorName;


  CalculatorClearResponseParams _CalculatorClearResponseParamsFactory(double value) {
    var result = new CalculatorClearResponseParams();
    result.value = value;
    return result;
  }
  CalculatorAddResponseParams _CalculatorAddResponseParamsFactory(double value) {
    var result = new CalculatorAddResponseParams();
    result.value = value;
    return result;
  }
  CalculatorMultiplyResponseParams _CalculatorMultiplyResponseParamsFactory(double value) {
    var result = new CalculatorMultiplyResponseParams();
    result.value = value;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCalculator_clear_name:
        var params = CalculatorClearParams.deserialize(
            message.payload);
        return _impl.clear(_CalculatorClearResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCalculator_clear_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kCalculator_add_name:
        var params = CalculatorAddParams.deserialize(
            message.payload);
        return _impl.add(params.value,_CalculatorAddResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCalculator_add_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kCalculator_multiply_name:
        var params = CalculatorMultiplyParams.deserialize(
            message.payload);
        return _impl.multiply(params.value,_CalculatorMultiplyResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCalculator_multiply_name,
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

  Calculator get impl => _impl;
      set impl(Calculator d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CalculatorStub($superString)";
  }
}


