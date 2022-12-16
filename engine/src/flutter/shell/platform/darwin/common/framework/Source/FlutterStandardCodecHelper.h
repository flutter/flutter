// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECHELPER_H_
#define SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECHELPER_H_

#include <CoreFoundation/CoreFoundation.h>
#include <stdbool.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

// Note: Update FlutterStandardFieldIsStandardType if this changes.
typedef enum {
  FlutterStandardFieldNil,
  FlutterStandardFieldTrue,
  FlutterStandardFieldFalse,
  FlutterStandardFieldInt32,
  FlutterStandardFieldInt64,
  FlutterStandardFieldIntHex,
  FlutterStandardFieldFloat64,
  FlutterStandardFieldString,
  FlutterStandardFieldUInt8Data,
  FlutterStandardFieldInt32Data,
  FlutterStandardFieldInt64Data,
  FlutterStandardFieldFloat64Data,
  FlutterStandardFieldList,
  FlutterStandardFieldMap,
  FlutterStandardFieldFloat32Data,
} FlutterStandardField;

static inline bool FlutterStandardFieldIsStandardType(uint8_t field) {
  return field <= FlutterStandardFieldFloat32Data &&
         field >= FlutterStandardFieldNil;
}

void FlutterStandardCodecHelperReadAlignment(unsigned long* location,
                                             uint8_t alignment);

void FlutterStandardCodecHelperReadBytes(unsigned long* location,
                                         unsigned long length,
                                         void* destination,
                                         CFDataRef data);

uint8_t FlutterStandardCodecHelperReadByte(unsigned long* location,
                                           CFDataRef data);

uint32_t FlutterStandardCodecHelperReadSize(unsigned long* location,
                                            CFDataRef data);

CFStringRef FlutterStandardCodecHelperReadUTF8(unsigned long* location,
                                               CFDataRef data);

CFTypeRef FlutterStandardCodecHelperReadValueOfType(
    unsigned long* location,
    CFDataRef data,
    uint8_t type,
    CFTypeRef (*ReadValue)(CFTypeRef),
    CFTypeRef (*ReadTypedDataOfType)(FlutterStandardField, CFTypeRef),
    CFTypeRef user_data);

#if defined(__cplusplus)
}
#endif

#endif  // SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECHELPER_H_
