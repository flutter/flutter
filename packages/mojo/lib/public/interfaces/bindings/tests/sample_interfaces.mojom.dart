// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sample_interfaces.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
final kLong = 4405;

final int Enum_VALUE = 0;


class ProviderEchoStringParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  String a = null;

  ProviderEchoStringParams() : super(kVersions.last.size);

  static ProviderEchoStringParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoStringParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoStringParams result = new ProviderEchoStringParams();

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
      
      result.a = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(a, 8, false);
  }

  String toString() {
    return "ProviderEchoStringParams("
           "a: $a" ")";
  }
}

class ProviderEchoStringResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  String a = null;

  ProviderEchoStringResponseParams() : super(kVersions.last.size);

  static ProviderEchoStringResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoStringResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoStringResponseParams result = new ProviderEchoStringResponseParams();

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
      
      result.a = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(a, 8, false);
  }

  String toString() {
    return "ProviderEchoStringResponseParams("
           "a: $a" ")";
  }
}

class ProviderEchoStringsParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String a = null;
  String b = null;

  ProviderEchoStringsParams() : super(kVersions.last.size);

  static ProviderEchoStringsParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoStringsParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoStringsParams result = new ProviderEchoStringsParams();

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
      
      result.a = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.b = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(a, 8, false);
    
    encoder0.encodeString(b, 16, false);
  }

  String toString() {
    return "ProviderEchoStringsParams("
           "a: $a" ", "
           "b: $b" ")";
  }
}

class ProviderEchoStringsResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String a = null;
  String b = null;

  ProviderEchoStringsResponseParams() : super(kVersions.last.size);

  static ProviderEchoStringsResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoStringsResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoStringsResponseParams result = new ProviderEchoStringsResponseParams();

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
      
      result.a = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.b = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(a, 8, false);
    
    encoder0.encodeString(b, 16, false);
  }

  String toString() {
    return "ProviderEchoStringsResponseParams("
           "a: $a" ", "
           "b: $b" ")";
  }
}

class ProviderEchoMessagePipeHandleParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  core.MojoMessagePipeEndpoint a = null;

  ProviderEchoMessagePipeHandleParams() : super(kVersions.last.size);

  static ProviderEchoMessagePipeHandleParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoMessagePipeHandleParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoMessagePipeHandleParams result = new ProviderEchoMessagePipeHandleParams();

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
      
      result.a = decoder0.decodeMessagePipeHandle(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeMessagePipeHandle(a, 8, false);
  }

  String toString() {
    return "ProviderEchoMessagePipeHandleParams("
           "a: $a" ")";
  }
}

class ProviderEchoMessagePipeHandleResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  core.MojoMessagePipeEndpoint a = null;

  ProviderEchoMessagePipeHandleResponseParams() : super(kVersions.last.size);

  static ProviderEchoMessagePipeHandleResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoMessagePipeHandleResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoMessagePipeHandleResponseParams result = new ProviderEchoMessagePipeHandleResponseParams();

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
      
      result.a = decoder0.decodeMessagePipeHandle(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeMessagePipeHandle(a, 8, false);
  }

  String toString() {
    return "ProviderEchoMessagePipeHandleResponseParams("
           "a: $a" ")";
  }
}

class ProviderEchoEnumParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int a = 0;

  ProviderEchoEnumParams() : super(kVersions.last.size);

  static ProviderEchoEnumParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoEnumParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoEnumParams result = new ProviderEchoEnumParams();

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
      
      result.a = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(a, 8);
  }

  String toString() {
    return "ProviderEchoEnumParams("
           "a: $a" ")";
  }
}

class ProviderEchoEnumResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int a = 0;

  ProviderEchoEnumResponseParams() : super(kVersions.last.size);

  static ProviderEchoEnumResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoEnumResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoEnumResponseParams result = new ProviderEchoEnumResponseParams();

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
      
      result.a = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(a, 8);
  }

  String toString() {
    return "ProviderEchoEnumResponseParams("
           "a: $a" ")";
  }
}

class ProviderEchoIntParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int a = 0;

  ProviderEchoIntParams() : super(kVersions.last.size);

  static ProviderEchoIntParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoIntParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoIntParams result = new ProviderEchoIntParams();

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
      
      result.a = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(a, 8);
  }

  String toString() {
    return "ProviderEchoIntParams("
           "a: $a" ")";
  }
}

class ProviderEchoIntResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int a = 0;

  ProviderEchoIntResponseParams() : super(kVersions.last.size);

  static ProviderEchoIntResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ProviderEchoIntResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ProviderEchoIntResponseParams result = new ProviderEchoIntResponseParams();

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
      
      result.a = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(a, 8);
  }

  String toString() {
    return "ProviderEchoIntResponseParams("
           "a: $a" ")";
  }
}
const int kProvider_echoString_name = 0;
const int kProvider_echoStrings_name = 1;
const int kProvider_echoMessagePipeHandle_name = 2;
const int kProvider_echoEnum_name = 3;
const int kProvider_echoInt_name = 4;

const String ProviderName =
      'sample::Provider';

abstract class Provider {
  Future<ProviderEchoStringResponseParams> echoString(String a,[Function responseFactory = null]);
  Future<ProviderEchoStringsResponseParams> echoStrings(String a,String b,[Function responseFactory = null]);
  Future<ProviderEchoMessagePipeHandleResponseParams> echoMessagePipeHandle(core.MojoMessagePipeEndpoint a,[Function responseFactory = null]);
  Future<ProviderEchoEnumResponseParams> echoEnum(int a,[Function responseFactory = null]);
  Future<ProviderEchoIntResponseParams> echoInt(int a,[Function responseFactory = null]);

}


class ProviderProxyImpl extends bindings.Proxy {
  ProviderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ProviderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ProviderProxyImpl.unbound() : super.unbound();

  static ProviderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ProviderProxyImpl.fromEndpoint(endpoint);

  String get name => ProviderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kProvider_echoString_name:
        var r = ProviderEchoStringResponseParams.deserialize(
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
      case kProvider_echoStrings_name:
        var r = ProviderEchoStringsResponseParams.deserialize(
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
      case kProvider_echoMessagePipeHandle_name:
        var r = ProviderEchoMessagePipeHandleResponseParams.deserialize(
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
      case kProvider_echoEnum_name:
        var r = ProviderEchoEnumResponseParams.deserialize(
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
      case kProvider_echoInt_name:
        var r = ProviderEchoIntResponseParams.deserialize(
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
    return "ProviderProxyImpl($superString)";
  }
}


class _ProviderProxyCalls implements Provider {
  ProviderProxyImpl _proxyImpl;

  _ProviderProxyCalls(this._proxyImpl);
    Future<ProviderEchoStringResponseParams> echoString(String a,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ProviderEchoStringParams();
      params.a = a;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kProvider_echoString_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<ProviderEchoStringsResponseParams> echoStrings(String a,String b,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ProviderEchoStringsParams();
      params.a = a;
      params.b = b;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kProvider_echoStrings_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<ProviderEchoMessagePipeHandleResponseParams> echoMessagePipeHandle(core.MojoMessagePipeEndpoint a,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ProviderEchoMessagePipeHandleParams();
      params.a = a;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kProvider_echoMessagePipeHandle_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<ProviderEchoEnumResponseParams> echoEnum(int a,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ProviderEchoEnumParams();
      params.a = a;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kProvider_echoEnum_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<ProviderEchoIntResponseParams> echoInt(int a,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ProviderEchoIntParams();
      params.a = a;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kProvider_echoInt_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class ProviderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Provider ptr;
  final String name = ProviderName;

  ProviderProxy(ProviderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ProviderProxyCalls(proxyImpl);

  ProviderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ProviderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ProviderProxyCalls(impl);
  }

  ProviderProxy.fromHandle(core.MojoHandle handle) :
      impl = new ProviderProxyImpl.fromHandle(handle) {
    ptr = new _ProviderProxyCalls(impl);
  }

  ProviderProxy.unbound() :
      impl = new ProviderProxyImpl.unbound() {
    ptr = new _ProviderProxyCalls(impl);
  }

  static ProviderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ProviderProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "ProviderProxy($impl)";
  }
}


class ProviderStub extends bindings.Stub {
  Provider _impl = null;

  ProviderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ProviderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ProviderStub.unbound() : super.unbound();

  static ProviderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ProviderStub.fromEndpoint(endpoint);

  static const String name = ProviderName;


  ProviderEchoStringResponseParams _ProviderEchoStringResponseParamsFactory(String a) {
    var result = new ProviderEchoStringResponseParams();
    result.a = a;
    return result;
  }
  ProviderEchoStringsResponseParams _ProviderEchoStringsResponseParamsFactory(String a, String b) {
    var result = new ProviderEchoStringsResponseParams();
    result.a = a;
    result.b = b;
    return result;
  }
  ProviderEchoMessagePipeHandleResponseParams _ProviderEchoMessagePipeHandleResponseParamsFactory(core.MojoMessagePipeEndpoint a) {
    var result = new ProviderEchoMessagePipeHandleResponseParams();
    result.a = a;
    return result;
  }
  ProviderEchoEnumResponseParams _ProviderEchoEnumResponseParamsFactory(int a) {
    var result = new ProviderEchoEnumResponseParams();
    result.a = a;
    return result;
  }
  ProviderEchoIntResponseParams _ProviderEchoIntResponseParamsFactory(int a) {
    var result = new ProviderEchoIntResponseParams();
    result.a = a;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kProvider_echoString_name:
        var params = ProviderEchoStringParams.deserialize(
            message.payload);
        return _impl.echoString(params.a,_ProviderEchoStringResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kProvider_echoString_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kProvider_echoStrings_name:
        var params = ProviderEchoStringsParams.deserialize(
            message.payload);
        return _impl.echoStrings(params.a,params.b,_ProviderEchoStringsResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kProvider_echoStrings_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kProvider_echoMessagePipeHandle_name:
        var params = ProviderEchoMessagePipeHandleParams.deserialize(
            message.payload);
        return _impl.echoMessagePipeHandle(params.a,_ProviderEchoMessagePipeHandleResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kProvider_echoMessagePipeHandle_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kProvider_echoEnum_name:
        var params = ProviderEchoEnumParams.deserialize(
            message.payload);
        return _impl.echoEnum(params.a,_ProviderEchoEnumResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kProvider_echoEnum_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kProvider_echoInt_name:
        var params = ProviderEchoIntParams.deserialize(
            message.payload);
        return _impl.echoInt(params.a,_ProviderEchoIntResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kProvider_echoInt_name,
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

  Provider get impl => _impl;
      set impl(Provider d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ProviderStub($superString)";
  }
}


