// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/framework/Source/FlutterStandardCodecHelper.h"
#include <stdint.h>

void FlutterStandardCodecHelperReadAlignment(unsigned long* location,
                                             uint8_t alignment) {
  uint8_t mod = *location % alignment;
  if (mod) {
    *location += (alignment - mod);
  }
}

static uint8_t PeekByte(unsigned long location, CFDataRef data) {
  uint8_t result;
  CFRange range = CFRangeMake(location, 1);
  CFDataGetBytes(data, range, &result);
  return result;
}

void FlutterStandardCodecHelperReadBytes(unsigned long* location,
                                         unsigned long length,
                                         void* destination,
                                         CFDataRef data) {
  CFRange range = CFRangeMake(*location, length);
  CFDataGetBytes(data, range, destination);
  *location += length;
}

uint8_t FlutterStandardCodecHelperReadByte(unsigned long* location,
                                           CFDataRef data) {
  uint8_t value;
  FlutterStandardCodecHelperReadBytes(location, 1, &value, data);
  return value;
}

uint32_t FlutterStandardCodecHelperReadSize(unsigned long* location,
                                            CFDataRef data) {
  uint8_t byte = FlutterStandardCodecHelperReadByte(location, data);
  if (byte < 254) {
    return (uint32_t)byte;
  } else if (byte == 254) {
    UInt16 value;
    FlutterStandardCodecHelperReadBytes(location, 2, &value, data);
    return value;
  } else {
    UInt32 value;
    FlutterStandardCodecHelperReadBytes(location, 4, &value, data);
    return value;
  }
}

static CFDataRef ReadDataNoCopy(unsigned long* location,
                                unsigned long length,
                                CFDataRef data) {
  CFDataRef result = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault, CFDataGetBytePtr(data) + *location, length,
      kCFAllocatorNull);
  *location += length;
  return CFAutorelease(result);
}

CFStringRef FlutterStandardCodecHelperReadUTF8(unsigned long* location,
                                               CFDataRef data) {
  uint32_t size = FlutterStandardCodecHelperReadSize(location, data);
  CFDataRef bytes = ReadDataNoCopy(location, size, data);
  CFStringRef result = CFStringCreateFromExternalRepresentation(
      kCFAllocatorDefault, bytes, kCFStringEncodingUTF8);
  return CFAutorelease(result);
}

// Peeks ahead to see if we are reading a standard type.  If so, recurse
// directly to FlutterStandardCodecHelperReadValueOfType, otherwise recurse to
// objc.
static inline CFTypeRef FastReadValue(
    unsigned long* location,
    CFDataRef data,
    CFTypeRef (*ReadValue)(CFTypeRef),
    CFTypeRef (*ReadTypedDataOfType)(FlutterStandardField, CFTypeRef),
    CFTypeRef user_data) {
  uint8_t type = PeekByte(*location, data);
  if (FlutterStandardFieldIsStandardType(type)) {
    *location += 1;
    return FlutterStandardCodecHelperReadValueOfType(
        location, data, type, ReadValue, ReadTypedDataOfType, user_data);
  } else {
    return ReadValue(user_data);
  }
}

CFTypeRef FlutterStandardCodecHelperReadValueOfType(
    unsigned long* location,
    CFDataRef data,
    uint8_t type,
    CFTypeRef (*ReadValue)(CFTypeRef),
    CFTypeRef (*ReadTypedDataOfType)(FlutterStandardField, CFTypeRef),
    CFTypeRef user_data) {
  FlutterStandardField field = (FlutterStandardField)type;
  switch (field) {
    case FlutterStandardFieldNil:
      return nil;
    case FlutterStandardFieldTrue:
      return kCFBooleanTrue;
    case FlutterStandardFieldFalse:
      return kCFBooleanFalse;
    case FlutterStandardFieldInt32: {
      int32_t value;
      FlutterStandardCodecHelperReadBytes(location, 4, &value, data);
      return CFAutorelease(
          CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &value));
    }
    case FlutterStandardFieldInt64: {
      int64_t value;
      FlutterStandardCodecHelperReadBytes(location, 8, &value, data);
      return CFAutorelease(
          CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &value));
    }
    case FlutterStandardFieldFloat64: {
      Float64 value;
      FlutterStandardCodecHelperReadAlignment(location, 8);
      FlutterStandardCodecHelperReadBytes(location, 8, &value, data);
      return CFAutorelease(
          CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &value));
    }
    case FlutterStandardFieldIntHex:
    case FlutterStandardFieldString:
      return FlutterStandardCodecHelperReadUTF8(location, data);
    case FlutterStandardFieldUInt8Data:
    case FlutterStandardFieldInt32Data:
    case FlutterStandardFieldInt64Data:
    case FlutterStandardFieldFloat32Data:
    case FlutterStandardFieldFloat64Data:
      return ReadTypedDataOfType(field, user_data);
    case FlutterStandardFieldList: {
      UInt32 length = FlutterStandardCodecHelperReadSize(location, data);
      CFMutableArrayRef array = CFArrayCreateMutable(
          kCFAllocatorDefault, length, &kCFTypeArrayCallBacks);
      for (UInt32 i = 0; i < length; i++) {
        CFTypeRef value = FastReadValue(location, data, ReadValue,
                                        ReadTypedDataOfType, user_data);
        CFArrayAppendValue(array, (value == nil ? kCFNull : value));
      }
      return CFAutorelease(array);
    }
    case FlutterStandardFieldMap: {
      UInt32 size = FlutterStandardCodecHelperReadSize(location, data);
      CFMutableDictionaryRef dict = CFDictionaryCreateMutable(
          kCFAllocatorDefault, size, &kCFTypeDictionaryKeyCallBacks,
          &kCFTypeDictionaryValueCallBacks);
      for (UInt32 i = 0; i < size; i++) {
        CFTypeRef key = FastReadValue(location, data, ReadValue,
                                      ReadTypedDataOfType, user_data);
        CFTypeRef val = FastReadValue(location, data, ReadValue,
                                      ReadTypedDataOfType, user_data);
        CFDictionaryAddValue(dict, (key == nil ? kCFNull : key),
                             (val == nil ? kCFNull : val));
      }
      return CFAutorelease(dict);
    }
    default:
      // Malformed message.
      assert(false);
  }
}
