// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_VALUE_CONVERSIONS_H_
#define BASE_VALUE_CONVERSIONS_H_

// This file contains methods to convert things to a |Value| and back.

#include "base/base_export.h"


namespace base {

class FilePath;
class TimeDelta;
class StringValue;
class Value;

// The caller takes ownership of the returned value.
BASE_EXPORT StringValue* CreateFilePathValue(const FilePath& in_value);
BASE_EXPORT bool GetValueAsFilePath(const Value& value, FilePath* file_path);

BASE_EXPORT StringValue* CreateTimeDeltaValue(const TimeDelta& time);
BASE_EXPORT bool GetValueAsTimeDelta(const Value& value, TimeDelta* time);

}  // namespace base

#endif  // BASE_VALUE_CONVERSIONS_H_
