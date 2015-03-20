// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library console.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class ConsoleReadLineParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  ConsoleReadLineParams() : super(kStructSize);

  static ConsoleReadLineParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConsoleReadLineParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConsoleReadLineParams result = new ConsoleReadLineParams();

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
    return "ConsoleReadLineParams("")";
  }
}

class ConsoleReadLineResponseParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool success = false;
  String line = null;

  ConsoleReadLineResponseParams() : super(kStructSize);

  static ConsoleReadLineResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConsoleReadLineResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConsoleReadLineResponseParams result = new ConsoleReadLineResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    {
      
      result.line = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(success, 8, 0);
    
    encoder0.encodeString(line, 16, false);
  }

  String toString() {
    return "ConsoleReadLineResponseParams("
           "success: $success" ", "
           "line: $line" ")";
  }
}

class ConsolePrintLinesParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<String> lines = null;

  ConsolePrintLinesParams() : super(kStructSize);

  static ConsolePrintLinesParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConsolePrintLinesParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConsolePrintLinesParams result = new ConsolePrintLinesParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.lines = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.lines[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (lines == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(lines.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < lines.length; ++i0) {
        
        encoder1.encodeString(lines[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "ConsolePrintLinesParams("
           "lines: $lines" ")";
  }
}

class ConsolePrintLinesResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool success = false;

  ConsolePrintLinesResponseParams() : super(kStructSize);

  static ConsolePrintLinesResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConsolePrintLinesResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConsolePrintLinesResponseParams result = new ConsolePrintLinesResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(success, 8, 0);
  }

  String toString() {
    return "ConsolePrintLinesResponseParams("
           "success: $success" ")";
  }
}
const int kConsole_readLine_name = 0;
const int kConsole_printLines_name = 1;

const String ConsoleName =
      'mojo::Console';

abstract class Console {
  Future<ConsoleReadLineResponseParams> readLine([Function responseFactory = null]);
  Future<ConsolePrintLinesResponseParams> printLines(List<String> lines,[Function responseFactory = null]);

}


class ConsoleProxyImpl extends bindings.Proxy {
  ConsoleProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ConsoleProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ConsoleProxyImpl.unbound() : super.unbound();

  static ConsoleProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConsoleProxyImpl.fromEndpoint(endpoint);

  String get name => ConsoleName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kConsole_readLine_name:
        var r = ConsoleReadLineResponseParams.deserialize(
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
      case kConsole_printLines_name:
        var r = ConsolePrintLinesResponseParams.deserialize(
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
    return "ConsoleProxyImpl($superString)";
  }
}


class _ConsoleProxyCalls implements Console {
  ConsoleProxyImpl _proxyImpl;

  _ConsoleProxyCalls(this._proxyImpl);
    Future<ConsoleReadLineResponseParams> readLine([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ConsoleReadLineParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kConsole_readLine_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<ConsolePrintLinesResponseParams> printLines(List<String> lines,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ConsolePrintLinesParams();
      params.lines = lines;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kConsole_printLines_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class ConsoleProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Console ptr;
  final String name = ConsoleName;

  ConsoleProxy(ConsoleProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ConsoleProxyCalls(proxyImpl);

  ConsoleProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ConsoleProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ConsoleProxyCalls(impl);
  }

  ConsoleProxy.fromHandle(core.MojoHandle handle) :
      impl = new ConsoleProxyImpl.fromHandle(handle) {
    ptr = new _ConsoleProxyCalls(impl);
  }

  ConsoleProxy.unbound() :
      impl = new ConsoleProxyImpl.unbound() {
    ptr = new _ConsoleProxyCalls(impl);
  }

  static ConsoleProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConsoleProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "ConsoleProxy($impl)";
  }
}


class ConsoleStub extends bindings.Stub {
  Console _impl = null;

  ConsoleStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ConsoleStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ConsoleStub.unbound() : super.unbound();

  static ConsoleStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConsoleStub.fromEndpoint(endpoint);

  static const String name = ConsoleName;


  ConsoleReadLineResponseParams _ConsoleReadLineResponseParamsFactory(bool success, String line) {
    var result = new ConsoleReadLineResponseParams();
    result.success = success;
    result.line = line;
    return result;
  }
  ConsolePrintLinesResponseParams _ConsolePrintLinesResponseParamsFactory(bool success) {
    var result = new ConsolePrintLinesResponseParams();
    result.success = success;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kConsole_readLine_name:
        var params = ConsoleReadLineParams.deserialize(
            message.payload);
        return _impl.readLine(_ConsoleReadLineResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kConsole_readLine_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kConsole_printLines_name:
        var params = ConsolePrintLinesParams.deserialize(
            message.payload);
        return _impl.printLines(params.lines,_ConsolePrintLinesResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kConsole_printLines_name,
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

  Console get impl => _impl;
      set impl(Console d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ConsoleStub($superString)";
  }
}


