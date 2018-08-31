// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"

typedef NS_ENUM(NSInteger, FlutterStandardField) {
  FlutterStandardFieldNil,
  FlutterStandardFieldTrue,
  FlutterStandardFieldFalse,
  FlutterStandardFieldInt32,
  FlutterStandardFieldInt64,
  FlutterStandardFieldIntHex,
  FlutterStandardFieldFloat64,
  FlutterStandardFieldString,
  // The following must match the corresponding order from `FlutterStandardDataType`.
  FlutterStandardFieldUInt8Data,
  FlutterStandardFieldInt32Data,
  FlutterStandardFieldInt64Data,
  FlutterStandardFieldFloat64Data,
  FlutterStandardFieldList,
  FlutterStandardFieldMap,
};

namespace shell {
FlutterStandardField FlutterStandardFieldForDataType(FlutterStandardDataType type) {
  return (FlutterStandardField)(type + FlutterStandardFieldUInt8Data);
}
FlutterStandardDataType FlutterStandardDataTypeForField(FlutterStandardField field) {
  return (FlutterStandardDataType)(field - FlutterStandardFieldUInt8Data);
}
UInt8 elementSizeForFlutterStandardDataType(FlutterStandardDataType type) {
  switch (type) {
    case FlutterStandardDataTypeUInt8:
      return 1;
    case FlutterStandardDataTypeInt32:
      return 4;
    case FlutterStandardDataTypeInt64:
      return 8;
    case FlutterStandardDataTypeFloat64:
      return 8;
  }
}
}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_
