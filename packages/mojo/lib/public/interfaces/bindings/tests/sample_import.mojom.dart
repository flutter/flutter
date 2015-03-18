// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sample_import.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;

final int Shape_RECTANGLE = 1;
final int Shape_CIRCLE = Shape_RECTANGLE + 1;
final int Shape_TRIANGLE = Shape_CIRCLE + 1;
final int Shape_LAST = Shape_TRIANGLE;

final int AnotherShape_RECTANGLE = 10;
final int AnotherShape_CIRCLE = AnotherShape_RECTANGLE + 1;
final int AnotherShape_TRIANGLE = AnotherShape_CIRCLE + 1;

final int YetAnotherShape_RECTANGLE = 20;
final int YetAnotherShape_CIRCLE = YetAnotherShape_RECTANGLE + 1;
final int YetAnotherShape_TRIANGLE = YetAnotherShape_CIRCLE + 1;


class Point extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int x = 0;
  int y = 0;

  Point() : super(kStructSize);

  static Point deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Point decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Point result = new Point();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.x = decoder0.decodeInt32(8);
    }
    {
      
      result.y = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(x, 8);
    
    encoder0.encodeInt32(y, 12);
  }

  String toString() {
    return "Point("
           "x: $x" ", "
           "y: $y" ")";
  }
}

class ImportedInterfaceDoSomethingParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  ImportedInterfaceDoSomethingParams() : super(kStructSize);

  static ImportedInterfaceDoSomethingParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ImportedInterfaceDoSomethingParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ImportedInterfaceDoSomethingParams result = new ImportedInterfaceDoSomethingParams();

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
    return "ImportedInterfaceDoSomethingParams("")";
  }
}
const int kImportedInterface_doSomething_name = 0;

const String ImportedInterfaceName =
      'imported::ImportedInterface';

abstract class ImportedInterface {
  void doSomething();

}


class ImportedInterfaceProxyImpl extends bindings.Proxy {
  ImportedInterfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ImportedInterfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ImportedInterfaceProxyImpl.unbound() : super.unbound();

  static ImportedInterfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ImportedInterfaceProxyImpl.fromEndpoint(endpoint);

  String get name => ImportedInterfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ImportedInterfaceProxyImpl($superString)";
  }
}


class _ImportedInterfaceProxyCalls implements ImportedInterface {
  ImportedInterfaceProxyImpl _proxyImpl;

  _ImportedInterfaceProxyCalls(this._proxyImpl);
    void doSomething() {
      assert(_proxyImpl.isBound);
      var params = new ImportedInterfaceDoSomethingParams();
      _proxyImpl.sendMessage(params, kImportedInterface_doSomething_name);
    }
  
}


class ImportedInterfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ImportedInterface ptr;
  final String name = ImportedInterfaceName;

  ImportedInterfaceProxy(ImportedInterfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ImportedInterfaceProxyCalls(proxyImpl);

  ImportedInterfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ImportedInterfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ImportedInterfaceProxyCalls(impl);
  }

  ImportedInterfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new ImportedInterfaceProxyImpl.fromHandle(handle) {
    ptr = new _ImportedInterfaceProxyCalls(impl);
  }

  ImportedInterfaceProxy.unbound() :
      impl = new ImportedInterfaceProxyImpl.unbound() {
    ptr = new _ImportedInterfaceProxyCalls(impl);
  }

  static ImportedInterfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ImportedInterfaceProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "ImportedInterfaceProxy($impl)";
  }
}


class ImportedInterfaceStub extends bindings.Stub {
  ImportedInterface _impl = null;

  ImportedInterfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ImportedInterfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ImportedInterfaceStub.unbound() : super.unbound();

  static ImportedInterfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ImportedInterfaceStub.fromEndpoint(endpoint);

  static const String name = ImportedInterfaceName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kImportedInterface_doSomething_name:
        var params = ImportedInterfaceDoSomethingParams.deserialize(
            message.payload);
        _impl.doSomething();
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ImportedInterface get impl => _impl;
      set impl(ImportedInterface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ImportedInterfaceStub($superString)";
  }
}


