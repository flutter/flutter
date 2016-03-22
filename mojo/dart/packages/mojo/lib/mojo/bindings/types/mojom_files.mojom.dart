// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mojom_files_mojom;
import 'package:mojo/bindings.dart' as bindings;

import 'package:mojo/mojo/bindings/types/mojom_types.mojom.dart' as mojom_types_mojom;



class MojomFile extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(64, 0)
  ];
  String fileName = null;
  String specifiedFileName = null;
  String moduleNamespace = null;
  List<mojom_types_mojom.Attribute> attributes = null;
  List<String> imports = null;
  KeysByType declaredMojomObjects = null;
  List<int> serializedRuntimeTypeInfo = null;

  MojomFile() : super(kVersions.last.size);

  static MojomFile deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomFile decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomFile result = new MojomFile();

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
      
      result.specifiedFileName = decoder0.decodeString(16, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.moduleNamespace = decoder0.decodeString(24, true);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      if (decoder1 == null) {
        result.attributes = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.attributes = new List<mojom_types_mojom.Attribute>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.attributes[i1] = mojom_types_mojom.Attribute.decode(decoder2);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.imports = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.imports = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.imports[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(48, false);
      result.declaredMojomObjects = KeysByType.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.serializedRuntimeTypeInfo = decoder0.decodeUint8Array(56, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeString(fileName, 8, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "fileName of struct MojomFile: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(specifiedFileName, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "specifiedFileName of struct MojomFile: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(moduleNamespace, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "moduleNamespace of struct MojomFile: $e";
      rethrow;
    }
    try {
      if (attributes == null) {
        encoder0.encodeNullPointer(32, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(attributes.length, 32, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < attributes.length; ++i0) {
          encoder1.encodeStruct(attributes[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "attributes of struct MojomFile: $e";
      rethrow;
    }
    try {
      if (imports == null) {
        encoder0.encodeNullPointer(40, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(imports.length, 40, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < imports.length; ++i0) {
          encoder1.encodeString(imports[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "imports of struct MojomFile: $e";
      rethrow;
    }
    try {
      encoder0.encodeStruct(declaredMojomObjects, 48, false);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "declaredMojomObjects of struct MojomFile: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint8Array(serializedRuntimeTypeInfo, 56, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "serializedRuntimeTypeInfo of struct MojomFile: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomFile("
           "fileName: $fileName" ", "
           "specifiedFileName: $specifiedFileName" ", "
           "moduleNamespace: $moduleNamespace" ", "
           "attributes: $attributes" ", "
           "imports: $imports" ", "
           "declaredMojomObjects: $declaredMojomObjects" ", "
           "serializedRuntimeTypeInfo: $serializedRuntimeTypeInfo" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["fileName"] = fileName;
    map["specifiedFileName"] = specifiedFileName;
    map["moduleNamespace"] = moduleNamespace;
    map["attributes"] = attributes;
    map["imports"] = imports;
    map["declaredMojomObjects"] = declaredMojomObjects;
    map["serializedRuntimeTypeInfo"] = serializedRuntimeTypeInfo;
    return map;
  }
}


class MojomFileGraph extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  Map<String, MojomFile> files = null;
  Map<String, mojom_types_mojom.UserDefinedType> resolvedTypes = null;
  Map<String, mojom_types_mojom.UserDefinedValue> resolvedValues = null;

  MojomFileGraph() : super(kVersions.last.size);

  static MojomFileGraph deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static MojomFileGraph decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojomFileGraph result = new MojomFileGraph();

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
        List<MojomFile> values0;
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
            values0 = new List<MojomFile>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              values0[i2] = MojomFile.decode(decoder3);
            }
          }
        }
        result.files = new Map<String, MojomFile>.fromIterables(
            keys0, values0);
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
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
        result.resolvedTypes = new Map<String, mojom_types_mojom.UserDefinedType>.fromIterables(
            keys0, values0);
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<mojom_types_mojom.UserDefinedValue> values0;
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
            values0 = new List<mojom_types_mojom.UserDefinedValue>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
                values0[i2] = mojom_types_mojom.UserDefinedValue.decode(decoder2, bindings.ArrayDataHeader.kHeaderSize + bindings.kUnionSize * i2);
                if (values0[i2] == null) {
                  throw new bindings.MojoCodecError(
                    'Trying to decode null union for non-nullable mojom_types_mojom.UserDefinedValue.');
                }
            }
          }
        }
        result.resolvedValues = new Map<String, mojom_types_mojom.UserDefinedValue>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (files == null) {
        encoder0.encodeNullPointer(8, false);
      } else {
        var encoder1 = encoder0.encoderForMap(8);
        var keys0 = files.keys.toList();
        var values0 = files.values.toList();
        
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
          "files of struct MojomFileGraph: $e";
      rethrow;
    }
    try {
      if (resolvedTypes == null) {
        encoder0.encodeNullPointer(16, false);
      } else {
        var encoder1 = encoder0.encoderForMap(16);
        var keys0 = resolvedTypes.keys.toList();
        var values0 = resolvedTypes.values.toList();
        
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
          "resolvedTypes of struct MojomFileGraph: $e";
      rethrow;
    }
    try {
      if (resolvedValues == null) {
        encoder0.encodeNullPointer(24, false);
      } else {
        var encoder1 = encoder0.encoderForMap(24);
        var keys0 = resolvedValues.keys.toList();
        var values0 = resolvedValues.values.toList();
        
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
          "resolvedValues of struct MojomFileGraph: $e";
      rethrow;
    }
  }

  String toString() {
    return "MojomFileGraph("
           "files: $files" ", "
           "resolvedTypes: $resolvedTypes" ", "
           "resolvedValues: $resolvedValues" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["files"] = files;
    map["resolvedTypes"] = resolvedTypes;
    map["resolvedValues"] = resolvedValues;
    return map;
  }
}


class KeysByType extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(64, 0)
  ];
  List<String> interfaces = null;
  List<String> structs = null;
  List<String> unions = null;
  List<String> topLevelEnums = null;
  List<String> embeddedEnums = null;
  List<String> topLevelConstants = null;
  List<String> embeddedConstants = null;

  KeysByType() : super(kVersions.last.size);

  static KeysByType deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static KeysByType decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    KeysByType result = new KeysByType();

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
        result.interfaces = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.interfaces = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.interfaces[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.structs = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.structs = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.structs[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      if (decoder1 == null) {
        result.unions = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.unions = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.unions[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      if (decoder1 == null) {
        result.topLevelEnums = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.topLevelEnums = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.topLevelEnums[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.embeddedEnums = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.embeddedEnums = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.embeddedEnums[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(48, true);
      if (decoder1 == null) {
        result.topLevelConstants = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.topLevelConstants = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.topLevelConstants[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(56, true);
      if (decoder1 == null) {
        result.embeddedConstants = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.embeddedConstants = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.embeddedConstants[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      if (interfaces == null) {
        encoder0.encodeNullPointer(8, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(interfaces.length, 8, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < interfaces.length; ++i0) {
          encoder1.encodeString(interfaces[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "interfaces of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (structs == null) {
        encoder0.encodeNullPointer(16, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(structs.length, 16, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < structs.length; ++i0) {
          encoder1.encodeString(structs[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "structs of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (unions == null) {
        encoder0.encodeNullPointer(24, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(unions.length, 24, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < unions.length; ++i0) {
          encoder1.encodeString(unions[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "unions of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (topLevelEnums == null) {
        encoder0.encodeNullPointer(32, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(topLevelEnums.length, 32, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < topLevelEnums.length; ++i0) {
          encoder1.encodeString(topLevelEnums[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "topLevelEnums of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (embeddedEnums == null) {
        encoder0.encodeNullPointer(40, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(embeddedEnums.length, 40, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < embeddedEnums.length; ++i0) {
          encoder1.encodeString(embeddedEnums[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "embeddedEnums of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (topLevelConstants == null) {
        encoder0.encodeNullPointer(48, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(topLevelConstants.length, 48, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < topLevelConstants.length; ++i0) {
          encoder1.encodeString(topLevelConstants[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "topLevelConstants of struct KeysByType: $e";
      rethrow;
    }
    try {
      if (embeddedConstants == null) {
        encoder0.encodeNullPointer(56, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(embeddedConstants.length, 56, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < embeddedConstants.length; ++i0) {
          encoder1.encodeString(embeddedConstants[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "embeddedConstants of struct KeysByType: $e";
      rethrow;
    }
  }

  String toString() {
    return "KeysByType("
           "interfaces: $interfaces" ", "
           "structs: $structs" ", "
           "unions: $unions" ", "
           "topLevelEnums: $topLevelEnums" ", "
           "embeddedEnums: $embeddedEnums" ", "
           "topLevelConstants: $topLevelConstants" ", "
           "embeddedConstants: $embeddedConstants" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["interfaces"] = interfaces;
    map["structs"] = structs;
    map["unions"] = unions;
    map["topLevelEnums"] = topLevelEnums;
    map["embeddedEnums"] = embeddedEnums;
    map["topLevelConstants"] = topLevelConstants;
    map["embeddedConstants"] = embeddedConstants;
    return map;
  }
}



