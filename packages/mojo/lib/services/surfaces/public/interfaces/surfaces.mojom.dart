// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library surfaces.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;
import 'package:mojo/services/surfaces/public/interfaces/quads.mojom.dart' as quads_mojom;
import 'package:mojo/services/surfaces/public/interfaces/surface_id.mojom.dart' as surface_id_mojom;

final int ResourceFormat_RGBA_8888 = 0;
final int ResourceFormat_RGBA_4444 = ResourceFormat_RGBA_8888 + 1;
final int ResourceFormat_BGRA_8888 = ResourceFormat_RGBA_4444 + 1;
final int ResourceFormat_ALPHA_8 = ResourceFormat_BGRA_8888 + 1;
final int ResourceFormat_LUMINANCE_8 = ResourceFormat_ALPHA_8 + 1;
final int ResourceFormat_RGB_565 = ResourceFormat_LUMINANCE_8 + 1;
final int ResourceFormat_ETC1 = ResourceFormat_RGB_565 + 1;


class Mailbox extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<int> name = null;

  Mailbox() : super(kStructSize);

  static Mailbox deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Mailbox decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Mailbox result = new Mailbox();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.name = decoder0.decodeInt8Array(8, bindings.kNothingNullable, 64);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt8Array(name, 8, bindings.kNothingNullable, 64);
  }

  String toString() {
    return "Mailbox("
           "name: $name" ")";
  }
}

class MailboxHolder extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Mailbox mailbox = null;
  int textureTarget = 0;
  int syncPoint = 0;

  MailboxHolder() : super(kStructSize);

  static MailboxHolder deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MailboxHolder decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MailboxHolder result = new MailboxHolder();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.mailbox = Mailbox.decode(decoder1);
    }
    {
      
      result.textureTarget = decoder0.decodeUint32(16);
    }
    {
      
      result.syncPoint = decoder0.decodeUint32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(mailbox, 8, false);
    
    encoder0.encodeUint32(textureTarget, 16);
    
    encoder0.encodeUint32(syncPoint, 20);
  }

  String toString() {
    return "MailboxHolder("
           "mailbox: $mailbox" ", "
           "textureTarget: $textureTarget" ", "
           "syncPoint: $syncPoint" ")";
  }
}

class TransferableResource extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;
  int format = 0;
  int filter = 0;
  bool isRepeated = false;
  bool isSoftware = false;
  geometry_mojom.Size size = null;
  MailboxHolder mailboxHolder = null;

  TransferableResource() : super(kStructSize);

  static TransferableResource deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TransferableResource decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TransferableResource result = new TransferableResource();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeUint32(8);
    }
    {
      
      result.format = decoder0.decodeInt32(12);
    }
    {
      
      result.filter = decoder0.decodeUint32(16);
    }
    {
      
      result.isRepeated = decoder0.decodeBool(20, 0);
    }
    {
      
      result.isSoftware = decoder0.decodeBool(20, 1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.size = geometry_mojom.Size.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.mailboxHolder = MailboxHolder.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(id, 8);
    
    encoder0.encodeInt32(format, 12);
    
    encoder0.encodeUint32(filter, 16);
    
    encoder0.encodeBool(isRepeated, 20, 0);
    
    encoder0.encodeBool(isSoftware, 20, 1);
    
    encoder0.encodeStruct(size, 24, false);
    
    encoder0.encodeStruct(mailboxHolder, 32, false);
  }

  String toString() {
    return "TransferableResource("
           "id: $id" ", "
           "format: $format" ", "
           "filter: $filter" ", "
           "isRepeated: $isRepeated" ", "
           "isSoftware: $isSoftware" ", "
           "size: $size" ", "
           "mailboxHolder: $mailboxHolder" ")";
  }
}

class ReturnedResource extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;
  int syncPoint = 0;
  int count = 0;
  bool lost = false;

  ReturnedResource() : super(kStructSize);

  static ReturnedResource deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ReturnedResource decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ReturnedResource result = new ReturnedResource();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeUint32(8);
    }
    {
      
      result.syncPoint = decoder0.decodeUint32(12);
    }
    {
      
      result.count = decoder0.decodeInt32(16);
    }
    {
      
      result.lost = decoder0.decodeBool(20, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(id, 8);
    
    encoder0.encodeUint32(syncPoint, 12);
    
    encoder0.encodeInt32(count, 16);
    
    encoder0.encodeBool(lost, 20, 0);
  }

  String toString() {
    return "ReturnedResource("
           "id: $id" ", "
           "syncPoint: $syncPoint" ", "
           "count: $count" ", "
           "lost: $lost" ")";
  }
}

class Frame extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<TransferableResource> resources = null;
  List<quads_mojom.Pass> passes = null;

  Frame() : super(kStructSize);

  static Frame deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Frame decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Frame result = new Frame();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.resources = new List<TransferableResource>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.resources[i1] = TransferableResource.decode(decoder2);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.passes = new List<quads_mojom.Pass>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.passes[i1] = quads_mojom.Pass.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (resources == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(resources.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < resources.length; ++i0) {
        
        encoder1.encodeStruct(resources[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    if (passes == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(passes.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < passes.length; ++i0) {
        
        encoder1.encodeStruct(passes[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "Frame("
           "resources: $resources" ", "
           "passes: $passes" ")";
  }
}

class ResourceReturnerReturnResourcesParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<ReturnedResource> resources = null;

  ResourceReturnerReturnResourcesParams() : super(kStructSize);

  static ResourceReturnerReturnResourcesParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ResourceReturnerReturnResourcesParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ResourceReturnerReturnResourcesParams result = new ResourceReturnerReturnResourcesParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.resources = new List<ReturnedResource>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.resources[i1] = ReturnedResource.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (resources == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(resources.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < resources.length; ++i0) {
        
        encoder1.encodeStruct(resources[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "ResourceReturnerReturnResourcesParams("
           "resources: $resources" ")";
  }
}

class SurfaceGetIdNamespaceParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  SurfaceGetIdNamespaceParams() : super(kStructSize);

  static SurfaceGetIdNamespaceParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceGetIdNamespaceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceGetIdNamespaceParams result = new SurfaceGetIdNamespaceParams();

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
    return "SurfaceGetIdNamespaceParams("")";
  }
}

class SurfaceGetIdNamespaceResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int idNamespace = 0;

  SurfaceGetIdNamespaceResponseParams() : super(kStructSize);

  static SurfaceGetIdNamespaceResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceGetIdNamespaceResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceGetIdNamespaceResponseParams result = new SurfaceGetIdNamespaceResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.idNamespace = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(idNamespace, 8);
  }

  String toString() {
    return "SurfaceGetIdNamespaceResponseParams("
           "idNamespace: $idNamespace" ")";
  }
}

class SurfaceSetResourceReturnerParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object returner = null;

  SurfaceSetResourceReturnerParams() : super(kStructSize);

  static SurfaceSetResourceReturnerParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceSetResourceReturnerParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceSetResourceReturnerParams result = new SurfaceSetResourceReturnerParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.returner = decoder0.decodeServiceInterface(8, false, ResourceReturnerProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterface(returner, 8, false);
  }

  String toString() {
    return "SurfaceSetResourceReturnerParams("
           "returner: $returner" ")";
  }
}

class SurfaceCreateSurfaceParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int idLocal = 0;

  SurfaceCreateSurfaceParams() : super(kStructSize);

  static SurfaceCreateSurfaceParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceCreateSurfaceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceCreateSurfaceParams result = new SurfaceCreateSurfaceParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.idLocal = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(idLocal, 8);
  }

  String toString() {
    return "SurfaceCreateSurfaceParams("
           "idLocal: $idLocal" ")";
  }
}

class SurfaceSubmitFrameParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int idLocal = 0;
  Frame frame = null;

  SurfaceSubmitFrameParams() : super(kStructSize);

  static SurfaceSubmitFrameParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceSubmitFrameParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceSubmitFrameParams result = new SurfaceSubmitFrameParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.idLocal = decoder0.decodeUint32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.frame = Frame.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(idLocal, 8);
    
    encoder0.encodeStruct(frame, 16, false);
  }

  String toString() {
    return "SurfaceSubmitFrameParams("
           "idLocal: $idLocal" ", "
           "frame: $frame" ")";
  }
}

class SurfaceSubmitFrameResponseParams extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  SurfaceSubmitFrameResponseParams() : super(kStructSize);

  static SurfaceSubmitFrameResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceSubmitFrameResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceSubmitFrameResponseParams result = new SurfaceSubmitFrameResponseParams();

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
    return "SurfaceSubmitFrameResponseParams("")";
  }
}

class SurfaceDestroySurfaceParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int idLocal = 0;

  SurfaceDestroySurfaceParams() : super(kStructSize);

  static SurfaceDestroySurfaceParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceDestroySurfaceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceDestroySurfaceParams result = new SurfaceDestroySurfaceParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.idLocal = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(idLocal, 8);
  }

  String toString() {
    return "SurfaceDestroySurfaceParams("
           "idLocal: $idLocal" ")";
  }
}
const int kResourceReturner_returnResources_name = 0;

const String ResourceReturnerName =
      'mojo::ResourceReturner';

abstract class ResourceReturner {
  void returnResources(List<ReturnedResource> resources);

}


class ResourceReturnerProxyImpl extends bindings.Proxy {
  ResourceReturnerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ResourceReturnerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ResourceReturnerProxyImpl.unbound() : super.unbound();

  static ResourceReturnerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ResourceReturnerProxyImpl.fromEndpoint(endpoint);

  String get name => ResourceReturnerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "ResourceReturnerProxyImpl($superString)";
  }
}


class _ResourceReturnerProxyCalls implements ResourceReturner {
  ResourceReturnerProxyImpl _proxyImpl;

  _ResourceReturnerProxyCalls(this._proxyImpl);
    void returnResources(List<ReturnedResource> resources) {
      assert(_proxyImpl.isBound);
      var params = new ResourceReturnerReturnResourcesParams();
      params.resources = resources;
      _proxyImpl.sendMessage(params, kResourceReturner_returnResources_name);
    }
  
}


class ResourceReturnerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ResourceReturner ptr;
  final String name = ResourceReturnerName;

  ResourceReturnerProxy(ResourceReturnerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ResourceReturnerProxyCalls(proxyImpl);

  ResourceReturnerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ResourceReturnerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ResourceReturnerProxyCalls(impl);
  }

  ResourceReturnerProxy.fromHandle(core.MojoHandle handle) :
      impl = new ResourceReturnerProxyImpl.fromHandle(handle) {
    ptr = new _ResourceReturnerProxyCalls(impl);
  }

  ResourceReturnerProxy.unbound() :
      impl = new ResourceReturnerProxyImpl.unbound() {
    ptr = new _ResourceReturnerProxyCalls(impl);
  }

  static ResourceReturnerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ResourceReturnerProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "ResourceReturnerProxy($impl)";
  }
}


class ResourceReturnerStub extends bindings.Stub {
  ResourceReturner _impl = null;

  ResourceReturnerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ResourceReturnerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ResourceReturnerStub.unbound() : super.unbound();

  static ResourceReturnerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ResourceReturnerStub.fromEndpoint(endpoint);

  static const String name = ResourceReturnerName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kResourceReturner_returnResources_name:
        var params = ResourceReturnerReturnResourcesParams.deserialize(
            message.payload);
        _impl.returnResources(params.resources);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ResourceReturner get impl => _impl;
      set impl(ResourceReturner d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ResourceReturnerStub($superString)";
  }
}

const int kSurface_getIdNamespace_name = 0;
const int kSurface_setResourceReturner_name = 1;
const int kSurface_createSurface_name = 2;
const int kSurface_submitFrame_name = 3;
const int kSurface_destroySurface_name = 4;

const String SurfaceName =
      'mojo::Surface';

abstract class Surface {
  Future<SurfaceGetIdNamespaceResponseParams> getIdNamespace([Function responseFactory = null]);
  void setResourceReturner(Object returner);
  void createSurface(int idLocal);
  Future<SurfaceSubmitFrameResponseParams> submitFrame(int idLocal,Frame frame,[Function responseFactory = null]);
  void destroySurface(int idLocal);

}


class SurfaceProxyImpl extends bindings.Proxy {
  SurfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  SurfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  SurfaceProxyImpl.unbound() : super.unbound();

  static SurfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SurfaceProxyImpl.fromEndpoint(endpoint);

  String get name => SurfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kSurface_getIdNamespace_name:
        var r = SurfaceGetIdNamespaceResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        completerMap[message.header.requestId] = null;
        c.complete(r);
        break;
      case kSurface_submitFrame_name:
        var r = SurfaceSubmitFrameResponseParams.deserialize(
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
    return "SurfaceProxyImpl($superString)";
  }
}


class _SurfaceProxyCalls implements Surface {
  SurfaceProxyImpl _proxyImpl;

  _SurfaceProxyCalls(this._proxyImpl);
    Future<SurfaceGetIdNamespaceResponseParams> getIdNamespace([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new SurfaceGetIdNamespaceParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kSurface_getIdNamespace_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    void setResourceReturner(Object returner) {
      assert(_proxyImpl.isBound);
      var params = new SurfaceSetResourceReturnerParams();
      params.returner = returner;
      _proxyImpl.sendMessage(params, kSurface_setResourceReturner_name);
    }
  
    void createSurface(int idLocal) {
      assert(_proxyImpl.isBound);
      var params = new SurfaceCreateSurfaceParams();
      params.idLocal = idLocal;
      _proxyImpl.sendMessage(params, kSurface_createSurface_name);
    }
  
    Future<SurfaceSubmitFrameResponseParams> submitFrame(int idLocal,Frame frame,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new SurfaceSubmitFrameParams();
      params.idLocal = idLocal;
      params.frame = frame;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kSurface_submitFrame_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    void destroySurface(int idLocal) {
      assert(_proxyImpl.isBound);
      var params = new SurfaceDestroySurfaceParams();
      params.idLocal = idLocal;
      _proxyImpl.sendMessage(params, kSurface_destroySurface_name);
    }
  
}


class SurfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Surface ptr;
  final String name = SurfaceName;

  SurfaceProxy(SurfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _SurfaceProxyCalls(proxyImpl);

  SurfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new SurfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _SurfaceProxyCalls(impl);
  }

  SurfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new SurfaceProxyImpl.fromHandle(handle) {
    ptr = new _SurfaceProxyCalls(impl);
  }

  SurfaceProxy.unbound() :
      impl = new SurfaceProxyImpl.unbound() {
    ptr = new _SurfaceProxyCalls(impl);
  }

  static SurfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SurfaceProxy.fromEndpoint(endpoint);

  Future close() => impl.close();

  String toString() {
    return "SurfaceProxy($impl)";
  }
}


class SurfaceStub extends bindings.Stub {
  Surface _impl = null;

  SurfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  SurfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  SurfaceStub.unbound() : super.unbound();

  static SurfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new SurfaceStub.fromEndpoint(endpoint);

  static const String name = SurfaceName;


  SurfaceGetIdNamespaceResponseParams _SurfaceGetIdNamespaceResponseParamsFactory(int idNamespace) {
    var result = new SurfaceGetIdNamespaceResponseParams();
    result.idNamespace = idNamespace;
    return result;
  }
  SurfaceSubmitFrameResponseParams _SurfaceSubmitFrameResponseParamsFactory() {
    var result = new SurfaceSubmitFrameResponseParams();
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kSurface_getIdNamespace_name:
        var params = SurfaceGetIdNamespaceParams.deserialize(
            message.payload);
        return _impl.getIdNamespace(_SurfaceGetIdNamespaceResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kSurface_getIdNamespace_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kSurface_setResourceReturner_name:
        var params = SurfaceSetResourceReturnerParams.deserialize(
            message.payload);
        _impl.setResourceReturner(params.returner);
        break;
      case kSurface_createSurface_name:
        var params = SurfaceCreateSurfaceParams.deserialize(
            message.payload);
        _impl.createSurface(params.idLocal);
        break;
      case kSurface_submitFrame_name:
        var params = SurfaceSubmitFrameParams.deserialize(
            message.payload);
        return _impl.submitFrame(params.idLocal,params.frame,_SurfaceSubmitFrameResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kSurface_submitFrame_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kSurface_destroySurface_name:
        var params = SurfaceDestroySurfaceParams.deserialize(
            message.payload);
        _impl.destroySurface(params.idLocal);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Surface get impl => _impl;
      set impl(Surface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "SurfaceStub($superString)";
  }
}


