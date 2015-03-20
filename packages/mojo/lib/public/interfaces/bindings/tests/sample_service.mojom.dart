// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sample_service.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/public/interfaces/bindings/tests/sample_import.mojom.dart' as sample_import_mojom;
import 'package:mojo/public/interfaces/bindings/tests/sample_import2.mojom.dart' as sample_import2_mojom;
final kTwelve = 12;
final kTooBigForSignedInt64 = 9999999999999999999;
final kDoubleInfinity = double.INFINITY;
final kDoubleNegativeInfinity = double.NEGATIVE_INFINITY;
final kDoubleNaN = double.NAN;
final kFloatInfinity = double.INFINITY;
final kFloatNegativeInfinity = double.NEGATIVE_INFINITY;
final kFloatNaN = double.NAN;


class Bar extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  
  static final int Type_VERTICAL = 1;
  static final int Type_HORIZONTAL = Type_VERTICAL + 1;
  static final int Type_BOTH = Type_HORIZONTAL + 1;
  static final int Type_INVALID = Type_BOTH + 1;
  int alpha = 0xff;
  int beta = 0;
  int gamma = 0;
  int type = Bar.Type_VERTICAL;

  Bar() : super(kStructSize);

  static Bar deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Bar decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Bar result = new Bar();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.alpha = decoder0.decodeUint8(8);
    }
    {
      
      result.beta = decoder0.decodeUint8(9);
    }
    {
      
      result.gamma = decoder0.decodeUint8(10);
    }
    {
      
      result.type = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint8(alpha, 8);
    
    encoder0.encodeUint8(beta, 9);
    
    encoder0.encodeUint8(gamma, 10);
    
    encoder0.encodeInt32(type, 12);
  }

  String toString() {
    return "Bar("
           "alpha: $alpha" ", "
           "beta: $beta" ", "
           "gamma: $gamma" ", "
           "type: $type" ")";
  }
}

class Foo extends bindings.Struct {
  static const int kStructSize = 96;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  static final kFooby = "Fooby";
  int x = 0;
  int y = 0;
  bool a = true;
  bool b = false;
  bool c = false;
  core.MojoMessagePipeEndpoint source = null;
  Bar bar = null;
  List<int> data = null;
  List<Bar> extraBars = null;
  String name = Foo.kFooby;
  List<core.MojoDataPipeConsumer> inputStreams = null;
  List<core.MojoDataPipeProducer> outputStreams = null;
  List<List<bool>> arrayOfArrayOfBools = null;
  List<List<List<String>>> multiArrayOfStrings = null;
  List<bool> arrayOfBools = null;

  Foo() : super(kStructSize);

  static Foo deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Foo decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Foo result = new Foo();

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
    {
      
      result.a = decoder0.decodeBool(16, 0);
    }
    {
      
      result.b = decoder0.decodeBool(16, 1);
    }
    {
      
      result.c = decoder0.decodeBool(16, 2);
    }
    {
      
      result.source = decoder0.decodeMessagePipeHandle(20, true);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.bar = Bar.decode(decoder1);
    }
    {
      
      result.data = decoder0.decodeUint8Array(32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.extraBars = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.extraBars = new List<Bar>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.extraBars[i1] = Bar.decode(decoder2);
        }
      }
    }
    {
      
      result.name = decoder0.decodeString(48, false);
    }
    {
      
      result.inputStreams = decoder0.decodeConsumerHandleArray(56, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.outputStreams = decoder0.decodeProducerHandleArray(64, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      var decoder1 = decoder0.decodePointer(72, true);
      if (decoder1 == null) {
        result.arrayOfArrayOfBools = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.arrayOfArrayOfBools = new List<List<bool>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.arrayOfArrayOfBools[i1] = decoder1.decodeBoolArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(80, true);
      if (decoder1 == null) {
        result.multiArrayOfStrings = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.multiArrayOfStrings = new List<List<List<String>>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
            result.multiArrayOfStrings[i1] = new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              var decoder3 = decoder2.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
                result.multiArrayOfStrings[i1][i2] = new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  
                  result.multiArrayOfStrings[i1][i2][i3] = decoder3.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i3, false);
                }
              }
            }
          }
        }
      }
    }
    {
      
      result.arrayOfBools = decoder0.decodeBoolArray(88, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(x, 8);
    
    encoder0.encodeInt32(y, 12);
    
    encoder0.encodeBool(a, 16, 0);
    
    encoder0.encodeBool(b, 16, 1);
    
    encoder0.encodeBool(c, 16, 2);
    
    encoder0.encodeMessagePipeHandle(source, 20, true);
    
    encoder0.encodeStruct(bar, 24, true);
    
    encoder0.encodeUint8Array(data, 32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    
    if (extraBars == null) {
      encoder0.encodeNullPointer(40, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(extraBars.length, 40, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < extraBars.length; ++i0) {
        
        encoder1.encodeStruct(extraBars[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeString(name, 48, false);
    
    encoder0.encodeConsumerHandleArray(inputStreams, 56, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeProducerHandleArray(outputStreams, 64, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    
    if (arrayOfArrayOfBools == null) {
      encoder0.encodeNullPointer(72, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(arrayOfArrayOfBools.length, 72, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < arrayOfArrayOfBools.length; ++i0) {
        
        encoder1.encodeBoolArray(arrayOfArrayOfBools[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      }
    }
    
    if (multiArrayOfStrings == null) {
      encoder0.encodeNullPointer(80, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(multiArrayOfStrings.length, 80, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < multiArrayOfStrings.length; ++i0) {
        
        if (multiArrayOfStrings[i0] == null) {
          encoder1.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        } else {
          var encoder2 = encoder1.encodePointerArray(multiArrayOfStrings[i0].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < multiArrayOfStrings[i0].length; ++i1) {
            
            if (multiArrayOfStrings[i0][i1] == null) {
              encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
            } else {
              var encoder3 = encoder2.encodePointerArray(multiArrayOfStrings[i0][i1].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kUnspecifiedArrayLength);
              for (int i2 = 0; i2 < multiArrayOfStrings[i0][i1].length; ++i2) {
                
                encoder3.encodeString(multiArrayOfStrings[i0][i1][i2], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
              }
            }
          }
        }
      }
    }
    
    encoder0.encodeBoolArray(arrayOfBools, 88, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "Foo("
           "x: $x" ", "
           "y: $y" ", "
           "a: $a" ", "
           "b: $b" ", "
           "c: $c" ", "
           "source: $source" ", "
           "bar: $bar" ", "
           "data: $data" ", "
           "extraBars: $extraBars" ", "
           "name: $name" ", "
           "inputStreams: $inputStreams" ", "
           "outputStreams: $outputStreams" ", "
           "arrayOfArrayOfBools: $arrayOfArrayOfBools" ", "
           "multiArrayOfStrings: $multiArrayOfStrings" ", "
           "arrayOfBools: $arrayOfBools" ")";
  }
}

class DefaultsTest extends bindings.Struct {
  static const int kStructSize = 184;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int a0 = -12;
  int a1 = kTwelve;
  int a2 = 1234;
  int a3 = 34567;
  bool a11 = true;
  bool a12 = false;
  int a4 = 123456;
  int a5 = 3456789012;
  int a6 = -111111111111;
  int a7 = 9999999999999999999;
  int a8 = 0x12345;
  int a9 = -0x12345;
  int a10 = 1234;
  double a13 = 123.25;
  double a14 = 1234567890.123;
  double a15 = 1E10;
  double a16 = -1.2E+20;
  double a17 = 1.23E-20;
  List<int> a18 = null;
  String a19 = null;
  int a20 = Bar.Type_BOTH;
  double a29 = double.INFINITY;
  sample_import_mojom.Point a21 = null;
  sample_import2_mojom.Thing a22 = new sample_import2_mojom.Thing();
  int a23 = 0xFFFFFFFFFFFFFFFF;
  int a24 = 0x123456789;
  int a25 = -0x123456789;
  double a26 = double.INFINITY;
  double a27 = double.NEGATIVE_INFINITY;
  double a28 = double.NAN;
  double a30 = double.NEGATIVE_INFINITY;
  double a31 = double.NAN;

  DefaultsTest() : super(kStructSize);

  static DefaultsTest deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DefaultsTest decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DefaultsTest result = new DefaultsTest();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.a0 = decoder0.decodeInt8(8);
    }
    {
      
      result.a1 = decoder0.decodeUint8(9);
    }
    {
      
      result.a2 = decoder0.decodeInt16(10);
    }
    {
      
      result.a3 = decoder0.decodeUint16(12);
    }
    {
      
      result.a11 = decoder0.decodeBool(14, 0);
    }
    {
      
      result.a12 = decoder0.decodeBool(14, 1);
    }
    {
      
      result.a4 = decoder0.decodeInt32(16);
    }
    {
      
      result.a5 = decoder0.decodeUint32(20);
    }
    {
      
      result.a6 = decoder0.decodeInt64(24);
    }
    {
      
      result.a7 = decoder0.decodeUint64(32);
    }
    {
      
      result.a8 = decoder0.decodeInt32(40);
    }
    {
      
      result.a9 = decoder0.decodeInt32(44);
    }
    {
      
      result.a10 = decoder0.decodeInt32(48);
    }
    {
      
      result.a13 = decoder0.decodeFloat(52);
    }
    {
      
      result.a14 = decoder0.decodeDouble(56);
    }
    {
      
      result.a15 = decoder0.decodeDouble(64);
    }
    {
      
      result.a16 = decoder0.decodeDouble(72);
    }
    {
      
      result.a17 = decoder0.decodeDouble(80);
    }
    {
      
      result.a18 = decoder0.decodeUint8Array(88, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    {
      
      result.a19 = decoder0.decodeString(96, false);
    }
    {
      
      result.a20 = decoder0.decodeInt32(104);
    }
    {
      
      result.a29 = decoder0.decodeFloat(108);
    }
    {
      
      var decoder1 = decoder0.decodePointer(112, false);
      result.a21 = sample_import_mojom.Point.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(120, false);
      result.a22 = sample_import2_mojom.Thing.decode(decoder1);
    }
    {
      
      result.a23 = decoder0.decodeUint64(128);
    }
    {
      
      result.a24 = decoder0.decodeInt64(136);
    }
    {
      
      result.a25 = decoder0.decodeInt64(144);
    }
    {
      
      result.a26 = decoder0.decodeDouble(152);
    }
    {
      
      result.a27 = decoder0.decodeDouble(160);
    }
    {
      
      result.a28 = decoder0.decodeDouble(168);
    }
    {
      
      result.a30 = decoder0.decodeFloat(176);
    }
    {
      
      result.a31 = decoder0.decodeFloat(180);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt8(a0, 8);
    
    encoder0.encodeUint8(a1, 9);
    
    encoder0.encodeInt16(a2, 10);
    
    encoder0.encodeUint16(a3, 12);
    
    encoder0.encodeBool(a11, 14, 0);
    
    encoder0.encodeBool(a12, 14, 1);
    
    encoder0.encodeInt32(a4, 16);
    
    encoder0.encodeUint32(a5, 20);
    
    encoder0.encodeInt64(a6, 24);
    
    encoder0.encodeUint64(a7, 32);
    
    encoder0.encodeInt32(a8, 40);
    
    encoder0.encodeInt32(a9, 44);
    
    encoder0.encodeInt32(a10, 48);
    
    encoder0.encodeFloat(a13, 52);
    
    encoder0.encodeDouble(a14, 56);
    
    encoder0.encodeDouble(a15, 64);
    
    encoder0.encodeDouble(a16, 72);
    
    encoder0.encodeDouble(a17, 80);
    
    encoder0.encodeUint8Array(a18, 88, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeString(a19, 96, false);
    
    encoder0.encodeInt32(a20, 104);
    
    encoder0.encodeFloat(a29, 108);
    
    encoder0.encodeStruct(a21, 112, false);
    
    encoder0.encodeStruct(a22, 120, false);
    
    encoder0.encodeUint64(a23, 128);
    
    encoder0.encodeInt64(a24, 136);
    
    encoder0.encodeInt64(a25, 144);
    
    encoder0.encodeDouble(a26, 152);
    
    encoder0.encodeDouble(a27, 160);
    
    encoder0.encodeDouble(a28, 168);
    
    encoder0.encodeFloat(a30, 176);
    
    encoder0.encodeFloat(a31, 180);
  }

  String toString() {
    return "DefaultsTest("
           "a0: $a0" ", "
           "a1: $a1" ", "
           "a2: $a2" ", "
           "a3: $a3" ", "
           "a11: $a11" ", "
           "a12: $a12" ", "
           "a4: $a4" ", "
           "a5: $a5" ", "
           "a6: $a6" ", "
           "a7: $a7" ", "
           "a8: $a8" ", "
           "a9: $a9" ", "
           "a10: $a10" ", "
           "a13: $a13" ", "
           "a14: $a14" ", "
           "a15: $a15" ", "
           "a16: $a16" ", "
           "a17: $a17" ", "
           "a18: $a18" ", "
           "a19: $a19" ", "
           "a20: $a20" ", "
           "a29: $a29" ", "
           "a21: $a21" ", "
           "a22: $a22" ", "
           "a23: $a23" ", "
           "a24: $a24" ", "
           "a25: $a25" ", "
           "a26: $a26" ", "
           "a27: $a27" ", "
           "a28: $a28" ", "
           "a30: $a30" ", "
           "a31: $a31" ")";
  }
}

class StructWithHoleV1 extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int v1 = 1;
  int v2 = 2;

  StructWithHoleV1() : super(kStructSize);

  static StructWithHoleV1 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructWithHoleV1 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructWithHoleV1 result = new StructWithHoleV1();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.v1 = decoder0.decodeInt32(8);
    }
    {
      
      result.v2 = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(v1, 8);
    
    encoder0.encodeInt64(v2, 16);
  }

  String toString() {
    return "StructWithHoleV1("
           "v1: $v1" ", "
           "v2: $v2" ")";
  }
}

class StructWithHoleV2 extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int v1 = 1;
  int v3 = 3;
  int v2 = 2;

  StructWithHoleV2() : super(kStructSize);

  static StructWithHoleV2 deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructWithHoleV2 decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructWithHoleV2 result = new StructWithHoleV2();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.v1 = decoder0.decodeInt32(8);
    }
    {
      
      result.v3 = decoder0.decodeInt32(12);
    }
    {
      
      result.v2 = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(v1, 8);
    
    encoder0.encodeInt32(v3, 12);
    
    encoder0.encodeInt64(v2, 16);
  }

  String toString() {
    return "StructWithHoleV2("
           "v1: $v1" ", "
           "v3: $v3" ", "
           "v2: $v2" ")";
  }
}

class ServiceFrobinateParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Foo foo = null;
  int baz = 0;
  Object port = null;

  ServiceFrobinateParams() : super(kStructSize);

  static ServiceFrobinateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ServiceFrobinateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceFrobinateParams result = new ServiceFrobinateParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.foo = Foo.decode(decoder1);
    }
    {
      
      result.baz = decoder0.decodeInt32(16);
    }
    {
      
      result.port = decoder0.decodeServiceInterface(20, true, PortProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(foo, 8, true);
    
    encoder0.encodeInt32(baz, 16);
    
    encoder0.encodeInterface(port, 20, true);
  }

  String toString() {
    return "ServiceFrobinateParams("
           "foo: $foo" ", "
           "baz: $baz" ", "
           "port: $port" ")";
  }
}

class ServiceFrobinateResponseParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int result = 0;

  ServiceFrobinateResponseParams() : super(kStructSize);

  static ServiceFrobinateResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ServiceFrobinateResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceFrobinateResponseParams result = new ServiceFrobinateResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.result = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(result, 8);
  }

  String toString() {
    return "ServiceFrobinateResponseParams("
           "result: $result" ")";
  }
}

class ServiceGetPortParams extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Object port = null;

  ServiceGetPortParams() : super(kStructSize);

  static ServiceGetPortParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ServiceGetPortParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ServiceGetPortParams result = new ServiceGetPortParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.port = decoder0.decodeInterfaceRequest(8, false, PortStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInterfaceRequest(port, 8, false);
  }

  String toString() {
    return "ServiceGetPortParams("
           "port: $port" ")";
  }
}

class PortPostMessageParams extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  String messageText = null;
  Object port = null;

  PortPostMessageParams() : super(kStructSize);

  static PortPostMessageParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static PortPostMessageParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    PortPostMessageParams result = new PortPostMessageParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.messageText = decoder0.decodeString(8, false);
    }
    {
      
      result.port = decoder0.decodeServiceInterface(16, false, PortProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeString(messageText, 8, false);
    
    encoder0.encodeInterface(port, 16, false);
  }

  String toString() {
    return "PortPostMessageParams("
           "messageText: $messageText" ", "
           "port: $port" ")";
  }
}
const int kService_frobinate_name = 0;
const int kService_getPort_name = 1;

const String ServiceName =
      'sample::Service';

abstract class Service {
  Future<ServiceFrobinateResponseParams> frobinate(Foo foo,int baz,Object port,[Function responseFactory = null]);
  void getPort(Object port);

  static final FAVORITE_BAZ = 1;
  
  static final int BazOptions_REGULAR = 0;
  static final int BazOptions_EXTRA = BazOptions_REGULAR + 1;
}


class ServiceProxyImpl extends bindings.Proxy {
  ServiceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ServiceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ServiceProxyImpl.unbound() : super.unbound();

  static ServiceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceProxyImpl.fromEndpoint(endpoint);

  String get name => ServiceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kService_frobinate_name:
        var r = ServiceFrobinateResponseParams.deserialize(
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
    return "ServiceProxyImpl($superString)";
  }
}


class _ServiceProxyCalls implements Service {
  ServiceProxyImpl _proxyImpl;

  _ServiceProxyCalls(this._proxyImpl);
    Future<ServiceFrobinateResponseParams> frobinate(Foo foo,int baz,Object port,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ServiceFrobinateParams();
      params.foo = foo;
      params.baz = baz;
      params.port = port;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kService_frobinate_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    void getPort(Object port) {
      assert(_proxyImpl.isBound);
      var params = new ServiceGetPortParams();
      params.port = port;
      _proxyImpl.sendMessage(params, kService_getPort_name);
    }
  
}


class ServiceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Service ptr;
  final String name = ServiceName;

  ServiceProxy(ServiceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ServiceProxyCalls(proxyImpl);

  ServiceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ServiceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ServiceProxyCalls(impl);
  }

  ServiceProxy.fromHandle(core.MojoHandle handle) :
      impl = new ServiceProxyImpl.fromHandle(handle) {
    ptr = new _ServiceProxyCalls(impl);
  }

  ServiceProxy.unbound() :
      impl = new ServiceProxyImpl.unbound() {
    ptr = new _ServiceProxyCalls(impl);
  }

  static ServiceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "ServiceProxy($impl)";
  }
}


class ServiceStub extends bindings.Stub {
  Service _impl = null;

  ServiceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ServiceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ServiceStub.unbound() : super.unbound();

  static ServiceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ServiceStub.fromEndpoint(endpoint);

  static const String name = ServiceName;


  ServiceFrobinateResponseParams _ServiceFrobinateResponseParamsFactory(int result) {
    var result = new ServiceFrobinateResponseParams();
    result.result = result;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kService_frobinate_name:
        var params = ServiceFrobinateParams.deserialize(
            message.payload);
        return _impl.frobinate(params.foo,params.baz,params.port,_ServiceFrobinateResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kService_frobinate_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kService_getPort_name:
        var params = ServiceGetPortParams.deserialize(
            message.payload);
        _impl.getPort(params.port);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Service get impl => _impl;
      set impl(Service d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ServiceStub($superString)";
  }
}

const int kPort_postMessage_name = 0;

const String PortName =
      'sample::Port';

abstract class Port {
  void postMessage(String messageText, Object port);

}


class PortProxyImpl extends bindings.Proxy {
  PortProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  PortProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  PortProxyImpl.unbound() : super.unbound();

  static PortProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new PortProxyImpl.fromEndpoint(endpoint);

  String get name => PortName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "PortProxyImpl($superString)";
  }
}


class _PortProxyCalls implements Port {
  PortProxyImpl _proxyImpl;

  _PortProxyCalls(this._proxyImpl);
    void postMessage(String messageText, Object port) {
      assert(_proxyImpl.isBound);
      var params = new PortPostMessageParams();
      params.messageText = messageText;
      params.port = port;
      _proxyImpl.sendMessage(params, kPort_postMessage_name);
    }
  
}


class PortProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  Port ptr;
  final String name = PortName;

  PortProxy(PortProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _PortProxyCalls(proxyImpl);

  PortProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new PortProxyImpl.fromEndpoint(endpoint) {
    ptr = new _PortProxyCalls(impl);
  }

  PortProxy.fromHandle(core.MojoHandle handle) :
      impl = new PortProxyImpl.fromHandle(handle) {
    ptr = new _PortProxyCalls(impl);
  }

  PortProxy.unbound() :
      impl = new PortProxyImpl.unbound() {
    ptr = new _PortProxyCalls(impl);
  }

  static PortProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new PortProxy.fromEndpoint(endpoint);

  Future close({bool nodefer: false}) => impl.close(nodefer: nodefer);

  String toString() {
    return "PortProxy($impl)";
  }
}


class PortStub extends bindings.Stub {
  Port _impl = null;

  PortStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  PortStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  PortStub.unbound() : super.unbound();

  static PortStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new PortStub.fromEndpoint(endpoint);

  static const String name = PortName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kPort_postMessage_name:
        var params = PortPostMessageParams.deserialize(
            message.payload);
        _impl.postMessage(params.messageText, params.port);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  Port get impl => _impl;
      set impl(Port d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "PortStub($superString)";
  }
}


