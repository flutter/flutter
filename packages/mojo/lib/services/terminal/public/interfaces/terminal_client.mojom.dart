// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library terminal_client.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/files/public/interfaces/file.mojom.dart' as file_mojom;


class TerminalClientConnectToTerminalParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object terminal = null;

  TerminalClientConnectToTerminalParams() : super(kVersions.last.size);

  static TerminalClientConnectToTerminalParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TerminalClientConnectToTerminalParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TerminalClientConnectToTerminalParams result = new TerminalClientConnectToTerminalParams();

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
      
      result.terminal = decoder0.decodeServiceInterface(8, false, file_mojom.FileProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterface(terminal, 8, false);
  }

  String toString() {
    return "TerminalClientConnectToTerminalParams("
           "terminal: $terminal" ")";
  }
}
const int kTerminalClient_connectToTerminal_name = 0;

const String TerminalClientName =
      'mojo::terminal::TerminalClient';

abstract class TerminalClient {
  void connectToTerminal(Object terminal);

}


class TerminalClientProxyImpl extends bindings.Proxy {
  TerminalClientProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  TerminalClientProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  TerminalClientProxyImpl.unbound() : super.unbound();

  static TerminalClientProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TerminalClientProxyImpl.fromEndpoint(endpoint);

  String get name => TerminalClientName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "TerminalClientProxyImpl($superString)";
  }
}


class _TerminalClientProxyCalls implements TerminalClient {
  TerminalClientProxyImpl _proxyImpl;

  _TerminalClientProxyCalls(this._proxyImpl);
    void connectToTerminal(Object terminal) {
      assert(_proxyImpl.isBound);
      var params = new TerminalClientConnectToTerminalParams();
      params.terminal = terminal;
      _proxyImpl.sendMessage(params, kTerminalClient_connectToTerminal_name);
    }
  
}


class TerminalClientProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  TerminalClient ptr;
  final String name = TerminalClientName;

  TerminalClientProxy(TerminalClientProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _TerminalClientProxyCalls(proxyImpl);

  TerminalClientProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new TerminalClientProxyImpl.fromEndpoint(endpoint) {
    ptr = new _TerminalClientProxyCalls(impl);
  }

  TerminalClientProxy.fromHandle(core.MojoHandle handle) :
      impl = new TerminalClientProxyImpl.fromHandle(handle) {
    ptr = new _TerminalClientProxyCalls(impl);
  }

  TerminalClientProxy.unbound() :
      impl = new TerminalClientProxyImpl.unbound() {
    ptr = new _TerminalClientProxyCalls(impl);
  }

  static TerminalClientProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TerminalClientProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "TerminalClientProxy($impl)";
  }
}


class TerminalClientStub extends bindings.Stub {
  TerminalClient _impl = null;

  TerminalClientStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  TerminalClientStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  TerminalClientStub.unbound() : super.unbound();

  static TerminalClientStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new TerminalClientStub.fromEndpoint(endpoint);

  static const String name = TerminalClientName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kTerminalClient_connectToTerminal_name:
        var params = TerminalClientConnectToTerminalParams.deserialize(
            message.payload);
        _impl.connectToTerminal(params.terminal);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  TerminalClient get impl => _impl;
      set impl(TerminalClient d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "TerminalClientStub($superString)";
  }
}


