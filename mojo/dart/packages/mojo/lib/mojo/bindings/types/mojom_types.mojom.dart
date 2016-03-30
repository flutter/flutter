// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mojom_types_mojom;
import 'package:mojo/bindings.dart' as bindings;


class SimpleType extends bindings.MojoEnum {
  static const SimpleType bool = const SimpleType._(0);
  static const SimpleType double = const SimpleType._(1);
  static const SimpleType float = const SimpleType._(2);
  static const SimpleType int8 = const SimpleType._(3);
  static const SimpleType int16 = const SimpleType._(4);
  static const SimpleType int32 = const SimpleType._(5);
  static const SimpleType int64 = const SimpleType._(6);
  static const SimpleType uint8 = const SimpleType._(7);
  static const SimpleType uint16 = const SimpleType._(8);
  static const SimpleType uint32 = const SimpleType._(9);
  static const SimpleType uint64 = const SimpleType._(10);

  const SimpleType._(int v) : super(v);

  static const Map<String, SimpleType> valuesMap = const {
    "bool": bool,
    "double": double,
    "float": float,
    "int8": int8,
    "int16": int16,
    "int32": int32,
    "int64": int64,
    "uint8": uint8,
    "uint16": uint16,
    "uint32": uint32,
    "uint64": uint64,
  };
  static const List<SimpleType> values = const [
    bool,
    double,
    float,
    int8,
    int16,
    int32,
    int64,
    uint8,
    uint16,
    uint32,
    uint64,
  ];

  static SimpleType valueOf(String name) => valuesMap[name];

  factory SimpleType(int v) {
    switch (v) {
      case 0:
        return SimpleType.bool;
      case 1:
        return SimpleType.double;
      case 2:
        return SimpleType.float;
      case 3:
        return SimpleType.int8;
      case 4:
        return SimpleType.int16;
      case 5:
        return SimpleType.int32;
      case 6:
        return SimpleType.int64;
      case 7:
        return SimpleType.uint8;
      case 8:
        return SimpleType.uint16;
      case 9:
        return SimpleType.uint32;
      case 10:
        return SimpleType.uint64;
      default:
        return null;
    }
  }

  static SimpleType decode(bindings.Decoder decoder0, int offset) {
    int v = decoder0.decodeUint32(offset);
    SimpleType result = new SimpleType(v);
    if (result == null) {
      throw new bindings.MojoCodecError(
          'Bad value $v for enum SimpleType.');
    }
    return result;
  }

  String toString() {
    switch(this) {
      case bool:
        return 'SimpleType.bool';
      case double:
        return 'SimpleType.double';
      case float:
        return 'SimpleType.float';
      case int8:
        return 'SimpleType.int8';
      case int16:
        return 'SimpleType.int16';
      case int32:
        return 'SimpleType.int32';
      case int64:
        return 'SimpleType.int64';
      case uint8:
        return 'SimpleType.uint8';
      case uint16:
        return 'SimpleType.uint16';
      case uint32:
        return 'SimpleType.uint32';
      case uint64:
        return 'SimpleType.uint64';
      default:
        return null;
    }
  }

  int toJson() => mojoEnumValue;
}

class BuiltinConstantValue extends bindings.MojoEnum {
  static const BuiltinConstantValue doubleInfinity = const BuiltinConstantValue._(0);
  static const BuiltinConstantValue doubleNegativeInfinity = const BuiltinConstantValue._(1);
  static const BuiltinConstantValue doubleNan = const BuiltinConstantValue._(2);
  static const BuiltinConstantValue floatInfinity = const BuiltinConstantValue._(3);
  static const BuiltinConstantValue floatNegativeInfinity = const BuiltinConstantValue._(4);
  static const BuiltinConstantValue floatNan = const BuiltinConstantValue._(5);

  const BuiltinConstantValue._(int v) : super(v);

  static const Map<String, BuiltinConstantValue> valuesMap = const {
    "doubleInfinity": doubleInfinity,
    "doubleNegativeInfinity": doubleNegativeInfinity,
    "doubleNan": doubleNan,
    "floatInfinity": floatInfinity,
    "floatNegativeInfinity": floatNegativeInfinity,
    "floatNan": floatNan,
  };
  static const List<BuiltinConstantValue> values = const [
    doubleInfinity,
    doubleNegativeInfinity,
    doubleNan,
    floatInfinity,
    floatNegativeInfinity,
    floatNan,
  ];

  static BuiltinConstantValue valueOf(String name) => valuesMap[name];

  factory BuiltinConstantValue(int v) {
    switch (v) {
      case 0:
        return BuiltinConstantValue.doubleInfinity;
      case 1:
        return BuiltinConstantValue.doubleNegativeInfinity;
      case 2:
        return BuiltinConstantValue.doubleNan;
      case 3:
        return BuiltinConstantValue.floatInfinity;
      case 4:
        return BuiltinConstantValue.floatNegativeInfinity;
      case 5:
        return BuiltinConstantValue.floatNan;
      default:
        return null;
    }
  }

  static BuiltinConstantValue decode(bindings.Decoder decoder0, int offset) {
    int v = decoder0.decodeUint32(offset);
    BuiltinConstantValue result = new BuiltinConstantValue(v);
    if (result == null) {
      throw new bindings.MojoCodecError(
          'Bad value $v for enum BuiltinConstantValue.');
    }
    return result;
  }

  String toString() {
    switch(this) {
      case doubleInfinity:
        return 'BuiltinConstantValue.doubleInfinity';
      case doubleNegativeInfinity:
        return 'BuiltinConstantValue.doubleNegativeInfinity';
      case doubleNan:
        return 'BuiltinConstantValue.doubleNan';
      case floatInfinity:
        return 'BuiltinConstantValue.floatInfinity';
      case floatNegativeInfinity:
        return 'BuiltinConstantValue.floatNegativeInfinity';
      case floatNan:
        return 'BuiltinConstantValue.floatNan';
      default:
        return null;
    }
  }

  int toJson() => mojoEnumValue;
}



class StringType extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool nullable = false;

  StringType() : super(kVersions.last.size);

  static StringType deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static StringType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StringType result = new StringType();

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
      
      result.nullable = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeBool(nullable, 8, 0);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "nullable of struct StringType: $e";
      rethrow;
    }
  }

  String toString() {
    return "StringType("
           "nullable: $nullable" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["nullable"] = nullable;
    return map;
  }
}


class HandleTypeKind extends bindings.MojoEnum {
  static const HandleTypeKind unspecified = const HandleTypeKind._(0);
  static const HandleTypeKind messagePipe = const HandleTypeKind._(1);
  static const HandleTypeKind dataPipeConsumer = const HandleTypeKind._(2);
  static const HandleTypeKind dataPipeProducer = const HandleTypeKind._(3);
  static const HandleTypeKind sharedBuffer = const HandleTypeKind._(4);

  const HandleTypeKind._(int v) : super(v);

  static const Map<String, HandleTypeKind> valuesMap = const {
    "unspecified": unspecified,
    "messagePipe": messagePipe,
    "dataPipeConsumer": dataPipeConsumer,
    "dataPipeProducer": dataPipeProducer,
    "sharedBuffer": sharedBuffer,
  };
  static const List<HandleTypeKind> values = const [
    unspecified,
    messagePipe,
    dataPipeConsumer,
    dataPipeProducer,
    sharedBuffer,
  ];

  static HandleTypeKind valueOf(String name) => valuesMap[name];

  factory HandleTypeKind(int v) {
    switch (v) {
      case 0:
        return HandleTypeKind.unspecified;
      case 1:
        return HandleTypeKind.messagePipe;
      case 2:
        return HandleTypeKind.dataPipeConsumer;
      case 3:
        return HandleTypeKind.dataPipeProducer;
      case 4:
        return HandleTypeKind.sharedBuffer;
      default:
        return null;
    }
  }

  static HandleTypeKind decode(bindings.Decoder decoder0, int offset) {
    int v = decoder0.decodeUint32(offset);
    HandleTypeKind result = new HandleTypeKind(v);
    if (result == null) {
      throw new bindings.MojoCodecError(
          'Bad value $v for enum HandleTypeKind.');
    }
    return result;
  }

  String toString() {
    switch(this) {
      case unspecified:
        return 'HandleTypeKind.unspecified';
      case messagePipe:
        return 'HandleTypeKind.messagePipe';
      case dataPipeConsumer:
        return 'HandleTypeKind.dataPipeConsumer';
      case dataPipeProducer:
        return 'HandleTypeKind.dataPipeProducer';
      case sharedBuffer:
        return 'HandleTypeKind.sharedBuffer';
      default:
        return null;
    }
  }

  int toJson() => mojoEnumValue;
}

class HandleType extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool nullable = false;
  HandleTypeKind kind = new HandleTypeKind(0);

  HandleType() : super(kVersions.last.size);

  static HandleType deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static HandleType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HandleType result = new HandleType();

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
      
      result.nullable = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
        result.kind = HandleTypeKind.decode(decoder0, 12);
        if (result.kind == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable HandleTypeKind.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeBool(nullable, 8, 0);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "nullable of struct HandleType: $e";
      rethrow;
    }
    try {
      encoder0.encodeEnum(kind, 12);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "kind of struct HandleType: $e";
      rethrow;
    }
  }

  String toString() {
    return "HandleType("
           "nullable: $nullable" ", "
           "kind: $kind" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["nullable"] = nullable;
    map["kind"] = kind;
    return map;
  }
}


class ArrayType extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  bool nullable = false;
  int fixedLength = -1;
  Type elementType = null;

  ArrayType() : super(kVersions.last.size);

  static ArrayType deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ArrayType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ArrayType result = new ArrayType();

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
      
      result.nullable = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      result.fixedLength = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
        result.elementType = Type.decode(decoder0, 16);
        if (result.elementType == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeBool(nullable, 8, 0);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "nullable of struct ArrayType: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt32(fixedLength, 12);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fixedLength of struct ArrayType: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(elementType, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "elementType of struct ArrayType: $e";
      rethrow;
    }
  }

  String toString() {
    return "ArrayType("
           "nullable: $nullable" ", "
           "fixedLength: $fixedLength" ", "
           "elementType: $elementType" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["nullable"] = nullable;
    map["fixedLength"] = fixedLength;
    map["elementType"] = elementType;
    return map;
  }
}


class MapType extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(48, 0)
  ];
  bool nullable = false;
  Type keyType = null;
  Type valueType = null;

  MapType() : super(kVersions.last.size);

  static MapType deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MapType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MapType result = new MapType();

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
      
      result.nullable = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
        result.keyType = Type.decode(decoder0, 16);
        if (result.keyType == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    if (mainDataHeader.version >= 0) {
      
        result.valueType = Type.decode(decoder0, 32);
        if (result.valueType == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeBool(nullable, 8, 0);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "nullable of struct MapType: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(keyType, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "keyType of struct MapType: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(valueType, 32, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "valueType of struct MapType: $e";
      rethrow;
    }
  }

  String toString() {
    return "MapType("
           "nullable: $nullable" ", "
           "keyType: $keyType" ", "
           "valueType: $valueType" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["nullable"] = nullable;
    map["keyType"] = keyType;
    map["valueType"] = valueType;
    return map;
  }
}


class TypeReference extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  bool nullable = false;
  bool isInterfaceRequest = false;
  String identifier = null;
  String typeKey = null;

  TypeReference() : super(kVersions.last.size);

  static TypeReference deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static TypeReference decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TypeReference result = new TypeReference();

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
      
      result.nullable = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      result.isInterfaceRequest = decoder0.decodeBool(8, 1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.identifier = decoder0.decodeString(16, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.typeKey = decoder0.decodeString(24, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeBool(nullable, 8, 0);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "nullable of struct TypeReference: $e";
      rethrow;
    }
    try {
      encoder0.encodeBool(isInterfaceRequest, 8, 1);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "isInterfaceRequest of struct TypeReference: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(identifier, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "identifier of struct TypeReference: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(typeKey, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "typeKey of struct TypeReference: $e";
      rethrow;
    }
  }

  String toString() {
    return "TypeReference("
           "nullable: $nullable" ", "
           "isInterfaceRequest: $isInterfaceRequest" ", "
           "identifier: $identifier" ", "
           "typeKey: $typeKey" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["nullable"] = nullable;
    map["isInterfaceRequest"] = isInterfaceRequest;
    map["identifier"] = identifier;
    map["typeKey"] = typeKey;
    return map;
  }
}


class StructField extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(64, 0)
  ];
  DeclarationData declData = null;
  Type type = null;
  DefaultFieldValue defaultValue = null;
  int offset = 0;
  int bit = 0;
  int minVersion = 0;

  StructField() : super(kVersions.last.size);

  static StructField deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static StructField decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructField result = new StructField();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
        result.type = Type.decode(decoder0, 16);
        if (result.type == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    if (mainDataHeader.version >= 0) {
      
        result.defaultValue = DefaultFieldValue.decode(decoder0, 32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt32(48);
    }
    if (mainDataHeader.version >= 0) {
      
      result.bit = decoder0.decodeInt8(52);
    }
    if (mainDataHeader.version >= 0) {
      
      result.minVersion = decoder0.decodeUint32(56);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct StructField: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(type, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "type of struct StructField: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(defaultValue, 32, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "defaultValue of struct StructField: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt32(offset, 48);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "offset of struct StructField: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt8(bit, 52);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "bit of struct StructField: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(minVersion, 56);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "minVersion of struct StructField: $e";
      rethrow;
    }
  }

  String toString() {
    return "StructField("
           "declData: $declData" ", "
           "type: $type" ", "
           "defaultValue: $defaultValue" ", "
           "offset: $offset" ", "
           "bit: $bit" ", "
           "minVersion: $minVersion" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["type"] = type;
    map["defaultValue"] = defaultValue;
    map["offset"] = offset;
    map["bit"] = bit;
    map["minVersion"] = minVersion;
    return map;
  }
}


class DefaultKeyword extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  DefaultKeyword() : super(kVersions.last.size);

  static DefaultKeyword deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static DefaultKeyword decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DefaultKeyword result = new DefaultKeyword();

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
    return "DefaultKeyword("")";
  }

  Map toJson() {
    Map map = new Map();
    return map;
  }
}


class StructVersion extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int versionNumber = 0;
  int numFields = 0;
  int numBytes = 0;

  StructVersion() : super(kVersions.last.size);

  static StructVersion deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static StructVersion decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructVersion result = new StructVersion();

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
      
      result.versionNumber = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.numFields = decoder0.decodeUint32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.numBytes = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeUint32(versionNumber, 8);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "versionNumber of struct StructVersion: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(numFields, 12);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "numFields of struct StructVersion: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(numBytes, 16);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "numBytes of struct StructVersion: $e";
      rethrow;
    }
  }

  String toString() {
    return "StructVersion("
           "versionNumber: $versionNumber" ", "
           "numFields: $numFields" ", "
           "numBytes: $numBytes" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["versionNumber"] = versionNumber;
    map["numFields"] = numFields;
    map["numBytes"] = numBytes;
    return map;
  }
}


class MojomStruct extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  DeclarationData declData = null;
  List<StructField> fields = null;
  List<StructVersion> versionInfo = null;

  MojomStruct() : super(kVersions.last.size);

  static MojomStruct deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomStruct decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomStruct result = new MojomStruct();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.fields = new List<StructField>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.fields[i1] = StructField.decode(decoder2);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      if (decoder1 == null) {
        result.versionInfo = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.versionInfo = new List<StructVersion>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.versionInfo[i1] = StructVersion.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct MojomStruct: $e";
      rethrow;
    }
    try {
      if (fields == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encodePointerArray(fields.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < fields.length; ++i0) {
          encoder1.encodeStruct(fields[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fields of struct MojomStruct: $e";
      rethrow;
    }
    try {
      if (versionInfo == null) {
        encoder0.encodeNullPointer(24, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(versionInfo.length, 24, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < versionInfo.length; ++i0) {
          encoder1.encodeStruct(versionInfo[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "versionInfo of struct MojomStruct: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomStruct("
           "declData: $declData" ", "
           "fields: $fields" ", "
           "versionInfo: $versionInfo" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["fields"] = fields;
    map["versionInfo"] = versionInfo;
    return map;
  }
}


class UnionField extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  DeclarationData declData = null;
  Type type = null;
  int tag = 0;

  UnionField() : super(kVersions.last.size);

  static UnionField deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static UnionField decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UnionField result = new UnionField();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
        result.type = Type.decode(decoder0, 16);
        if (result.type == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    if (mainDataHeader.version >= 0) {
      
      result.tag = decoder0.decodeUint32(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct UnionField: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(type, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "type of struct UnionField: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(tag, 32);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "tag of struct UnionField: $e";
      rethrow;
    }
  }

  String toString() {
    return "UnionField("
           "declData: $declData" ", "
           "type: $type" ", "
           "tag: $tag" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["type"] = type;
    map["tag"] = tag;
    return map;
  }
}


class MojomUnion extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  DeclarationData declData = null;
  List<UnionField> fields = null;

  MojomUnion() : super(kVersions.last.size);

  static MojomUnion deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomUnion decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomUnion result = new MojomUnion();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.fields = new List<UnionField>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.fields[i1] = UnionField.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct MojomUnion: $e";
      rethrow;
    }
    try {
      if (fields == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encodePointerArray(fields.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < fields.length; ++i0) {
          encoder1.encodeStruct(fields[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fields of struct MojomUnion: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomUnion("
           "declData: $declData" ", "
           "fields: $fields" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["fields"] = fields;
    return map;
  }
}


class EnumValue extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(48, 0)
  ];
  DeclarationData declData = null;
  String enumTypeKey = null;
  Value initializerValue = null;
  int intValue = 0;

  EnumValue() : super(kVersions.last.size);

  static EnumValue deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static EnumValue decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EnumValue result = new EnumValue();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.enumTypeKey = decoder0.decodeString(16, false);
    }
    if (mainDataHeader.version >= 0) {
      
        result.initializerValue = Value.decode(decoder0, 24);
    }
    if (mainDataHeader.version >= 0) {
      
      result.intValue = decoder0.decodeInt32(40);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct EnumValue: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(enumTypeKey, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "enumTypeKey of struct EnumValue: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(initializerValue, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "initializerValue of struct EnumValue: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt32(intValue, 40);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "intValue of struct EnumValue: $e";
      rethrow;
    }
  }

  String toString() {
    return "EnumValue("
           "declData: $declData" ", "
           "enumTypeKey: $enumTypeKey" ", "
           "initializerValue: $initializerValue" ", "
           "intValue: $intValue" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["enumTypeKey"] = enumTypeKey;
    map["initializerValue"] = initializerValue;
    map["intValue"] = intValue;
    return map;
  }
}


class MojomEnum extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  DeclarationData declData = null;
  List<EnumValue> values = null;

  MojomEnum() : super(kVersions.last.size);

  static MojomEnum deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomEnum decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomEnum result = new MojomEnum();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.values = new List<EnumValue>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.values[i1] = EnumValue.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct MojomEnum: $e";
      rethrow;
    }
    try {
      if (values == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encodePointerArray(values.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < values.length; ++i0) {
          encoder1.encodeStruct(values[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "values of struct MojomEnum: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomEnum("
           "declData: $declData" ", "
           "values: $values" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["values"] = values;
    return map;
  }
}


class MojomMethod extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  DeclarationData declData = null;
  MojomStruct parameters = null;
  MojomStruct responseParams = null;
  int ordinal = 0;
  int minVersion = 0;

  MojomMethod() : super(kVersions.last.size);

  static MojomMethod deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomMethod decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomMethod result = new MojomMethod();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.parameters = MojomStruct.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.responseParams = MojomStruct.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.ordinal = decoder0.decodeUint32(32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.minVersion = decoder0.decodeUint32(36);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct MojomMethod: $e";
      rethrow;
    }
    try {
      encoder0.encodeStruct(parameters, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "parameters of struct MojomMethod: $e";
      rethrow;
    }
    try {
      encoder0.encodeStruct(responseParams, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "responseParams of struct MojomMethod: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(ordinal, 32);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "ordinal of struct MojomMethod: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(minVersion, 36);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "minVersion of struct MojomMethod: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomMethod("
           "declData: $declData" ", "
           "parameters: $parameters" ", "
           "responseParams: $responseParams" ", "
           "ordinal: $ordinal" ", "
           "minVersion: $minVersion" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["parameters"] = parameters;
    map["responseParams"] = responseParams;
    map["ordinal"] = ordinal;
    map["minVersion"] = minVersion;
    return map;
  }
}


class MojomInterface extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  DeclarationData declData = null;
  String serviceName_ = null;
  Map<int, MojomMethod> methods = null;
  int currentVersion = 0;

  MojomInterface() : super(kVersions.last.size);

  static MojomInterface deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomInterface decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomInterface result = new MojomInterface();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.serviceName_ = decoder0.decodeString(16, true);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<MojomMethod> values0;
        {
          
          keys0 = decoder1.decodeUint32Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(keys0.length);
            values0 = new List<MojomMethod>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              values0[i2] = MojomMethod.decode(decoder3);
            }
          }
        }
        result.methods = new Map<int, MojomMethod>.fromIterables(
            keys0, values0);
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.currentVersion = decoder0.decodeUint32(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct MojomInterface: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(serviceName_, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "serviceName_ of struct MojomInterface: $e";
      rethrow;
    }
    try {
      if (methods == null) {
        encoder0.encodeNullPointer(24, false);
      } else {
        var encoder1 = encoder0.encoderForMap(24);
        var keys0 = methods.keys.toList();
        var values0 = methods.values.toList();
        encoder1.encodeUint32Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        
        {
          var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < values0.length; ++i1) {
            encoder2.encodeStruct(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          }
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "methods of struct MojomInterface: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(currentVersion, 32);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "currentVersion of struct MojomInterface: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomInterface("
           "declData: $declData" ", "
           "serviceName_: $serviceName_" ", "
           "methods: $methods" ", "
           "currentVersion: $currentVersion" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["serviceName_"] = serviceName_;
    map["methods"] = methods;
    map["currentVersion"] = currentVersion;
    return map;
  }
}


class UserValueReference extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String identifier = null;
  String valueKey = null;

  UserValueReference() : super(kVersions.last.size);

  static UserValueReference deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static UserValueReference decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UserValueReference result = new UserValueReference();

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
      
      result.identifier = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.valueKey = decoder0.decodeString(16, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(identifier, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "identifier of struct UserValueReference: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(valueKey, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "valueKey of struct UserValueReference: $e";
      rethrow;
    }
  }

  String toString() {
    return "UserValueReference("
           "identifier: $identifier" ", "
           "valueKey: $valueKey" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["identifier"] = identifier;
    map["valueKey"] = valueKey;
    return map;
  }
}


class DeclaredConstant extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(48, 0)
  ];
  DeclarationData declData = null;
  Type type = null;
  Value value = null;

  DeclaredConstant() : super(kVersions.last.size);

  static DeclaredConstant deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static DeclaredConstant decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DeclaredConstant result = new DeclaredConstant();

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
      result.declData = DeclarationData.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
        result.type = Type.decode(decoder0, 16);
        if (result.type == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Type.');
        }
    }
    if (mainDataHeader.version >= 0) {
      
        result.value = Value.decode(decoder0, 32);
        if (result.value == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable Value.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(declData, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declData of struct DeclaredConstant: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(type, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "type of struct DeclaredConstant: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(value, 32, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "value of struct DeclaredConstant: $e";
      rethrow;
    }
  }

  String toString() {
    return "DeclaredConstant("
           "declData: $declData" ", "
           "type: $type" ", "
           "value: $value" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["declData"] = declData;
    map["type"] = type;
    map["value"] = value;
    return map;
  }
}


class Attribute extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  String key = null;
  LiteralValue value = null;

  Attribute() : super(kVersions.last.size);

  static Attribute deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static Attribute decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Attribute result = new Attribute();

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
      
      result.key = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
        result.value = LiteralValue.decode(decoder0, 16);
        if (result.value == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable LiteralValue.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(key, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "key of struct Attribute: $e";
      rethrow;
    }
    try {
      encoder0.encodeUnion(value, 16, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "value of struct Attribute: $e";
      rethrow;
    }
  }

  String toString() {
    return "Attribute("
           "key: $key" ", "
           "value: $value" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["key"] = key;
    map["value"] = value;
    return map;
  }
}


class DeclarationData extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(64, 0)
  ];
  List<Attribute> attributes = null;
  String shortName = null;
  String fullIdentifier = null;
  int declaredOrdinal = -1;
  int declarationOrder = -1;
  SourceFileInfo sourceFileInfo = null;
  ContainedDeclarations containedDeclarations = null;
  String containerTypeKey = null;

  DeclarationData() : super(kVersions.last.size);

  static DeclarationData deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static DeclarationData decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DeclarationData result = new DeclarationData();

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
        result.attributes = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.attributes = new List<Attribute>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.attributes[i1] = Attribute.decode(decoder2);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.shortName = decoder0.decodeString(16, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.fullIdentifier = decoder0.decodeString(24, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.declaredOrdinal = decoder0.decodeInt32(32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.declarationOrder = decoder0.decodeInt32(36);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(40, true);
      result.sourceFileInfo = SourceFileInfo.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(48, true);
      result.containedDeclarations = ContainedDeclarations.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.containerTypeKey = decoder0.decodeString(56, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (attributes == null) {
        encoder0.encodeNullPointer(8, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(attributes.length, 8, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < attributes.length; ++i0) {
          encoder1.encodeStruct(attributes[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "attributes of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(shortName, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "shortName of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(fullIdentifier, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fullIdentifier of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt32(declaredOrdinal, 32);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declaredOrdinal of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeInt32(declarationOrder, 36);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declarationOrder of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeStruct(sourceFileInfo, 40, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "sourceFileInfo of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeStruct(containedDeclarations, 48, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "containedDeclarations of struct DeclarationData: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(containerTypeKey, 56, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "containerTypeKey of struct DeclarationData: $e";
      rethrow;
    }
  }

  String toString() {
    return "DeclarationData("
           "attributes: $attributes" ", "
           "shortName: $shortName" ", "
           "fullIdentifier: $fullIdentifier" ", "
           "declaredOrdinal: $declaredOrdinal" ", "
           "declarationOrder: $declarationOrder" ", "
           "sourceFileInfo: $sourceFileInfo" ", "
           "containedDeclarations: $containedDeclarations" ", "
           "containerTypeKey: $containerTypeKey" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["attributes"] = attributes;
    map["shortName"] = shortName;
    map["fullIdentifier"] = fullIdentifier;
    map["declaredOrdinal"] = declaredOrdinal;
    map["declarationOrder"] = declarationOrder;
    map["sourceFileInfo"] = sourceFileInfo;
    map["containedDeclarations"] = containedDeclarations;
    map["containerTypeKey"] = containerTypeKey;
    return map;
  }
}


class SourceFileInfo extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String fileName = null;
  int lineNumber = 0;
  int columnNumber = 0;

  SourceFileInfo() : super(kVersions.last.size);

  static SourceFileInfo deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static SourceFileInfo decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SourceFileInfo result = new SourceFileInfo();

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
      
      result.fileName = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.lineNumber = decoder0.decodeUint32(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.columnNumber = decoder0.decodeUint32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(fileName, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fileName of struct SourceFileInfo: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(lineNumber, 16);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "lineNumber of struct SourceFileInfo: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(columnNumber, 20);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "columnNumber of struct SourceFileInfo: $e";
      rethrow;
    }
  }

  String toString() {
    return "SourceFileInfo("
           "fileName: $fileName" ", "
           "lineNumber: $lineNumber" ", "
           "columnNumber: $columnNumber" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["fileName"] = fileName;
    map["lineNumber"] = lineNumber;
    map["columnNumber"] = columnNumber;
    return map;
  }
}


class ContainedDeclarations extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  List<String> enums = null;
  List<String> constants = null;

  ContainedDeclarations() : super(kVersions.last.size);

  static ContainedDeclarations deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ContainedDeclarations decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ContainedDeclarations result = new ContainedDeclarations();

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
        result.enums = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.enums = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.enums[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.constants = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.constants = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.constants[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (enums == null) {
        encoder0.encodeNullPointer(8, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(enums.length, 8, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < enums.length; ++i0) {
          encoder1.encodeString(enums[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "enums of struct ContainedDeclarations: $e";
      rethrow;
    }
    try {
      if (constants == null) {
        encoder0.encodeNullPointer(16, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(constants.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < constants.length; ++i0) {
          encoder1.encodeString(constants[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "constants of struct ContainedDeclarations: $e";
      rethrow;
    }
  }

  String toString() {
    return "ContainedDeclarations("
           "enums: $enums" ", "
           "constants: $constants" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["enums"] = enums;
    map["constants"] = constants;
    return map;
  }
}


class ServiceTypeInfo extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String topLevelInterface = null;
  List<String> completeTypeSet = null;

  ServiceTypeInfo() : super(kVersions.last.size);

  static ServiceTypeInfo deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static ServiceTypeInfo decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceTypeInfo result = new ServiceTypeInfo();

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
      
      result.topLevelInterface = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.completeTypeSet = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.completeTypeSet[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(topLevelInterface, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "topLevelInterface of struct ServiceTypeInfo: $e";
      rethrow;
    }
    try {
      if (completeTypeSet == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encodePointerArray(completeTypeSet.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < completeTypeSet.length; ++i0) {
          encoder1.encodeString(completeTypeSet[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "completeTypeSet of struct ServiceTypeInfo: $e";
      rethrow;
    }
  }

  String toString() {
    return "ServiceTypeInfo("
           "topLevelInterface: $topLevelInterface" ", "
           "completeTypeSet: $completeTypeSet" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["topLevelInterface"] = topLevelInterface;
    map["completeTypeSet"] = completeTypeSet;
    return map;
  }
}


class RuntimeTypeInfo extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  Map<String, ServiceTypeInfo> servicesByName = null;
  Map<String, UserDefinedType> typeMap = null;

  RuntimeTypeInfo() : super(kVersions.last.size);

  static RuntimeTypeInfo deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static RuntimeTypeInfo decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    RuntimeTypeInfo result = new RuntimeTypeInfo();

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
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<ServiceTypeInfo> values0;
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
            var si2 = decoder2.decodeDataHeaderForPointerArray(keys0.length);
            values0 = new List<ServiceTypeInfo>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              values0[i2] = ServiceTypeInfo.decode(decoder3);
            }
          }
        }
        result.servicesByName = new Map<String, ServiceTypeInfo>.fromIterables(
            keys0, values0);
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<UserDefinedType> values0;
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
            values0 = new List<UserDefinedType>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
                values0[i2] = UserDefinedType.decode(decoder2, bindings.ArrayDataHeader.kHeaderSize + bindings.kUnionSize * i2);
                if (values0[i2] == null) {
                  throw new bindings.MojoCodecError(
                    'Trying to decode null union for non-nullable UserDefinedType.');
                }
            }
          }
        }
        result.typeMap = new Map<String, UserDefinedType>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (servicesByName == null) {
        encoder0.encodeNullPointer(8, false);
      } else {
        var encoder1 = encoder0.encoderForMap(8);
        var keys0 = servicesByName.keys.toList();
        var values0 = servicesByName.values.toList();
        
        {
          var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < keys0.length; ++i1) {
            encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          }
        }
        
        {
          var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < values0.length; ++i1) {
            encoder2.encodeStruct(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          }
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "servicesByName of struct RuntimeTypeInfo: $e";
      rethrow;
    }
    try {
      if (typeMap == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encoderForMap(16);
        var keys0 = typeMap.keys.toList();
        var values0 = typeMap.values.toList();
        
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
          "typeMap of struct RuntimeTypeInfo: $e";
      rethrow;
    }
  }

  String toString() {
    return "RuntimeTypeInfo("
           "servicesByName: $servicesByName" ", "
           "typeMap: $typeMap" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["servicesByName"] = servicesByName;
    map["typeMap"] = typeMap;
    return map;
  }
}



enum TypeTag {
  simpleType,
  stringType,
  arrayType,
  mapType,
  handleType,
  typeReference,
  unknown
}

class Type extends bindings.Union {
  static final _tagToInt = const {
    TypeTag.simpleType: 0,
    TypeTag.stringType: 1,
    TypeTag.arrayType: 2,
    TypeTag.mapType: 3,
    TypeTag.handleType: 4,
    TypeTag.typeReference: 5,
  };

  static final _intToTag = const {
    0: TypeTag.simpleType,
    1: TypeTag.stringType,
    2: TypeTag.arrayType,
    3: TypeTag.mapType,
    4: TypeTag.handleType,
    5: TypeTag.typeReference,
  };

  var _data;
  TypeTag _tag = TypeTag.unknown;

  TypeTag get tag => _tag;
  SimpleType get simpleType {
    if (_tag != TypeTag.simpleType) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.simpleType);
    }
    return _data;
  }

  set simpleType(SimpleType value) {
    _tag = TypeTag.simpleType;
    _data = value;
  }
  StringType get stringType {
    if (_tag != TypeTag.stringType) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.stringType);
    }
    return _data;
  }

  set stringType(StringType value) {
    _tag = TypeTag.stringType;
    _data = value;
  }
  ArrayType get arrayType {
    if (_tag != TypeTag.arrayType) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.arrayType);
    }
    return _data;
  }

  set arrayType(ArrayType value) {
    _tag = TypeTag.arrayType;
    _data = value;
  }
  MapType get mapType {
    if (_tag != TypeTag.mapType) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.mapType);
    }
    return _data;
  }

  set mapType(MapType value) {
    _tag = TypeTag.mapType;
    _data = value;
  }
  HandleType get handleType {
    if (_tag != TypeTag.handleType) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.handleType);
    }
    return _data;
  }

  set handleType(HandleType value) {
    _tag = TypeTag.handleType;
    _data = value;
  }
  TypeReference get typeReference {
    if (_tag != TypeTag.typeReference) {
      throw new bindings.UnsetUnionTagError(_tag, TypeTag.typeReference);
    }
    return _data;
  }

  set typeReference(TypeReference value) {
    _tag = TypeTag.typeReference;
    _data = value;
  }

  static Type decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    Type result = new Type();

    
    TypeTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case TypeTag.simpleType:
        
          result.simpleType = SimpleType.decode(decoder0, offset + 8);
          if (result.simpleType == null) {
            throw new bindings.MojoCodecError(
              'Trying to decode null union for non-nullable SimpleType.');
          }
        break;
      case TypeTag.stringType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.stringType = StringType.decode(decoder1);
        break;
      case TypeTag.arrayType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.arrayType = ArrayType.decode(decoder1);
        break;
      case TypeTag.mapType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.mapType = MapType.decode(decoder1);
        break;
      case TypeTag.handleType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.handleType = HandleType.decode(decoder1);
        break;
      case TypeTag.typeReference:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.typeReference = TypeReference.decode(decoder1);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case TypeTag.simpleType:
        encoder0.encodeEnum(simpleType, offset + 8);
        break;
      case TypeTag.stringType:
        encoder0.encodeStruct(stringType, offset + 8, false);
        break;
      case TypeTag.arrayType:
        encoder0.encodeStruct(arrayType, offset + 8, false);
        break;
      case TypeTag.mapType:
        encoder0.encodeStruct(mapType, offset + 8, false);
        break;
      case TypeTag.handleType:
        encoder0.encodeStruct(handleType, offset + 8, false);
        break;
      case TypeTag.typeReference:
        encoder0.encodeStruct(typeReference, offset + 8, false);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "Type(";
    switch (_tag) {
      case TypeTag.simpleType:
        result += "simpleType";
        break;
      case TypeTag.stringType:
        result += "stringType";
        break;
      case TypeTag.arrayType:
        result += "arrayType";
        break;
      case TypeTag.mapType:
        result += "mapType";
        break;
      case TypeTag.handleType:
        result += "handleType";
        break;
      case TypeTag.typeReference:
        result += "typeReference";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


enum UserDefinedTypeTag {
  enumType,
  structType,
  unionType,
  interfaceType,
  unknown
}

class UserDefinedType extends bindings.Union {
  static final _tagToInt = const {
    UserDefinedTypeTag.enumType: 0,
    UserDefinedTypeTag.structType: 1,
    UserDefinedTypeTag.unionType: 2,
    UserDefinedTypeTag.interfaceType: 3,
  };

  static final _intToTag = const {
    0: UserDefinedTypeTag.enumType,
    1: UserDefinedTypeTag.structType,
    2: UserDefinedTypeTag.unionType,
    3: UserDefinedTypeTag.interfaceType,
  };

  var _data;
  UserDefinedTypeTag _tag = UserDefinedTypeTag.unknown;

  UserDefinedTypeTag get tag => _tag;
  MojomEnum get enumType {
    if (_tag != UserDefinedTypeTag.enumType) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedTypeTag.enumType);
    }
    return _data;
  }

  set enumType(MojomEnum value) {
    _tag = UserDefinedTypeTag.enumType;
    _data = value;
  }
  MojomStruct get structType {
    if (_tag != UserDefinedTypeTag.structType) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedTypeTag.structType);
    }
    return _data;
  }

  set structType(MojomStruct value) {
    _tag = UserDefinedTypeTag.structType;
    _data = value;
  }
  MojomUnion get unionType {
    if (_tag != UserDefinedTypeTag.unionType) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedTypeTag.unionType);
    }
    return _data;
  }

  set unionType(MojomUnion value) {
    _tag = UserDefinedTypeTag.unionType;
    _data = value;
  }
  MojomInterface get interfaceType {
    if (_tag != UserDefinedTypeTag.interfaceType) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedTypeTag.interfaceType);
    }
    return _data;
  }

  set interfaceType(MojomInterface value) {
    _tag = UserDefinedTypeTag.interfaceType;
    _data = value;
  }

  static UserDefinedType decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    UserDefinedType result = new UserDefinedType();

    
    UserDefinedTypeTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case UserDefinedTypeTag.enumType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.enumType = MojomEnum.decode(decoder1);
        break;
      case UserDefinedTypeTag.structType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.structType = MojomStruct.decode(decoder1);
        break;
      case UserDefinedTypeTag.unionType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.unionType = MojomUnion.decode(decoder1);
        break;
      case UserDefinedTypeTag.interfaceType:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.interfaceType = MojomInterface.decode(decoder1);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case UserDefinedTypeTag.enumType:
        encoder0.encodeStruct(enumType, offset + 8, false);
        break;
      case UserDefinedTypeTag.structType:
        encoder0.encodeStruct(structType, offset + 8, false);
        break;
      case UserDefinedTypeTag.unionType:
        encoder0.encodeStruct(unionType, offset + 8, false);
        break;
      case UserDefinedTypeTag.interfaceType:
        encoder0.encodeStruct(interfaceType, offset + 8, false);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "UserDefinedType(";
    switch (_tag) {
      case UserDefinedTypeTag.enumType:
        result += "enumType";
        break;
      case UserDefinedTypeTag.structType:
        result += "structType";
        break;
      case UserDefinedTypeTag.unionType:
        result += "unionType";
        break;
      case UserDefinedTypeTag.interfaceType:
        result += "interfaceType";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


enum DefaultFieldValueTag {
  value,
  defaultKeyword,
  unknown
}

class DefaultFieldValue extends bindings.Union {
  static final _tagToInt = const {
    DefaultFieldValueTag.value: 0,
    DefaultFieldValueTag.defaultKeyword: 1,
  };

  static final _intToTag = const {
    0: DefaultFieldValueTag.value,
    1: DefaultFieldValueTag.defaultKeyword,
  };

  var _data;
  DefaultFieldValueTag _tag = DefaultFieldValueTag.unknown;

  DefaultFieldValueTag get tag => _tag;
  Value get value {
    if (_tag != DefaultFieldValueTag.value) {
      throw new bindings.UnsetUnionTagError(_tag, DefaultFieldValueTag.value);
    }
    return _data;
  }

  set value(Value value) {
    _tag = DefaultFieldValueTag.value;
    _data = value;
  }
  DefaultKeyword get defaultKeyword {
    if (_tag != DefaultFieldValueTag.defaultKeyword) {
      throw new bindings.UnsetUnionTagError(_tag, DefaultFieldValueTag.defaultKeyword);
    }
    return _data;
  }

  set defaultKeyword(DefaultKeyword value) {
    _tag = DefaultFieldValueTag.defaultKeyword;
    _data = value;
  }

  static DefaultFieldValue decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    DefaultFieldValue result = new DefaultFieldValue();

    
    DefaultFieldValueTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case DefaultFieldValueTag.value:
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.value = Value.decode(decoder1, 0);
        break;
      case DefaultFieldValueTag.defaultKeyword:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.defaultKeyword = DefaultKeyword.decode(decoder1);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case DefaultFieldValueTag.value:
        encoder0.encodeNestedUnion(value, offset + 8, false);
        break;
      case DefaultFieldValueTag.defaultKeyword:
        encoder0.encodeStruct(defaultKeyword, offset + 8, false);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "DefaultFieldValue(";
    switch (_tag) {
      case DefaultFieldValueTag.value:
        result += "value";
        break;
      case DefaultFieldValueTag.defaultKeyword:
        result += "defaultKeyword";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


enum ValueTag {
  literalValue,
  userValueReference,
  builtinValue,
  unknown
}

class Value extends bindings.Union {
  static final _tagToInt = const {
    ValueTag.literalValue: 0,
    ValueTag.userValueReference: 1,
    ValueTag.builtinValue: 2,
  };

  static final _intToTag = const {
    0: ValueTag.literalValue,
    1: ValueTag.userValueReference,
    2: ValueTag.builtinValue,
  };

  var _data;
  ValueTag _tag = ValueTag.unknown;

  ValueTag get tag => _tag;
  LiteralValue get literalValue {
    if (_tag != ValueTag.literalValue) {
      throw new bindings.UnsetUnionTagError(_tag, ValueTag.literalValue);
    }
    return _data;
  }

  set literalValue(LiteralValue value) {
    _tag = ValueTag.literalValue;
    _data = value;
  }
  UserValueReference get userValueReference {
    if (_tag != ValueTag.userValueReference) {
      throw new bindings.UnsetUnionTagError(_tag, ValueTag.userValueReference);
    }
    return _data;
  }

  set userValueReference(UserValueReference value) {
    _tag = ValueTag.userValueReference;
    _data = value;
  }
  BuiltinConstantValue get builtinValue {
    if (_tag != ValueTag.builtinValue) {
      throw new bindings.UnsetUnionTagError(_tag, ValueTag.builtinValue);
    }
    return _data;
  }

  set builtinValue(BuiltinConstantValue value) {
    _tag = ValueTag.builtinValue;
    _data = value;
  }

  static Value decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    Value result = new Value();

    
    ValueTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case ValueTag.literalValue:
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.literalValue = LiteralValue.decode(decoder1, 0);
        break;
      case ValueTag.userValueReference:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.userValueReference = UserValueReference.decode(decoder1);
        break;
      case ValueTag.builtinValue:
        
          result.builtinValue = BuiltinConstantValue.decode(decoder0, offset + 8);
          if (result.builtinValue == null) {
            throw new bindings.MojoCodecError(
              'Trying to decode null union for non-nullable BuiltinConstantValue.');
          }
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case ValueTag.literalValue:
        encoder0.encodeNestedUnion(literalValue, offset + 8, false);
        break;
      case ValueTag.userValueReference:
        encoder0.encodeStruct(userValueReference, offset + 8, false);
        break;
      case ValueTag.builtinValue:
        encoder0.encodeEnum(builtinValue, offset + 8);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "Value(";
    switch (_tag) {
      case ValueTag.literalValue:
        result += "literalValue";
        break;
      case ValueTag.userValueReference:
        result += "userValueReference";
        break;
      case ValueTag.builtinValue:
        result += "builtinValue";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


enum LiteralValueTag {
  boolValue,
  doubleValue,
  floatValue,
  int8Value,
  int16Value,
  int32Value,
  int64Value,
  stringValue,
  uint8Value,
  uint16Value,
  uint32Value,
  uint64Value,
  unknown
}

class LiteralValue extends bindings.Union {
  static final _tagToInt = const {
    LiteralValueTag.boolValue: 0,
    LiteralValueTag.doubleValue: 1,
    LiteralValueTag.floatValue: 2,
    LiteralValueTag.int8Value: 3,
    LiteralValueTag.int16Value: 4,
    LiteralValueTag.int32Value: 5,
    LiteralValueTag.int64Value: 6,
    LiteralValueTag.stringValue: 7,
    LiteralValueTag.uint8Value: 8,
    LiteralValueTag.uint16Value: 9,
    LiteralValueTag.uint32Value: 10,
    LiteralValueTag.uint64Value: 11,
  };

  static final _intToTag = const {
    0: LiteralValueTag.boolValue,
    1: LiteralValueTag.doubleValue,
    2: LiteralValueTag.floatValue,
    3: LiteralValueTag.int8Value,
    4: LiteralValueTag.int16Value,
    5: LiteralValueTag.int32Value,
    6: LiteralValueTag.int64Value,
    7: LiteralValueTag.stringValue,
    8: LiteralValueTag.uint8Value,
    9: LiteralValueTag.uint16Value,
    10: LiteralValueTag.uint32Value,
    11: LiteralValueTag.uint64Value,
  };

  var _data;
  LiteralValueTag _tag = LiteralValueTag.unknown;

  LiteralValueTag get tag => _tag;
  bool get boolValue {
    if (_tag != LiteralValueTag.boolValue) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.boolValue);
    }
    return _data;
  }

  set boolValue(bool value) {
    _tag = LiteralValueTag.boolValue;
    _data = value;
  }
  double get doubleValue {
    if (_tag != LiteralValueTag.doubleValue) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.doubleValue);
    }
    return _data;
  }

  set doubleValue(double value) {
    _tag = LiteralValueTag.doubleValue;
    _data = value;
  }
  double get floatValue {
    if (_tag != LiteralValueTag.floatValue) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.floatValue);
    }
    return _data;
  }

  set floatValue(double value) {
    _tag = LiteralValueTag.floatValue;
    _data = value;
  }
  int get int8Value {
    if (_tag != LiteralValueTag.int8Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.int8Value);
    }
    return _data;
  }

  set int8Value(int value) {
    _tag = LiteralValueTag.int8Value;
    _data = value;
  }
  int get int16Value {
    if (_tag != LiteralValueTag.int16Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.int16Value);
    }
    return _data;
  }

  set int16Value(int value) {
    _tag = LiteralValueTag.int16Value;
    _data = value;
  }
  int get int32Value {
    if (_tag != LiteralValueTag.int32Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.int32Value);
    }
    return _data;
  }

  set int32Value(int value) {
    _tag = LiteralValueTag.int32Value;
    _data = value;
  }
  int get int64Value {
    if (_tag != LiteralValueTag.int64Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.int64Value);
    }
    return _data;
  }

  set int64Value(int value) {
    _tag = LiteralValueTag.int64Value;
    _data = value;
  }
  String get stringValue {
    if (_tag != LiteralValueTag.stringValue) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.stringValue);
    }
    return _data;
  }

  set stringValue(String value) {
    _tag = LiteralValueTag.stringValue;
    _data = value;
  }
  int get uint8Value {
    if (_tag != LiteralValueTag.uint8Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.uint8Value);
    }
    return _data;
  }

  set uint8Value(int value) {
    _tag = LiteralValueTag.uint8Value;
    _data = value;
  }
  int get uint16Value {
    if (_tag != LiteralValueTag.uint16Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.uint16Value);
    }
    return _data;
  }

  set uint16Value(int value) {
    _tag = LiteralValueTag.uint16Value;
    _data = value;
  }
  int get uint32Value {
    if (_tag != LiteralValueTag.uint32Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.uint32Value);
    }
    return _data;
  }

  set uint32Value(int value) {
    _tag = LiteralValueTag.uint32Value;
    _data = value;
  }
  int get uint64Value {
    if (_tag != LiteralValueTag.uint64Value) {
      throw new bindings.UnsetUnionTagError(_tag, LiteralValueTag.uint64Value);
    }
    return _data;
  }

  set uint64Value(int value) {
    _tag = LiteralValueTag.uint64Value;
    _data = value;
  }

  static LiteralValue decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    LiteralValue result = new LiteralValue();

    
    LiteralValueTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case LiteralValueTag.boolValue:
        
        result.boolValue = decoder0.decodeBool(offset + 8, 0);
        break;
      case LiteralValueTag.doubleValue:
        
        result.doubleValue = decoder0.decodeDouble(offset + 8);
        break;
      case LiteralValueTag.floatValue:
        
        result.floatValue = decoder0.decodeFloat(offset + 8);
        break;
      case LiteralValueTag.int8Value:
        
        result.int8Value = decoder0.decodeInt8(offset + 8);
        break;
      case LiteralValueTag.int16Value:
        
        result.int16Value = decoder0.decodeInt16(offset + 8);
        break;
      case LiteralValueTag.int32Value:
        
        result.int32Value = decoder0.decodeInt32(offset + 8);
        break;
      case LiteralValueTag.int64Value:
        
        result.int64Value = decoder0.decodeInt64(offset + 8);
        break;
      case LiteralValueTag.stringValue:
        
        result.stringValue = decoder0.decodeString(offset + 8, false);
        break;
      case LiteralValueTag.uint8Value:
        
        result.uint8Value = decoder0.decodeUint8(offset + 8);
        break;
      case LiteralValueTag.uint16Value:
        
        result.uint16Value = decoder0.decodeUint16(offset + 8);
        break;
      case LiteralValueTag.uint32Value:
        
        result.uint32Value = decoder0.decodeUint32(offset + 8);
        break;
      case LiteralValueTag.uint64Value:
        
        result.uint64Value = decoder0.decodeUint64(offset + 8);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case LiteralValueTag.boolValue:
        encoder0.encodeBool(boolValue, offset + 8, 0);
        break;
      case LiteralValueTag.doubleValue:
        encoder0.encodeDouble(doubleValue, offset + 8);
        break;
      case LiteralValueTag.floatValue:
        encoder0.encodeFloat(floatValue, offset + 8);
        break;
      case LiteralValueTag.int8Value:
        encoder0.encodeInt8(int8Value, offset + 8);
        break;
      case LiteralValueTag.int16Value:
        encoder0.encodeInt16(int16Value, offset + 8);
        break;
      case LiteralValueTag.int32Value:
        encoder0.encodeInt32(int32Value, offset + 8);
        break;
      case LiteralValueTag.int64Value:
        encoder0.encodeInt64(int64Value, offset + 8);
        break;
      case LiteralValueTag.stringValue:
        encoder0.encodeString(stringValue, offset + 8, false);
        break;
      case LiteralValueTag.uint8Value:
        encoder0.encodeUint8(uint8Value, offset + 8);
        break;
      case LiteralValueTag.uint16Value:
        encoder0.encodeUint16(uint16Value, offset + 8);
        break;
      case LiteralValueTag.uint32Value:
        encoder0.encodeUint32(uint32Value, offset + 8);
        break;
      case LiteralValueTag.uint64Value:
        encoder0.encodeUint64(uint64Value, offset + 8);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "LiteralValue(";
    switch (_tag) {
      case LiteralValueTag.boolValue:
        result += "boolValue";
        break;
      case LiteralValueTag.doubleValue:
        result += "doubleValue";
        break;
      case LiteralValueTag.floatValue:
        result += "floatValue";
        break;
      case LiteralValueTag.int8Value:
        result += "int8Value";
        break;
      case LiteralValueTag.int16Value:
        result += "int16Value";
        break;
      case LiteralValueTag.int32Value:
        result += "int32Value";
        break;
      case LiteralValueTag.int64Value:
        result += "int64Value";
        break;
      case LiteralValueTag.stringValue:
        result += "stringValue";
        break;
      case LiteralValueTag.uint8Value:
        result += "uint8Value";
        break;
      case LiteralValueTag.uint16Value:
        result += "uint16Value";
        break;
      case LiteralValueTag.uint32Value:
        result += "uint32Value";
        break;
      case LiteralValueTag.uint64Value:
        result += "uint64Value";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


enum UserDefinedValueTag {
  enumValue,
  declaredConstant,
  unknown
}

class UserDefinedValue extends bindings.Union {
  static final _tagToInt = const {
    UserDefinedValueTag.enumValue: 0,
    UserDefinedValueTag.declaredConstant: 1,
  };

  static final _intToTag = const {
    0: UserDefinedValueTag.enumValue,
    1: UserDefinedValueTag.declaredConstant,
  };

  var _data;
  UserDefinedValueTag _tag = UserDefinedValueTag.unknown;

  UserDefinedValueTag get tag => _tag;
  EnumValue get enumValue {
    if (_tag != UserDefinedValueTag.enumValue) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedValueTag.enumValue);
    }
    return _data;
  }

  set enumValue(EnumValue value) {
    _tag = UserDefinedValueTag.enumValue;
    _data = value;
  }
  DeclaredConstant get declaredConstant {
    if (_tag != UserDefinedValueTag.declaredConstant) {
      throw new bindings.UnsetUnionTagError(_tag, UserDefinedValueTag.declaredConstant);
    }
    return _data;
  }

  set declaredConstant(DeclaredConstant value) {
    _tag = UserDefinedValueTag.declaredConstant;
    _data = value;
  }

  static UserDefinedValue decode(bindings.Decoder decoder0, int offset) {
    int size = decoder0.decodeUint32(offset);
    if (size == 0) {
      return null;
    }
    UserDefinedValue result = new UserDefinedValue();

    
    UserDefinedValueTag tag = _intToTag[decoder0.decodeUint32(offset + 4)];
    switch (tag) {
      case UserDefinedValueTag.enumValue:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.enumValue = EnumValue.decode(decoder1);
        break;
      case UserDefinedValueTag.declaredConstant:
        
        var decoder1 = decoder0.decodePointer(offset + 8, false);
        result.declaredConstant = DeclaredConstant.decode(decoder1);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $tag");
    }

    return result;
  }

  void encode(bindings.Encoder encoder0, int offset) {
    
    encoder0.encodeUint32(16, offset);
    encoder0.encodeUint32(_tagToInt[_tag], offset + 4);
    switch (_tag) {
      case UserDefinedValueTag.enumValue:
        encoder0.encodeStruct(enumValue, offset + 8, false);
        break;
      case UserDefinedValueTag.declaredConstant:
        encoder0.encodeStruct(declaredConstant, offset + 8, false);
        break;
      default:
        throw new bindings.MojoCodecError("Bad union tag: $_tag");
    }
  }

  String toString() {
    String result = "UserDefinedValue(";
    switch (_tag) {
      case UserDefinedValueTag.enumValue:
        result += "enumValue";
        break;
      case UserDefinedValueTag.declaredConstant:
        result += "declaredConstant";
        break;
      default:
        result += "unknown";
    }
    result += ": $_data)";
    return result;
  }
}


