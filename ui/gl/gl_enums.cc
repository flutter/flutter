// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>
#include <GLES2/gl2.h>

#include "ui/gl/gl_enums.h"

namespace gfx {

std::string GLEnums::GetStringEnum(uint32 value) {
  const EnumToString* entry = enum_to_string_table_;
  const EnumToString* end = entry + enum_to_string_table_len_;
  for (;entry < end; ++entry) {
    if (value == entry->value) {
      return entry->name;
    }
  }
  std::stringstream ss;
  ss.fill('0');
  ss.width(value < 0x10000 ? 4 : 8);
  ss << std::hex << value;
  return "0x" + ss.str();
}

std::string GLEnums::GetStringError(uint32 value) {
  if (value == GL_NONE)
    return "GL_NONE";
  return GetStringEnum(value);
}

std::string GLEnums::GetStringBool(uint32 value) {
  return value ? "GL_TRUE" : "GL_FALSE";
}

#include "ui/gl/gl_enums_implementation_autogen.h"

}  // namespace gfx

