// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library binding_callback_test_interfaces.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class BindingCallbackTestInterfaceEchoIntParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int param0 = 0;

  BindingCallbackTestInterfaceEchoIntParams() : super(kVersions.last.size);

  static BindingCallbackTestInterfaceEchoIntParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BindingCallbackTestInterfaceEchoIntParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BindingCallbackTestInterfaceEchoIntParams result = new BindingCallbackTestInterfaceEchoIntParams();

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
      
      result.param0 = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(param0, 8);
  }

  String toString() {
    return "BindingCallbackTestInterfaceEchoIntParams("
           "param0: $param0" ")";
  }
}

class BindingCallbackTestInterfaceEchoIntResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int param0 = 0;

  BindingCallbackTestInterfaceEchoIntResponseParams() : super(kVersions.last.size);

  static BindingCallbackTestInterfaceEchoIntResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BindingCallbackTestInterfaceEchoIntResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BindingCallbackTestInterfaceEchoIntResponseParams result = new BindingCallbackTestInterfaceEchoIntResponseParams();

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
      
      result.param0 = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(param0, 8);
  }

  String toString() {
    return "BindingCallbackTestInterfaceEchoIntResponseParams("
           "param0: $param0" ")";
  }
}
const int kBindingCallbackTestInterface_echoInt_name = 0;

const String BindingCallbackTestInterfaceName =
      '::BindingCallbackTestInterface';

abstract class BindingCallbackTestInterface {
  Future<BindingCallbackTestInterfaceEchoIntResponseParams> echoInt(int param0,[Function responseFactory = null]);

}


class BindingCallbackTestInterfaceProxyImpl extends bindings.Proxy {
  BindingCallbackTestInterfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  BindingCallbackTestInterfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  BindingCallbackTestInterfaceProxyImpl.unbound() : super.unbound();

  static BindingCallbackTestInterfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BindingCallbackTestInterfaceProxyImpl.fromEndpoint(endpoint);

  String get name => BindingCallbackTestInterfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kBindingCallbackTestInterface_echoInt_name:
        var r = BindingCallbackTestInterfaceEchoIntResponseParams.deserialize(
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
    return "BindingCallbackTestInterfaceProxyImpl($superString)";
  }
}


class _BindingCallbackTestInterfaceProxyCalls implements BindingCallbackTestInterface {
  BindingCallbackTestInterfaceProxyImpl _proxyImpl;

  _BindingCallbackTestInterfaceProxyCalls(this._proxyImpl);
    Future<BindingCallbackTestInterfaceEchoIntResponseParams> echoInt(int param0,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new BindingCallbackTestInterfaceEchoIntParams();
      params.param0 = param0;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kBindingCallbackTestInterface_echoInt_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class BindingCallbackTestInterfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  BindingCallbackTestInterface ptr;
  final String name = BindingCallbackTestInterfaceName;

  BindingCallbackTestInterfaceProxy(BindingCallbackTestInterfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _BindingCallbackTestInterfaceProxyCalls(proxyImpl);

  BindingCallbackTestInterfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new BindingCallbackTestInterfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _BindingCallbackTestInterfaceProxyCalls(impl);
  }

  BindingCallbackTestInterfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new BindingCallbackTestInterfaceProxyImpl.fromHandle(handle) {
    ptr = new _BindingCallbackTestInterfaceProxyCalls(impl);
  }

  BindingCallbackTestInterfaceProxy.unbound() :
      impl = new BindingCallbackTestInterfaceProxyImpl.unbound() {
    ptr = new _BindingCallbackTestInterfaceProxyCalls(impl);
  }

  static BindingCallbackTestInterfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BindingCallbackTestInterfaceProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "BindingCallbackTestInterfaceProxy($impl)";
  }
}


class BindingCallbackTestInterfaceStub extends bindings.Stub {
  BindingCallbackTestInterface _impl = null;

  BindingCallbackTestInterfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  BindingCallbackTestInterfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  BindingCallbackTestInterfaceStub.unbound() : super.unbound();

  static BindingCallbackTestInterfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BindingCallbackTestInterfaceStub.fromEndpoint(endpoint);

  static const String name = BindingCallbackTestInterfaceName;


  BindingCallbackTestInterfaceEchoIntResponseParams _BindingCallbackTestInterfaceEchoIntResponseParamsFactory(int param0) {
    var result = new BindingCallbackTestInterfaceEchoIntResponseParams();
    result.param0 = param0;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kBindingCallbackTestInterface_echoInt_name:
        var params = BindingCallbackTestInterfaceEchoIntParams.deserialize(
            message.payload);
        return _impl.echoInt(params.param0,_BindingCallbackTestInterfaceEchoIntResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kBindingCallbackTestInterface_echoInt_name,
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

  BindingCallbackTestInterface get impl => _impl;
      set impl(BindingCallbackTestInterface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "BindingCallbackTestInterfaceStub($superString)";
  }
}


