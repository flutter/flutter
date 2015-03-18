// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library test_structs.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/public/interfaces/bindings/tests/rect.mojom.dart' as rect_mojom;


class NamedRegion extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String name = null;
  List<rect_mojom.Rect> rects = null;

  NamedRegion() : super(kStructSize);

  static NamedRegion deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NamedRegion decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NamedRegion result = new NamedRegion();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.name = decoder0.decodeString(8, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.rects = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.rects = new List<rect_mojom.Rect>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.rects[i1] = rect_mojom.Rect.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(name, 8, true);
    
    if (rects == null) {
      encoder0.encodeNullPointer(16, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(rects.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < rects.length; ++i0) {
        
        encoder1.encodeStruct(rects[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "NamedRegion("
           "name: $name" ", "
           "rects: $rects" ")";
  }
}

class RectPair extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  rect_mojom.Rect first = null;
  rect_mojom.Rect second = null;

  RectPair() : super(kStructSize);

  static RectPair deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static RectPair decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    RectPair result = new RectPair();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.first = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.second = rect_mojom.Rect.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(first, 8, true);
    
    encoder0.encodeStruct(second, 16, true);
  }

  String toString() {
    return "RectPair("
           "first: $first" ", "
           "second: $second" ")";
  }
}

class EmptyStruct extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  EmptyStruct() : super(kStructSize);

  static EmptyStruct deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EmptyStruct decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EmptyStruct result = new EmptyStruct();

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
    return "EmptyStruct("")";
  }
}

class NoDefaultFieldValues extends bindings.Struct {
  static const int kStructSize = 160;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool f0 = false;
  int f1 = 0;
  int f2 = 0;
  int f3 = 0;
  int f4 = 0;
  int f5 = 0;
  int f6 = 0;
  int f7 = 0;
  int f8 = 0;
  double f9 = 0.0;
  core.MojoMessagePipeEndpoint f13 = null;
  double f10 = 0.0;
  String f11 = null;
  String f12 = null;
  core.MojoDataPipeConsumer f14 = null;
  core.MojoDataPipeProducer f15 = null;
  core.MojoMessagePipeEndpoint f16 = null;
  core.MojoDataPipeConsumer f17 = null;
  core.MojoDataPipeProducer f18 = null;
  core.MojoHandle f19 = null;
  core.MojoHandle f20 = null;
  core.MojoSharedBuffer f21 = null;
  core.MojoSharedBuffer f22 = null;
  List<String> f23 = null;
  List<String> f24 = null;
  List<String> f25 = null;
  List<String> f26 = null;
  EmptyStruct f27 = null;
  EmptyStruct f28 = null;

  NoDefaultFieldValues() : super(kStructSize);

  static NoDefaultFieldValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NoDefaultFieldValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NoDefaultFieldValues result = new NoDefaultFieldValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeBool(8, 0);
    }
    {
      
      result.f1 = decoder0.decodeInt8(9);
    }
    {
      
      result.f2 = decoder0.decodeUint8(10);
    }
    {
      
      result.f3 = decoder0.decodeInt16(12);
    }
    {
      
      result.f4 = decoder0.decodeUint16(14);
    }
    {
      
      result.f5 = decoder0.decodeInt32(16);
    }
    {
      
      result.f6 = decoder0.decodeUint32(20);
    }
    {
      
      result.f7 = decoder0.decodeInt64(24);
    }
    {
      
      result.f8 = decoder0.decodeUint64(32);
    }
    {
      
      result.f9 = decoder0.decodeFloat(40);
    }
    {
      
      result.f13 = decoder0.decodeMessagePipeHandle(44, false);
    }
    {
      
      result.f10 = decoder0.decodeDouble(48);
    }
    {
      
      result.f11 = decoder0.decodeString(56, false);
    }
    {
      
      result.f12 = decoder0.decodeString(64, true);
    }
    {
      
      result.f14 = decoder0.decodeConsumerHandle(72, false);
    }
    {
      
      result.f15 = decoder0.decodeProducerHandle(76, false);
    }
    {
      
      result.f16 = decoder0.decodeMessagePipeHandle(80, true);
    }
    {
      
      result.f17 = decoder0.decodeConsumerHandle(84, true);
    }
    {
      
      result.f18 = decoder0.decodeProducerHandle(88, true);
    }
    {
      
      result.f19 = decoder0.decodeHandle(92, false);
    }
    {
      
      result.f20 = decoder0.decodeHandle(96, true);
    }
    {
      
      result.f21 = decoder0.decodeSharedBufferHandle(100, false);
    }
    {
      
      result.f22 = decoder0.decodeSharedBufferHandle(104, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(112, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f23 = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f23[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(120, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f24 = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f24[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, true);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(128, true);
      if (decoder1 == null) {
        result.f25 = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f25 = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f25[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(136, true);
      if (decoder1 == null) {
        result.f26 = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f26 = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f26[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, true);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(144, false);
      result.f27 = EmptyStruct.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(152, true);
      result.f28 = EmptyStruct.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(f0, 8, 0);
    
    encoder0.encodeInt8(f1, 9);
    
    encoder0.encodeUint8(f2, 10);
    
    encoder0.encodeInt16(f3, 12);
    
    encoder0.encodeUint16(f4, 14);
    
    encoder0.encodeInt32(f5, 16);
    
    encoder0.encodeUint32(f6, 20);
    
    encoder0.encodeInt64(f7, 24);
    
    encoder0.encodeUint64(f8, 32);
    
    encoder0.encodeFloat(f9, 40);
    
    encoder0.encodeMessagePipeHandle(f13, 44, false);
    
    encoder0.encodeDouble(f10, 48);
    
    encoder0.encodeString(f11, 56, false);
    
    encoder0.encodeString(f12, 64, true);
    
    encoder0.encodeConsumerHandle(f14, 72, false);
    
    encoder0.encodeProducerHandle(f15, 76, false);
    
    encoder0.encodeMessagePipeHandle(f16, 80, true);
    
    encoder0.encodeConsumerHandle(f17, 84, true);
    
    encoder0.encodeProducerHandle(f18, 88, true);
    
    encoder0.encodeHandle(f19, 92, false);
    
    encoder0.encodeHandle(f20, 96, true);
    
    encoder0.encodeSharedBufferHandle(f21, 100, false);
    
    encoder0.encodeSharedBufferHandle(f22, 104, true);
    
    if (f23 == null) {
      encoder0.encodeNullPointer(112, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(f23.length, 112, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f23.length; ++i0) {
        
        encoder1.encodeString(f23[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    if (f24 == null) {
      encoder0.encodeNullPointer(120, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(f24.length, 120, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f24.length; ++i0) {
        
        encoder1.encodeString(f24[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, true);
      }
    }
    
    if (f25 == null) {
      encoder0.encodeNullPointer(128, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(f25.length, 128, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f25.length; ++i0) {
        
        encoder1.encodeString(f25[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    if (f26 == null) {
      encoder0.encodeNullPointer(136, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(f26.length, 136, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f26.length; ++i0) {
        
        encoder1.encodeString(f26[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, true);
      }
    }
    
    encoder0.encodeStruct(f27, 144, false);
    
    encoder0.encodeStruct(f28, 152, true);
  }

  String toString() {
    return "NoDefaultFieldValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ", "
           "f13: $f13" ", "
           "f10: $f10" ", "
           "f11: $f11" ", "
           "f12: $f12" ", "
           "f14: $f14" ", "
           "f15: $f15" ", "
           "f16: $f16" ", "
           "f17: $f17" ", "
           "f18: $f18" ", "
           "f19: $f19" ", "
           "f20: $f20" ", "
           "f21: $f21" ", "
           "f22: $f22" ", "
           "f23: $f23" ", "
           "f24: $f24" ", "
           "f25: $f25" ", "
           "f26: $f26" ", "
           "f27: $f27" ", "
           "f28: $f28" ")";
  }
}

class DefaultFieldValues extends bindings.Struct {
  static const int kStructSize = 96;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final kFoo = "foo";
  bool f0 = true;
  int f1 = 100;
  int f2 = 100;
  int f3 = 100;
  int f4 = 100;
  int f5 = 100;
  int f6 = 100;
  int f7 = 100;
  int f8 = 100;
  double f9 = 100;
  double f10 = 100.0;
  double f11 = 100;
  double f12 = 100.0;
  String f13 = DefaultFieldValues.kFoo;
  String f14 = DefaultFieldValues.kFoo;
  rect_mojom.Rect f15 = new rect_mojom.Rect();
  rect_mojom.Rect f16 = new rect_mojom.Rect();

  DefaultFieldValues() : super(kStructSize);

  static DefaultFieldValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DefaultFieldValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DefaultFieldValues result = new DefaultFieldValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeBool(8, 0);
    }
    {
      
      result.f1 = decoder0.decodeInt8(9);
    }
    {
      
      result.f2 = decoder0.decodeUint8(10);
    }
    {
      
      result.f3 = decoder0.decodeInt16(12);
    }
    {
      
      result.f4 = decoder0.decodeUint16(14);
    }
    {
      
      result.f5 = decoder0.decodeInt32(16);
    }
    {
      
      result.f6 = decoder0.decodeUint32(20);
    }
    {
      
      result.f7 = decoder0.decodeInt64(24);
    }
    {
      
      result.f8 = decoder0.decodeUint64(32);
    }
    {
      
      result.f9 = decoder0.decodeFloat(40);
    }
    {
      
      result.f10 = decoder0.decodeFloat(44);
    }
    {
      
      result.f11 = decoder0.decodeDouble(48);
    }
    {
      
      result.f12 = decoder0.decodeDouble(56);
    }
    {
      
      result.f13 = decoder0.decodeString(64, false);
    }
    {
      
      result.f14 = decoder0.decodeString(72, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(80, false);
      result.f15 = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(88, true);
      result.f16 = rect_mojom.Rect.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBool(f0, 8, 0);
    
    encoder0.encodeInt8(f1, 9);
    
    encoder0.encodeUint8(f2, 10);
    
    encoder0.encodeInt16(f3, 12);
    
    encoder0.encodeUint16(f4, 14);
    
    encoder0.encodeInt32(f5, 16);
    
    encoder0.encodeUint32(f6, 20);
    
    encoder0.encodeInt64(f7, 24);
    
    encoder0.encodeUint64(f8, 32);
    
    encoder0.encodeFloat(f9, 40);
    
    encoder0.encodeFloat(f10, 44);
    
    encoder0.encodeDouble(f11, 48);
    
    encoder0.encodeDouble(f12, 56);
    
    encoder0.encodeString(f13, 64, false);
    
    encoder0.encodeString(f14, 72, true);
    
    encoder0.encodeStruct(f15, 80, false);
    
    encoder0.encodeStruct(f16, 88, true);
  }

  String toString() {
    return "DefaultFieldValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ", "
           "f10: $f10" ", "
           "f11: $f11" ", "
           "f12: $f12" ", "
           "f13: $f13" ", "
           "f14: $f14" ", "
           "f15: $f15" ", "
           "f16: $f16" ")";
  }
}

class ScopedConstants extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  
  static final int EType_E0 = 0;
  static final int EType_E1 = EType_E0 + 1;
  static final int EType_E2 = 10;
  static final int EType_E3 = ScopedConstants.EType_E2;
  static final int EType_E4 = EType_E3 + 1;
  static final TEN = 10;
  static final ALSO_TEN = ScopedConstants.TEN;
  static final TEN_TOO = ScopedConstants.EType_E2;
  int f0 = ScopedConstants.EType_E0;
  int f1 = ScopedConstants.EType_E1;
  int f2 = ScopedConstants.EType_E2;
  int f3 = ScopedConstants.EType_E3;
  int f4 = ScopedConstants.EType_E4;
  int f5 = ScopedConstants.TEN;
  int f6 = ScopedConstants.ALSO_TEN;

  ScopedConstants() : super(kStructSize);

  static ScopedConstants deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ScopedConstants decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ScopedConstants result = new ScopedConstants();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeInt32(8);
    }
    {
      
      result.f1 = decoder0.decodeInt32(12);
    }
    {
      
      result.f2 = decoder0.decodeInt32(16);
    }
    {
      
      result.f3 = decoder0.decodeInt32(20);
    }
    {
      
      result.f4 = decoder0.decodeInt32(24);
    }
    {
      
      result.f5 = decoder0.decodeInt32(28);
    }
    {
      
      result.f6 = decoder0.decodeInt32(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(f0, 8);
    
    encoder0.encodeInt32(f1, 12);
    
    encoder0.encodeInt32(f2, 16);
    
    encoder0.encodeInt32(f3, 20);
    
    encoder0.encodeInt32(f4, 24);
    
    encoder0.encodeInt32(f5, 28);
    
    encoder0.encodeInt32(f6, 32);
  }

  String toString() {
    return "ScopedConstants("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ")";
  }
}

class MapKeyTypes extends bindings.Struct {
  static const int kStructSize = 104;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Map<bool, bool> f0 = null;
  Map<int, int> f1 = null;
  Map<int, int> f2 = null;
  Map<int, int> f3 = null;
  Map<int, int> f4 = null;
  Map<int, int> f5 = null;
  Map<int, int> f6 = null;
  Map<int, int> f7 = null;
  Map<int, int> f8 = null;
  Map<double, double> f9 = null;
  Map<double, double> f10 = null;
  Map<String, String> f11 = null;

  MapKeyTypes() : super(kStructSize);

  static MapKeyTypes deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MapKeyTypes decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MapKeyTypes result = new MapKeyTypes();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<bool> keys0;
        List<bool> values0;
        {
          
          keys0 = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f0 = new Map<bool, bool>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeInt8Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeInt8Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f1 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeUint8Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeUint8Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f2 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeInt16Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeInt16Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f3 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeUint16Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeUint16Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f4 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeInt32Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeInt32Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f5 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(56, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeUint32Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeUint32Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f6 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(64, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeInt64Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeInt64Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f7 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(72, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<int> keys0;
        List<int> values0;
        {
          
          keys0 = decoder1.decodeUint64Array(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeUint64Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f8 = new Map<int, int>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(80, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<double> keys0;
        List<double> values0;
        {
          
          keys0 = decoder1.decodeFloatArray(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeFloatArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f9 = new Map<double, double>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(88, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<double> keys0;
        List<double> values0;
        {
          
          keys0 = decoder1.decodeDoubleArray(bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
        {
          
          values0 = decoder1.decodeDoubleArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.f10 = new Map<double, double>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(96, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<String> values0;
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
            values0 = new List<String>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              values0[i2] = decoder2.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
        result.f11 = new Map<String, String>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (f0 == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encoderForMap(8);
      int size0 = f0.length;
      var keys0 = f0.keys.toList();
      var values0 = f0.values.toList();
      
      encoder1.encodeBoolArray(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeBoolArray(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f1 == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encoderForMap(16);
      int size0 = f1.length;
      var keys0 = f1.keys.toList();
      var values0 = f1.values.toList();
      
      encoder1.encodeInt8Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeInt8Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f2 == null) {
      encoder0.encodeNullPointer(24, false);
    } else {
      var encoder1 = encoder0.encoderForMap(24);
      int size0 = f2.length;
      var keys0 = f2.keys.toList();
      var values0 = f2.values.toList();
      
      encoder1.encodeUint8Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeUint8Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f3 == null) {
      encoder0.encodeNullPointer(32, false);
    } else {
      var encoder1 = encoder0.encoderForMap(32);
      int size0 = f3.length;
      var keys0 = f3.keys.toList();
      var values0 = f3.values.toList();
      
      encoder1.encodeInt16Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeInt16Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f4 == null) {
      encoder0.encodeNullPointer(40, false);
    } else {
      var encoder1 = encoder0.encoderForMap(40);
      int size0 = f4.length;
      var keys0 = f4.keys.toList();
      var values0 = f4.values.toList();
      
      encoder1.encodeUint16Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeUint16Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f5 == null) {
      encoder0.encodeNullPointer(48, false);
    } else {
      var encoder1 = encoder0.encoderForMap(48);
      int size0 = f5.length;
      var keys0 = f5.keys.toList();
      var values0 = f5.values.toList();
      
      encoder1.encodeInt32Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeInt32Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f6 == null) {
      encoder0.encodeNullPointer(56, false);
    } else {
      var encoder1 = encoder0.encoderForMap(56);
      int size0 = f6.length;
      var keys0 = f6.keys.toList();
      var values0 = f6.values.toList();
      
      encoder1.encodeUint32Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeUint32Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f7 == null) {
      encoder0.encodeNullPointer(64, false);
    } else {
      var encoder1 = encoder0.encoderForMap(64);
      int size0 = f7.length;
      var keys0 = f7.keys.toList();
      var values0 = f7.values.toList();
      
      encoder1.encodeInt64Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeInt64Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f8 == null) {
      encoder0.encodeNullPointer(72, false);
    } else {
      var encoder1 = encoder0.encoderForMap(72);
      int size0 = f8.length;
      var keys0 = f8.keys.toList();
      var values0 = f8.values.toList();
      
      encoder1.encodeUint64Array(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeUint64Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f9 == null) {
      encoder0.encodeNullPointer(80, false);
    } else {
      var encoder1 = encoder0.encoderForMap(80);
      int size0 = f9.length;
      var keys0 = f9.keys.toList();
      var values0 = f9.values.toList();
      
      encoder1.encodeFloatArray(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeFloatArray(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f10 == null) {
      encoder0.encodeNullPointer(88, false);
    } else {
      var encoder1 = encoder0.encoderForMap(88);
      int size0 = f10.length;
      var keys0 = f10.keys.toList();
      var values0 = f10.values.toList();
      
      encoder1.encodeDoubleArray(keys0, bindings.ArrayDataHeader.kHeaderSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      
      encoder1.encodeDoubleArray(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    
    if (f11 == null) {
      encoder0.encodeNullPointer(96, false);
    } else {
      var encoder1 = encoder0.encoderForMap(96);
      int size0 = f11.length;
      var keys0 = f11.keys.toList();
      var values0 = f11.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          encoder2.encodeString(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
  }

  String toString() {
    return "MapKeyTypes("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ", "
           "f10: $f10" ", "
           "f11: $f11" ")";
  }
}

class MapValueTypes extends bindings.Struct {
  static const int kStructSize = 80;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Map<String, List<String>> f0 = null;
  Map<String, List<String>> f1 = null;
  Map<String, List<String>> f2 = null;
  Map<String, List<String>> f3 = null;
  Map<String, List<List<String>>> f4 = null;
  Map<String, List<List<String>>> f5 = null;
  Map<String, rect_mojom.Rect> f6 = null;
  Map<String, Map<String, String>> f7 = null;
  Map<String, List<Map<String, String>>> f8 = null;

  MapValueTypes() : super(kStructSize);

  static MapValueTypes deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MapValueTypes decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MapValueTypes result = new MapValueTypes();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<String>> values0;
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
            values0 = new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                values0[i2] = new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  values0[i2][i3] = decoder3.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
        result.f0 = new Map<String, List<String>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<String>> values0;
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
            values0 = new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, true);
              if (decoder3 == null) {
                values0[i2] = null;
              } else {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                values0[i2] = new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  values0[i2][i3] = decoder3.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
        result.f1 = new Map<String, List<String>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<String>> values0;
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
            values0 = new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                values0[i2] = new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  values0[i2][i3] = decoder3.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, true);
                }
              }
            }
          }
        }
        result.f2 = new Map<String, List<String>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<String>> values0;
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
            values0 = new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(2);
                values0[i2] = new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  values0[i2][i3] = decoder3.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
        result.f3 = new Map<String, List<String>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<List<String>>> values0;
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
            values0 = new List<List<List<String>>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                values0[i2] = new List<List<String>>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  var decoder4 = decoder3.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, true);
                  if (decoder4 == null) {
                    values0[i2][i3] = null;
                  } else {
                    var si4 = decoder4.decodeDataHeaderForPointerArray(2);
                    values0[i2][i3] = new List<String>(si4.numElements);
                    for (int i4 = 0; i4 < si4.numElements; ++i4) {
                      
                      values0[i2][i3][i4] = decoder4.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                    }
                  }
                }
              }
            }
          }
        }
        result.f4 = new Map<String, List<List<String>>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<List<String>>> values0;
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
            values0 = new List<List<List<String>>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(1);
                values0[i2] = new List<List<String>>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  var decoder4 = decoder3.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                  {
                    var si4 = decoder4.decodeDataHeaderForPointerArray(2);
                    values0[i2][i3] = new List<String>(si4.numElements);
                    for (int i4 = 0; i4 < si4.numElements; ++i4) {
                      
                      values0[i2][i3][i4] = decoder4.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                    }
                  }
                }
              }
            }
          }
        }
        result.f5 = new Map<String, List<List<String>>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(56, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<rect_mojom.Rect> values0;
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
            values0 = new List<rect_mojom.Rect>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, true);
              values0[i2] = rect_mojom.Rect.decode(decoder3);
            }
          }
        }
        result.f6 = new Map<String, rect_mojom.Rect>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(64, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<Map<String, String>> values0;
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
            values0 = new List<Map<String, String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                decoder3.decodeDataHeaderForMap();
                List<String> keys2;
                List<String> values2;
                {
                  
                  var decoder4 = decoder3.decodePointer(bindings.ArrayDataHeader.kHeaderSize, false);
                  {
                    var si4 = decoder4.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                    keys2 = new List<String>(si4.numElements);
                    for (int i4 = 0; i4 < si4.numElements; ++i4) {
                      
                      keys2[i4] = decoder4.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                    }
                  }
                }
                {
                  
                  var decoder4 = decoder3.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, false);
                  {
                    var si4 = decoder4.decodeDataHeaderForPointerArray(keys2.length);
                    values2 = new List<String>(si4.numElements);
                    for (int i4 = 0; i4 < si4.numElements; ++i4) {
                      
                      values2[i4] = decoder4.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                    }
                  }
                }
                values0[i2] = new Map<String, String>.fromIterables(
                    keys2, values2);
              }
            }
          }
        }
        result.f7 = new Map<String, Map<String, String>>.fromIterables(
            keys0, values0);
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(72, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<List<Map<String, String>>> values0;
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
            values0 = new List<List<Map<String, String>>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                values0[i2] = new List<Map<String, String>>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  var decoder4 = decoder3.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                  {
                    decoder4.decodeDataHeaderForMap();
                    List<String> keys3;
                    List<String> values3;
                    {
                      
                      var decoder5 = decoder4.decodePointer(bindings.ArrayDataHeader.kHeaderSize, false);
                      {
                        var si5 = decoder5.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                        keys3 = new List<String>(si5.numElements);
                        for (int i5 = 0; i5 < si5.numElements; ++i5) {
                          
                          keys3[i5] = decoder5.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i5, false);
                        }
                      }
                    }
                    {
                      
                      var decoder5 = decoder4.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, false);
                      {
                        var si5 = decoder5.decodeDataHeaderForPointerArray(keys3.length);
                        values3 = new List<String>(si5.numElements);
                        for (int i5 = 0; i5 < si5.numElements; ++i5) {
                          
                          values3[i5] = decoder5.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i5, false);
                        }
                      }
                    }
                    values0[i2][i3] = new Map<String, String>.fromIterables(
                        keys3, values3);
                  }
                }
              }
            }
          }
        }
        result.f8 = new Map<String, List<Map<String, String>>>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    if (f0 == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encoderForMap(8);
      int size0 = f0.length;
      var keys0 = f0.keys.toList();
      var values0 = f0.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              encoder3.encodeString(values0[i1][i2], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
      }
    }
    
    if (f1 == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encoderForMap(16);
      int size0 = f1.length;
      var keys0 = f1.keys.toList();
      var values0 = f1.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, true);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              encoder3.encodeString(values0[i1][i2], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
      }
    }
    
    if (f2 == null) {
      encoder0.encodeNullPointer(24, false);
    } else {
      var encoder1 = encoder0.encoderForMap(24);
      int size0 = f2.length;
      var keys0 = f2.keys.toList();
      var values0 = f2.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              encoder3.encodeString(values0[i1][i2], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, true);
            }
          }
        }
      }
    }
    
    if (f3 == null) {
      encoder0.encodeNullPointer(32, false);
    } else {
      var encoder1 = encoder0.encoderForMap(32);
      int size0 = f3.length;
      var keys0 = f3.keys.toList();
      var values0 = f3.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, 2);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              encoder3.encodeString(values0[i1][i2], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
      }
    }
    
    if (f4 == null) {
      encoder0.encodeNullPointer(40, false);
    } else {
      var encoder1 = encoder0.encoderForMap(40);
      int size0 = f4.length;
      var keys0 = f4.keys.toList();
      var values0 = f4.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              if (values0[i1][i2] == null) {
                encoder3.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, true);
              } else {
                var encoder4 = encoder3.encodePointerArray(values0[i1][i2].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, 2);
                for (int i3 = 0; i3 < values0[i1][i2].length; ++i3) {
                  
                  encoder4.encodeString(values0[i1][i2][i3], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
      }
    }
    
    if (f5 == null) {
      encoder0.encodeNullPointer(48, false);
    } else {
      var encoder1 = encoder0.encoderForMap(48);
      int size0 = f5.length;
      var keys0 = f5.keys.toList();
      var values0 = f5.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, 1);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              if (values0[i1][i2] == null) {
                encoder3.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              } else {
                var encoder4 = encoder3.encodePointerArray(values0[i1][i2].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, 2);
                for (int i3 = 0; i3 < values0[i1][i2].length; ++i3) {
                  
                  encoder4.encodeString(values0[i1][i2][i3], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
      }
    }
    
    if (f6 == null) {
      encoder0.encodeNullPointer(56, false);
    } else {
      var encoder1 = encoder0.encoderForMap(56);
      int size0 = f6.length;
      var keys0 = f6.keys.toList();
      var values0 = f6.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          encoder2.encodeStruct(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, true);
        }
      }
    }
    
    if (f7 == null) {
      encoder0.encodeNullPointer(64, false);
    } else {
      var encoder1 = encoder0.encoderForMap(64);
      int size0 = f7.length;
      var keys0 = f7.keys.toList();
      var values0 = f7.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encoderForMap(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1);
            int size2 = values0[i1].length;
            var keys2 = values0[i1].keys.toList();
            var values2 = values0[i1].values.toList();
            
            {
              var encoder4 = encoder3.encodePointerArray(keys2.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
              for (int i3 = 0; i3 < keys2.length; ++i3) {
                
                encoder4.encodeString(keys2[i3], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
              }
            }
            
            {
              var encoder4 = encoder3.encodePointerArray(values2.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
              for (int i3 = 0; i3 < values2.length; ++i3) {
                
                encoder4.encodeString(values2[i3], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
              }
            }
          }
        }
      }
    }
    
    if (f8 == null) {
      encoder0.encodeNullPointer(72, false);
    } else {
      var encoder1 = encoder0.encoderForMap(72);
      int size0 = f8.length;
      var keys0 = f8.keys.toList();
      var values0 = f8.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          if (values0[i1] == null) {
            encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          } else {
            var encoder3 = encoder2.encodePointerArray(values0[i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
            for (int i2 = 0; i2 < values0[i1].length; ++i2) {
              
              if (values0[i1][i2] == null) {
                encoder3.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              } else {
                var encoder4 = encoder3.encoderForMap(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2);
                int size3 = values0[i1][i2].length;
                var keys3 = values0[i1][i2].keys.toList();
                var values3 = values0[i1][i2].values.toList();
                
                {
                  var encoder5 = encoder4.encodePointerArray(keys3.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
                  for (int i4 = 0; i4 < keys3.length; ++i4) {
                    
                    encoder5.encodeString(keys3[i4], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                  }
                }
                
                {
                  var encoder5 = encoder4.encodePointerArray(values3.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
                  for (int i4 = 0; i4 < values3.length; ++i4) {
                    
                    encoder5.encodeString(values3[i4], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i4, false);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  String toString() {
    return "MapValueTypes("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ")";
  }
}

class ArrayValueTypes extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<int> f0 = null;
  List<int> f1 = null;
  List<int> f2 = null;
  List<int> f3 = null;
  List<double> f4 = null;
  List<double> f5 = null;

  ArrayValueTypes() : super(kStructSize);

  static ArrayValueTypes deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ArrayValueTypes decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ArrayValueTypes result = new ArrayValueTypes();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeInt8Array(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.f1 = decoder0.decodeInt16Array(16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.f2 = decoder0.decodeInt32Array(24, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.f3 = decoder0.decodeInt64Array(32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.f4 = decoder0.decodeFloatArray(40, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.f5 = decoder0.decodeDoubleArray(48, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt8Array(f0, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeInt16Array(f1, 16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeInt32Array(f2, 24, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeInt64Array(f3, 32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeFloatArray(f4, 40, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeDoubleArray(f5, 48, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "ArrayValueTypes("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ")";
  }
}

class FloatNumberValues extends bindings.Struct {
  static const int kStructSize = 72;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final V0 = double.INFINITY;
  static final V1 = double.NEGATIVE_INFINITY;
  static final V2 = double.NAN;
  static final V3 = double.INFINITY;
  static final V4 = double.NEGATIVE_INFINITY;
  static final V5 = double.NAN;
  static final V6 = 0;
  static final V7 = 1234567890.123;
  static final V8 = 1.2E+20;
  static final V9 = -1.2E+20;
  double f0 = FloatNumberValues.V0;
  double f1 = FloatNumberValues.V1;
  double f2 = FloatNumberValues.V2;
  double f3 = FloatNumberValues.V3;
  double f4 = FloatNumberValues.V4;
  double f5 = FloatNumberValues.V5;
  double f6 = FloatNumberValues.V6;
  double f7 = FloatNumberValues.V7;
  double f8 = FloatNumberValues.V8;
  double f9 = FloatNumberValues.V9;

  FloatNumberValues() : super(kStructSize);

  static FloatNumberValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FloatNumberValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FloatNumberValues result = new FloatNumberValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeDouble(8);
    }
    {
      
      result.f1 = decoder0.decodeDouble(16);
    }
    {
      
      result.f2 = decoder0.decodeDouble(24);
    }
    {
      
      result.f3 = decoder0.decodeFloat(32);
    }
    {
      
      result.f4 = decoder0.decodeFloat(36);
    }
    {
      
      result.f5 = decoder0.decodeFloat(40);
    }
    {
      
      result.f6 = decoder0.decodeFloat(44);
    }
    {
      
      result.f7 = decoder0.decodeDouble(48);
    }
    {
      
      result.f8 = decoder0.decodeDouble(56);
    }
    {
      
      result.f9 = decoder0.decodeDouble(64);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeDouble(f0, 8);
    
    encoder0.encodeDouble(f1, 16);
    
    encoder0.encodeDouble(f2, 24);
    
    encoder0.encodeFloat(f3, 32);
    
    encoder0.encodeFloat(f4, 36);
    
    encoder0.encodeFloat(f5, 40);
    
    encoder0.encodeFloat(f6, 44);
    
    encoder0.encodeDouble(f7, 48);
    
    encoder0.encodeDouble(f8, 56);
    
    encoder0.encodeDouble(f9, 64);
  }

  String toString() {
    return "FloatNumberValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ")";
  }
}

class IntegerNumberValues extends bindings.Struct {
  static const int kStructSize = 88;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final V0 = -128;
  static final V1 = -1;
  static final V2 = 0;
  static final V3 = 42;
  static final V4 = 127;
  static final V5 = -32768;
  static final V6 = -1;
  static final V7 = 0;
  static final V8 = 12345;
  static final V9 = 32767;
  static final V10 = -2147483648;
  static final V11 = -1;
  static final V12 = 0;
  static final V13 = 1234567890;
  static final V14 = 2147483647;
  static final V15 = -9007199254740991;
  static final V16 = -1;
  static final V17 = 0;
  static final V18 = 1234567890123456;
  static final V19 = 9007199254740991;
  int f0 = IntegerNumberValues.V0;
  int f1 = IntegerNumberValues.V1;
  int f2 = IntegerNumberValues.V2;
  int f3 = IntegerNumberValues.V3;
  int f4 = IntegerNumberValues.V4;
  int f5 = IntegerNumberValues.V5;
  int f6 = IntegerNumberValues.V6;
  int f7 = IntegerNumberValues.V7;
  int f8 = IntegerNumberValues.V8;
  int f9 = IntegerNumberValues.V9;
  int f10 = IntegerNumberValues.V10;
  int f11 = IntegerNumberValues.V11;
  int f12 = IntegerNumberValues.V12;
  int f13 = IntegerNumberValues.V13;
  int f14 = IntegerNumberValues.V14;
  int f15 = IntegerNumberValues.V15;
  int f16 = IntegerNumberValues.V16;
  int f17 = IntegerNumberValues.V17;
  int f18 = IntegerNumberValues.V18;
  int f19 = IntegerNumberValues.V19;

  IntegerNumberValues() : super(kStructSize);

  static IntegerNumberValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static IntegerNumberValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    IntegerNumberValues result = new IntegerNumberValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeInt8(8);
    }
    {
      
      result.f1 = decoder0.decodeInt8(9);
    }
    {
      
      result.f2 = decoder0.decodeInt8(10);
    }
    {
      
      result.f3 = decoder0.decodeInt8(11);
    }
    {
      
      result.f4 = decoder0.decodeInt8(12);
    }
    {
      
      result.f5 = decoder0.decodeInt16(14);
    }
    {
      
      result.f6 = decoder0.decodeInt16(16);
    }
    {
      
      result.f7 = decoder0.decodeInt16(18);
    }
    {
      
      result.f8 = decoder0.decodeInt16(20);
    }
    {
      
      result.f9 = decoder0.decodeInt16(22);
    }
    {
      
      result.f10 = decoder0.decodeInt32(24);
    }
    {
      
      result.f11 = decoder0.decodeInt32(28);
    }
    {
      
      result.f12 = decoder0.decodeInt32(32);
    }
    {
      
      result.f13 = decoder0.decodeInt32(36);
    }
    {
      
      result.f14 = decoder0.decodeInt32(40);
    }
    {
      
      result.f15 = decoder0.decodeInt64(48);
    }
    {
      
      result.f16 = decoder0.decodeInt64(56);
    }
    {
      
      result.f17 = decoder0.decodeInt64(64);
    }
    {
      
      result.f18 = decoder0.decodeInt64(72);
    }
    {
      
      result.f19 = decoder0.decodeInt64(80);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt8(f0, 8);
    
    encoder0.encodeInt8(f1, 9);
    
    encoder0.encodeInt8(f2, 10);
    
    encoder0.encodeInt8(f3, 11);
    
    encoder0.encodeInt8(f4, 12);
    
    encoder0.encodeInt16(f5, 14);
    
    encoder0.encodeInt16(f6, 16);
    
    encoder0.encodeInt16(f7, 18);
    
    encoder0.encodeInt16(f8, 20);
    
    encoder0.encodeInt16(f9, 22);
    
    encoder0.encodeInt32(f10, 24);
    
    encoder0.encodeInt32(f11, 28);
    
    encoder0.encodeInt32(f12, 32);
    
    encoder0.encodeInt32(f13, 36);
    
    encoder0.encodeInt32(f14, 40);
    
    encoder0.encodeInt64(f15, 48);
    
    encoder0.encodeInt64(f16, 56);
    
    encoder0.encodeInt64(f17, 64);
    
    encoder0.encodeInt64(f18, 72);
    
    encoder0.encodeInt64(f19, 80);
  }

  String toString() {
    return "IntegerNumberValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ", "
           "f10: $f10" ", "
           "f11: $f11" ", "
           "f12: $f12" ", "
           "f13: $f13" ", "
           "f14: $f14" ", "
           "f15: $f15" ", "
           "f16: $f16" ", "
           "f17: $f17" ", "
           "f18: $f18" ", "
           "f19: $f19" ")";
  }
}

class UnsignedNumberValues extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final V0 = 0;
  static final V1 = 42;
  static final V2 = 0xFF;
  static final V3 = 0;
  static final V4 = 12345;
  static final V5 = 0xFFFF;
  static final V6 = 0;
  static final V7 = 1234567890;
  static final V8 = 0xFFFFFFFF;
  static final V9 = 0;
  static final V10 = 1234567890123456;
  static final V11 = 9007199254740991;
  int f0 = UnsignedNumberValues.V0;
  int f1 = UnsignedNumberValues.V1;
  int f2 = UnsignedNumberValues.V2;
  int f3 = UnsignedNumberValues.V3;
  int f4 = UnsignedNumberValues.V4;
  int f5 = UnsignedNumberValues.V5;
  int f6 = UnsignedNumberValues.V6;
  int f7 = UnsignedNumberValues.V7;
  int f8 = UnsignedNumberValues.V8;
  int f9 = UnsignedNumberValues.V9;
  int f10 = UnsignedNumberValues.V10;
  int f11 = UnsignedNumberValues.V11;

  UnsignedNumberValues() : super(kStructSize);

  static UnsignedNumberValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static UnsignedNumberValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UnsignedNumberValues result = new UnsignedNumberValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeUint8(8);
    }
    {
      
      result.f1 = decoder0.decodeUint8(9);
    }
    {
      
      result.f2 = decoder0.decodeUint8(10);
    }
    {
      
      result.f3 = decoder0.decodeUint16(12);
    }
    {
      
      result.f4 = decoder0.decodeUint16(14);
    }
    {
      
      result.f5 = decoder0.decodeUint16(16);
    }
    {
      
      result.f6 = decoder0.decodeUint32(20);
    }
    {
      
      result.f7 = decoder0.decodeUint32(24);
    }
    {
      
      result.f8 = decoder0.decodeUint32(28);
    }
    {
      
      result.f9 = decoder0.decodeUint64(32);
    }
    {
      
      result.f10 = decoder0.decodeUint64(40);
    }
    {
      
      result.f11 = decoder0.decodeUint64(48);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint8(f0, 8);
    
    encoder0.encodeUint8(f1, 9);
    
    encoder0.encodeUint8(f2, 10);
    
    encoder0.encodeUint16(f3, 12);
    
    encoder0.encodeUint16(f4, 14);
    
    encoder0.encodeUint16(f5, 16);
    
    encoder0.encodeUint32(f6, 20);
    
    encoder0.encodeUint32(f7, 24);
    
    encoder0.encodeUint32(f8, 28);
    
    encoder0.encodeUint64(f9, 32);
    
    encoder0.encodeUint64(f10, 40);
    
    encoder0.encodeUint64(f11, 48);
  }

  String toString() {
    return "UnsignedNumberValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ", "
           "f7: $f7" ", "
           "f8: $f8" ", "
           "f9: $f9" ", "
           "f10: $f10" ", "
           "f11: $f11" ")";
  }
}

class BitArrayValues extends bindings.Struct {
  static const int kStructSize = 64;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<bool> f0 = null;
  List<bool> f1 = null;
  List<bool> f2 = null;
  List<bool> f3 = null;
  List<List<bool>> f4 = null;
  List<List<bool>> f5 = null;
  List<List<bool>> f6 = null;

  BitArrayValues() : super(kStructSize);

  static BitArrayValues deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BitArrayValues decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BitArrayValues result = new BitArrayValues();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.f0 = decoder0.decodeBoolArray(8, bindings.kNothingNullable, 1);
    }
    {
      
      result.f1 = decoder0.decodeBoolArray(16, bindings.kNothingNullable, 7);
    }
    {
      
      result.f2 = decoder0.decodeBoolArray(24, bindings.kNothingNullable, 9);
    }
    {
      
      result.f3 = decoder0.decodeBoolArray(32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f4 = new List<List<bool>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f4[i1] = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f5 = new List<List<bool>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f5[i1] = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(56, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.f6 = new List<List<bool>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.f6[i1] = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kArrayNullable, 2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeBoolArray(f0, 8, bindings.kNothingNullable, 1);
    
    encoder0.encodeBoolArray(f1, 16, bindings.kNothingNullable, 7);
    
    encoder0.encodeBoolArray(f2, 24, bindings.kNothingNullable, 9);
    
    encoder0.encodeBoolArray(f3, 32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    if (f4 == null) {
      encoder0.encodeNullPointer(40, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(f4.length, 40, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f4.length; ++i0) {
        
        encoder1.encodeBoolArray(f4[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      }
    }
    
    if (f5 == null) {
      encoder0.encodeNullPointer(48, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(f5.length, 48, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f5.length; ++i0) {
        
        encoder1.encodeBoolArray(f5[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
      }
    }
    
    if (f6 == null) {
      encoder0.encodeNullPointer(56, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(f6.length, 56, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < f6.length; ++i0) {
        
        encoder1.encodeBoolArray(f6[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kArrayNullable, 2);
      }
    }
  }

  String toString() {
    return "BitArrayValues("
           "f0: $f0" ", "
           "f1: $f1" ", "
           "f2: $f2" ", "
           "f3: $f3" ", "
           "f4: $f4" ", "
           "f5: $f5" ", "
           "f6: $f6" ")";
  }
}

class MultiVersionStruct extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 9);
  int fInt32 = 0;
  core.MojoMessagePipeEndpoint fMessagePipe = null;
  rect_mojom.Rect fRect = null;
  String fString = null;
  List<int> fArray = null;
  bool fBool = false;
  int fInt16 = 0;

  MultiVersionStruct() : super(kStructSize);

  static MultiVersionStruct deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStruct decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStruct result = new MultiVersionStruct();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 9)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    {
      
      result.fMessagePipe = decoder0.decodeMessagePipeHandle(12, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fRect = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      result.fString = decoder0.decodeString(24, true);
    }
    {
      
      result.fArray = decoder0.decodeInt8Array(32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.fBool = decoder0.decodeBool(40, 0);
    }
    {
      
      result.fInt16 = decoder0.decodeInt16(42);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
    
    encoder0.encodeMessagePipeHandle(fMessagePipe, 12, true);
    
    encoder0.encodeStruct(fRect, 16, true);
    
    encoder0.encodeString(fString, 24, true);
    
    encoder0.encodeInt8Array(fArray, 32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeBool(fBool, 40, 0);
    
    encoder0.encodeInt16(fInt16, 42);
  }

  String toString() {
    return "MultiVersionStruct("
           "fInt32: $fInt32" ", "
           "fMessagePipe: $fMessagePipe" ", "
           "fRect: $fRect" ", "
           "fString: $fString" ", "
           "fArray: $fArray" ", "
           "fBool: $fBool" ", "
           "fInt16: $fInt16" ")";
  }
}

class MultiVersionStructV0 extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int fInt32 = 0;

  MultiVersionStructV0() : super(kStructSize);

  static MultiVersionStructV0 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStructV0 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStructV0 result = new MultiVersionStructV0();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
  }

  String toString() {
    return "MultiVersionStructV0("
           "fInt32: $fInt32" ")";
  }
}

class MultiVersionStructV1 extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 1);
  int fInt32 = 0;
  rect_mojom.Rect fRect = null;

  MultiVersionStructV1() : super(kStructSize);

  static MultiVersionStructV1 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStructV1 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStructV1 result = new MultiVersionStructV1();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 1)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fRect = rect_mojom.Rect.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
    
    encoder0.encodeStruct(fRect, 16, true);
  }

  String toString() {
    return "MultiVersionStructV1("
           "fInt32: $fInt32" ", "
           "fRect: $fRect" ")";
  }
}

class MultiVersionStructV3 extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 3);
  int fInt32 = 0;
  rect_mojom.Rect fRect = null;
  String fString = null;

  MultiVersionStructV3() : super(kStructSize);

  static MultiVersionStructV3 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStructV3 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStructV3 result = new MultiVersionStructV3();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 3)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fRect = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      result.fString = decoder0.decodeString(24, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
    
    encoder0.encodeStruct(fRect, 16, true);
    
    encoder0.encodeString(fString, 24, true);
  }

  String toString() {
    return "MultiVersionStructV3("
           "fInt32: $fInt32" ", "
           "fRect: $fRect" ", "
           "fString: $fString" ")";
  }
}

class MultiVersionStructV5 extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 5);
  int fInt32 = 0;
  rect_mojom.Rect fRect = null;
  String fString = null;
  List<int> fArray = null;

  MultiVersionStructV5() : super(kStructSize);

  static MultiVersionStructV5 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStructV5 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStructV5 result = new MultiVersionStructV5();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 5)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fRect = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      result.fString = decoder0.decodeString(24, true);
    }
    {
      
      result.fArray = decoder0.decodeInt8Array(32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
    
    encoder0.encodeStruct(fRect, 16, true);
    
    encoder0.encodeString(fString, 24, true);
    
    encoder0.encodeInt8Array(fArray, 32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "MultiVersionStructV5("
           "fInt32: $fInt32" ", "
           "fRect: $fRect" ", "
           "fString: $fString" ", "
           "fArray: $fArray" ")";
  }
}

class MultiVersionStructV7 extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 7);
  int fInt32 = 0;
  core.MojoMessagePipeEndpoint fMessagePipe = null;
  rect_mojom.Rect fRect = null;
  String fString = null;
  List<int> fArray = null;
  bool fBool = false;

  MultiVersionStructV7() : super(kStructSize);

  static MultiVersionStructV7 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MultiVersionStructV7 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MultiVersionStructV7 result = new MultiVersionStructV7();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 7)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.fInt32 = decoder0.decodeInt32(8);
    }
    {
      
      result.fMessagePipe = decoder0.decodeMessagePipeHandle(12, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fRect = rect_mojom.Rect.decode(decoder1);
    }
    {
      
      result.fString = decoder0.decodeString(24, true);
    }
    {
      
      result.fArray = decoder0.decodeInt8Array(32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.fBool = decoder0.decodeBool(40, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(fInt32, 8);
    
    encoder0.encodeMessagePipeHandle(fMessagePipe, 12, true);
    
    encoder0.encodeStruct(fRect, 16, true);
    
    encoder0.encodeString(fString, 24, true);
    
    encoder0.encodeInt8Array(fArray, 32, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeBool(fBool, 40, 0);
  }

  String toString() {
    return "MultiVersionStructV7("
           "fInt32: $fInt32" ", "
           "fMessagePipe: $fMessagePipe" ", "
           "fRect: $fRect" ", "
           "fString: $fString" ", "
           "fArray: $fArray" ", "
           "fBool: $fBool" ")";
  }
}

