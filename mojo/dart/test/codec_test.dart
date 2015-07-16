// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:_testing/expect.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;

class Bar extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 4);

  static final int Type_VERTICAL = 1;
  static final int Type_HORIZONTAL = Type_VERTICAL + 1;
  static final int Type_BOTH = Type_HORIZONTAL + 1;
  static final int Type_INVALID = Type_BOTH + 1;
  int alpha;
  int beta;
  int gamma;
  int type;

  Bar() : super(kStructSize) {
    alpha = 0xff;
    type = Bar.Type_VERTICAL;
  }

  static Bar deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Bar decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Bar result = new Bar();
    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version > 0) {
      result.alpha = decoder0.decodeUint8(8);
    }
    if (mainDataHeader.version > 1) {
      result.beta = decoder0.decodeUint8(9);
    }
    if (mainDataHeader.version > 2) {
      result.gamma = decoder0.decodeUint8(10);
    }
    if (mainDataHeader.version > 3) {
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
}

void testBar() {
  var bar = new Bar();
  bar.alpha = 1;
  bar.beta = 2;
  bar.gamma = 3;
  bar.type = 0x08070605;

  int name = 42;
  var header = new bindings.MessageHeader(name);
  var message = bar.serializeWithHeader(header);

  var expectedMemory = new Uint8List.fromList([
    16,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    42,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    16,
    0,
    0,
    0,
    4,
    0,
    0,
    0,
    1,
    2,
    3,
    0,
    5,
    6,
    7,
    8,
  ]);

  var actualMemory = message.buffer.buffer.asUint8List();
  Expect.listEquals(expectedMemory, actualMemory);

  var receivedMessage = new bindings.ServiceMessage.fromMessage(message);

  Expect.equals(receivedMessage.header.size, header.size);
  Expect.equals(receivedMessage.header.type, header.type);

  var bar2 = Bar.deserialize(receivedMessage.payload);

  Expect.equals(bar.alpha, bar2.alpha);
  Expect.equals(bar.beta, bar2.beta);
  Expect.equals(bar.gamma, bar2.gamma);
  Expect.equals(bar.type, bar2.type);
}

class Foo extends bindings.Struct {
  static const int kStructSize = 96;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 15);
  static final kFooby = "Fooby";
  int x = 0;
  int y = 0;
  bool a = true;
  bool b = false;
  bool c = false;
  core.MojoHandle source = null;
  Bar bar = null;
  List<int> data = null;
  List<Bar> extraBars = null;
  String name = Foo.kFooby;
  List<core.MojoHandle> inputStreams = null;
  List<core.MojoHandle> outputStreams = null;
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
    if (mainDataHeader.version > 0) {
      result.x = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version > 1) {
      result.y = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version > 2) {
      result.a = decoder0.decodeBool(16, 0);
    }
    if (mainDataHeader.version > 3) {
      result.b = decoder0.decodeBool(16, 1);
    }
    if (mainDataHeader.version > 4) {
      result.c = decoder0.decodeBool(16, 2);
    }
    if (mainDataHeader.version > 9) {
      result.source = decoder0.decodeHandle(20, true);
    }
    if (mainDataHeader.version > 5) {
      var decoder1 = decoder0.decodePointer(24, true);
      result.bar = Bar.decode(decoder1);
    }
    if (mainDataHeader.version > 6) {
      result.data = decoder0.decodeUint8Array(
          32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    if (mainDataHeader.version > 7) {
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.extraBars = null;
      } else {
        var si1 = decoder1
            .decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.extraBars = new List<Bar>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          var decoder2 = decoder1.decodePointer(
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1,
              false);
          result.extraBars[i1] = Bar.decode(decoder2);
        }
      }
    }
    if (mainDataHeader.version > 8) {
      result.name = decoder0.decodeString(48, false);
    }
    if (mainDataHeader.version > 10) {
      result.inputStreams = decoder0.decodeHandleArray(
          56, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    if (mainDataHeader.version > 11) {
      result.outputStreams = decoder0.decodeHandleArray(
          64, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    if (mainDataHeader.version > 12) {
      var decoder1 = decoder0.decodePointer(72, true);
      if (decoder1 == null) {
        result.arrayOfArrayOfBools = null;
      } else {
        var si1 = decoder1
            .decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.arrayOfArrayOfBools = new List<List<bool>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          result.arrayOfArrayOfBools[i1] = decoder1.decodeBoolArray(
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1,
              bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    if (mainDataHeader.version > 13) {
      var decoder1 = decoder0.decodePointer(80, true);
      if (decoder1 == null) {
        result.multiArrayOfStrings = null;
      } else {
        var si1 = decoder1
            .decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.multiArrayOfStrings =
            new List<List<List<String>>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          var decoder2 = decoder1.decodePointer(
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1,
              false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(
                bindings.kUnspecifiedArrayLength);
            result.multiArrayOfStrings[i1] =
                new List<List<String>>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              var decoder3 = decoder2.decodePointer(
                  bindings.ArrayDataHeader.kHeaderSize +
                      bindings.kPointerSize * i2, false);
              {
                var si3 = decoder3.decodeDataHeaderForPointerArray(
                    bindings.kUnspecifiedArrayLength);
                result.multiArrayOfStrings[i1][i2] =
                    new List<String>(si3.numElements);
                for (int i3 = 0; i3 < si3.numElements; ++i3) {
                  var length = bindings.ArrayDataHeader.kHeaderSize +
                      bindings.kPointerSize * i3;
                  result.multiArrayOfStrings[i1][i2][i3] =
                      decoder3.decodeString(length, false);
                }
              }
            }
          }
        }
      }
    }
    if (mainDataHeader.version > 14) {
      result.arrayOfBools = decoder0.decodeBoolArray(
          88, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
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
    encoder0.encodeHandle(source, 20, true);
    encoder0.encodeStruct(bar, 24, true);
    encoder0.encodeUint8Array(
        data, 32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);

    if (extraBars == null) {
      encoder0.encodeNullPointer(40, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(
          extraBars.length, 40, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < extraBars.length; ++i0) {
        encoder1.encodeStruct(extraBars[i0],
            bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0,
            false);
      }
    }

    encoder0.encodeString(name, 48, false);
    encoder0.encodeHandleArray(inputStreams, 56,
        bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    encoder0.encodeHandleArray(outputStreams, 64, bindings.kArrayNullable,
        bindings.kUnspecifiedArrayLength);

    if (arrayOfArrayOfBools == null) {
      encoder0.encodeNullPointer(72, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(
          arrayOfArrayOfBools.length, 72, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < arrayOfArrayOfBools.length; ++i0) {
        encoder1.encodeBoolArray(arrayOfArrayOfBools[i0],
            bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0,
            bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      }
    }

    if (multiArrayOfStrings == null) {
      encoder0.encodeNullPointer(80, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(
          multiArrayOfStrings.length, 80, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < multiArrayOfStrings.length; ++i0) {
        if (multiArrayOfStrings[i0] == null) {
          encoder1.encodeNullPointer(
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0,
              false);
        } else {
          var encoder2 = encoder1.encodePointerArray(
              multiArrayOfStrings[i0].length,
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0,
              bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < multiArrayOfStrings[i0].length; ++i1) {
            if (multiArrayOfStrings[i0][i1] == null) {
              encoder2.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize +
                  bindings.kPointerSize * i1, false);
            } else {
              var encoder3 = encoder2.encodePointerArray(
                  multiArrayOfStrings[i0][i1].length,
                  bindings.ArrayDataHeader.kHeaderSize +
                      bindings.kPointerSize * i1,
                  bindings.kUnspecifiedArrayLength);
              for (int i2 = 0; i2 < multiArrayOfStrings[i0][i1].length; ++i2) {
                var length = bindings.ArrayDataHeader.kHeaderSize +
                    bindings.kPointerSize * i2;
                encoder3.encodeString(
                    multiArrayOfStrings[i0][i1][i2], length, false);
              }
            }
          }
        }
      }
    }

    encoder0.encodeBoolArray(arrayOfBools, 88, bindings.kArrayNullable,
        bindings.kUnspecifiedArrayLength);
  }
}

void testFoo() {
  var foo = new Foo();
  foo.x = 0x212B4D5;
  foo.y = 0x16E93;
  foo.a = true;
  foo.b = false;
  foo.c = true;
  foo.bar = new Bar();
  foo.bar.alpha = 91;
  foo.bar.beta = 82;
  foo.bar.gamma = 73;
  foo.data = [4, 5, 6, 7, 8,];
  foo.extraBars = [new Bar(), new Bar(), new Bar(),];
  for (int i = 0; i < foo.extraBars.length; ++i) {
    foo.extraBars[i].alpha = 1 * i;
    foo.extraBars[i].beta = 2 * i;
    foo.extraBars[i].gamma = 3 * i;
  }
  foo.name = "I am a banana";
  // This is supposed to be a handle, but we fake it with an integer.
  foo.source = new core.MojoHandle(23423782);
  foo.arrayOfArrayOfBools = [[true], [false, true]];
  foo.arrayOfBools = [true, false, true, false, true, false, true, true];

  int name = 31;
  var header = new bindings.MessageHeader(name);
  var message = foo.serializeWithHeader(header);

  var expectedMemory = new Uint8List.fromList([
    /*  0: */ 16,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /*  8: */ 31,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /* 16: */ 96,
    0,
    0,
    0,
    15,
    0,
    0,
    0,
    /* 24: */ 0xD5,
    0xB4,
    0x12,
    0x02,
    0x93,
    0x6E,
    0x01,
    0,
    /* 32: */ 5,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /* 40: */ 72,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]);

  var allActualMemory = message.buffer.buffer.asUint8List();
  var actualMemory = allActualMemory.sublist(0, expectedMemory.length);
  Expect.listEquals(expectedMemory, actualMemory);

  var expectedHandles = <core.MojoHandle>[new core.MojoHandle(23423782),];

  Expect.listEquals(expectedHandles, message.handles);

  var receivedMessage = new bindings.ServiceMessage.fromMessage(message);

  Expect.equals(receivedMessage.header.size, header.size);
  Expect.equals(receivedMessage.header.type, header.type);

  var foo2 = Foo.deserialize(receivedMessage.payload);

  Expect.equals(foo.x, foo2.x);
  Expect.equals(foo.y, foo2.y);

  Expect.equals(foo.a, foo2.a);
  Expect.equals(foo.b, foo2.b);
  Expect.equals(foo.c, foo2.c);

  Expect.equals(foo.bar.alpha, foo2.bar.alpha);
  Expect.equals(foo.bar.beta, foo2.bar.beta);
  Expect.equals(foo.bar.gamma, foo2.bar.gamma);
  Expect.equals(foo.bar.type, foo2.bar.type);
  Expect.listEquals(foo.data, foo2.data);

  for (int i = 0; i < foo2.extraBars.length; i++) {
    Expect.equals(foo.extraBars[i].alpha, foo2.extraBars[i].alpha);
    Expect.equals(foo.extraBars[i].beta, foo2.extraBars[i].beta);
    Expect.equals(foo.extraBars[i].gamma, foo2.extraBars[i].gamma);
    Expect.equals(foo.extraBars[i].type, foo2.extraBars[i].type);
  }

  Expect.equals(foo.name, foo2.name);
  Expect.equals(foo.source, foo2.source);

  Expect.listEquals(foo.arrayOfBools, foo2.arrayOfBools);
  for (int i = 0; i < foo2.arrayOfArrayOfBools.length; i++) {
    Expect.listEquals(foo.arrayOfArrayOfBools[i], foo2.arrayOfArrayOfBools[i]);
  }
}

class Rect extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 4);
  int x;
  int y;
  int width;
  int height;

  Rect() : super(kStructSize);

  static Rect deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Rect decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Rect result = new Rect();
    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version > 0) {
      result.x = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version > 1) {
      result.y = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version > 2) {
      result.width = decoder0.decodeInt32(16);
    }
    if (mainDataHeader.version > 3) {
      result.height = decoder0.decodeInt32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    encoder0.encodeInt32(x, 8);
    encoder0.encodeInt32(y, 12);
    encoder0.encodeInt32(width, 16);
    encoder0.encodeInt32(height, 20);
  }

  bool operator ==(Rect other) => (this.x == other.x) &&
      (this.y == other.y) &&
      (this.width == other.width) &&
      (this.height == other.height);
}

Rect createRect(int x, int y, int width, int height) {
  var r = new Rect();
  r.x = x;
  r.y = y;
  r.width = width;
  r.height = height;
  return r;
}

class NamedRegion extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 2);
  String name;
  List<Rect> rects;

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
    if (mainDataHeader.version > 0) {
      result.name = decoder0.decodeString(8, true);
    }
    if (mainDataHeader.version > 1) {
      var decoder1 = decoder0.decodePointer(16, true);
      if (decoder1 == null) {
        result.rects = null;
      } else {
        var si1 = decoder1
            .decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.rects = new List<Rect>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          var decoder2 = decoder1.decodePointer(
              bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1,
              false);
          result.rects[i1] = Rect.decode(decoder2);
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
      var encoder1 = encoder0.encodePointerArray(
          rects.length, 16, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < rects.length; ++i0) {
        encoder1.encodeStruct(rects[i0],
            bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0,
            false);
      }
    }
  }
}

testNamedRegion() {
  var r = new NamedRegion();
  r.name = "rectangle";
  r.rects = [createRect(1, 2, 3, 4), createRect(10, 20, 30, 40)];

  int name = 1;
  var header = new bindings.MessageHeader(name);
  var message = r.serializeWithHeader(header);
  var resultMessage = new bindings.ServiceMessage.fromMessage(message);
  var result = NamedRegion.deserialize(resultMessage.payload);

  Expect.equals("rectangle", result.name);
  Expect.equals(createRect(1, 2, 3, 4), result.rects[0]);
  Expect.equals(createRect(10, 20, 30, 40), result.rects[1]);
}

void testAlign() {
  List aligned = [
    0, // 0
    8, // 1
    8, // 2
    8, // 3
    8, // 4
    8, // 5
    8, // 6
    8, // 7
    8, // 8
    16, // 9
    16, // 10
    16, // 11
    16, // 12
    16, // 13
    16, // 14
    16, // 15
    16, // 16
    24, // 17
    24, // 18
    24, // 19
    24, // 20
  ];
  for (int i = 0; i < aligned.length; ++i) {
    Expect.equals(bindings.align(i), aligned[i]);
  }
}

class MojoString extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 1);
  String string;
  MojoString() : super(kStructSize);

  static MojoString deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static MojoString decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    MojoString result = new MojoString();
    var mainDataHeader = decoder0.decodeStructDataHeader();
    result.string = decoder0.decodeString(8, false);
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    encoder0.encodeString(string, 8, false);
  }
}

testUtf8() {
  var str = "B\u03ba\u1f79"; // some UCS-2 codepoints.
  var name = 42;
  var payloadSize = 24;

  var mojoString = new MojoString();
  mojoString.string = str;

  var header = new bindings.MessageHeader(name);
  var message = mojoString.serializeWithHeader(header);
  var resultMessage = new bindings.ServiceMessage.fromMessage(message);
  var result = MojoString.deserialize(resultMessage.payload);

  var expectedMemory = new Uint8List.fromList([
    /*  0: */ 16,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /*  8: */ 42,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /* 16: */ 16,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    /* 24: */ 8,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    /* 32: */ 14,
    0,
    0,
    0,
    6,
    0,
    0,
    0,
    /* 40: */ 0x42,
    0xCE,
    0xBA,
    0xE1,
    0xBD,
    0xB9,
    0,
    0,
  ]);
  var allActualMemory = message.buffer.buffer.asUint8List();
  var actualMemory = allActualMemory.sublist(0, expectedMemory.length);
  Expect.equals(expectedMemory.length, actualMemory.length);
  Expect.listEquals(expectedMemory, actualMemory);

  Expect.equals(str, result.string);
}

main() {
  testAlign();
  testBar();
  testFoo();
  testNamedRegion();
  testUtf8();
}
