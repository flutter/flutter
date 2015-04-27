// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library js_to_cpp.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class EchoArgs extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(104, 0)
  ];
  int si64 = 0;
  int si32 = 0;
  int si16 = 0;
  int si8 = 0;
  int ui8 = 0;
  int ui64 = 0;
  int ui32 = 0;
  int ui16 = 0;
  double floatVal = 0.0;
  double floatInf = 0.0;
  double floatNan = 0.0;
  core.MojoMessagePipeEndpoint messageHandle = null;
  double doubleVal = 0.0;
  double doubleInf = 0.0;
  double doubleNan = 0.0;
  String name = null;
  List<String> stringArray = null;
  core.MojoDataPipeConsumer dataHandle = null;

  EchoArgs() : super(kVersions.last.size);

  static EchoArgs deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EchoArgs decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EchoArgs result = new EchoArgs();

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
      
      result.si64 = decoder0.decodeInt64(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.si32 = decoder0.decodeInt32(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.si16 = decoder0.decodeInt16(20);
    }
    if (mainDataHeader.version >= 0) {
      
      result.si8 = decoder0.decodeInt8(22);
    }
    if (mainDataHeader.version >= 0) {
      
      result.ui8 = decoder0.decodeUint8(23);
    }
    if (mainDataHeader.version >= 0) {
      
      result.ui64 = decoder0.decodeUint64(24);
    }
    if (mainDataHeader.version >= 0) {
      
      result.ui32 = decoder0.decodeUint32(32);
    }
    if (mainDataHeader.version >= 0) {
      
      result.ui16 = decoder0.decodeUint16(36);
    }
    if (mainDataHeader.version >= 0) {
      
      result.floatVal = decoder0.decodeFloat(40);
    }
    if (mainDataHeader.version >= 0) {
      
      result.floatInf = decoder0.decodeFloat(44);
    }
    if (mainDataHeader.version >= 0) {
      
      result.floatNan = decoder0.decodeFloat(48);
    }
    if (mainDataHeader.version >= 0) {
      
      result.messageHandle = decoder0.decodeMessagePipeHandle(52, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.doubleVal = decoder0.decodeDouble(56);
    }
    if (mainDataHeader.version >= 0) {
      
      result.doubleInf = decoder0.decodeDouble(64);
    }
    if (mainDataHeader.version >= 0) {
      
      result.doubleNan = decoder0.decodeDouble(72);
    }
    if (mainDataHeader.version >= 0) {
      
      result.name = decoder0.decodeString(80, true);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(88, true);
      if (decoder1 == null) {
        result.stringArray = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.stringArray = new List<String>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          result.stringArray[i1] = decoder1.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.dataHandle = decoder0.decodeConsumerHandle(96, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt64(si64, 8);
    
    encoder0.encodeInt32(si32, 16);
    
    encoder0.encodeInt16(si16, 20);
    
    encoder0.encodeInt8(si8, 22);
    
    encoder0.encodeUint8(ui8, 23);
    
    encoder0.encodeUint64(ui64, 24);
    
    encoder0.encodeUint32(ui32, 32);
    
    encoder0.encodeUint16(ui16, 36);
    
    encoder0.encodeFloat(floatVal, 40);
    
    encoder0.encodeFloat(floatInf, 44);
    
    encoder0.encodeFloat(floatNan, 48);
    
    encoder0.encodeMessagePipeHandle(messageHandle, 52, true);
    
    encoder0.encodeDouble(doubleVal, 56);
    
    encoder0.encodeDouble(doubleInf, 64);
    
    encoder0.encodeDouble(doubleNan, 72);
    
    encoder0.encodeString(name, 80, true);
    
    if (stringArray == null) {
      encoder0.encodeNullPointer(88, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(stringArray.length, 88, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < stringArray.length; ++i0) {
        
        encoder1.encodeString(stringArray[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeConsumerHandle(dataHandle, 96, true);
  }

  String toString() {
    return "EchoArgs("
           "si64: $si64" ", "
           "si32: $si32" ", "
           "si16: $si16" ", "
           "si8: $si8" ", "
           "ui8: $ui8" ", "
           "ui64: $ui64" ", "
           "ui32: $ui32" ", "
           "ui16: $ui16" ", "
           "floatVal: $floatVal" ", "
           "floatInf: $floatInf" ", "
           "floatNan: $floatNan" ", "
           "messageHandle: $messageHandle" ", "
           "doubleVal: $doubleVal" ", "
           "doubleInf: $doubleInf" ", "
           "doubleNan: $doubleNan" ", "
           "name: $name" ", "
           "stringArray: $stringArray" ", "
           "dataHandle: $dataHandle" ")";
  }
}

class EchoArgsList extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  EchoArgsList next = null;
  EchoArgs item = null;

  EchoArgsList() : super(kVersions.last.size);

  static EchoArgsList deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static EchoArgsList decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    EchoArgsList result = new EchoArgsList();

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
      result.next = EchoArgsList.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.item = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(next, 8, true);
    
    encoder0.encodeStruct(item, 16, true);
  }

  String toString() {
    return "EchoArgsList("
           "next: $next" ", "
           "item: $item" ")";
  }
}

class CppSideStartTestParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CppSideStartTestParams() : super(kVersions.last.size);

  static CppSideStartTestParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideStartTestParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideStartTestParams result = new CppSideStartTestParams();

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
    return "CppSideStartTestParams("")";
  }
}

class CppSideTestFinishedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CppSideTestFinishedParams() : super(kVersions.last.size);

  static CppSideTestFinishedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideTestFinishedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideTestFinishedParams result = new CppSideTestFinishedParams();

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
    return "CppSideTestFinishedParams("")";
  }
}

class CppSidePingResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  CppSidePingResponseParams() : super(kVersions.last.size);

  static CppSidePingResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSidePingResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSidePingResponseParams result = new CppSidePingResponseParams();

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
    return "CppSidePingResponseParams("")";
  }
}

class CppSideEchoResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EchoArgsList list = null;

  CppSideEchoResponseParams() : super(kVersions.last.size);

  static CppSideEchoResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideEchoResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideEchoResponseParams result = new CppSideEchoResponseParams();

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
      result.list = EchoArgsList.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(list, 8, false);
  }

  String toString() {
    return "CppSideEchoResponseParams("
           "list: $list" ")";
  }
}

class CppSideBitFlipResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EchoArgsList arg = null;

  CppSideBitFlipResponseParams() : super(kVersions.last.size);

  static CppSideBitFlipResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideBitFlipResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideBitFlipResponseParams result = new CppSideBitFlipResponseParams();

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
      result.arg = EchoArgsList.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(arg, 8, false);
  }

  String toString() {
    return "CppSideBitFlipResponseParams("
           "arg: $arg" ")";
  }
}

class CppSideBackPointerResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EchoArgsList arg = null;

  CppSideBackPointerResponseParams() : super(kVersions.last.size);

  static CppSideBackPointerResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CppSideBackPointerResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CppSideBackPointerResponseParams result = new CppSideBackPointerResponseParams();

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
      result.arg = EchoArgsList.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(arg, 8, false);
  }

  String toString() {
    return "CppSideBackPointerResponseParams("
           "arg: $arg" ")";
  }
}

class JsSideSetCppSideParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object cpp = null;

  JsSideSetCppSideParams() : super(kVersions.last.size);

  static JsSideSetCppSideParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static JsSideSetCppSideParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    JsSideSetCppSideParams result = new JsSideSetCppSideParams();

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
      
      result.cpp = decoder0.decodeServiceInterface(8, false, CppSideProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterface(cpp, 8, false);
  }

  String toString() {
    return "JsSideSetCppSideParams("
           "cpp: $cpp" ")";
  }
}

class JsSidePingParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  JsSidePingParams() : super(kVersions.last.size);

  static JsSidePingParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static JsSidePingParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    JsSidePingParams result = new JsSidePingParams();

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
    return "JsSidePingParams("")";
  }
}

class JsSideEchoParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int numIterations = 0;
  EchoArgs arg = null;

  JsSideEchoParams() : super(kVersions.last.size);

  static JsSideEchoParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static JsSideEchoParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    JsSideEchoParams result = new JsSideEchoParams();

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
      
      result.numIterations = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.arg = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(numIterations, 8);
    
    encoder0.encodeStruct(arg, 16, false);
  }

  String toString() {
    return "JsSideEchoParams("
           "numIterations: $numIterations" ", "
           "arg: $arg" ")";
  }
}

class JsSideBitFlipParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EchoArgs arg = null;

  JsSideBitFlipParams() : super(kVersions.last.size);

  static JsSideBitFlipParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static JsSideBitFlipParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    JsSideBitFlipParams result = new JsSideBitFlipParams();

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
      result.arg = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(arg, 8, false);
  }

  String toString() {
    return "JsSideBitFlipParams("
           "arg: $arg" ")";
  }
}

class JsSideBackPointerParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  EchoArgs arg = null;

  JsSideBackPointerParams() : super(kVersions.last.size);

  static JsSideBackPointerParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static JsSideBackPointerParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    JsSideBackPointerParams result = new JsSideBackPointerParams();

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
      result.arg = EchoArgs.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(arg, 8, false);
  }

  String toString() {
    return "JsSideBackPointerParams("
           "arg: $arg" ")";
  }
}
const int kCppSide_startTest_name = 88888888;
const int kCppSide_testFinished_name = 99999999;
const int kCppSide_pingResponse_name = 100000000;
const int kCppSide_echoResponse_name = 100000001;
const int kCppSide_bitFlipResponse_name = 100000002;
const int kCppSide_backPointerResponse_name = 100000003;

const String CppSideName =
      'js_to_cpp::CppSide';

abstract class CppSide {
  void startTest();
  void testFinished();
  void pingResponse();
  void echoResponse(EchoArgsList list);
  void bitFlipResponse(EchoArgsList arg);
  void backPointerResponse(EchoArgsList arg);

}


class CppSideProxyImpl extends bindings.Proxy {
  CppSideProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  CppSideProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  CppSideProxyImpl.unbound() : super.unbound();

  static CppSideProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideProxyImpl.fromEndpoint(endpoint);

  String get name => CppSideName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "CppSideProxyImpl($superString)";
  }
}


class _CppSideProxyCalls implements CppSide {
  CppSideProxyImpl _proxyImpl;

  _CppSideProxyCalls(this._proxyImpl);
    void startTest() {
      assert(_proxyImpl.isBound);
      var params = new CppSideStartTestParams();
      _proxyImpl.sendMessage(params, kCppSide_startTest_name);
    }
  
    void testFinished() {
      assert(_proxyImpl.isBound);
      var params = new CppSideTestFinishedParams();
      _proxyImpl.sendMessage(params, kCppSide_testFinished_name);
    }
  
    void pingResponse() {
      assert(_proxyImpl.isBound);
      var params = new CppSidePingResponseParams();
      _proxyImpl.sendMessage(params, kCppSide_pingResponse_name);
    }
  
    void echoResponse(EchoArgsList list) {
      assert(_proxyImpl.isBound);
      var params = new CppSideEchoResponseParams();
      params.list = list;
      _proxyImpl.sendMessage(params, kCppSide_echoResponse_name);
    }
  
    void bitFlipResponse(EchoArgsList arg) {
      assert(_proxyImpl.isBound);
      var params = new CppSideBitFlipResponseParams();
      params.arg = arg;
      _proxyImpl.sendMessage(params, kCppSide_bitFlipResponse_name);
    }
  
    void backPointerResponse(EchoArgsList arg) {
      assert(_proxyImpl.isBound);
      var params = new CppSideBackPointerResponseParams();
      params.arg = arg;
      _proxyImpl.sendMessage(params, kCppSide_backPointerResponse_name);
    }
  
}


class CppSideProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  CppSide ptr;
  final String name = CppSideName;

  CppSideProxy(CppSideProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _CppSideProxyCalls(proxyImpl);

  CppSideProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new CppSideProxyImpl.fromEndpoint(endpoint) {
    ptr = new _CppSideProxyCalls(impl);
  }

  CppSideProxy.fromHandle(core.MojoHandle handle) :
      impl = new CppSideProxyImpl.fromHandle(handle) {
    ptr = new _CppSideProxyCalls(impl);
  }

  CppSideProxy.unbound() :
      impl = new CppSideProxyImpl.unbound() {
    ptr = new _CppSideProxyCalls(impl);
  }

  static CppSideProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "CppSideProxy($impl)";
  }
}


class CppSideStub extends bindings.Stub {
  CppSide _impl = null;

  CppSideStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  CppSideStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  CppSideStub.unbound() : super.unbound();

  static CppSideStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new CppSideStub.fromEndpoint(endpoint);

  static const String name = CppSideName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kCppSide_startTest_name:
        var params = CppSideStartTestParams.deserialize(
            message.payload);
        _impl.startTest();
        break;
      case kCppSide_testFinished_name:
        var params = CppSideTestFinishedParams.deserialize(
            message.payload);
        _impl.testFinished();
        break;
      case kCppSide_pingResponse_name:
        var params = CppSidePingResponseParams.deserialize(
            message.payload);
        _impl.pingResponse();
        break;
      case kCppSide_echoResponse_name:
        var params = CppSideEchoResponseParams.deserialize(
            message.payload);
        _impl.echoResponse(params.list);
        break;
      case kCppSide_bitFlipResponse_name:
        var params = CppSideBitFlipResponseParams.deserialize(
            message.payload);
        _impl.bitFlipResponse(params.arg);
        break;
      case kCppSide_backPointerResponse_name:
        var params = CppSideBackPointerResponseParams.deserialize(
            message.payload);
        _impl.backPointerResponse(params.arg);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  CppSide get impl => _impl;
      set impl(CppSide d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "CppSideStub($superString)";
  }
}

const int kJsSide_setCppSide_name = 0;
const int kJsSide_ping_name = 1;
const int kJsSide_echo_name = 2;
const int kJsSide_bitFlip_name = 3;
const int kJsSide_backPointer_name = 4;

const String JsSideName =
      'js_to_cpp::JsSide';

abstract class JsSide {
  void setCppSide(Object cpp);
  void ping();
  void echo(int numIterations, EchoArgs arg);
  void bitFlip(EchoArgs arg);
  void backPointer(EchoArgs arg);

}


class JsSideProxyImpl extends bindings.Proxy {
  JsSideProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  JsSideProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  JsSideProxyImpl.unbound() : super.unbound();

  static JsSideProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new JsSideProxyImpl.fromEndpoint(endpoint);

  String get name => JsSideName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "JsSideProxyImpl($superString)";
  }
}


class _JsSideProxyCalls implements JsSide {
  JsSideProxyImpl _proxyImpl;

  _JsSideProxyCalls(this._proxyImpl);
    void setCppSide(Object cpp) {
      assert(_proxyImpl.isBound);
      var params = new JsSideSetCppSideParams();
      params.cpp = cpp;
      _proxyImpl.sendMessage(params, kJsSide_setCppSide_name);
    }
  
    void ping() {
      assert(_proxyImpl.isBound);
      var params = new JsSidePingParams();
      _proxyImpl.sendMessage(params, kJsSide_ping_name);
    }
  
    void echo(int numIterations, EchoArgs arg) {
      assert(_proxyImpl.isBound);
      var params = new JsSideEchoParams();
      params.numIterations = numIterations;
      params.arg = arg;
      _proxyImpl.sendMessage(params, kJsSide_echo_name);
    }
  
    void bitFlip(EchoArgs arg) {
      assert(_proxyImpl.isBound);
      var params = new JsSideBitFlipParams();
      params.arg = arg;
      _proxyImpl.sendMessage(params, kJsSide_bitFlip_name);
    }
  
    void backPointer(EchoArgs arg) {
      assert(_proxyImpl.isBound);
      var params = new JsSideBackPointerParams();
      params.arg = arg;
      _proxyImpl.sendMessage(params, kJsSide_backPointer_name);
    }
  
}


class JsSideProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  JsSide ptr;
  final String name = JsSideName;

  JsSideProxy(JsSideProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _JsSideProxyCalls(proxyImpl);

  JsSideProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new JsSideProxyImpl.fromEndpoint(endpoint) {
    ptr = new _JsSideProxyCalls(impl);
  }

  JsSideProxy.fromHandle(core.MojoHandle handle) :
      impl = new JsSideProxyImpl.fromHandle(handle) {
    ptr = new _JsSideProxyCalls(impl);
  }

  JsSideProxy.unbound() :
      impl = new JsSideProxyImpl.unbound() {
    ptr = new _JsSideProxyCalls(impl);
  }

  static JsSideProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new JsSideProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "JsSideProxy($impl)";
  }
}


class JsSideStub extends bindings.Stub {
  JsSide _impl = null;

  JsSideStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  JsSideStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  JsSideStub.unbound() : super.unbound();

  static JsSideStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new JsSideStub.fromEndpoint(endpoint);

  static const String name = JsSideName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kJsSide_setCppSide_name:
        var params = JsSideSetCppSideParams.deserialize(
            message.payload);
        _impl.setCppSide(params.cpp);
        break;
      case kJsSide_ping_name:
        var params = JsSidePingParams.deserialize(
            message.payload);
        _impl.ping();
        break;
      case kJsSide_echo_name:
        var params = JsSideEchoParams.deserialize(
            message.payload);
        _impl.echo(params.numIterations, params.arg);
        break;
      case kJsSide_bitFlip_name:
        var params = JsSideBitFlipParams.deserialize(
            message.payload);
        _impl.bitFlip(params.arg);
        break;
      case kJsSide_backPointer_name:
        var params = JsSideBackPointerParams.deserialize(
            message.payload);
        _impl.backPointer(params.arg);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  JsSide get impl => _impl;
      set impl(JsSide d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "JsSideStub($superString)";
  }
}


