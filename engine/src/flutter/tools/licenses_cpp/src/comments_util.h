// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_UTIL_H_
#define FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_UTIL_H_

#include <string>

/// @brief Helper functions for the generated comments lexer.
class CommentsUtil {
 public:
  static void AddTrimLine(std::string* buffer, const char* text, size_t length);
  static void AddCTrimLine(std::string* buffer,
                           const char* text,
                           size_t length);
  static void AddCEndTrimLine(std::string* buffer,
                              const char* text,
                              size_t length);
};

#endif  // FLUTTER_TOOLS_LICENSES_CPP_SRC_COMMENTS_UTIL_H_
