// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library types.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
const kOpenFlagRead = 0x1;
const kOpenFlagWrite = 0x2;
const kOpenFlagCreate = 0x4;
const kOpenFlagExclusive = 0x8;
const kOpenFlagAppend = 0x10;
const kOpenFlagTruncate = 0x20;
const kDeleteFlagFileOnly = 0x1;
const kDeleteFlagDirectoryOnly = 0x2;
const kDeleteFlagRecursive = 0x4;

const int Error_OK = 0;
const int Error_UNKNOWN = 1;
const int Error_INVALID_ARGUMENT = 2;
const int Error_PERMISSION_DENIED = 3;
const int Error_OUT_OF_RANGE = 4;
const int Error_UNIMPLEMENTED = 5;
const int Error_CLOSED = 6;
const int Error_UNAVAILABLE = 7;
const int Error_INTERNAL = 8;

const int Whence_FROM_CURRENT = 0;
const int Whence_FROM_START = 1;
const int Whence_FROM_END = 2;

const int FileType_UNKNOWN = 0;
const int FileType_REGULAR_FILE = 1;
const int FileType_DIRECTORY = 2;


class Timespec extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int seconds = 0;
  int nanoseconds = 0;

  Timespec() : super(kVersions.last.size);

  static Timespec deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static Timespec decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Timespec result = new Timespec();

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
      
      result.seconds = decoder0.decodeInt64(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.nanoseconds = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt64(seconds, 8);
    
    encoder0.encodeInt32(nanoseconds, 16);
  }

  String toString() {
    return "Timespec("
           "seconds: $seconds" ", "
           "nanoseconds: $nanoseconds" ")";
  }
}

class TimespecOrNow extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  bool now = false;
  Timespec timespec = null;

  TimespecOrNow() : super(kVersions.last.size);

  static TimespecOrNow deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static TimespecOrNow decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TimespecOrNow result = new TimespecOrNow();

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
      
      result.now = decoder0.decodeBool(8, 0);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.timespec = Timespec.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(now, 8, 0);
    
    encoder0.encodeStruct(timespec, 16, true);
  }

  String toString() {
    return "TimespecOrNow("
           "now: $now" ", "
           "timespec: $timespec" ")";
  }
}

class FileInformation extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int type = 0;
  int size = 0;
  Timespec atime = null;
  Timespec mtime = null;

  FileInformation() : super(kVersions.last.size);

  static FileInformation deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static FileInformation decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileInformation result = new FileInformation();

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
      
      result.type = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.size = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.atime = Timespec.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.mtime = Timespec.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(type, 8);
    
    encoder0.encodeInt64(size, 16);
    
    encoder0.encodeStruct(atime, 24, true);
    
    encoder0.encodeStruct(mtime, 32, true);
  }

  String toString() {
    return "FileInformation("
           "type: $type" ", "
           "size: $size" ", "
           "atime: $atime" ", "
           "mtime: $mtime" ")";
  }
}

class DirectoryEntry extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int type = 0;
  String name = null;

  DirectoryEntry() : super(kVersions.last.size);

  static DirectoryEntry deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    decoder.excessHandles.forEach((h) => h.close());
    return result;
  }

  static DirectoryEntry decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryEntry result = new DirectoryEntry();

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
      
      result.type = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.name = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(type, 8);
    
    encoder0.encodeString(name, 16, false);
  }

  String toString() {
    return "DirectoryEntry("
           "type: $type" ", "
           "name: $name" ")";
  }
}

