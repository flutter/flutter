// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library types.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
final kOpenFlagRead = 0x1;
final kOpenFlagWrite = 0x2;
final kOpenFlagCreate = 0x4;
final kOpenFlagExclusive = 0x8;
final kOpenFlagAppend = 0x10;
final kOpenFlagTruncate = 0x20;
final kDeleteFlagFileOnly = 0x1;
final kDeleteFlagDirectoryOnly = 0x2;
final kDeleteFlagRecursive = 0x4;

final int Error_OK = 0;
final int Error_UNKNOWN = Error_OK + 1;
final int Error_INVALID_ARGUMENT = Error_UNKNOWN + 1;
final int Error_PERMISSION_DENIED = Error_INVALID_ARGUMENT + 1;
final int Error_OUT_OF_RANGE = Error_PERMISSION_DENIED + 1;
final int Error_UNIMPLEMENTED = Error_OUT_OF_RANGE + 1;
final int Error_CLOSED = Error_UNIMPLEMENTED + 1;
final int Error_UNAVAILABLE = Error_CLOSED + 1;
final int Error_INTERNAL = Error_UNAVAILABLE + 1;

final int Whence_FROM_CURRENT = 0;
final int Whence_FROM_START = Whence_FROM_CURRENT + 1;
final int Whence_FROM_END = Whence_FROM_START + 1;

final int FileType_UNKNOWN = 0;
final int FileType_REGULAR_FILE = FileType_UNKNOWN + 1;
final int FileType_DIRECTORY = FileType_REGULAR_FILE + 1;


class Timespec extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int seconds = 0;
  int nanoseconds = 0;

  Timespec() : super(kStructSize);

  static Timespec deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Timespec decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Timespec result = new Timespec();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.seconds = decoder0.decodeInt64(8);
    }
    {
      
      result.nanoseconds = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
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
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  bool now = false;
  Timespec timespec = null;

  TimespecOrNow() : super(kStructSize);

  static TimespecOrNow deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TimespecOrNow decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TimespecOrNow result = new TimespecOrNow();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.now = decoder0.decodeBool(8, 0);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, true);
      result.timespec = Timespec.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
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
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int type = 0;
  int size = 0;
  Timespec atime = null;
  Timespec mtime = null;

  FileInformation() : super(kStructSize);

  static FileInformation deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static FileInformation decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    FileInformation result = new FileInformation();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.type = decoder0.decodeInt32(8);
    }
    {
      
      result.size = decoder0.decodeInt64(16);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, true);
      result.atime = Timespec.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, true);
      result.mtime = Timespec.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
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
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int type = 0;
  String name = null;

  DirectoryEntry() : super(kStructSize);

  static DirectoryEntry deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DirectoryEntry decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DirectoryEntry result = new DirectoryEntry();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.type = decoder0.decodeInt32(8);
    }
    {
      
      result.name = decoder0.decodeString(16, false);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(type, 8);
    
    encoder0.encodeString(name, 16, false);
  }

  String toString() {
    return "DirectoryEntry("
           "type: $type" ", "
           "name: $name" ")";
  }
}

