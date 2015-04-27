// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library validation_test_interfaces.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class StructA extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int i = 0;

  StructA() : super(kVersions.last.size);

  static StructA deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructA decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructA result = new StructA();

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
      
      result.i = decoder0.decodeUint64(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint64(i, 8);
  }

  String toString() {
    return "StructA("
           "i: $i" ")";
  }
}

class StructB extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  StructA structA = null;

  StructB() : super(kVersions.last.size);

  static StructB deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructB decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructB result = new StructB();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.structA = StructA.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(structA, 8, false);
  }

  String toString() {
    return "StructB("
           "structA: $structA" ")";
  }
}

class StructC extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<int> data = null;

  StructC() : super(kVersions.last.size);

  static StructC deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructC decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructC result = new StructC();

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
      
      result.data = decoder0.decodeUint8Array(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8Array(data, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "StructC("
           "data: $data" ")";
  }
}

class StructD extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<core.MojoMessagePipeEndpoint> messagePipes = null;

  StructD() : super(kVersions.last.size);

  static StructD deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructD decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructD result = new StructD();

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
      
      result.messagePipes = decoder0.decodeMessagePipeHandleArray(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeMessagePipeHandleArray(messagePipes, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "StructD("
           "messagePipes: $messagePipes" ")";
  }
}

class StructE extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  StructD structD = null;
  core.MojoDataPipeConsumer dataPipeConsumer = null;

  StructE() : super(kVersions.last.size);

  static StructE deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructE decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructE result = new StructE();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.structD = StructD.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.dataPipeConsumer = decoder0.decodeConsumerHandle(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(structD, 8, false);
    
    encoder0.encodeConsumerHandle(dataPipeConsumer, 16, false);
  }

  String toString() {
    return "StructE("
           "structD: $structD" ", "
           "dataPipeConsumer: $dataPipeConsumer" ")";
  }
}

class StructF extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<int> fixedSizeArray = null;

  StructF() : super(kVersions.last.size);

  static StructF deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructF decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructF result = new StructF();

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
      
      result.fixedSizeArray = decoder0.decodeUint8Array(8, bindings.kNothingNullable, 3);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8Array(fixedSizeArray, 8, bindings.kNothingNullable, 3);
  }

  String toString() {
    return "StructF("
           "fixedSizeArray: $fixedSizeArray" ")";
  }
}

class StructG extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0),
    const bindings.StructDataHeader(24, 1),
    const bindings.StructDataHeader(32, 3)
  ];
  int i = 0;
  bool b = false;
  StructA structA = null;
  String str = null;

  StructG() : super(kVersions.last.size);

  static StructG deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StructG decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StructG result = new StructG();

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
      
      result.i = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 3) {
      
      result.b = decoder0.decodeBool(12, 0);
    }
    if (mainDataHeader.version >= 1) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.structA = StructA.decode(decoder1);
    }
    if (mainDataHeader.version >= 3) {
      
      result.str = decoder0.decodeString(24, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(i, 8);
    
    encoder0.encodeBool(b, 12, 0);
    
    encoder0.encodeStruct(structA, 16, true);
    
    encoder0.encodeString(str, 24, true);
  }

  String toString() {
    return "StructG("
           "i: $i" ", "
           "b: $b" ", "
           "structA: $structA" ", "
           "str: $str" ")";
  }
}

class BasicStruct extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int a = 0;

  BasicStruct() : super(kVersions.last.size);

  static BasicStruct deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BasicStruct decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BasicStruct result = new BasicStruct();

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
      
      result.a = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(a, 8);
  }

  String toString() {
    return "BasicStruct("
           "a: $a" ")";
  }
}

class BoundsCheckTestInterfaceMethod0Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int param0 = 0;

  BoundsCheckTestInterfaceMethod0Params() : super(kVersions.last.size);

  static BoundsCheckTestInterfaceMethod0Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BoundsCheckTestInterfaceMethod0Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BoundsCheckTestInterfaceMethod0Params result = new BoundsCheckTestInterfaceMethod0Params();

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
      
      result.param0 = decoder0.decodeUint8(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8(param0, 8);
  }

  String toString() {
    return "BoundsCheckTestInterfaceMethod0Params("
           "param0: $param0" ")";
  }
}

class BoundsCheckTestInterfaceMethod0ResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int param0 = 0;

  BoundsCheckTestInterfaceMethod0ResponseParams() : super(kVersions.last.size);

  static BoundsCheckTestInterfaceMethod0ResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BoundsCheckTestInterfaceMethod0ResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BoundsCheckTestInterfaceMethod0ResponseParams result = new BoundsCheckTestInterfaceMethod0ResponseParams();

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
      
      result.param0 = decoder0.decodeUint8(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8(param0, 8);
  }

  String toString() {
    return "BoundsCheckTestInterfaceMethod0ResponseParams("
           "param0: $param0" ")";
  }
}

class BoundsCheckTestInterfaceMethod1Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int param0 = 0;

  BoundsCheckTestInterfaceMethod1Params() : super(kVersions.last.size);

  static BoundsCheckTestInterfaceMethod1Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static BoundsCheckTestInterfaceMethod1Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    BoundsCheckTestInterfaceMethod1Params result = new BoundsCheckTestInterfaceMethod1Params();

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
      
      result.param0 = decoder0.decodeUint8(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8(param0, 8);
  }

  String toString() {
    return "BoundsCheckTestInterfaceMethod1Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod0Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  double param0 = 0.0;

  ConformanceTestInterfaceMethod0Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod0Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod0Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod0Params result = new ConformanceTestInterfaceMethod0Params();

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
      
      result.param0 = decoder0.decodeFloat(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeFloat(param0, 8);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod0Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod1Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  StructA param0 = null;

  ConformanceTestInterfaceMethod1Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod1Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod1Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod1Params result = new ConformanceTestInterfaceMethod1Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructA.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod1Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod2Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  StructB param0 = null;
  StructA param1 = null;

  ConformanceTestInterfaceMethod2Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod2Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod2Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod2Params result = new ConformanceTestInterfaceMethod2Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructB.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.param1 = StructA.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
    
    encoder0.encodeStruct(param1, 16, false);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod2Params("
           "param0: $param0" ", "
           "param1: $param1" ")";
  }
}

class ConformanceTestInterfaceMethod3Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<bool> param0 = null;

  ConformanceTestInterfaceMethod3Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod3Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod3Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod3Params result = new ConformanceTestInterfaceMethod3Params();

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
      
      result.param0 = decoder0.decodeBoolArray(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBoolArray(param0, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod3Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod4Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  StructC param0 = null;
  List<int> param1 = null;

  ConformanceTestInterfaceMethod4Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod4Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod4Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod4Params result = new ConformanceTestInterfaceMethod4Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructC.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.param1 = decoder0.decodeUint8Array(16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
    
    encoder0.encodeUint8Array(param1, 16, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod4Params("
           "param0: $param0" ", "
           "param1: $param1" ")";
  }
}

class ConformanceTestInterfaceMethod5Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  StructE param0 = null;
  core.MojoDataPipeProducer param1 = null;

  ConformanceTestInterfaceMethod5Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod5Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod5Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod5Params result = new ConformanceTestInterfaceMethod5Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructE.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.param1 = decoder0.decodeProducerHandle(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
    
    encoder0.encodeProducerHandle(param1, 16, false);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod5Params("
           "param0: $param0" ", "
           "param1: $param1" ")";
  }
}

class ConformanceTestInterfaceMethod6Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<List<int>> param0 = null;

  ConformanceTestInterfaceMethod6Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod6Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod6Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod6Params result = new ConformanceTestInterfaceMethod6Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.param0 = new List<List<int>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.param0[i1] = decoder1.decodeUint8Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    if (param0 == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(param0.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < param0.length; ++i0) {
        
        encoder1.encodeUint8Array(param0[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
      }
    }
  }

  String toString() {
    return "ConformanceTestInterfaceMethod6Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod7Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  StructF param0 = null;
  List<List<int>> param1 = null;

  ConformanceTestInterfaceMethod7Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod7Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod7Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod7Params result = new ConformanceTestInterfaceMethod7Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructF.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(2);
        result.param1 = new List<List<int>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.param1[i1] = decoder1.decodeUint8Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kArrayNullable, 3);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
    
    if (param1 == null) {
      encoder0.encodeNullPointer(16, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(param1.length, 16, 2);
      for (int i0 = 0; i0 < param1.length; ++i0) {
        
        encoder1.encodeUint8Array(param1[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kArrayNullable, 3);
      }
    }
  }

  String toString() {
    return "ConformanceTestInterfaceMethod7Params("
           "param0: $param0" ", "
           "param1: $param1" ")";
  }
}

class ConformanceTestInterfaceMethod8Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<List<String>> param0 = null;

  ConformanceTestInterfaceMethod8Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod8Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod8Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod8Params result = new ConformanceTestInterfaceMethod8Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.param0 = new List<List<String>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, true);
          if (decoder2 == null) {
            result.param0[i1] = null;
          } else {
            var si2 = decoder2.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
            result.param0[i1] = new List<String>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              result.param0[i1][i2] = decoder2.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    if (param0 == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(param0.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < param0.length; ++i0) {
        
        if (param0[i0] == null) {
          encoder1.encodeNullPointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, true);
        } else {
          var encoder2 = encoder1.encodePointerArray(param0[i0].length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kUnspecifiedArrayLength);
          for (int i1 = 0; i1 < param0[i0].length; ++i1) {
            
            encoder2.encodeString(param0[i0][i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          }
        }
      }
    }
  }

  String toString() {
    return "ConformanceTestInterfaceMethod8Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod9Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<List<core.MojoHandle>> param0 = null;

  ConformanceTestInterfaceMethod9Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod9Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod9Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod9Params result = new ConformanceTestInterfaceMethod9Params();

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
      
      var decoder1 = decoder0.decodePointer(8, true);
      if (decoder1 == null) {
        result.param0 = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.param0 = new List<List<core.MojoHandle>>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.param0[i1] = decoder1.decodeHandleArray(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, bindings.kElementNullable, bindings.kUnspecifiedArrayLength);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    if (param0 == null) {
      encoder0.encodeNullPointer(8, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(param0.length, 8, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < param0.length; ++i0) {
        
        encoder1.encodeHandleArray(param0[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, bindings.kElementNullable, bindings.kUnspecifiedArrayLength);
      }
    }
  }

  String toString() {
    return "ConformanceTestInterfaceMethod9Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod10Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Map<String, int> param0 = null;

  ConformanceTestInterfaceMethod10Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod10Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod10Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod10Params result = new ConformanceTestInterfaceMethod10Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<int> values0;
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
          
          values0 = decoder1.decodeUint8Array(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, keys0.length);
        }
        result.param0 = new Map<String, int>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    if (param0 == null) {
      encoder0.encodeNullPointer(8, false);
    } else {
      var encoder1 = encoder0.encoderForMap(8);
      int size0 = param0.length;
      var keys0 = param0.keys.toList();
      var values0 = param0.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      encoder1.encodeUint8Array(values0, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
  }

  String toString() {
    return "ConformanceTestInterfaceMethod10Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod11Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  StructG param0 = null;

  ConformanceTestInterfaceMethod11Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod11Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod11Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod11Params result = new ConformanceTestInterfaceMethod11Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = StructG.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod11Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod12Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  double param0 = 0.0;

  ConformanceTestInterfaceMethod12Params() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod12Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod12Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod12Params result = new ConformanceTestInterfaceMethod12Params();

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
      
      result.param0 = decoder0.decodeFloat(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeFloat(param0, 8);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod12Params("
           "param0: $param0" ")";
  }
}

class ConformanceTestInterfaceMethod12ResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  double param0 = 0.0;

  ConformanceTestInterfaceMethod12ResponseParams() : super(kVersions.last.size);

  static ConformanceTestInterfaceMethod12ResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static ConformanceTestInterfaceMethod12ResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    ConformanceTestInterfaceMethod12ResponseParams result = new ConformanceTestInterfaceMethod12ResponseParams();

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
      
      result.param0 = decoder0.decodeFloat(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeFloat(param0, 8);
  }

  String toString() {
    return "ConformanceTestInterfaceMethod12ResponseParams("
           "param0: $param0" ")";
  }
}

class IntegrationTestInterfaceMethod0Params extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  BasicStruct param0 = null;

  IntegrationTestInterfaceMethod0Params() : super(kVersions.last.size);

  static IntegrationTestInterfaceMethod0Params deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static IntegrationTestInterfaceMethod0Params decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    IntegrationTestInterfaceMethod0Params result = new IntegrationTestInterfaceMethod0Params();

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
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.param0 = BasicStruct.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(param0, 8, false);
  }

  String toString() {
    return "IntegrationTestInterfaceMethod0Params("
           "param0: $param0" ")";
  }
}

class IntegrationTestInterfaceMethod0ResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  List<int> param0 = null;

  IntegrationTestInterfaceMethod0ResponseParams() : super(kVersions.last.size);

  static IntegrationTestInterfaceMethod0ResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static IntegrationTestInterfaceMethod0ResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    IntegrationTestInterfaceMethod0ResponseParams result = new IntegrationTestInterfaceMethod0ResponseParams();

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
      
      result.param0 = decoder0.decodeUint8Array(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8Array(param0, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "IntegrationTestInterfaceMethod0ResponseParams("
           "param0: $param0" ")";
  }
}
const int kBoundsCheckTestInterface_method0_name = 0;
const int kBoundsCheckTestInterface_method1_name = 1;

const String BoundsCheckTestInterfaceName =
      'mojo::test::BoundsCheckTestInterface';

abstract class BoundsCheckTestInterface {
  Future<BoundsCheckTestInterfaceMethod0ResponseParams> method0(int param0,[Function responseFactory = null]);
  void method1(int param0);

}


class BoundsCheckTestInterfaceProxyImpl extends bindings.Proxy {
  BoundsCheckTestInterfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  BoundsCheckTestInterfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  BoundsCheckTestInterfaceProxyImpl.unbound() : super.unbound();

  static BoundsCheckTestInterfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BoundsCheckTestInterfaceProxyImpl.fromEndpoint(endpoint);

  String get name => BoundsCheckTestInterfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kBoundsCheckTestInterface_method0_name:
        var r = BoundsCheckTestInterfaceMethod0ResponseParams.deserialize(
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
    return "BoundsCheckTestInterfaceProxyImpl($superString)";
  }
}


class _BoundsCheckTestInterfaceProxyCalls implements BoundsCheckTestInterface {
  BoundsCheckTestInterfaceProxyImpl _proxyImpl;

  _BoundsCheckTestInterfaceProxyCalls(this._proxyImpl);
    Future<BoundsCheckTestInterfaceMethod0ResponseParams> method0(int param0,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new BoundsCheckTestInterfaceMethod0Params();
      params.param0 = param0;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kBoundsCheckTestInterface_method0_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    void method1(int param0) {
      assert(_proxyImpl.isBound);
      var params = new BoundsCheckTestInterfaceMethod1Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kBoundsCheckTestInterface_method1_name);
    }
  
}


class BoundsCheckTestInterfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  BoundsCheckTestInterface ptr;
  final String name = BoundsCheckTestInterfaceName;

  BoundsCheckTestInterfaceProxy(BoundsCheckTestInterfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _BoundsCheckTestInterfaceProxyCalls(proxyImpl);

  BoundsCheckTestInterfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new BoundsCheckTestInterfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _BoundsCheckTestInterfaceProxyCalls(impl);
  }

  BoundsCheckTestInterfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new BoundsCheckTestInterfaceProxyImpl.fromHandle(handle) {
    ptr = new _BoundsCheckTestInterfaceProxyCalls(impl);
  }

  BoundsCheckTestInterfaceProxy.unbound() :
      impl = new BoundsCheckTestInterfaceProxyImpl.unbound() {
    ptr = new _BoundsCheckTestInterfaceProxyCalls(impl);
  }

  static BoundsCheckTestInterfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BoundsCheckTestInterfaceProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "BoundsCheckTestInterfaceProxy($impl)";
  }
}


class BoundsCheckTestInterfaceStub extends bindings.Stub {
  BoundsCheckTestInterface _impl = null;

  BoundsCheckTestInterfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  BoundsCheckTestInterfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  BoundsCheckTestInterfaceStub.unbound() : super.unbound();

  static BoundsCheckTestInterfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new BoundsCheckTestInterfaceStub.fromEndpoint(endpoint);

  static const String name = BoundsCheckTestInterfaceName;


  BoundsCheckTestInterfaceMethod0ResponseParams _BoundsCheckTestInterfaceMethod0ResponseParamsFactory(int param0) {
    var result = new BoundsCheckTestInterfaceMethod0ResponseParams();
    result.param0 = param0;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kBoundsCheckTestInterface_method0_name:
        var params = BoundsCheckTestInterfaceMethod0Params.deserialize(
            message.payload);
        return _impl.method0(params.param0,_BoundsCheckTestInterfaceMethod0ResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kBoundsCheckTestInterface_method0_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kBoundsCheckTestInterface_method1_name:
        var params = BoundsCheckTestInterfaceMethod1Params.deserialize(
            message.payload);
        _impl.method1(params.param0);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  BoundsCheckTestInterface get impl => _impl;
      set impl(BoundsCheckTestInterface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "BoundsCheckTestInterfaceStub($superString)";
  }
}

const int kConformanceTestInterface_method0_name = 0;
const int kConformanceTestInterface_method1_name = 1;
const int kConformanceTestInterface_method2_name = 2;
const int kConformanceTestInterface_method3_name = 3;
const int kConformanceTestInterface_method4_name = 4;
const int kConformanceTestInterface_method5_name = 5;
const int kConformanceTestInterface_method6_name = 6;
const int kConformanceTestInterface_method7_name = 7;
const int kConformanceTestInterface_method8_name = 8;
const int kConformanceTestInterface_method9_name = 9;
const int kConformanceTestInterface_method10_name = 10;
const int kConformanceTestInterface_method11_name = 11;
const int kConformanceTestInterface_method12_name = 12;

const String ConformanceTestInterfaceName =
      'mojo::test::ConformanceTestInterface';

abstract class ConformanceTestInterface {
  void method0(double param0);
  void method1(StructA param0);
  void method2(StructB param0, StructA param1);
  void method3(List<bool> param0);
  void method4(StructC param0, List<int> param1);
  void method5(StructE param0, core.MojoDataPipeProducer param1);
  void method6(List<List<int>> param0);
  void method7(StructF param0, List<List<int>> param1);
  void method8(List<List<String>> param0);
  void method9(List<List<core.MojoHandle>> param0);
  void method10(Map<String, int> param0);
  void method11(StructG param0);
  Future<ConformanceTestInterfaceMethod12ResponseParams> method12(double param0,[Function responseFactory = null]);

}


class ConformanceTestInterfaceProxyImpl extends bindings.Proxy {
  ConformanceTestInterfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  ConformanceTestInterfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  ConformanceTestInterfaceProxyImpl.unbound() : super.unbound();

  static ConformanceTestInterfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConformanceTestInterfaceProxyImpl.fromEndpoint(endpoint);

  String get name => ConformanceTestInterfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kConformanceTestInterface_method12_name:
        var r = ConformanceTestInterfaceMethod12ResponseParams.deserialize(
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
    return "ConformanceTestInterfaceProxyImpl($superString)";
  }
}


class _ConformanceTestInterfaceProxyCalls implements ConformanceTestInterface {
  ConformanceTestInterfaceProxyImpl _proxyImpl;

  _ConformanceTestInterfaceProxyCalls(this._proxyImpl);
    void method0(double param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod0Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method0_name);
    }
  
    void method1(StructA param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod1Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method1_name);
    }
  
    void method2(StructB param0, StructA param1) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod2Params();
      params.param0 = param0;
      params.param1 = param1;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method2_name);
    }
  
    void method3(List<bool> param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod3Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method3_name);
    }
  
    void method4(StructC param0, List<int> param1) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod4Params();
      params.param0 = param0;
      params.param1 = param1;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method4_name);
    }
  
    void method5(StructE param0, core.MojoDataPipeProducer param1) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod5Params();
      params.param0 = param0;
      params.param1 = param1;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method5_name);
    }
  
    void method6(List<List<int>> param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod6Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method6_name);
    }
  
    void method7(StructF param0, List<List<int>> param1) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod7Params();
      params.param0 = param0;
      params.param1 = param1;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method7_name);
    }
  
    void method8(List<List<String>> param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod8Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method8_name);
    }
  
    void method9(List<List<core.MojoHandle>> param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod9Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method9_name);
    }
  
    void method10(Map<String, int> param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod10Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method10_name);
    }
  
    void method11(StructG param0) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod11Params();
      params.param0 = param0;
      _proxyImpl.sendMessage(params, kConformanceTestInterface_method11_name);
    }
  
    Future<ConformanceTestInterfaceMethod12ResponseParams> method12(double param0,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new ConformanceTestInterfaceMethod12Params();
      params.param0 = param0;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kConformanceTestInterface_method12_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class ConformanceTestInterfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  ConformanceTestInterface ptr;
  final String name = ConformanceTestInterfaceName;

  ConformanceTestInterfaceProxy(ConformanceTestInterfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _ConformanceTestInterfaceProxyCalls(proxyImpl);

  ConformanceTestInterfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new ConformanceTestInterfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _ConformanceTestInterfaceProxyCalls(impl);
  }

  ConformanceTestInterfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new ConformanceTestInterfaceProxyImpl.fromHandle(handle) {
    ptr = new _ConformanceTestInterfaceProxyCalls(impl);
  }

  ConformanceTestInterfaceProxy.unbound() :
      impl = new ConformanceTestInterfaceProxyImpl.unbound() {
    ptr = new _ConformanceTestInterfaceProxyCalls(impl);
  }

  static ConformanceTestInterfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConformanceTestInterfaceProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "ConformanceTestInterfaceProxy($impl)";
  }
}


class ConformanceTestInterfaceStub extends bindings.Stub {
  ConformanceTestInterface _impl = null;

  ConformanceTestInterfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  ConformanceTestInterfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  ConformanceTestInterfaceStub.unbound() : super.unbound();

  static ConformanceTestInterfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new ConformanceTestInterfaceStub.fromEndpoint(endpoint);

  static const String name = ConformanceTestInterfaceName;


  ConformanceTestInterfaceMethod12ResponseParams _ConformanceTestInterfaceMethod12ResponseParamsFactory(double param0) {
    var result = new ConformanceTestInterfaceMethod12ResponseParams();
    result.param0 = param0;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kConformanceTestInterface_method0_name:
        var params = ConformanceTestInterfaceMethod0Params.deserialize(
            message.payload);
        _impl.method0(params.param0);
        break;
      case kConformanceTestInterface_method1_name:
        var params = ConformanceTestInterfaceMethod1Params.deserialize(
            message.payload);
        _impl.method1(params.param0);
        break;
      case kConformanceTestInterface_method2_name:
        var params = ConformanceTestInterfaceMethod2Params.deserialize(
            message.payload);
        _impl.method2(params.param0, params.param1);
        break;
      case kConformanceTestInterface_method3_name:
        var params = ConformanceTestInterfaceMethod3Params.deserialize(
            message.payload);
        _impl.method3(params.param0);
        break;
      case kConformanceTestInterface_method4_name:
        var params = ConformanceTestInterfaceMethod4Params.deserialize(
            message.payload);
        _impl.method4(params.param0, params.param1);
        break;
      case kConformanceTestInterface_method5_name:
        var params = ConformanceTestInterfaceMethod5Params.deserialize(
            message.payload);
        _impl.method5(params.param0, params.param1);
        break;
      case kConformanceTestInterface_method6_name:
        var params = ConformanceTestInterfaceMethod6Params.deserialize(
            message.payload);
        _impl.method6(params.param0);
        break;
      case kConformanceTestInterface_method7_name:
        var params = ConformanceTestInterfaceMethod7Params.deserialize(
            message.payload);
        _impl.method7(params.param0, params.param1);
        break;
      case kConformanceTestInterface_method8_name:
        var params = ConformanceTestInterfaceMethod8Params.deserialize(
            message.payload);
        _impl.method8(params.param0);
        break;
      case kConformanceTestInterface_method9_name:
        var params = ConformanceTestInterfaceMethod9Params.deserialize(
            message.payload);
        _impl.method9(params.param0);
        break;
      case kConformanceTestInterface_method10_name:
        var params = ConformanceTestInterfaceMethod10Params.deserialize(
            message.payload);
        _impl.method10(params.param0);
        break;
      case kConformanceTestInterface_method11_name:
        var params = ConformanceTestInterfaceMethod11Params.deserialize(
            message.payload);
        _impl.method11(params.param0);
        break;
      case kConformanceTestInterface_method12_name:
        var params = ConformanceTestInterfaceMethod12Params.deserialize(
            message.payload);
        return _impl.method12(params.param0,_ConformanceTestInterfaceMethod12ResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kConformanceTestInterface_method12_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  ConformanceTestInterface get impl => _impl;
      set impl(ConformanceTestInterface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "ConformanceTestInterfaceStub($superString)";
  }
}

const int kIntegrationTestInterface_method0_name = 0;

const String IntegrationTestInterfaceName =
      'mojo::test::IntegrationTestInterface';

abstract class IntegrationTestInterface {
  Future<IntegrationTestInterfaceMethod0ResponseParams> method0(BasicStruct param0,[Function responseFactory = null]);

}


class IntegrationTestInterfaceProxyImpl extends bindings.Proxy {
  IntegrationTestInterfaceProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  IntegrationTestInterfaceProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  IntegrationTestInterfaceProxyImpl.unbound() : super.unbound();

  static IntegrationTestInterfaceProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IntegrationTestInterfaceProxyImpl.fromEndpoint(endpoint);

  String get name => IntegrationTestInterfaceName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kIntegrationTestInterface_method0_name:
        var r = IntegrationTestInterfaceMethod0ResponseParams.deserialize(
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
    return "IntegrationTestInterfaceProxyImpl($superString)";
  }
}


class _IntegrationTestInterfaceProxyCalls implements IntegrationTestInterface {
  IntegrationTestInterfaceProxyImpl _proxyImpl;

  _IntegrationTestInterfaceProxyCalls(this._proxyImpl);
    Future<IntegrationTestInterfaceMethod0ResponseParams> method0(BasicStruct param0,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new IntegrationTestInterfaceMethod0Params();
      params.param0 = param0;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kIntegrationTestInterface_method0_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class IntegrationTestInterfaceProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  IntegrationTestInterface ptr;
  final String name = IntegrationTestInterfaceName;

  IntegrationTestInterfaceProxy(IntegrationTestInterfaceProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _IntegrationTestInterfaceProxyCalls(proxyImpl);

  IntegrationTestInterfaceProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new IntegrationTestInterfaceProxyImpl.fromEndpoint(endpoint) {
    ptr = new _IntegrationTestInterfaceProxyCalls(impl);
  }

  IntegrationTestInterfaceProxy.fromHandle(core.MojoHandle handle) :
      impl = new IntegrationTestInterfaceProxyImpl.fromHandle(handle) {
    ptr = new _IntegrationTestInterfaceProxyCalls(impl);
  }

  IntegrationTestInterfaceProxy.unbound() :
      impl = new IntegrationTestInterfaceProxyImpl.unbound() {
    ptr = new _IntegrationTestInterfaceProxyCalls(impl);
  }

  static IntegrationTestInterfaceProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IntegrationTestInterfaceProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "IntegrationTestInterfaceProxy($impl)";
  }
}


class IntegrationTestInterfaceStub extends bindings.Stub {
  IntegrationTestInterface _impl = null;

  IntegrationTestInterfaceStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  IntegrationTestInterfaceStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  IntegrationTestInterfaceStub.unbound() : super.unbound();

  static IntegrationTestInterfaceStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new IntegrationTestInterfaceStub.fromEndpoint(endpoint);

  static const String name = IntegrationTestInterfaceName;


  IntegrationTestInterfaceMethod0ResponseParams _IntegrationTestInterfaceMethod0ResponseParamsFactory(List<int> param0) {
    var result = new IntegrationTestInterfaceMethod0ResponseParams();
    result.param0 = param0;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kIntegrationTestInterface_method0_name:
        var params = IntegrationTestInterfaceMethod0Params.deserialize(
            message.payload);
        return _impl.method0(params.param0,_IntegrationTestInterfaceMethod0ResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kIntegrationTestInterface_method0_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  IntegrationTestInterface get impl => _impl;
      set impl(IntegrationTestInterface d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "IntegrationTestInterfaceStub($superString)";
  }
}


