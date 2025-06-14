// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/comments_util.h"
#include "flutter/third_party/re2/re2/re2.h"

void CommentsUtil::AddTrimLine(std::string* buffer,
                               const char* text,
                               size_t length) {
  RE2 regex(R"regex(^(?:\s*//\s?)(.*))regex");
  re2::StringPiece captured_content;
  RE2::FullMatch(re2::StringPiece(text), regex, &captured_content);
  buffer->append(captured_content);
}
