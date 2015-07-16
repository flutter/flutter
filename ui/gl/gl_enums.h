// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_ENUMS_H_
#define UI_GL_GL_ENUMS_H_

#include <string>

#include "base/basictypes.h"
#include "ui/gl/gl_export.h"

namespace gfx {

class GL_EXPORT GLEnums {
 public:
  struct EnumToString {
    uint32_t value;
    const char* name;
  };

  static std::string GetStringEnum(uint32_t value);
  static std::string GetStringBool(uint32_t value);
  static std::string GetStringError(uint32_t value);

 private:
  static const EnumToString* const enum_to_string_table_;
  static const size_t enum_to_string_table_len_;
};

}  // namespace gfx

#endif  // UI_GL_GL_ENUMS_H_

