// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library keyboard.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class KeyboardShowParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  KeyboardShowParams() : super(kVersions.last.size);

  static KeyboardShowParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardShowParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardShowParams result = new KeyboardShowParams();

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
    return "KeyboardShowParams("")";
  }
}

class KeyboardHideParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  KeyboardHideParams() : super(kVersions.last.size);

  static KeyboardHideParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static KeyboardHideParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeyboardHideParams result = new KeyboardHideParams();

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
    return "KeyboardHideParams("")";
  }
}
const int kKeyboard_show_name = 0;
const int kKeyboard_hide_name = 1;

const String KeyboardName =
      'mojo::Keyboard';

abstract class Keyboard {
  void show();
  void hide();

}


class KeyboardProxyImpl extends bindings.Proxy {
  KeyboardProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  KeyboardProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  KeyboardProxyImpl.unbound() : super.unbound();

  static KeyboardProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardProxyImpl.fromEndpoint(endpoint);

  String get name => KeyboardName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardProxyImpl($superString)";
  }
}


class _KeyboardProxyCalls implements Keyboard {
  KeyboardProxyImpl _proxyImpl;

  _KeyboardProxyCalls(this._proxyImpl);
    void show() {
      assert(_proxyImpl.isBound);
      var params = new KeyboardShowParams();
      _proxyImpl.sendMessage(params, kKeyboard_show_name);
    }
  
    void hide() {
      assert(_proxyImpl.isBound);
      var params = new KeyboardHideParams();
      _proxyImpl.sendMessage(params, kKeyboard_hide_name);
    }
  
}


class KeyboardProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Keyboard ptr;
  final String name = KeyboardName;

  KeyboardProxy(KeyboardProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _KeyboardProxyCalls(proxyImpl);

  KeyboardProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new KeyboardProxyImpl.fromEndpoint(endpoint) {
    ptr = new _KeyboardProxyCalls(impl);
  }

  KeyboardProxy.fromHandle(core.MojoHandle handle) :
      impl = new KeyboardProxyImpl.fromHandle(handle) {
    ptr = new _KeyboardProxyCalls(impl);
  }

  KeyboardProxy.unbound() :
      impl = new KeyboardProxyImpl.unbound() {
    ptr = new _KeyboardProxyCalls(impl);
  }

  static KeyboardProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "KeyboardProxy($impl)";
  }
}


class KeyboardStub extends bindings.Stub {
  Keyboard _impl = null;

  KeyboardStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  KeyboardStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  KeyboardStub.unbound() : super.unbound();

  static KeyboardStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new KeyboardStub.fromEndpoint(endpoint);

  static const String name = KeyboardName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kKeyboard_show_name:
        var params = KeyboardShowParams.deserialize(
            message.payload);
        _impl.show();
        break;
      case kKeyboard_hide_name:
        var params = KeyboardHideParams.deserialize(
            message.payload);
        _impl.hide();
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Keyboard get impl => _impl;
      set impl(Keyboard d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "KeyboardStub($superString)";
  }
}


