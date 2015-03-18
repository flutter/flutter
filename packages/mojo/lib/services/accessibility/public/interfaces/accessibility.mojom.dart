// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library accessibility.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;


class AxNode extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;
  int parentId = 0;
  int nextSiblingId = 0;
  geometry_mojom.Rect bounds = null;
  AxLink link = null;
  AxText text = null;

  AxNode() : super(kStructSize);

  static AxNode deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AxNode decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AxNode result = new AxNode();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeUint32(8);
    }
    {
      
      result.parentId = decoder0.decodeUint32(12);
    }
    {
      
      result.nextSiblingId = decoder0.decodeUint32(16);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.bounds = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.link = AxLink.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, true);
      result.text = AxText.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(id, 8);
    
    encoder0.encodeUint32(parentId, 12);
    
    encoder0.encodeUint32(nextSiblingId, 16);
    
    encoder0.encodeStruct(bounds, 24, false);
    
    encoder0.encodeStruct(link, 32, true);
    
    encoder0.encodeStruct(text, 40, true);
  }

  String toString() {
    return "AxNode("
           "id: $id" ", "
           "parentId: $parentId" ", "
           "nextSiblingId: $nextSiblingId" ", "
           "bounds: $bounds" ", "
           "link: $link" ", "
           "text: $text" ")";
  }
}

class AxLink extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String url = null;

  AxLink() : super(kStructSize);

  static AxLink deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AxLink decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AxLink result = new AxLink();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.url = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(url, 8, false);
  }

  String toString() {
    return "AxLink("
           "url: $url" ")";
  }
}

class AxText extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String content = null;

  AxText() : super(kStructSize);

  static AxText deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AxText decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AxText result = new AxText();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.content = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(content, 8, false);
  }

  String toString() {
    return "AxText("
           "content: $content" ")";
  }
}

class AxProviderGetTreeParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  AxProviderGetTreeParams() : super(kStructSize);

  static AxProviderGetTreeParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AxProviderGetTreeParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AxProviderGetTreeParams result = new AxProviderGetTreeParams();

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
    return "AxProviderGetTreeParams("")";
  }
}

class AxProviderGetTreeResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<AxNode> nodes = null;

  AxProviderGetTreeResponseParams() : super(kStructSize);

  static AxProviderGetTreeResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static AxProviderGetTreeResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    AxProviderGetTreeResponseParams result = new AxProviderGetTreeResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.nodes = new List<AxNode>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.nodes[i1] = AxNode.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (nodes == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(nodes.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < nodes.length; ++i0) {
        
        encoder1.encodeStruct(nodes[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "AxProviderGetTreeResponseParams("
           "nodes: $nodes" ")";
  }
}
const int kAxProvider_getTree_name = 0;

const String AxProviderName =
      'mojo::AxProvider';

abstract class AxProvider {
  Future<AxProviderGetTreeResponseParams> getTree([Function responseFactory = null]);

}


class AxProviderProxyImpl extends bindings.Proxy {
  AxProviderProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  AxProviderProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  AxProviderProxyImpl.unbound() : super.unbound();

  static AxProviderProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new AxProviderProxyImpl.fromEndpoint(endpoint);

  String get name => AxProviderName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kAxProvider_getTree_name:
        var r = AxProviderGetTreeResponseParams.deserialize(
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
    return "AxProviderProxyImpl($superString)";
  }
}


class _AxProviderProxyCalls implements AxProvider {
  AxProviderProxyImpl _proxyImpl;

  _AxProviderProxyCalls(this._proxyImpl);
    Future<AxProviderGetTreeResponseParams> getTree([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new AxProviderGetTreeParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kAxProvider_getTree_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class AxProviderProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  AxProvider ptr;
  final String name = AxProviderName;

  AxProviderProxy(AxProviderProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _AxProviderProxyCalls(proxyImpl);

  AxProviderProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new AxProviderProxyImpl.fromEndpoint(endpoint) {
    ptr = new _AxProviderProxyCalls(impl);
  }

  AxProviderProxy.fromHandle(core.MojoHandle handle) :
      impl = new AxProviderProxyImpl.fromHandle(handle) {
    ptr = new _AxProviderProxyCalls(impl);
  }

  AxProviderProxy.unbound() :
      impl = new AxProviderProxyImpl.unbound() {
    ptr = new _AxProviderProxyCalls(impl);
  }

  static AxProviderProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new AxProviderProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "AxProviderProxy($impl)";
  }
}


class AxProviderStub extends bindings.Stub {
  AxProvider _impl = null;

  AxProviderStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  AxProviderStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  AxProviderStub.unbound() : super.unbound();

  static AxProviderStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new AxProviderStub.fromEndpoint(endpoint);

  static const String name = AxProviderName;


  AxProviderGetTreeResponseParams _AxProviderGetTreeResponseParamsFactory(List<AxNode> nodes) {
    var result = new AxProviderGetTreeResponseParams();
    result.nodes = nodes;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kAxProvider_getTree_name:
        var params = AxProviderGetTreeParams.deserialize(
            message.payload);
        return _impl.getTree(_AxProviderGetTreeResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kAxProvider_getTree_name,
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

  AxProvider get impl => _impl;
      set impl(AxProvider d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "AxProviderStub($superString)";
  }
}


