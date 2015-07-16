// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/value_conversions.h"

#include <string>

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/strings/string_number_conversions.h"
#include "base/time/time.h"
#include "base/values.h"

namespace base {

// |Value| internally stores strings in UTF-8, so we have to convert from the
// system native code to UTF-8 and back.
StringValue* CreateFilePathValue(const FilePath& in_value) {
  return new StringValue(in_value.AsUTF8Unsafe());
}

bool GetValueAsFilePath(const Value& value, FilePath* file_path) {
  std::string str;
  if (!value.GetAsString(&str))
    return false;
  if (file_path)
    *file_path = FilePath::FromUTF8Unsafe(str);
  return true;
}

// |Value| does not support 64-bit integers, and doubles do not have enough
// precision, so we store the 64-bit time value as a string instead.
StringValue* CreateTimeDeltaValue(const TimeDelta& time) {
  std::string string_value = base::Int64ToString(time.ToInternalValue());
  return new StringValue(string_value);
}

bool GetValueAsTimeDelta(const Value& value, TimeDelta* time) {
  std::string str;
  int64 int_value;
  if (!value.GetAsString(&str) || !base::StringToInt64(str, &int_value))
    return false;
  if (time)
    *time = TimeDelta::FromInternalValue(int_value);
  return true;
}

}  // namespace base
