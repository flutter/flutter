// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_version_info.h"

#include "base/strings/string_number_conversions.h"
#include "base/strings/string_tokenizer.h"
#include "base/strings/string_util.h"

namespace gfx {

GLVersionInfo::GLVersionInfo(const char* version_str, const char* renderer_str)
    : is_es(false),
      is_angle(false),
      major_version(0),
      minor_version(0),
      is_es3(false) {
  if (version_str) {
    std::string lstr(base::StringToLowerASCII(std::string(version_str)));
    is_es = (lstr.length() > 12) && (lstr.substr(0, 9) == "opengl es");
    if (is_es)
      lstr = lstr.substr(10, 3);
    base::StringTokenizer tokenizer(lstr.begin(), lstr.end(), ".");
    unsigned major, minor;
    if (tokenizer.GetNext() &&
        base::StringToUint(tokenizer.token_piece(), &major)) {
      major_version = major;
      if (tokenizer.GetNext() &&
          base::StringToUint(tokenizer.token_piece(), &minor)) {
        minor_version = minor;
      }
    }
    if (is_es && major_version == 3)
      is_es3 = true;
  }
  if (renderer_str) {
    is_angle = StartsWithASCII(renderer_str, "ANGLE", true);
  }
}

}  // namespace gfx
