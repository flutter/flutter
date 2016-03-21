// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library service_describer_mojom;
import 'dart:async';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;

import 'package:mojo/mojo/bindings/types/mojom_types.mojom.dart' as mojom_types_mojom;



class _ServiceDescriberDescribeServiceParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String interfaceName = null;
  Object descriptionRequest = null;

  _ServiceDescriberDescribeServiceParams() : super(kVersions.last.size);

  static _ServiceDescriberDescribeServiceParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ServiceDescriberDescribeServiceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ServiceDescriberDescribeServiceParams result = new _ServiceDescriberDescribeServiceParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.interfaceName = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.descriptionRequest = decoder0.decodeInterfaceRequest(16, false, ServiceDescriptionStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(interfaceName, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "interfaceName of struct _ServiceDescriberDescribeServiceParams: $e";
      rethrow;
    }
    try {
      encoder0.encodeInterfaceRequest(descriptionRequest, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "descriptionRequest of struct _ServiceDescriberDescribeServiceParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ServiceDescriberDescribeServiceParams("
           "interfaceName: $interfaceName" ", "
           "descriptionRequest: $descriptionRequest" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


class _ServiceDescriptionGetTopLevelInterfaceParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  _ServiceDescriptionGetTopLevelInterfaceParams() : super(kVersions.last.size);

  static _ServiceDescriptionGetTopLevelInterfaceParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ServiceDescriptionGetTopLevelInterfaceParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ServiceDescriptionGetTopLevelInterfaceParams result = new _ServiceDescriptionGetTopLevelInterfaceParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
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
    return "_ServiceDescriptionGetTopLevelInterfaceParams("")";
  }

  Map toJson() {
    Map map = new Map();
    return map;
  }
}


class ServiceDescriptionGetTopLevelInterfaceResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  mojom_types_mojom.MojomInterface mojomInterface = null;

  ServiceDescriptionGetTopLevelInterfaceResponseParams() : super(kVersions.last.size);

  static ServiceDescriptionGetTopLevelInterfaceResponseParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ServiceDescriptionGetTopLevelInterfaceResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceDescriptionGetTopLevelInterfaceResponseParams result = new ServiceDescriptionGetTopLevelInterfaceResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.mojomInterface = mojom_types_mojom.MojomInterface.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(mojomInterface, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "mojomInterface of struct ServiceDescriptionGetTopLevelInterfaceResponseParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "ServiceDescriptionGetTopLevelInterfaceResponseParams("
           "mojomInterface: $mojomInterface" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["mojomInterface"] = mojomInterface;
    return map;
  }
}


class _ServiceDescriptionGetTypeDefinitionParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  String typeKey = null;

  _ServiceDescriptionGetTypeDefinitionParams() : super(kVersions.last.size);

  static _ServiceDescriptionGetTypeDefinitionParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ServiceDescriptionGetTypeDefinitionParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ServiceDescriptionGetTypeDefinitionParams result = new _ServiceDescriptionGetTypeDefinitionParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.typeKey = decoder0.decodeString(8, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(typeKey, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "typeKey of struct _ServiceDescriptionGetTypeDefinitionParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "_ServiceDescriptionGetTypeDefinitionParams("
           "typeKey: $typeKey" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["typeKey"] = typeKey;
    return map;
  }
}


class ServiceDescriptionGetTypeDefinitionResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  mojom_types_mojom.UserDefinedType type = null;

  ServiceDescriptionGetTypeDefinitionResponseParams() : super(kVersions.last.size);

  static ServiceDescriptionGetTypeDefinitionResponseParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ServiceDescriptionGetTypeDefinitionResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceDescriptionGetTypeDefinitionResponseParams result = new ServiceDescriptionGetTypeDefinitionResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
        result.type = mojom_types_mojom.UserDefinedType.decode(decoder0, 8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeUnion(type, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "type of struct ServiceDescriptionGetTypeDefinitionResponseParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "ServiceDescriptionGetTypeDefinitionResponseParams("
           "type: $type" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["type"] = type;
    return map;
  }
}


class _ServiceDescriptionGetAllTypeDefinitionsParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  _ServiceDescriptionGetAllTypeDefinitionsParams() : super(kVersions.last.size);

  static _ServiceDescriptionGetAllTypeDefinitionsParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static _ServiceDescriptionGetAllTypeDefinitionsParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    _ServiceDescriptionGetAllTypeDefinitionsParams result = new _ServiceDescriptionGetAllTypeDefinitionsParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
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
    return "_ServiceDescriptionGetAllTypeDefinitionsParams("")";
  }

  Map toJson() {
    Map map = new Map();
    return map;
  }
}


class ServiceDescriptionGetAllTypeDefinitionsResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Map<String, mojom_types_mojom.UserDefinedType> definitions = null;

  ServiceDescriptionGetAllTypeDefinitionsResponseParams() : super(kVersions.last.size);

  static ServiceDescriptionGetAllTypeDefinitionsResponseParams deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ServiceDescriptionGetAllTypeDefinitionsResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceDescriptionGetAllTypeDefinitionsResponseParams result = new ServiceDescriptionGetAllTypeDefinitionsResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(8, true);
      if (decoder1 == null) {
        result.definitions = null;
      } else {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<mojom_types_mojom.UserDefinedType> values0;
        {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize, false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
            keys0 = new List<String>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              keys0[i2] = decoder2.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
        {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, false);
          {
            var si2 = decoder2.decodeDataHeaderForUnionArray(keys0.length);
            values0 = new List<mojom_types_mojom.UserDefinedType>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
                values0[i2] = mojom_types_mojom.UserDefinedType.decode(decoder2, bindings.ArrayDataHeader.kHeaderSize + bindings.kUnionSize * i2);
                if (values0[i2] == null) {
                  throw new bindings.MojoCodecError(
                    'Trying to decode null union for non-nullable mojom_types_mojom.UserDefinedType.');
                }
            }
          }
        }
        result.definitions = new Map<String, mojom_types_mojom.UserDefinedType>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (definitions == null) {
        encoder0.encodeNullPointer(8, true);
      } else {
        var encoder1 = encoder0.encoderForMap(8);
        var keys0 = definitions.keys.toList();
        var values0 = definitions.values.toList();
        
        {
          var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < keys0.length; ++i1) {
            encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          }
        }
        
        {
          var encoder2 = encoder1.encodeUnionArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < values0.length; ++i1) {
            encoder2.encodeUnion(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kUnionSize * i1, false);
          }
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "definitions of struct ServiceDescriptionGetAllTypeDefinitionsResponseParams: $e";
      rethrow;
    }
  }

  String toString() {
    return "ServiceDescriptionGetAllTypeDefinitionsResponseParams("
           "definitions: $definitions" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["definitions"] = definitions;
    return map;
  }
}

const int _serviceDescriberMethodDescribeServiceName = 0;

class _ServiceDescriberServiceDescription implements ServiceDescription {
  dynamic getTopLevelInterface([Function responseFactory]) =>
      responseFactory(null);

  dynamic getTypeDefinition(String typeKey, [Function responseFactory]) =>
      responseFactory(null);

  dynamic getAllTypeDefinitions([Function responseFactory]) =>
      responseFactory(null);
}

abstract class ServiceDescriber {
  static const String serviceName = "mojo::bindings::types::ServiceDescriber";
  void describeService(String interfaceName, Object descriptionRequest);
}


class _ServiceDescriberProxyImpl extends bindings.Proxy {
  _ServiceDescriberProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  _ServiceDescriberProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  _ServiceDescriberProxyImpl.unbound() : super.unbound();

  static _ServiceDescriberProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For _ServiceDescriberProxyImpl"));
    return new _ServiceDescriberProxyImpl.fromEndpoint(endpoint);
  }

  ServiceDescription get serviceDescription =>
    new _ServiceDescriberServiceDescription();

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        proxyError("Unexpected message type: ${message.header.type}");
        close(immediate: true);
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "_ServiceDescriberProxyImpl($superString)";
  }
}


class _ServiceDescriberProxyCalls implements ServiceDescriber {
  _ServiceDescriberProxyImpl _proxyImpl;

  _ServiceDescriberProxyCalls(this._proxyImpl);
    void describeService(String interfaceName, Object descriptionRequest) {
      if (!_proxyImpl.isBound) {
        _proxyImpl.proxyError("The Proxy is closed.");
        return;
      }
      var params = new _ServiceDescriberDescribeServiceParams();
      params.interfaceName = interfaceName;
      params.descriptionRequest = descriptionRequest;
      _proxyImpl.sendMessage(params, _serviceDescriberMethodDescribeServiceName);
    }
}


class ServiceDescriberProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ServiceDescriber ptr;

  ServiceDescriberProxy(_ServiceDescriberProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ServiceDescriberProxyCalls(proxyImpl);

  ServiceDescriberProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new _ServiceDescriberProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ServiceDescriberProxyCalls(impl);
  }

  ServiceDescriberProxy.fromHandle(core.MojoHandle handle) :
      impl = new _ServiceDescriberProxyImpl.fromHandle(handle) {
    ptr = new _ServiceDescriberProxyCalls(impl);
  }

  ServiceDescriberProxy.unbound() :
      impl = new _ServiceDescriberProxyImpl.unbound() {
    ptr = new _ServiceDescriberProxyCalls(impl);
  }

  factory ServiceDescriberProxy.connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ServiceDescriberProxy p = new ServiceDescriberProxy.unbound();
    s.connectToService(url, p, serviceName);
    return p;
  }

  static ServiceDescriberProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceDescriberProxy"));
    return new ServiceDescriberProxy.fromEndpoint(endpoint);
  }

  String get serviceName => ServiceDescriber.serviceName;

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  Future responseOrError(Future f) => impl.responseOrError(f);

  Future get errorFuture => impl.errorFuture;

  int get version => impl.version;

  Future<int> queryVersion() => impl.queryVersion();

  void requireVersion(int requiredVersion) {
    impl.requireVersion(requiredVersion);
  }

  String toString() {
    return "ServiceDescriberProxy($impl)";
  }
}


class ServiceDescriberStub extends bindings.Stub {
  ServiceDescriber _impl = null;

  ServiceDescriberStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ServiceDescriberStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ServiceDescriberStub.unbound() : super.unbound();

  static ServiceDescriberStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceDescriberStub"));
    return new ServiceDescriberStub.fromEndpoint(endpoint);
  }



  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case _serviceDescriberMethodDescribeServiceName:
        var params = _ServiceDescriberDescribeServiceParams.deserialize(
            message.payload);
        _impl.describeService(params.interfaceName, params.descriptionRequest);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ServiceDescriber get impl => _impl;
  set impl(ServiceDescriber d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ServiceDescriberStub($superString)";
  }

  int get version => 0;

  static ServiceDescription _cachedServiceDescription;
  static ServiceDescription get serviceDescription {
    if (_cachedServiceDescription == null) {
      _cachedServiceDescription = new _ServiceDescriberServiceDescription();
    }
    return _cachedServiceDescription;
  }
}

const int _serviceDescriptionMethodGetTopLevelInterfaceName = 0;
const int _serviceDescriptionMethodGetTypeDefinitionName = 1;
const int _serviceDescriptionMethodGetAllTypeDefinitionsName = 2;

class _ServiceDescriptionServiceDescription implements ServiceDescription {
  dynamic getTopLevelInterface([Function responseFactory]) =>
      responseFactory(null);

  dynamic getTypeDefinition(String typeKey, [Function responseFactory]) =>
      responseFactory(null);

  dynamic getAllTypeDefinitions([Function responseFactory]) =>
      responseFactory(null);
}

abstract class ServiceDescription {
  static const String serviceName = null;
  dynamic getTopLevelInterface([Function responseFactory = null]);
  dynamic getTypeDefinition(String typeKey,[Function responseFactory = null]);
  dynamic getAllTypeDefinitions([Function responseFactory = null]);
}


class _ServiceDescriptionProxyImpl extends bindings.Proxy {
  _ServiceDescriptionProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  _ServiceDescriptionProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  _ServiceDescriptionProxyImpl.unbound() : super.unbound();

  static _ServiceDescriptionProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For _ServiceDescriptionProxyImpl"));
    return new _ServiceDescriptionProxyImpl.fromEndpoint(endpoint);
  }

  ServiceDescription get serviceDescription =>
    new _ServiceDescriptionServiceDescription();

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case _serviceDescriptionMethodGetTopLevelInterfaceName:
        var r = ServiceDescriptionGetTopLevelInterfaceResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          proxyError("Expected a message with a valid request Id.");
          return;
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          proxyError(
              "Message had unknown request Id: ${message.header.requestId}");
          return;
        }
        completerMap.remove(message.header.requestId);
        if (c.isCompleted) {
          proxyError("Response completer already completed");
          return;
        }
        c.complete(r);
        break;
      case _serviceDescriptionMethodGetTypeDefinitionName:
        var r = ServiceDescriptionGetTypeDefinitionResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          proxyError("Expected a message with a valid request Id.");
          return;
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          proxyError(
              "Message had unknown request Id: ${message.header.requestId}");
          return;
        }
        completerMap.remove(message.header.requestId);
        if (c.isCompleted) {
          proxyError("Response completer already completed");
          return;
        }
        c.complete(r);
        break;
      case _serviceDescriptionMethodGetAllTypeDefinitionsName:
        var r = ServiceDescriptionGetAllTypeDefinitionsResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          proxyError("Expected a message with a valid request Id.");
          return;
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          proxyError(
              "Message had unknown request Id: ${message.header.requestId}");
          return;
        }
        completerMap.remove(message.header.requestId);
        if (c.isCompleted) {
          proxyError("Response completer already completed");
          return;
        }
        c.complete(r);
        break;
      default:
        proxyError("Unexpected message type: ${message.header.type}");
        close(immediate: true);
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "_ServiceDescriptionProxyImpl($superString)";
  }
}


class _ServiceDescriptionProxyCalls implements ServiceDescription {
  _ServiceDescriptionProxyImpl _proxyImpl;

  _ServiceDescriptionProxyCalls(this._proxyImpl);
    dynamic getTopLevelInterface([Function responseFactory = null]) {
      var params = new _ServiceDescriptionGetTopLevelInterfaceParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          _serviceDescriptionMethodGetTopLevelInterfaceName,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    dynamic getTypeDefinition(String typeKey,[Function responseFactory = null]) {
      var params = new _ServiceDescriptionGetTypeDefinitionParams();
      params.typeKey = typeKey;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          _serviceDescriptionMethodGetTypeDefinitionName,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    dynamic getAllTypeDefinitions([Function responseFactory = null]) {
      var params = new _ServiceDescriptionGetAllTypeDefinitionsParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          _serviceDescriptionMethodGetAllTypeDefinitionsName,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class ServiceDescriptionProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ServiceDescription ptr;

  ServiceDescriptionProxy(_ServiceDescriptionProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ServiceDescriptionProxyCalls(proxyImpl);

  ServiceDescriptionProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new _ServiceDescriptionProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ServiceDescriptionProxyCalls(impl);
  }

  ServiceDescriptionProxy.fromHandle(core.MojoHandle handle) :
      impl = new _ServiceDescriptionProxyImpl.fromHandle(handle) {
    ptr = new _ServiceDescriptionProxyCalls(impl);
  }

  ServiceDescriptionProxy.unbound() :
      impl = new _ServiceDescriptionProxyImpl.unbound() {
    ptr = new _ServiceDescriptionProxyCalls(impl);
  }

  factory ServiceDescriptionProxy.connectToService(
      bindings.ServiceConnector s, String url, [String serviceName]) {
    ServiceDescriptionProxy p = new ServiceDescriptionProxy.unbound();
    s.connectToService(url, p, serviceName);
    return p;
  }

  static ServiceDescriptionProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceDescriptionProxy"));
    return new ServiceDescriptionProxy.fromEndpoint(endpoint);
  }

  String get serviceName => ServiceDescription.serviceName;

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  Future responseOrError(Future f) => impl.responseOrError(f);

  Future get errorFuture => impl.errorFuture;

  int get version => impl.version;

  Future<int> queryVersion() => impl.queryVersion();

  void requireVersion(int requiredVersion) {
    impl.requireVersion(requiredVersion);
  }

  String toString() {
    return "ServiceDescriptionProxy($impl)";
  }
}


class ServiceDescriptionStub extends bindings.Stub {
  ServiceDescription _impl = null;

  ServiceDescriptionStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ServiceDescriptionStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ServiceDescriptionStub.unbound() : super.unbound();

  static ServiceDescriptionStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) {
    assert(endpoint.setDescription("For ServiceDescriptionStub"));
    return new ServiceDescriptionStub.fromEndpoint(endpoint);
  }


  ServiceDescriptionGetTopLevelInterfaceResponseParams _serviceDescriptionGetTopLevelInterfaceResponseParamsFactory(mojom_types_mojom.MojomInterface mojomInterface) {
    var result = new ServiceDescriptionGetTopLevelInterfaceResponseParams();
    result.mojomInterface = mojomInterface;
    return result;
  }
  ServiceDescriptionGetTypeDefinitionResponseParams _serviceDescriptionGetTypeDefinitionResponseParamsFactory(mojom_types_mojom.UserDefinedType type) {
    var result = new ServiceDescriptionGetTypeDefinitionResponseParams();
    result.type = type;
    return result;
  }
  ServiceDescriptionGetAllTypeDefinitionsResponseParams _serviceDescriptionGetAllTypeDefinitionsResponseParamsFactory(Map<String, mojom_types_mojom.UserDefinedType> definitions) {
    var result = new ServiceDescriptionGetAllTypeDefinitionsResponseParams();
    result.definitions = definitions;
    return result;
  }

  dynamic handleMessage(bindings.ServiceMessage message) {
    if (bindings.ControlMessageHandler.isControlMessage(message)) {
      return bindings.ControlMessageHandler.handleMessage(this,
                                                          0,
                                                          message);
    }
    assert(_impl != null);
    switch (message.header.type) {
      case _serviceDescriptionMethodGetTopLevelInterfaceName:
        var response = _impl.getTopLevelInterface(_serviceDescriptionGetTopLevelInterfaceResponseParamsFactory);
        if (response is Future) {
          return response.then((response) {
            if (response != null) {
              return buildResponseWithId(
                  response,
                  _serviceDescriptionMethodGetTopLevelInterfaceName,
                  message.header.requestId,
                  bindings.MessageHeader.kMessageIsResponse);
            }
          });
        } else if (response != null) {
          return buildResponseWithId(
              response,
              _serviceDescriptionMethodGetTopLevelInterfaceName,
              message.header.requestId,
              bindings.MessageHeader.kMessageIsResponse);
        }
        break;
      case _serviceDescriptionMethodGetTypeDefinitionName:
        var params = _ServiceDescriptionGetTypeDefinitionParams.deserialize(
            message.payload);
        var response = _impl.getTypeDefinition(params.typeKey,_serviceDescriptionGetTypeDefinitionResponseParamsFactory);
        if (response is Future) {
          return response.then((response) {
            if (response != null) {
              return buildResponseWithId(
                  response,
                  _serviceDescriptionMethodGetTypeDefinitionName,
                  message.header.requestId,
                  bindings.MessageHeader.kMessageIsResponse);
            }
          });
        } else if (response != null) {
          return buildResponseWithId(
              response,
              _serviceDescriptionMethodGetTypeDefinitionName,
              message.header.requestId,
              bindings.MessageHeader.kMessageIsResponse);
        }
        break;
      case _serviceDescriptionMethodGetAllTypeDefinitionsName:
        var response = _impl.getAllTypeDefinitions(_serviceDescriptionGetAllTypeDefinitionsResponseParamsFactory);
        if (response is Future) {
          return response.then((response) {
            if (response != null) {
              return buildResponseWithId(
                  response,
                  _serviceDescriptionMethodGetAllTypeDefinitionsName,
                  message.header.requestId,
                  bindings.MessageHeader.kMessageIsResponse);
            }
          });
        } else if (response != null) {
          return buildResponseWithId(
              response,
              _serviceDescriptionMethodGetAllTypeDefinitionsName,
              message.header.requestId,
              bindings.MessageHeader.kMessageIsResponse);
        }
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ServiceDescription get impl => _impl;
  set impl(ServiceDescription d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ServiceDescriptionStub($superString)";
  }

  int get version => 0;

  static ServiceDescription _cachedServiceDescription;
  static ServiceDescription get serviceDescription {
    if (_cachedServiceDescription == null) {
      _cachedServiceDescription = new _ServiceDescriptionServiceDescription();
    }
    return _cachedServiceDescription;
  }
}



