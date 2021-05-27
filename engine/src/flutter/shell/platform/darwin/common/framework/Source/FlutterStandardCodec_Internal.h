// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_
#define SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"

typedef NS_ENUM(NSInteger, FlutterStandardField) {
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
};

namespace flutter {
FlutterStandardField FlutterStandardFieldForDataType(FlutterStandardDataType type) {
  switch (type) {
    case FlutterStandardDataTypeUInt8:
      return FlutterStandardFieldUInt8Data;
    case FlutterStandardDataTypeInt32:
      return FlutterStandardFieldInt32Data;
    case FlutterStandardDataTypeInt64:
      return FlutterStandardFieldInt64Data;
    case FlutterStandardDataTypeFloat32:
      return FlutterStandardFieldFloat32Data;
    case FlutterStandardDataTypeFloat64:
      return FlutterStandardFieldFloat64Data;
  }
}
FlutterStandardDataType FlutterStandardDataTypeForField(FlutterStandardField field) {
  switch (field) {
    case FlutterStandardFieldUInt8Data:
      return FlutterStandardDataTypeUInt8;
    case FlutterStandardFieldInt32Data:
      return FlutterStandardDataTypeInt32;
    case FlutterStandardFieldInt64Data:
      return FlutterStandardDataTypeInt64;
    case FlutterStandardFieldFloat32Data:
      return FlutterStandardDataTypeFloat32;
    case FlutterStandardFieldFloat64Data:
      return FlutterStandardDataTypeFloat64;
    default:
      return FlutterStandardDataTypeUInt8;
  }
}

UInt8 elementSizeForFlutterStandardDataType(FlutterStandardDataType type) {
  switch (type) {
    case FlutterStandardDataTypeUInt8:
      return 1;
    case FlutterStandardDataTypeInt32:
      return 4;
    case FlutterStandardDataTypeInt64:
      return 8;
    case FlutterStandardDataTypeFloat32:
      return 4;
    case FlutterStandardDataTypeFloat64:
      return 8;
  }
}
}  // namespace flutter

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERSTANDARDCODECINTERNAL_H_
