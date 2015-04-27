// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library file.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/files/public/interfaces/types.mojom.dart' as types_mojom;


class FileCloseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  FileCloseParams() : super(kVersions.last.size);

  static FileCloseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileCloseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileCloseParams result = new FileCloseParams();

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
    return "FileCloseParams("")";
  }
}

class FileCloseResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int err = 0;

  FileCloseResponseParams() : super(kVersions.last.size);

  static FileCloseResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileCloseResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileCloseResponseParams result = new FileCloseResponseParams();

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
      
      result.err = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(err, 8);
  }

  String toString() {
    return "FileCloseResponseParams("
           "err: $err" ")";
  }
}

class FileReadParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int numBytesToRead = 0;
  int whence = 0;
  int offset = 0;

  FileReadParams() : super(kVersions.last.size);

  static FileReadParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReadParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReadParams result = new FileReadParams();

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
      
      result.numBytesToRead = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.whence = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(numBytesToRead, 8);
    
    encoder0.encodeInt32(whence, 12);
    
    encoder0.encodeInt64(offset, 16);
  }

  String toString() {
    return "FileReadParams("
           "numBytesToRead: $numBytesToRead" ", "
           "whence: $whence" ", "
           "offset: $offset" ")";
  }
}

class FileReadResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int error = 0;
  List<int> bytesRead = null;

  FileReadResponseParams() : super(kVersions.last.size);

  static FileReadResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReadResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReadResponseParams result = new FileReadResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.bytesRead = decoder0.decodeUint8Array(16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeUint8Array(bytesRead, 16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "FileReadResponseParams("
           "error: $error" ", "
           "bytesRead: $bytesRead" ")";
  }
}

class FileWriteParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  List<int> bytesToWrite = null;
  int offset = 0;
  int whence = 0;

  FileWriteParams() : super(kVersions.last.size);

  static FileWriteParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileWriteParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileWriteParams result = new FileWriteParams();

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
      
      result.bytesToWrite = decoder0.decodeUint8Array(8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.whence = decoder0.decodeInt32(24);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint8Array(bytesToWrite, 8, bindings.kNothingNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeInt64(offset, 16);
    
    encoder0.encodeInt32(whence, 24);
  }

  String toString() {
    return "FileWriteParams("
           "bytesToWrite: $bytesToWrite" ", "
           "offset: $offset" ", "
           "whence: $whence" ")";
  }
}

class FileWriteResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;
  int numBytesWritten = 0;

  FileWriteResponseParams() : super(kVersions.last.size);

  static FileWriteResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileWriteResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileWriteResponseParams result = new FileWriteResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.numBytesWritten = decoder0.decodeUint32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeUint32(numBytesWritten, 12);
  }

  String toString() {
    return "FileWriteResponseParams("
           "error: $error" ", "
           "numBytesWritten: $numBytesWritten" ")";
  }
}

class FileReadToStreamParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(32, 0)
  ];
  core.MojoDataPipeProducer source = null;
  int whence = 0;
  int offset = 0;
  int numBytesToRead = 0;

  FileReadToStreamParams() : super(kVersions.last.size);

  static FileReadToStreamParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReadToStreamParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReadToStreamParams result = new FileReadToStreamParams();

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
      
      result.source = decoder0.decodeProducerHandle(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.whence = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.numBytesToRead = decoder0.decodeInt64(24);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeProducerHandle(source, 8, false);
    
    encoder0.encodeInt32(whence, 12);
    
    encoder0.encodeInt64(offset, 16);
    
    encoder0.encodeInt64(numBytesToRead, 24);
  }

  String toString() {
    return "FileReadToStreamParams("
           "source: $source" ", "
           "whence: $whence" ", "
           "offset: $offset" ", "
           "numBytesToRead: $numBytesToRead" ")";
  }
}

class FileReadToStreamResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileReadToStreamResponseParams() : super(kVersions.last.size);

  static FileReadToStreamResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReadToStreamResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReadToStreamResponseParams result = new FileReadToStreamResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileReadToStreamResponseParams("
           "error: $error" ")";
  }
}

class FileWriteFromStreamParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  core.MojoDataPipeConsumer sink = null;
  int whence = 0;
  int offset = 0;

  FileWriteFromStreamParams() : super(kVersions.last.size);

  static FileWriteFromStreamParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileWriteFromStreamParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileWriteFromStreamParams result = new FileWriteFromStreamParams();

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
      
      result.sink = decoder0.decodeConsumerHandle(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.whence = decoder0.decodeInt32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.offset = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeConsumerHandle(sink, 8, false);
    
    encoder0.encodeInt32(whence, 12);
    
    encoder0.encodeInt64(offset, 16);
  }

  String toString() {
    return "FileWriteFromStreamParams("
           "sink: $sink" ", "
           "whence: $whence" ", "
           "offset: $offset" ")";
  }
}

class FileWriteFromStreamResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileWriteFromStreamResponseParams() : super(kVersions.last.size);

  static FileWriteFromStreamResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileWriteFromStreamResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileWriteFromStreamResponseParams result = new FileWriteFromStreamResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileWriteFromStreamResponseParams("
           "error: $error" ")";
  }
}

class FileTellParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  FileTellParams() : super(kVersions.last.size);

  static FileTellParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTellParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTellParams result = new FileTellParams();

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
    return "FileTellParams("")";
  }
}

class FileTellResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int error = 0;
  int position = 0;

  FileTellResponseParams() : super(kVersions.last.size);

  static FileTellResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTellResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTellResponseParams result = new FileTellResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.position = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeInt64(position, 16);
  }

  String toString() {
    return "FileTellResponseParams("
           "error: $error" ", "
           "position: $position" ")";
  }
}

class FileSeekParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int offset = 0;
  int whence = 0;

  FileSeekParams() : super(kVersions.last.size);

  static FileSeekParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileSeekParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileSeekParams result = new FileSeekParams();

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
      
      result.offset = decoder0.decodeInt64(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.whence = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt64(offset, 8);
    
    encoder0.encodeInt32(whence, 16);
  }

  String toString() {
    return "FileSeekParams("
           "offset: $offset" ", "
           "whence: $whence" ")";
  }
}

class FileSeekResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int error = 0;
  int position = 0;

  FileSeekResponseParams() : super(kVersions.last.size);

  static FileSeekResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileSeekResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileSeekResponseParams result = new FileSeekResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.position = decoder0.decodeInt64(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeInt64(position, 16);
  }

  String toString() {
    return "FileSeekResponseParams("
           "error: $error" ", "
           "position: $position" ")";
  }
}

class FileStatParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  FileStatParams() : super(kVersions.last.size);

  static FileStatParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileStatParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileStatParams result = new FileStatParams();

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
    return "FileStatParams("")";
  }
}

class FileStatResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int error = 0;
  types_mojom.FileInformation fileInformation = null;

  FileStatResponseParams() : super(kVersions.last.size);

  static FileStatResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileStatResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileStatResponseParams result = new FileStatResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.fileInformation = types_mojom.FileInformation.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeStruct(fileInformation, 16, true);
  }

  String toString() {
    return "FileStatResponseParams("
           "error: $error" ", "
           "fileInformation: $fileInformation" ")";
  }
}

class FileTruncateParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int size = 0;

  FileTruncateParams() : super(kVersions.last.size);

  static FileTruncateParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTruncateParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTruncateParams result = new FileTruncateParams();

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
      
      result.size = decoder0.decodeInt64(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt64(size, 8);
  }

  String toString() {
    return "FileTruncateParams("
           "size: $size" ")";
  }
}

class FileTruncateResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileTruncateResponseParams() : super(kVersions.last.size);

  static FileTruncateResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTruncateResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTruncateResponseParams result = new FileTruncateResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileTruncateResponseParams("
           "error: $error" ")";
  }
}

class FileTouchParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  types_mojom.TimespecOrNow atime = null;
  types_mojom.TimespecOrNow mtime = null;

  FileTouchParams() : super(kVersions.last.size);

  static FileTouchParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTouchParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTouchParams result = new FileTouchParams();

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
      result.atime = types_mojom.TimespecOrNow.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.mtime = types_mojom.TimespecOrNow.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeStruct(atime, 8, true);
    
    encoder0.encodeStruct(mtime, 16, true);
  }

  String toString() {
    return "FileTouchParams("
           "atime: $atime" ", "
           "mtime: $mtime" ")";
  }
}

class FileTouchResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileTouchResponseParams() : super(kVersions.last.size);

  static FileTouchResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileTouchResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileTouchResponseParams result = new FileTouchResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileTouchResponseParams("
           "error: $error" ")";
  }
}

class FileDupParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object file = null;

  FileDupParams() : super(kVersions.last.size);

  static FileDupParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileDupParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileDupParams result = new FileDupParams();

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
      
      result.file = decoder0.decodeInterfaceRequest(8, false, FileStub.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(file, 8, false);
  }

  String toString() {
    return "FileDupParams("
           "file: $file" ")";
  }
}

class FileDupResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileDupResponseParams() : super(kVersions.last.size);

  static FileDupResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileDupResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileDupResponseParams result = new FileDupResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileDupResponseParams("
           "error: $error" ")";
  }
}

class FileReopenParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object file = null;
  int openFlags = 0;

  FileReopenParams() : super(kVersions.last.size);

  static FileReopenParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReopenParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReopenParams result = new FileReopenParams();

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
      
      result.file = decoder0.decodeInterfaceRequest(8, false, FileStub.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      result.openFlags = decoder0.decodeUint32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterfaceRequest(file, 8, false);
    
    encoder0.encodeUint32(openFlags, 12);
  }

  String toString() {
    return "FileReopenParams("
           "file: $file" ", "
           "openFlags: $openFlags" ")";
  }
}

class FileReopenResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;

  FileReopenResponseParams() : super(kVersions.last.size);

  static FileReopenResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileReopenResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileReopenResponseParams result = new FileReopenResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
  }

  String toString() {
    return "FileReopenResponseParams("
           "error: $error" ")";
  }
}

class FileAsBufferParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(8, 0)
  ];

  FileAsBufferParams() : super(kVersions.last.size);

  static FileAsBufferParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileAsBufferParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileAsBufferParams result = new FileAsBufferParams();

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
    return "FileAsBufferParams("")";
  }
}

class FileAsBufferResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int error = 0;
  core.MojoSharedBuffer buffer = null;

  FileAsBufferResponseParams() : super(kVersions.last.size);

  static FileAsBufferResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileAsBufferResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileAsBufferResponseParams result = new FileAsBufferResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.buffer = decoder0.decodeSharedBufferHandle(12, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeSharedBufferHandle(buffer, 12, true);
  }

  String toString() {
    return "FileAsBufferResponseParams("
           "error: $error" ", "
           "buffer: $buffer" ")";
  }
}

class FileIoctlParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int request = 0;
  List<int> inValues = null;

  FileIoctlParams() : super(kVersions.last.size);

  static FileIoctlParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileIoctlParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileIoctlParams result = new FileIoctlParams();

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
      
      result.request = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.inValues = decoder0.decodeUint32Array(16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(request, 8);
    
    encoder0.encodeUint32Array(inValues, 16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "FileIoctlParams("
           "request: $request" ", "
           "inValues: $inValues" ")";
  }
}

class FileIoctlResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int error = 0;
  List<int> outValues = null;

  FileIoctlResponseParams() : super(kVersions.last.size);

  static FileIoctlResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileIoctlResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileIoctlResponseParams result = new FileIoctlResponseParams();

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
      
      result.error = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.outValues = decoder0.decodeUint32Array(16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(error, 8);
    
    encoder0.encodeUint32Array(outValues, 16, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
  }

  String toString() {
    return "FileIoctlResponseParams("
           "error: $error" ", "
           "outValues: $outValues" ")";
  }
}
const int kFile_close_name = 0;
const int kFile_read_name = 1;
const int kFile_write_name = 2;
const int kFile_readToStream_name = 3;
const int kFile_writeFromStream_name = 4;
const int kFile_tell_name = 5;
const int kFile_seek_name = 6;
const int kFile_stat_name = 7;
const int kFile_truncate_name = 8;
const int kFile_touch_name = 9;
const int kFile_dup_name = 10;
const int kFile_reopen_name = 11;
const int kFile_asBuffer_name = 12;
const int kFile_ioctl_name = 13;

const String FileName =
      'mojo::files::File';

abstract class File {
  Future<FileCloseResponseParams> close([Function responseFactory = null]);
  Future<FileReadResponseParams> read(int numBytesToRead,int offset,int whence,[Function responseFactory = null]);
  Future<FileWriteResponseParams> write(List<int> bytesToWrite,int offset,int whence,[Function responseFactory = null]);
  Future<FileReadToStreamResponseParams> readToStream(core.MojoDataPipeProducer source,int offset,int whence,int numBytesToRead,[Function responseFactory = null]);
  Future<FileWriteFromStreamResponseParams> writeFromStream(core.MojoDataPipeConsumer sink,int offset,int whence,[Function responseFactory = null]);
  Future<FileTellResponseParams> tell([Function responseFactory = null]);
  Future<FileSeekResponseParams> seek(int offset,int whence,[Function responseFactory = null]);
  Future<FileStatResponseParams> stat([Function responseFactory = null]);
  Future<FileTruncateResponseParams> truncate(int size,[Function responseFactory = null]);
  Future<FileTouchResponseParams> touch(types_mojom.TimespecOrNow atime,types_mojom.TimespecOrNow mtime,[Function responseFactory = null]);
  Future<FileDupResponseParams> dup(Object file,[Function responseFactory = null]);
  Future<FileReopenResponseParams> reopen(Object file,int openFlags,[Function responseFactory = null]);
  Future<FileAsBufferResponseParams> asBuffer([Function responseFactory = null]);
  Future<FileIoctlResponseParams> ioctl(int request,List<int> inValues,[Function responseFactory = null]);

}


class FileProxyImpl extends bindings.Proxy {
  FileProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  FileProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  FileProxyImpl.unbound() : super.unbound();

  static FileProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new FileProxyImpl.fromEndpoint(endpoint);

  String get name => FileName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kFile_close_name:
        var r = FileCloseResponseParams.deserialize(
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
      case kFile_read_name:
        var r = FileReadResponseParams.deserialize(
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
      case kFile_write_name:
        var r = FileWriteResponseParams.deserialize(
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
      case kFile_readToStream_name:
        var r = FileReadToStreamResponseParams.deserialize(
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
      case kFile_writeFromStream_name:
        var r = FileWriteFromStreamResponseParams.deserialize(
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
      case kFile_tell_name:
        var r = FileTellResponseParams.deserialize(
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
      case kFile_seek_name:
        var r = FileSeekResponseParams.deserialize(
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
      case kFile_stat_name:
        var r = FileStatResponseParams.deserialize(
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
      case kFile_truncate_name:
        var r = FileTruncateResponseParams.deserialize(
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
      case kFile_touch_name:
        var r = FileTouchResponseParams.deserialize(
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
      case kFile_dup_name:
        var r = FileDupResponseParams.deserialize(
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
      case kFile_reopen_name:
        var r = FileReopenResponseParams.deserialize(
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
      case kFile_asBuffer_name:
        var r = FileAsBufferResponseParams.deserialize(
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
      case kFile_ioctl_name:
        var r = FileIoctlResponseParams.deserialize(
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
    return "FileProxyImpl($superString)";
  }
}


class _FileProxyCalls implements File {
  FileProxyImpl _proxyImpl;

  _FileProxyCalls(this._proxyImpl);
    Future<FileCloseResponseParams> close([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileCloseParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_close_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileReadResponseParams> read(int numBytesToRead,int offset,int whence,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileReadParams();
      params.numBytesToRead = numBytesToRead;
      params.offset = offset;
      params.whence = whence;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_read_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileWriteResponseParams> write(List<int> bytesToWrite,int offset,int whence,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileWriteParams();
      params.bytesToWrite = bytesToWrite;
      params.offset = offset;
      params.whence = whence;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_write_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileReadToStreamResponseParams> readToStream(core.MojoDataPipeProducer source,int offset,int whence,int numBytesToRead,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileReadToStreamParams();
      params.source = source;
      params.offset = offset;
      params.whence = whence;
      params.numBytesToRead = numBytesToRead;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_readToStream_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileWriteFromStreamResponseParams> writeFromStream(core.MojoDataPipeConsumer sink,int offset,int whence,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileWriteFromStreamParams();
      params.sink = sink;
      params.offset = offset;
      params.whence = whence;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_writeFromStream_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileTellResponseParams> tell([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileTellParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_tell_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileSeekResponseParams> seek(int offset,int whence,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileSeekParams();
      params.offset = offset;
      params.whence = whence;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_seek_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileStatResponseParams> stat([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileStatParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_stat_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileTruncateResponseParams> truncate(int size,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileTruncateParams();
      params.size = size;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_truncate_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileTouchResponseParams> touch(types_mojom.TimespecOrNow atime,types_mojom.TimespecOrNow mtime,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileTouchParams();
      params.atime = atime;
      params.mtime = mtime;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_touch_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileDupResponseParams> dup(Object file,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileDupParams();
      params.file = file;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_dup_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileReopenResponseParams> reopen(Object file,int openFlags,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileReopenParams();
      params.file = file;
      params.openFlags = openFlags;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_reopen_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileAsBufferResponseParams> asBuffer([Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileAsBufferParams();
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_asBuffer_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<FileIoctlResponseParams> ioctl(int request,List<int> inValues,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new FileIoctlParams();
      params.request = request;
      params.inValues = inValues;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kFile_ioctl_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class FileProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  File ptr;
  final String name = FileName;

  FileProxy(FileProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _FileProxyCalls(proxyImpl);

  FileProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new FileProxyImpl.fromEndpoint(endpoint) {
    ptr = new _FileProxyCalls(impl);
  }

  FileProxy.fromHandle(core.MojoHandle handle) :
      impl = new FileProxyImpl.fromHandle(handle) {
    ptr = new _FileProxyCalls(impl);
  }

  FileProxy.unbound() :
      impl = new FileProxyImpl.unbound() {
    ptr = new _FileProxyCalls(impl);
  }

  static FileProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new FileProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "FileProxy($impl)";
  }
}


class FileStub extends bindings.Stub {
  File _impl = null;

  FileStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  FileStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  FileStub.unbound() : super.unbound();

  static FileStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new FileStub.fromEndpoint(endpoint);

  static const String name = FileName;


  FileCloseResponseParams _FileCloseResponseParamsFactory(int err) {
    var result = new FileCloseResponseParams();
    result.err = err;
    return result;
  }
  FileReadResponseParams _FileReadResponseParamsFactory(int error, List<int> bytesRead) {
    var result = new FileReadResponseParams();
    result.error = error;
    result.bytesRead = bytesRead;
    return result;
  }
  FileWriteResponseParams _FileWriteResponseParamsFactory(int error, int numBytesWritten) {
    var result = new FileWriteResponseParams();
    result.error = error;
    result.numBytesWritten = numBytesWritten;
    return result;
  }
  FileReadToStreamResponseParams _FileReadToStreamResponseParamsFactory(int error) {
    var result = new FileReadToStreamResponseParams();
    result.error = error;
    return result;
  }
  FileWriteFromStreamResponseParams _FileWriteFromStreamResponseParamsFactory(int error) {
    var result = new FileWriteFromStreamResponseParams();
    result.error = error;
    return result;
  }
  FileTellResponseParams _FileTellResponseParamsFactory(int error, int position) {
    var result = new FileTellResponseParams();
    result.error = error;
    result.position = position;
    return result;
  }
  FileSeekResponseParams _FileSeekResponseParamsFactory(int error, int position) {
    var result = new FileSeekResponseParams();
    result.error = error;
    result.position = position;
    return result;
  }
  FileStatResponseParams _FileStatResponseParamsFactory(int error, types_mojom.FileInformation fileInformation) {
    var result = new FileStatResponseParams();
    result.error = error;
    result.fileInformation = fileInformation;
    return result;
  }
  FileTruncateResponseParams _FileTruncateResponseParamsFactory(int error) {
    var result = new FileTruncateResponseParams();
    result.error = error;
    return result;
  }
  FileTouchResponseParams _FileTouchResponseParamsFactory(int error) {
    var result = new FileTouchResponseParams();
    result.error = error;
    return result;
  }
  FileDupResponseParams _FileDupResponseParamsFactory(int error) {
    var result = new FileDupResponseParams();
    result.error = error;
    return result;
  }
  FileReopenResponseParams _FileReopenResponseParamsFactory(int error) {
    var result = new FileReopenResponseParams();
    result.error = error;
    return result;
  }
  FileAsBufferResponseParams _FileAsBufferResponseParamsFactory(int error, core.MojoSharedBuffer buffer) {
    var result = new FileAsBufferResponseParams();
    result.error = error;
    result.buffer = buffer;
    return result;
  }
  FileIoctlResponseParams _FileIoctlResponseParamsFactory(int error, List<int> outValues) {
    var result = new FileIoctlResponseParams();
    result.error = error;
    result.outValues = outValues;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kFile_close_name:
        var params = FileCloseParams.deserialize(
            message.payload);
        return _impl.close(_FileCloseResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_close_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_read_name:
        var params = FileReadParams.deserialize(
            message.payload);
        return _impl.read(params.numBytesToRead,params.offset,params.whence,_FileReadResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_read_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_write_name:
        var params = FileWriteParams.deserialize(
            message.payload);
        return _impl.write(params.bytesToWrite,params.offset,params.whence,_FileWriteResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_write_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_readToStream_name:
        var params = FileReadToStreamParams.deserialize(
            message.payload);
        return _impl.readToStream(params.source,params.offset,params.whence,params.numBytesToRead,_FileReadToStreamResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_readToStream_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_writeFromStream_name:
        var params = FileWriteFromStreamParams.deserialize(
            message.payload);
        return _impl.writeFromStream(params.sink,params.offset,params.whence,_FileWriteFromStreamResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_writeFromStream_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_tell_name:
        var params = FileTellParams.deserialize(
            message.payload);
        return _impl.tell(_FileTellResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_tell_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_seek_name:
        var params = FileSeekParams.deserialize(
            message.payload);
        return _impl.seek(params.offset,params.whence,_FileSeekResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_seek_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_stat_name:
        var params = FileStatParams.deserialize(
            message.payload);
        return _impl.stat(_FileStatResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_stat_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_truncate_name:
        var params = FileTruncateParams.deserialize(
            message.payload);
        return _impl.truncate(params.size,_FileTruncateResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_truncate_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_touch_name:
        var params = FileTouchParams.deserialize(
            message.payload);
        return _impl.touch(params.atime,params.mtime,_FileTouchResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_touch_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_dup_name:
        var params = FileDupParams.deserialize(
            message.payload);
        return _impl.dup(params.file,_FileDupResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_dup_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_reopen_name:
        var params = FileReopenParams.deserialize(
            message.payload);
        return _impl.reopen(params.file,params.openFlags,_FileReopenResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_reopen_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_asBuffer_name:
        var params = FileAsBufferParams.deserialize(
            message.payload);
        return _impl.asBuffer(_FileAsBufferResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_asBuffer_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kFile_ioctl_name:
        var params = FileIoctlParams.deserialize(
            message.payload);
        return _impl.ioctl(params.request,params.inValues,_FileIoctlResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kFile_ioctl_name,
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

  File get impl => _impl;
      set impl(File d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "FileStub($superString)";
  }
}


