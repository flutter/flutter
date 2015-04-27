// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library regression_tests.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;

final int EnumWithReference_k_STEREO_AND_KEYBOARD_MIC = 30;
final int EnumWithReference_k_MAX = EnumWithReference_k_STEREO_AND_KEYBOARD_MIC;

final int EnumWithLowercase_PlanarF16 = 0;
final int EnumWithLowercase_PlanarF32 = EnumWithLowercase_PlanarF16 + 1;

final int EnumWithNumbers_k_2_1 = 4;

final int EnumWithK_K = 0;


class Edge extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Vertex v = null;

  Edge() : super(kVersions.last.size);

  static Edge deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Edge decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Edge result = new Edge();

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
      result.v = Vertex.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(v, 8, true);
  }

  String toString() {
    return "Edge("
           "v: $v" ")";
  }
}

class Vertex extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EmptyStruct e = null;

  Vertex() : super(kVersions.last.size);

  static Vertex deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Vertex decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Vertex result = new Vertex();

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
      result.e = EmptyStruct.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(e, 8, true);
  }

  String toString() {
    return "Vertex("
           "e: $e" ")";
  }
}

class EmptyStruct extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  EmptyStruct() : super(kVersions.last.size);

  static EmptyStruct deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EmptyStruct decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EmptyStruct result = new EmptyStruct();

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
    return "EmptyStruct("")";
  }
}

class A extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  B b = null;

  A() : super(kVersions.last.size);

  static A deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static A decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    A result = new A();

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
      result.b = B.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(b, 8, true);
  }

  String toString() {
    return "A("
           "b: $b" ")";
  }
}

class B extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  A a = null;

  B() : super(kVersions.last.size);

  static B deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static B decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    B result = new B();

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
      result.a = A.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(a, 8, true);
  }

  String toString() {
    return "B("
           "a: $a" ")";
  }
}

class CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams() : super(kVersions.last.size);

  static CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams result = new CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams();

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
    return "CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams("")";
  }
}

class CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams() : super(kVersions.last.size);

  static CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams result = new CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams();

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
    return "CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams("")";
  }
}

class CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool b = false;

  CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams() : super(kVersions.last.size);

  static CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams result = new CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams();

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
      
      result.b = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(b, 8, 0);
  }

  String toString() {
    return "CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams("
           "b: $b" ")";
  }
}

class CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams() : super(kVersions.last.size);

  static CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams result = new CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams();

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
    return "CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams("")";
  }
}

class CheckNameCollisionWithNameCollisionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool message = false;
  bool response = false;

  CheckNameCollisionWithNameCollisionParams() : super(kVersions.last.size);

  static CheckNameCollisionWithNameCollisionParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckNameCollisionWithNameCollisionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckNameCollisionWithNameCollisionParams result = new CheckNameCollisionWithNameCollisionParams();

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
      
      result.message = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      result.response = decoder0.decodeBool(8, 1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(message, 8, 0);
    
    encoder0.encodeBool(response, 8, 1);
  }

  String toString() {
    return "CheckNameCollisionWithNameCollisionParams("
           "message: $message" ", "
           "response: $response" ")";
  }
}

class CheckNameCollisionWithNameCollisionResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool message = false;
  bool response = false;

  CheckNameCollisionWithNameCollisionResponseParams() : super(kVersions.last.size);

  static CheckNameCollisionWithNameCollisionResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckNameCollisionWithNameCollisionResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckNameCollisionWithNameCollisionResponseParams result = new CheckNameCollisionWithNameCollisionResponseParams();

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
      
      result.message = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      result.response = decoder0.decodeBool(8, 1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(message, 8, 0);
    
    encoder0.encodeBool(response, 8, 1);
  }

  String toString() {
    return "CheckNameCollisionWithNameCollisionResponseParams("
           "message: $message" ", "
           "response: $response" ")";
  }
}
const int kCheckMethodWithEmptyResponse_withouParameterAndEmptyResponse_name = 0;
const int kCheckMethodWithEmptyResponse_withParameterAndEmptyResponse_name = 1;

const String CheckMethodWithEmptyResponseName =
      'regression_tests::CheckMethodWithEmptyResponse';

abstract class CheckMethodWithEmptyResponse {
  Future<CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams> withouParameterAndEmptyResponse([Function responseFactory = null]);
  Future<CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams> withParameterAndEmptyResponse(bool b,[Function responseFactory = null]);

}


class CheckMethodWithEmptyResponseProxyImpl extends bindings.Proxy {
  CheckMethodWithEmptyResponseProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CheckMethodWithEmptyResponseProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CheckMethodWithEmptyResponseProxyImpl.unbound() : super.unbound();

  static CheckMethodWithEmptyResponseProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckMethodWithEmptyResponseProxyImpl.fromEndpoint(endpoint);

  String get name => CheckMethodWithEmptyResponseName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kCheckMethodWithEmptyResponse_withouParameterAndEmptyResponse_name:
        var r = CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams.deserialize(
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
      case kCheckMethodWithEmptyResponse_withParameterAndEmptyResponse_name:
        var r = CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams.deserialize(
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
    return "CheckMethodWithEmptyResponseProxyImpl($superString)";
  }
}


class _CheckMethodWithEmptyResponseProxyCalls implements CheckMethodWithEmptyResponse {
  CheckMethodWithEmptyResponseProxyImpl _proxyImpl;

  _CheckMethodWithEmptyResponseProxyCalls(this._proxyImpl);
    Future<CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams> withouParameterAndEmptyResponse([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCheckMethodWithEmptyResponse_withouParameterAndEmptyResponse_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams> withParameterAndEmptyResponse(bool b,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams();
      params.b = b;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCheckMethodWithEmptyResponse_withParameterAndEmptyResponse_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class CheckMethodWithEmptyResponseProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CheckMethodWithEmptyResponse ptr;
  final String name = CheckMethodWithEmptyResponseName;

  CheckMethodWithEmptyResponseProxy(CheckMethodWithEmptyResponseProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CheckMethodWithEmptyResponseProxyCalls(proxyImpl);

  CheckMethodWithEmptyResponseProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CheckMethodWithEmptyResponseProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CheckMethodWithEmptyResponseProxyCalls(impl);
  }

  CheckMethodWithEmptyResponseProxy.fromHandle(core.MojoHandle handle) :
      impl = new CheckMethodWithEmptyResponseProxyImpl.fromHandle(handle) {
    ptr = new _CheckMethodWithEmptyResponseProxyCalls(impl);
  }

  CheckMethodWithEmptyResponseProxy.unbound() :
      impl = new CheckMethodWithEmptyResponseProxyImpl.unbound() {
    ptr = new _CheckMethodWithEmptyResponseProxyCalls(impl);
  }

  static CheckMethodWithEmptyResponseProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckMethodWithEmptyResponseProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "CheckMethodWithEmptyResponseProxy($impl)";
  }
}


class CheckMethodWithEmptyResponseStub extends bindings.Stub {
  CheckMethodWithEmptyResponse _impl = null;

  CheckMethodWithEmptyResponseStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CheckMethodWithEmptyResponseStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CheckMethodWithEmptyResponseStub.unbound() : super.unbound();

  static CheckMethodWithEmptyResponseStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckMethodWithEmptyResponseStub.fromEndpoint(endpoint);

  static const String name = CheckMethodWithEmptyResponseName;


  CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams _CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParamsFactory() {
    var result = new CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParams();
    return result;
  }
  CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams _CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParamsFactory() {
    var result = new CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParams();
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCheckMethodWithEmptyResponse_withouParameterAndEmptyResponse_name:
        var params = CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseParams.deserialize(
            message.payload);
        return _impl.withouParameterAndEmptyResponse(_CheckMethodWithEmptyResponseWithouParameterAndEmptyResponseResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCheckMethodWithEmptyResponse_withouParameterAndEmptyResponse_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kCheckMethodWithEmptyResponse_withParameterAndEmptyResponse_name:
        var params = CheckMethodWithEmptyResponseWithParameterAndEmptyResponseParams.deserialize(
            message.payload);
        return _impl.withParameterAndEmptyResponse(params.b,_CheckMethodWithEmptyResponseWithParameterAndEmptyResponseResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCheckMethodWithEmptyResponse_withParameterAndEmptyResponse_name,
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

  CheckMethodWithEmptyResponse get impl => _impl;
      set impl(CheckMethodWithEmptyResponse d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CheckMethodWithEmptyResponseStub($superString)";
  }
}

const int kCheckNameCollision_withNameCollision_name = 0;

const String CheckNameCollisionName =
      'regression_tests::CheckNameCollision';

abstract class CheckNameCollision {
  Future<CheckNameCollisionWithNameCollisionResponseParams> withNameCollision(bool message,bool response,[Function responseFactory = null]);

}


class CheckNameCollisionProxyImpl extends bindings.Proxy {
  CheckNameCollisionProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CheckNameCollisionProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CheckNameCollisionProxyImpl.unbound() : super.unbound();

  static CheckNameCollisionProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckNameCollisionProxyImpl.fromEndpoint(endpoint);

  String get name => CheckNameCollisionName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kCheckNameCollision_withNameCollision_name:
        var r = CheckNameCollisionWithNameCollisionResponseParams.deserialize(
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
    return "CheckNameCollisionProxyImpl($superString)";
  }
}


class _CheckNameCollisionProxyCalls implements CheckNameCollision {
  CheckNameCollisionProxyImpl _proxyImpl;

  _CheckNameCollisionProxyCalls(this._proxyImpl);
    Future<CheckNameCollisionWithNameCollisionResponseParams> withNameCollision(bool message,bool response,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new CheckNameCollisionWithNameCollisionParams();
      params.message = message;
      params.response = response;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kCheckNameCollision_withNameCollision_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class CheckNameCollisionProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CheckNameCollision ptr;
  final String name = CheckNameCollisionName;

  CheckNameCollisionProxy(CheckNameCollisionProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CheckNameCollisionProxyCalls(proxyImpl);

  CheckNameCollisionProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CheckNameCollisionProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CheckNameCollisionProxyCalls(impl);
  }

  CheckNameCollisionProxy.fromHandle(core.MojoHandle handle) :
      impl = new CheckNameCollisionProxyImpl.fromHandle(handle) {
    ptr = new _CheckNameCollisionProxyCalls(impl);
  }

  CheckNameCollisionProxy.unbound() :
      impl = new CheckNameCollisionProxyImpl.unbound() {
    ptr = new _CheckNameCollisionProxyCalls(impl);
  }

  static CheckNameCollisionProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckNameCollisionProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "CheckNameCollisionProxy($impl)";
  }
}


class CheckNameCollisionStub extends bindings.Stub {
  CheckNameCollision _impl = null;

  CheckNameCollisionStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CheckNameCollisionStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CheckNameCollisionStub.unbound() : super.unbound();

  static CheckNameCollisionStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CheckNameCollisionStub.fromEndpoint(endpoint);

  static const String name = CheckNameCollisionName;


  CheckNameCollisionWithNameCollisionResponseParams _CheckNameCollisionWithNameCollisionResponseParamsFactory(bool message, bool response) {
    var result = new CheckNameCollisionWithNameCollisionResponseParams();
    result.message = message;
    result.response = response;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCheckNameCollision_withNameCollision_name:
        var params = CheckNameCollisionWithNameCollisionParams.deserialize(
            message.payload);
        return _impl.withNameCollision(params.message,params.response,_CheckNameCollisionWithNameCollisionResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kCheckNameCollision_withNameCollision_name,
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

  CheckNameCollision get impl => _impl;
      set impl(CheckNameCollision d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CheckNameCollisionStub($superString)";
  }
}


